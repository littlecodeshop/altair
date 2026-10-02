"""Altair 8800 front panel, built procedurally with Blender's Python API.

    python3 altair_panel.py                       # build .blend + render all cameras
    python3 altair_panel.py --no-render           # build the .blend only
    python3 altair_panel.py --only front,macro_switch --samples 32

Needs the `bpy` module (pip install bpy) or run it with `blender -b -P`.

Structure of the generated .blend (everything is editable):

  Elements  (the "workbench": masters you edit, hidden from render)
    LED_Off      LED, unlit      \\  share ONE mesh (LED_mesh) -> edit once,
    LED_On       LED, lit + light /   both update. Materials are separate.
    Toggle_Up    switch, lever up   \\ share the meshes Toggle_Body_mesh and
    Toggle_Down  switch, lever down /  Toggle_Lever_mesh
  Altair_Panel  plate + silkscreen text + one collection-instance empty per
                LED / switch.  Editing a master updates every instance.

Materials (Material Properties / Shading editor): Chrome, Steel_Nut,
LED_Bezel, LED_Glass_Off, LED_Glass_On, LED_Core_Off, LED_Core_On,
Panel_Blue, Silkscreen.

Units: 1 Blender unit = 1 mm. Panel in the XZ plane, front face at y = 0,
parts stick out towards -Y.  Master elements are modelled along +Z; the
instance empties are rotated so +Z points out of the panel (-Y).
"""
import math
import os
import sys

import bpy
import bmesh  # noqa: E402 (must come after bpy when using the pip module)
from mathutils import Matrix, Vector

OUT_DIR = os.path.dirname(os.path.abspath(__file__))

# ---- Parameters ------------------------------------------------------------
PANEL_W, PANEL_H, PANEL_T = 432.0, 178.0, 3.0
ADDRESS = 0b0000_0001_1100_1010   # A15..A0 shown on switches and LEDs
DATA = 0xC3                        # D7..D0 (JMP)
STATUS_ON = {"MEMR", "M1", "WO"}
SWITCH_PITCH, GROUP_GAP = 12.5, 4.0
LEVER_TILT = 38.0                  # degrees from straight out
LEVER_PIVOT_Z = 9.6                # where the lever pivots (top of bushing)
LED_LIGHT_W = 600.0                # point light inside each lit LED
SEG = 48

COL_PANEL = (0.02, 0.09, 0.30, 1)
COL_TEXT = (0.92, 0.92, 0.88, 1)


# ---- Materials -------------------------------------------------------------
def mat(name, base, metallic=0.0, rough=0.4, emit=0.0, emit_col=None,
        transmission=0.0, ior=1.45):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = base
    b.inputs["Metallic"].default_value = metallic
    b.inputs["Roughness"].default_value = rough
    b.inputs["IOR"].default_value = ior
    b.inputs["Transmission Weight"].default_value = transmission
    b.inputs["Emission Color"].default_value = emit_col or base
    b.inputs["Emission Strength"].default_value = emit
    m.use_fake_user = True
    return m


def make_materials():
    return {
        "chrome": mat("Chrome", (0.9, 0.9, 0.92, 1), 1.0, 0.06),
        "nut": mat("Steel_Nut", (0.6, 0.6, 0.63, 1), 1.0, 0.28),
        "bezel": mat("LED_Bezel", (0.75, 0.72, 0.62, 1), 1.0, 0.22),
        "glass_off": mat("LED_Glass_Off", (0.45, 0.02, 0.02, 1), 0.0, 0.03,
                         transmission=1.0, ior=1.5),
        "glass_on": mat("LED_Glass_On", (1.0, 0.12, 0.08, 1), 0.0, 0.03,
                        emit=1.5, transmission=1.0, ior=1.5),
        "core_off": mat("LED_Core_Off", (0.25, 0.02, 0.02, 1), 0.0, 0.4),
        "core_on": mat("LED_Core_On", (1.0, 0.1, 0.05, 1), 0.0, 0.4,
                       emit=40.0),
        "panel": mat("Panel_Blue", COL_PANEL, 0.0, 0.45),
        "text": mat("Silkscreen", COL_TEXT, 0.0, 0.6),
        "backdrop": mat("Backdrop", (0.12, 0.12, 0.13, 1), 0.0, 0.9),
    }


