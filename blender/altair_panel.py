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
LED_Lens_Off, LED_Lens_On, LED_Die_Off, LED_Die_On, Panel_Black,
Frame_Blue, Silkscreen, Logo_Gold, Logo_Ink, Case_Paint, Cover_Paint.

Layout follows a real 8800: status LEDs top-left, D7..D0 above A7..A0,
WAIT/HLDA + A15..A0 on row two, each address switch straight below its
LED, control switches on a lower row, "ALTAIR 8800 COMPUTER" strip at the
bottom; black smoked-plastic front in a light-blue aluminium frame.

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
SWITCH_PITCH, GROUP_GAP = 17.0, 6.0
LEVER_TILT = 30.0                  # degrees from straight out
LEVER_PIVOT_Z = 6.4                # where the lever pivots (top of bushing)
LED_LIGHT_W = 600.0                # point light inside each lit LED
SEG = 48

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
    m = {
        "chrome": mat("Chrome", (0.86, 0.86, 0.88, 1), 1.0, 0.14),
        "nut": mat("Steel_Nut", (0.62, 0.62, 0.64, 1), 1.0, 0.3),
        "lens_off": mat("LED_Lens_Off", (0.55, 0.02, 0.02, 1), 0.0, 0.12,
                        transmission=0.85, ior=1.5),
        "lens_on": mat("LED_Lens_On", (1.0, 0.1, 0.06, 1), 0.0, 0.12,
                       emit=2.0, transmission=0.85, ior=1.5),
        "die_off": mat("LED_Die_Off", (0.2, 0.02, 0.02, 1), 0.0, 0.4),
        "die_on": mat("LED_Die_On", (1.0, 0.1, 0.05, 1), 0.0, 0.4, emit=25.0),
        "panel": mat("Panel_Black", (0.006, 0.006, 0.008, 1), 0.0, 0.08),
        "frame": mat("Frame_Blue", (0.22, 0.50, 0.75, 1), 1.0, 0.35),
        "text": mat("Silkscreen", COL_TEXT, 0.0, 0.6),
        "logo": mat("Logo_Gold", (0.80, 0.58, 0.22, 1), 1.0, 0.32),
        "ink": mat("Logo_Ink", (0.02, 0.02, 0.02, 1), 0.0, 0.5),
        "case": mat("Case_Paint", (0.70, 0.68, 0.62, 1), 0.0, 0.5),
        "cover": mat("Cover_Paint", (0.76, 0.75, 0.70, 1), 0.0, 0.45),
        "feet": mat("Rubber_Feet", (0.03, 0.03, 0.03, 1), 0.0, 0.8),
        "backdrop": mat("Floor", (0.10, 0.10, 0.11, 1), 0.0, 0.7),
    }
    b = m["panel"].node_tree.nodes["Principled BSDF"]
    b.inputs["Coat Weight"].default_value = 1.0      # smoked acrylic gloss
    return m


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


def paddle(bm, w0, w1, t, z0, z1, mat_idx, round_=0.5):
    """Flat bat-handle lever blade, width w0 at z0 widening to w1 at z1."""
    old_f = set(bm.faces)
    m = Matrix.Translation((0, 0, (z0 + z1) / 2)) @ Matrix.Diagonal((w0, t, z1 - z0, 1))
    ret = bmesh.ops.create_cube(bm, size=1.0, matrix=m)
    for v in ret["verts"]:
        if v.co.z > (z0 + z1) / 2:
            v.co.x *= w1 / w0
    edges = {e for v in ret["verts"] for e in v.link_edges}
    bmesh.ops.bevel(bm, geom=list(edges), offset=round_, segments=3,
                    profile=0.5, affect="EDGES")
    for f in bm.faces:
        if f not in old_f:
            f.material_index = mat_idx
            f.smooth = True


def build_led_mesh(m):
    """Plain 5 mm red LED: rim + cylinder + dome (epoxy), die inside."""
    bm = bmesh.new()
    lens = [(0, 0), (2.95, 0), (2.95, 0.9), (2.5, 0.95), (2.5, 4.0)]
    lens += arc(4.0, 2.5, math.pi / 2, 0.0, 14)[1:]
    lathe(bm, lens, 0)
    lathe(bm, [(0, 1.4)] + arc(2.0, 0.6, math.pi - 0.3, 0.0, 8), 1, seg=16)
    me = finish(bm, "LED_mesh")
    for k in ("lens_off", "die_off"):
        me.materials.append(m[k])
    return me