# ---- Mesh builders (bmesh) ---------------------------------------------------
def lathe(bm, profile, mat_idx, seg=SEG):
    """Revolve a closed (r, z) profile polygon around Z."""
    old_v, old_f = set(bm.verts), set(bm.faces)
    vs = [bm.verts.new((r, 0.0, z)) for r, z in profile]
    es = [bm.edges.new((vs[i], vs[(i + 1) % len(vs)])) for i in range(len(vs))]
    bmesh.ops.spin(bm, geom=vs + es, cent=(0, 0, 0), axis=(0, 0, 1),
                   dvec=(0, 0, 0), angle=2 * math.pi, steps=seg,
                   use_merge=False, use_duplicate=False)
    new_v = [v for v in bm.verts if v not in old_v]
    bmesh.ops.remove_doubles(bm, verts=new_v, dist=1e-4)
    bmesh.ops.delete(bm, geom=[e for e in bm.edges if not e.link_faces],
                     context="EDGES")
    new_f = [f for f in bm.faces if f not in old_f]
    bmesh.ops.recalc_face_normals(bm, faces=new_f)
    for f in new_f:
        f.material_index = mat_idx
        f.smooth = True


def hex_nut(bm, z0, height, radius, mat_idx, chamfer=0.35):
    old_f = set(bm.faces)
    ret = bmesh.ops.create_cone(
        bm, cap_ends=True, cap_tris=False, segments=6, radius1=radius,
        radius2=radius, depth=height,
        matrix=Matrix.Translation((0, 0, z0 + height / 2)))
    edges = {e for v in ret["verts"] for e in v.link_edges}
    bmesh.ops.bevel(bm, geom=list(edges), offset=chamfer, segments=2,
                    affect="EDGES")
    for f in bm.faces:
        if f not in old_f:
            f.material_index = mat_idx
            f.smooth = True


def arc(cz, R, phi0, phi1, n):
    """Points (r, z) of a circle centred on the axis at height cz."""
    return [(R * math.sin(phi0 + (phi1 - phi0) * i / n),
             cz + R * math.cos(phi0 + (phi1 - phi0) * i / n)) for i in range(n + 1)]


def finish(bm, name):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.set_sharp_from_angle(angle=math.radians(35))
    return me


def build_led_mesh(m):
    bm = bmesh.new()
    # 0: bezel ring (chamfered, with a groove)
    lathe(bm, [(2.55, 0), (3.5, 0), (3.5, 1.0), (3.2, 1.35), (2.9, 1.35),
               (2.75, 1.15), (2.55, 1.15)], 0)
    # 1: glass lens - closed solid, domed top
    lens = [(0, 0.25), (2.5, 0.25), (2.5, 0.9)]
    lens += arc(0.9, 2.5, math.pi / 2, 0.0, 14)[1:]
    lathe(bm, lens, 1)
    # 2: emitter core inside the lens
    core = [(0, 0.45)] + arc(1.05, 0.95, math.pi - 0.5, 0.0, 12)
    lathe(bm, core, 2, seg=24)
    me = finish(bm, "LED_mesh")
    for k in ("bezel", "glass_off", "core_off"):
        me.materials.append(m[k])
    return me