def build_toggle_meshes(m):
    """Switch as bolted through the panel: only a thin hex nut on a short
    threaded bushing shows, with a flat bat-handle lever.
    Body slots: 0 chrome, 1 nut.  Lever origin = pivot."""
    bm = bmesh.new()
    hex_nut(bm, 0.0, 1.6, 5.2, 1, chamfer=0.3)
    thread = [(0, 1.6), (2.95, 1.6)]
    z, pitch = 1.6, 0.635                        # 1/4"-40 thread
    while z + pitch < LEVER_PIVOT_Z - 0.4:
        thread += [(2.95, z + 0.05), (3.25, z + 0.28), (3.25, z + 0.36),
                   (2.95, z + 0.6)]
        z += pitch
    thread += [(2.95, LEVER_PIVOT_Z - 0.3), (2.6, LEVER_PIVOT_Z),
               (1.9, LEVER_PIVOT_Z), (1.9, LEVER_PIVOT_Z - 0.5), (0, LEVER_PIVOT_Z - 0.5)]
    lathe(bm, thread, 0)
    body = finish(bm, "Toggle_Body_mesh")
    body.materials.append(m["chrome"])
    body.materials.append(m["nut"])

    bm = bmesh.new()
    lathe(bm, [(0, -1.5), (1.7, -1.5), (1.7, 1.8), (0, 1.8)], 0, seg=24)  # stem
    paddle(bm, 2.8, 3.8, 1.5, 1.0, 13.0, 0)
    lever = finish(bm, "Toggle_Lever_mesh")
    lever.materials.append(m["chrome"])
    return body, lever


# ---- User-made toggle switch (optional) ------------------------------------------
TOGGLE_FILE = os.path.join(OUT_DIR, "elements", "toggle_switch.blend")


def load_user_toggle():
    """Use elements/toggle_switch.blend if present.

    Contract: objects "Toggle_body" and "Toggle_lever"; millimetres; the
    switch stands on the panel at the origin with +Z pointing out of the
    panel; the lever is modelled straight (neutral) and its object origin
    is its pivot (that is where it tilts).  Returns (body_mesh, lever_mesh,
    lever_location) or None.
    """
    if not os.path.exists(TOGGLE_FILE):
        return None
    with bpy.data.libraries.load(TOGGLE_FILE, link=False) as (src, dst):
        dst.objects = [n for n in ("Toggle_body", "Toggle_lever") if n in src.objects]
    objs = {o.name.split(".")[0]: o for o in dst.objects if o}
    if len(objs) != 2:
        raise SystemExit("toggle_switch.blend needs objects Toggle_body and Toggle_lever")
    # Bake modifiers (at render quality) and object scale/rotation into the
    # mesh; keep only the location (the lever's is its pivot).
    tmp = bpy.data.collections.new("_tmp")
    bpy.context.scene.collection.children.link(tmp)
    for o in objs.values():
        tmp.objects.link(o)
        for mod in o.modifiers:
            if hasattr(mod, "render_levels"):
                mod.levels = mod.render_levels
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    out = {}
    for key, o in objs.items():
        me = bpy.data.meshes.new_from_object(o.evaluated_get(dg))
        me.name = key + "_mesh"
        me.transform(Matrix.LocRotScale(None, o.rotation_euler, o.scale))
        out[key] = (me, Vector(o.location))
        tmp.objects.unlink(o)
    bpy.context.scene.collection.children.unlink(tmp)
    print("Using user-made toggle from", TOGGLE_FILE)
    return out["Toggle_body"][0], out["Toggle_lever"][0], out["Toggle_lever"][1]


def export_toggle_template():
    """Write elements/toggle_switch.blend containing the procedural switch."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    m = make_materials()
    body_me, lever_me = build_toggle_meshes(m)
    c = new_collection("Toggle")
    add_obj("Toggle_body", body_me, c)
    add_obj("Toggle_lever", lever_me, c, loc=(0, 0, LEVER_PIVOT_Z))
    # reference-only helpers: anything named REF_* is ignored by the script
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    ref = bpy.data.meshes.new("REF_panel")
    bm.to_mesh(ref)
    bm.free()
    p = add_obj("REF_panel", ref, c, loc=(0, 0, -1.5))
    p.scale = (30, 30, 3)
    p.display_type = "WIRE"
    os.makedirs(os.path.dirname(TOGGLE_FILE), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=TOGGLE_FILE)
    print("Wrote", TOGGLE_FILE)


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
    user = load_user_toggle()
    if user:
        body_me, lever_me, lever_loc = user
    else:
        body_me, lever_me = build_toggle_meshes(m)
        lever_loc = Vector((0, 0, LEVER_PIVOT_Z))
    masters = {}

    for state in ("Off", "On"):
        c = new_collection("LED_" + state, elements)
        o = add_obj("LED_" + state + "_obj", led_me, c)
        o.cycles.is_caustics_caster = True
        if state == "On":
            for slot, key in zip(o.material_slots, ("lens_on", "die_on")):
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
            add_obj("LED_light", ld, c, loc=(0, 0, 3.0))
        masters["LED_" + state] = c

    for state, sign in (("Up", -1), ("Down", 1)):
        c = new_collection("Toggle_" + state, elements)
        add_obj("Toggle_" + state + "_body", body_me, c)
        lv = add_obj("Toggle_" + state + "_lever", lever_me, c,
                     loc=lever_loc,
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


def box_obj(name, x0, x1, y0, y1, z0, z1, material, coll, bevel=1.0):
    bm = bmesh.new()
    m = (Matrix.Translation(((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
         @ Matrix.Diagonal((x1 - x0, y1 - y0, z1 - z0, 1)))
    ret = bmesh.ops.create_cube(bm, size=1.0, matrix=m)
    if bevel:
        edges = {e for v in ret["verts"] for e in v.link_edges}
        bmesh.ops.bevel(bm, geom=list(edges), offset=bevel, segments=3,
                        profile=0.5, affect="EDGES")
    for f in bm.faces:
        f.smooth = True
    me = finish(bm, name + "_mesh")
    me.materials.append(material)
    return add_obj(name, me, coll)


def addr_x(bit):
    """Address LED and switch columns share x (each LED sits above its switch)."""
    return 92.0 + (15 - bit) * SWITCH_PITCH + (5 - (bit + 2) // 3) * GROUP_GAP


OCTAL_GROUPS = [(15, 15), (14, 12), (11, 9), (8, 6), (5, 3), (2, 0)]
Z_LED1, Z_LED2, Z_SW, Z_CTRL = 150.0, 127.0, 96.0, 56.0


def build_panel(m, masters, coll):
    plate = box_obj("Panel_plate", 0, PANEL_W, 0, PANEL_T, 0, PANEL_H,
                    m["panel"], coll, bevel=1.0)
    plate.cycles.is_caustics_receiver = True
    F = 8.0
    for name, x0, x1, z0, z1 in (("L", -F, 0, -F, PANEL_H + F),
                                 ("R", PANEL_W, PANEL_W + F, -F, PANEL_H + F),
                                 ("T", 0, PANEL_W, PANEL_H, PANEL_H + F),
                                 ("B", 0, PANEL_W, -F, 0)):
        box_obj("Frame_" + name, x0, x1, -3.0, PANEL_T + 2, z0, z1, m["frame"],
                coll, bevel=1.2)

    tx = m["text"]
    rule(20, 152, Z_LED1 - 6, 0.6, tx, coll)                       # status
    rule(addr_x(7) - 6, addr_x(0) + 6, Z_LED1 - 6, 0.6, tx, coll)  # data
    for hi, lo in OCTAL_GROUPS:
        rule(addr_x(hi) - 6, addr_x(lo) + 6, Z_LED2 - 6, 0.6, tx, coll)
        rule(addr_x(hi) - 6, addr_x(lo) + 6, Z_SW - 14, 0.6, tx, coll)
    box_obj("Logo_strip", 78, 300, -0.8, 0.2, 9, 27, m["logo"], coll, bevel=0.3)
    t = text("ALTAIR 8800 COMPUTER", 189, 18, 9, m["ink"], coll)
    t.location.y = -0.85
    text("mits", 52, 18, 9, tx, coll)
    text("STATUS", 86, Z_LED1 - 10, 2.8, tx, coll)
    text("DATA", (addr_x(7) + addr_x(0)) / 2, Z_LED1 - 10, 2.8, tx, coll)
    text("ADDRESS", addr_x(8), Z_LED2 - 10, 2.8, tx, coll)

    def led(name, x, z, on):
        set_led(instance("LED_" + name, masters["LED_Off"], x, z, coll),
                masters, on)
        text(name, x, z + 6.5, 2.0, tx, coll)

    status = ["INTE", "PROT", "MEMR", "INP", "M1", "OUT", "HLTA", "STACK", "WO", "INT"]
    for i, n in enumerate(status):
        led(n, 26.0 + i * 13.0, Z_LED1, n in STATUS_ON)
    for bit in range(7, -1, -1):
        led(f"D{bit}", addr_x(bit), Z_LED1, bool(DATA >> bit & 1))
    led("WAIT", 40, Z_LED2, False)
    led("HLDA", 58, Z_LED2, False)
    for bit in range(15, -1, -1):
        led(f"A{bit}", addr_x(bit), Z_LED2, bool(ADDRESS >> bit & 1))

    def toggle(name, x, z, up):
        instance("SW_" + name, masters["Toggle_Up" if up else "Toggle_Down"],
                 x, z, coll)

    for bit in range(15, -1, -1):
        toggle(f"A{bit}", addr_x(bit), Z_SW, bool(ADDRESS >> bit & 1))
        text(str(bit), addr_x(bit), Z_SW - 19, 3.0, tx, coll)
    toggle("power", 40, Z_CTRL, True)
    text("ON", 40, Z_CTRL + 12, 2.8, tx, coll)
    text("OFF", 40, Z_CTRL - 12, 2.8, tx, coll)
    tops = ["STOP", "SINGLE STEP", "EXAMINE", "DEPOSIT", "RESET", "PROTECT", "AUX", "AUX"]
    bots = ["RUN", "", "EXAMINE NEXT", "DEPOSIT NEXT", "CLR", "UNPROTECT", "", ""]
    for i, (top, bot) in enumerate(zip(tops, bots)):
        x = (addr_x(15 - 2 * i) + addr_x(14 - 2 * i)) / 2
        toggle(f"ctrl{i}", x, Z_CTRL, False)
        text(top, x, Z_CTRL + 12, 2.3, tx, coll)
        if bot:
            text(bot, x, Z_CTRL - 12, 2.3, tx, coll)


def build_case(m, coll):
    box_obj("Case", -8, PANEL_W + 8, PANEL_T, 460, -8, PANEL_H + 4, m["case"],
            coll, bevel=3.0)
    box_obj("Cover", -10, PANEL_W + 10, PANEL_T + 3, 463, PANEL_H + 4, PANEL_H + 14,
            m["cover"], coll, bevel=3.0)
    for x in (30, PANEL_W - 30):
        for y in (60, 420):
            bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=15, depth=12,
                                                location=(x, y, -14))
            f = bpy.context.object
            f.name = "Foot"
            for c in f.users_collection:
                c.objects.unlink(f)
            coll.objects.link(f)
            f.data.materials.append(m["feet"])


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
    build_panel(m, masters, panel)
    build_case(m, panel)
    z_addr, z_sw = Z_LED2, Z_SW
    elements.hide_render = True           # workbench copies don't render

    # floor
    bpy.ops.mesh.primitive_plane_add(size=6000, location=(PANEL_W / 2, 0, -20))
    bpy.context.object.data.materials.append(m["backdrop"])

    # lights
    def area(name, loc, energy, size, rot):
        bpy.ops.object.light_add(type="AREA", location=loc)
        o = bpy.context.object
        o.name = name
        o.data.energy, o.data.size, o.rotation_euler = energy, size, rot
        return o

    # high and to the sides so the glossy black front doesn't mirror them
    area("Key", (PANEL_W / 2 + 150, -260, 750), 2.6e6, 350, (math.radians(22), 0, math.radians(15)))
    area("Fill", (-650, -250, 260), 9e5, 300, (math.radians(80), 0, math.radians(-70)))
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
        "angle": ((PANEL_W / 2 + 560, -820, PANEL_H / 2 + 420),
                  Vector((PANEL_W / 2, 170, 40)), 50, (1800, 1100)),
        "macro_led": ((addr_x(8) + 50, -190, z_addr + 45),
                      Vector((addr_x(8), -2, z_addr)), 85, (1400, 800)),
        "macro_switch": ((addr_x(8) + 50, -190, z_sw + 60),
                         Vector((addr_x(8), -6, z_sw + 2)), 85, (1400, 800)),
    }
    for name, (loc, target, lens, res) in cams.items():
        cd = bpy.data.cameras.new("cam_" + name)
        cd.lens, cd.clip_start, cd.clip_end = lens, 1.0, 20000.0
        cam = bpy.data.objects.new("cam_" + name, cd)
        cam["res"] = res
        scene.collection.objects.link(cam)
        cam.location = loc
        cam.rotation_euler = (target - Vector(loc)).to_track_quat("-Z", "Y").to_euler()

    scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs[0].default_value = (0.05, 0.05, 0.055, 1)
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
    if "--export-toggle-template" in sys.argv:
        export_toggle_template()
        sys.exit(0)
    sc = build()
    sc.cycles.samples = int(arg("--samples", sc.cycles.samples))
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "altair_panel.blend"))
    if "--no-render" not in sys.argv:
        only = arg("--only")
        render(sc, only.split(",") if only else None)