def build_toggle_meshes(m):
    # Body: washer, chamfered hex nut, threaded bushing.  Slots: 0 chrome, 1 nut
    bm = bmesh.new()
    lathe(bm, [(0, 0), (5.8, 0), (5.8, 0.55), (5.2, 0.7), (0, 0.7)], 1)
    hex_nut(bm, 0.7, 2.4, 4.6, 1)
    thread = [(0, 3.1), (2.95, 3.1)]
    z, pitch = 3.1, 0.7
    for _ in range(9):
        thread += [(2.85, z + 0.05), (3.25, z + 0.28), (3.25, z + 0.42),
                   (2.85, z + 0.65)]
        z += pitch
    thread += [(2.85, z), (2.4, z + 0.35), (0, z + 0.35)]
    lathe(bm, thread, 0)
    body = finish(bm, "Toggle_Body_mesh")
    body.materials.append(m["chrome"])
    body.materials.append(m["nut"])

    # Lever: ridged collar, tapered shaft with grip rings, ball tip
    bm = bmesh.new()
    prof = [(0, 0), (2.7, 0), (2.7, 0.5), (2.3, 0.8)]
    z = 0.8
    for _ in range(4):                      # grip ridges around the collar
        prof += [(2.0, z + 0.1), (2.45, z + 0.3), (2.45, z + 0.5),
                 (2.0, z + 0.7)]
        z += 0.8
    prof += [(1.85, z + 0.2)]               # z ~ 4.2
    z_end = 11.2
    for i in range(1, 7):                   # tapered shaft with fine rings
        t = i / 6
        r = 1.85 + (1.15 - 1.85) * t
        zz = z + 0.2 + (z_end - z - 0.2) * t
        prof += [(r + 0.12, zz - 0.15), (r + 0.12, zz - 0.02), (r, zz)]
    phi0 = math.pi - math.asin(1.15 / 1.9)
    prof += arc(12.6, 1.9, phi0, 0.0, 16)[1:]
    lathe(bm, prof, 0)
    lever = finish(bm, "Toggle_Lever_mesh")
    lever.materials.append(m["chrome"])
    return body, lever


# ---- Master elements ----------------------------------------------------------
def new_collection(name, parent=None):
    c = bpy.data.collections.new(name)
    (parent or bpy.context.scene.collection).children.link(c)
    return c


def add_obj(name, data, coll, loc=(0, 0, 0), rot=(0, 0, 0)):
    o = bpy.data.objects.new(name, data)
    o.location, o.rotation_euler = loc, rot
    coll.objects.link(o)
    return o


def build_masters(m, elements):
    led_me = build_led_mesh(m)
    body_me, lever_me = build_toggle_meshes(m)
    masters = {}

    for state in ("Off", "On"):
        c = new_collection("LED_" + state, elements)
        o = add_obj("LED_" + state + "_obj", led_me, c)
        o.cycles.is_caustics_caster = True
        if state == "On":
            for slot, key in zip(o.material_slots,
                                 ("bezel", "glass_on", "core_on")):
                slot.link = "OBJECT"
                slot.material = m[key]
            # Glass would block the light sitting inside it, so it must not
            # cast shadows; light still passes through for MNEE caustics.
            o.visible_shadow = False
            ld = bpy.data.lights.new("LED_light", "POINT")
            ld.color = (1.0, 0.12, 0.06)
            ld.energy = LED_LIGHT_W
            ld.shadow_soft_size = 0.8
            ld.cycles.is_caustics_light = True
            add_obj("LED_light", ld, c, loc=(0, 0, 1.6))
        masters["LED_" + state] = c

    for state, sign in (("Up", -1), ("Down", 1)):
        c = new_collection("Toggle_" + state, elements)
        add_obj("Toggle_" + state + "_body", body_me, c)
        lv = add_obj("Toggle_" + state + "_lever", lever_me, c,
                     loc=(0, 0, LEVER_PIVOT_Z),
                     rot=(sign * math.radians(LEVER_TILT), 0, 0))
        for ob in c.objects:
            ob.cycles.is_caustics_caster = True
        masters["Toggle_" + state] = c
    return masters


def instance(name, coll, x, z, parent_coll):
    e = bpy.data.objects.new(name, None)
    e.instance_type = "COLLECTION"
    e.instance_collection = coll
    e.empty_display_size = 3
    e.location = (x, 0, z)
    e.rotation_euler = (math.pi / 2, 0, 0)   # master +Z -> panel -Y
    parent_coll.objects.link(e)
    return e


def set_led(empty, masters, on):
    """Swap an LED instance between the lit and unlit master."""
    empty.instance_collection = masters["LED_On" if on else "LED_Off"]


# ---- Panel ---------------------------------------------------------------------
def text(txt, x, z, size, material, coll, align="CENTER"):
    c = bpy.data.curves.new("t", "FONT")
    c.body, c.size, c.align_x, c.align_y, c.extrude = txt, size, align, "CENTER", 0.04
    o = bpy.data.objects.new("txt_" + txt, c)
    coll.objects.link(o)
    o.rotation_euler = (math.pi / 2, 0, 0)
    o.location = (x, -0.05, z)
    o.data.materials.append(material)
    return o


def rule(x0, x1, z, w, material, coll):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    me = bpy.data.meshes.new("rule")
    bm.to_mesh(me)
    bm.free()
    me.materials.append(material)
    o = add_obj("rule", me, coll, loc=((x0 + x1) / 2, -0.05, z))
    o.scale = (x1 - x0, 0.1, w)


def build_panel(m, masters, coll):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    me = bpy.data.meshes.new("Panel_plate_mesh")
    bm.to_mesh(me)
    bm.free()
    me.materials.append(m["panel"])
    plate = add_obj("Panel_plate", me, coll,
                    loc=(PANEL_W / 2, PANEL_T / 2, PANEL_H / 2))
    plate.scale = (PANEL_W, PANEL_T, PANEL_H)
    plate.cycles.is_caustics_receiver = True
    bpy.context.view_layer.objects.active = plate
    plate.select_set(True)
    bpy.ops.object.transform_apply(scale=True)   # bake scale before bevel
    bev = plate.modifiers.new("bevel", "BEVEL")
    bev.width, bev.segments = 1.2, 3

    tx = m["text"]
    z_stat, z_addr, z_sw = 140.0, 113.0, 40.0
    text("ALTAIR 8800", 76, 160, 8.5, tx, coll)
    text("MITS", 380, 160, 6, tx, coll)
    rule(14, PANEL_W - 14, 154, 0.5, tx, coll)
    rule(14, PANEL_W - 14, 77, 0.4, tx, coll)

    def led(name, x, z, on):
        set_led(instance("LED_" + name, masters["LED_Off"], x, z, coll),
                masters, on)
        text(name, x, z + 8, 2.6, tx, coll)

    status = ["INT", "WO", "STACK", "HLTA", "OUT", "M1", "INP", "MEMR", "PROT", "INTE"]
    for i, n in enumerate(status):
        led(n, 38.0 + i * 16.0, z_stat, n in STATUS_ON)
    for i in range(8):
        bit = 7 - i
        led(f"D{bit}", 250.0 + i * 17.0, z_stat, bool(DATA >> bit & 1))
    text("DATA", 250.0 + 3.5 * 17.0, z_stat - 8.5, 3.2, tx, coll)
    led("WAIT", 32, z_addr, False)
    led("HLDA", 48, z_addr, False)

    def addr_x(bit):
        return 70.0 + (15 - bit) * SWITCH_PITCH + (5 - (bit + 2) // 3) * GROUP_GAP

    for bit in range(15, -1, -1):
        led(f"A{bit}", addr_x(bit), z_addr, bool(ADDRESS >> bit & 1))
    text("ADDRESS", addr_x(8), z_addr - 8.5, 3.2, tx, coll)

    def toggle(name, x, z, up):
        instance("SW_" + name, masters["Toggle_Up" if up else "Toggle_Down"],
                 x, z, coll)

    for bit in range(15, -1, -1):
        toggle(f"A{bit}", addr_x(bit), z_sw, bool(ADDRESS >> bit & 1))
        text(str(bit), addr_x(bit), z_sw - 19, 3.2, tx, coll)
    text("SENSE / ADDRESS", addr_x(8), z_sw + 20, 3.2, tx, coll)
    toggle("power", 22, z_sw, True)
    text("ON", 22, z_sw + 17, 3.2, tx, coll)
    text("OFF", 22, z_sw - 19, 3.2, tx, coll)

    ctrl = [("STOP", "RUN"), ("SINGLE", "STEP"), ("EXAMINE", "NEXT"),
            ("DEPOSIT", "NEXT"), ("RESET", "CLR"), ("PROTECT", "UNPROTECT"),
            ("AUX", "AUX")]
    for i, (top, bot) in enumerate(ctrl):
        x = 305.0 + i * 17.0
        toggle(f"ctrl{i}", x, z_sw, False)
        text(top, x, z_sw + 17, 2.4, tx, coll)
        text(bot, x, z_sw - 19, 2.4, tx, coll)
    return addr_x, z_addr, z_sw


# ---- Scene -----------------------------------------------------------------------
def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.scale_length = 0.001
    scene.unit_settings.length_unit = "MILLIMETERS"
    m = make_materials()

    elements = new_collection("Elements")
    masters = build_masters(m, elements)
    # lay the masters out on a workbench below the panel so they can be edited
    for i, c in enumerate(masters.values()):
        off = Vector((-60 + i * 40, 0, -70))
        c.instance_offset = off           # so instances ignore the bench spot
        for o in c.objects:
            o.location += off
    panel = new_collection("Altair_Panel")
    addr_x, z_addr, z_sw = build_panel(m, masters, panel)
    elements.hide_render = True           # workbench copies don't render

    # backdrop
    bpy.ops.mesh.primitive_plane_add(size=4000)
    bd = bpy.context.object
    bd.rotation_euler = (math.pi / 2, 0, 0)
    bd.location = (PANEL_W / 2, 400, PANEL_H / 2)
    bd.data.materials.append(m["backdrop"])

    # lights
    def area(name, loc, energy, size, rot):
        bpy.ops.object.light_add(type="AREA", location=loc)
        o = bpy.context.object
        o.name = name
        o.data.energy, o.data.size, o.rotation_euler = energy, size, rot
        return o

    area("Key", (PANEL_W / 2, -500, 380), 2.2e6, 400, (math.radians(60), 0, 0))
    area("Fill", (-250, -450, 120), 6e5, 300, (math.pi / 2, 0, math.radians(-35)))
    # small light that drives reflective/refractive caustics
    bpy.ops.object.light_add(type="POINT", location=(PANEL_W / 2 + 80, -260, 330))
    cl = bpy.context.object
    cl.name = "Caustics_Light"
    cl.data.energy, cl.data.shadow_soft_size = 4.0e5, 3.0
    cl.data.cycles.is_caustics_light = True

    # render settings
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 64
    scene.cycles.use_denoising = True
    scene.cycles.caustics_reflective = True
    scene.cycles.caustics_refractive = True
    scene.cycles.glossy_bounces = 8
    scene.cycles.transmission_bounces = 8
    scene.render.resolution_x, scene.render.resolution_y = 1800, 760

    center = Vector((PANEL_W / 2, 0, PANEL_H / 2))
    cams = {
        "front": ((PANEL_W / 2, -720, PANEL_H / 2), center, 50, (1800, 760)),
        "angle": ((PANEL_W / 2 + 330, -600, PANEL_H / 2 + 200), center, 50, (1800, 760)),
        "macro_led": ((addr_x(8) + 50, -190, z_addr + 45),
                      Vector((addr_x(8), -2, z_addr)), 85, (1400, 800)),
        "macro_switch": ((addr_x(8) + 50, -190, z_sw + 60),
                         Vector((addr_x(8), -6, z_sw + 2)), 85, (1400, 800)),
    }
    for name, (loc, target, lens, res) in cams.items():
        cd = bpy.data.cameras.new("cam_" + name)
        cd.lens = lens
        cam = bpy.data.objects.new("cam_" + name, cd)
        cam["res"] = res
        scene.collection.objects.link(cam)
        cam.location = loc
        cam.rotation_euler = (target - Vector(loc)).to_track_quat("-Z", "Y").to_euler()

    scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs[0].default_value = (0.03, 0.03, 0.035, 1)
    return scene


def render(scene, only):
    for name in ("front", "angle", "macro_led", "macro_switch"):
        if only and name not in only:
            continue
        cam = bpy.data.objects["cam_" + name]
        scene.camera = cam
        scene.render.resolution_x, scene.render.resolution_y = cam["res"]
        scene.render.filepath = os.path.join(OUT_DIR, f"altair_panel_{name}.png")
        bpy.ops.render.render(write_still=True)


def arg(flag, default=None):
    return sys.argv[sys.argv.index(flag) + 1] if flag in sys.argv else default


if __name__ == "__main__":
    sc = build()
    sc.cycles.samples = int(arg("--samples", sc.cycles.samples))
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "altair_panel.blend"))
    if "--no-render" not in sys.argv:
        only = arg("--only")
        render(sc, only.split(",") if only else None)
