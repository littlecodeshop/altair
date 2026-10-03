"""Altair 8800 front panel, low-poly / playful style (flat shading, chunky
chamfers, a small palette of bright flat colours), on its case and a desk.

    python3 altair_lowpoly.py                  # build .blend + render
    python3 altair_lowpoly.py --no-render
    python3 altair_lowpoly.py --only hero --samples 32

Same structure as altair_panel.py: the masters live in the "Elements"
collection (LP_LED_Off / LP_LED_On / LP_Toggle_Up / LP_Toggle_Down) and the
panel is populated with collection instances, so editing a master updates
every copy.  All colours are in PALETTE below, and each one is a named
material ("LP_<name>") you can tweak in Blender.

Units: 1 Blender unit = 1 mm.  Panel front face at y = 0, facing -Y.
"""
import math
import os
import sys

import bpy
import bmesh  # noqa: E402 (must come after bpy with the pip module)
from mathutils import Matrix, Vector

OUT_DIR = os.path.dirname(os.path.abspath(__file__))

PANEL_W, PANEL_H, PANEL_T = 432.0, 178.0, 10.0
ADDRESS = 0b0000_0001_1100_1010
DATA = 0xC3
STATUS_ON = {"MEMR", "M1", "WO"}
SWITCH_PITCH, GROUP_GAP = 12.5, 4.0
LEVER_TILT = 35.0
LEVER_PIVOT_Z = 8.0
LED_LIGHT_W = 800.0

# Flat colours (sRGB hex).  Emission strength only applies to "led_on".
PALETTE = {
    "panel": "2F5DA8", "inset": "1B2F5E", "group_a": "4F86D9",
    "group_b": "7BA7E8", "control": "F2C14E", "power": "E8604C",
    "text": "F4F1E8", "metal": "D5DCE6", "nut": "8C96A3", "knob": "F4F1E8",
    "bezel": "E8E2D0", "led_off": "6B1A1A", "led_on": "FF3B2F",
    "case": "C9CED8", "cover": "6F86AD", "feet": "3A3F4B",
    "desk": "C68B59", "desk_edge": "9C6A42",
}
SKY = "9ED8F0"


def srgb(hexstr):
    def lin(c):
        c /= 255.0
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return tuple(lin(int(hexstr[i:i + 2], 16)) for i in (0, 2, 4)) + (1.0,)


def make_materials():
    mats = {}
    for name, hx in PALETTE.items():
        m = bpy.data.materials.new("LP_" + name)
        m.use_nodes = True
        b = m.node_tree.nodes["Principled BSDF"]
        b.inputs["Base Color"].default_value = srgb(hx)
        b.inputs["Roughness"].default_value = 0.55
        if name in ("metal", "nut"):
            b.inputs["Metallic"].default_value = 0.6
            b.inputs["Roughness"].default_value = 0.3
        if name == "led_on":
            b.inputs["Emission Color"].default_value = srgb(hx)
            b.inputs["Emission Strength"].default_value = 1.6
        m.diffuse_color = srgb(hx)          # viewport solid colour too
        m.use_fake_user = True
        mats[name] = m
    return mats


# ---- low-poly bmesh primitives ---------------------------------------------------
class Builder:
    """Collects flat-shaded geometry with material indices into one mesh."""

    def __init__(self, mats):
        self.bm = bmesh.new()
        self.mats = list(mats)

    def _tag(self, old, mat):
        idx = self.mats.index(mat)
        new = [f for f in self.bm.faces if f not in old]
        for f in new:
            f.material_index = idx
        return new

    def prism(self, r, z0, z1, segs, mat, chamfer=0.0, r_top=None, rot=0.0):
        old = set(self.bm.faces)
        m = Matrix.Translation((0, 0, (z0 + z1) / 2)) @ Matrix.Rotation(rot, 4, "Z")
        ret = bmesh.ops.create_cone(self.bm, cap_ends=True, cap_tris=False,
                                    segments=segs, radius1=r,
                                    radius2=r if r_top is None else r_top,
                                    depth=z1 - z0, matrix=m)
        if chamfer:
            top = {e for v in ret["verts"] for e in v.link_edges
                   if all(abs(w.co.z - z1) < 1e-4 for w in e.verts)}
            bmesh.ops.bevel(self.bm, geom=list(top), offset=chamfer,
                            segments=1, affect="EDGES")
        self._tag(old, mat)

    def box(self, x0, x1, y0, y1, z0, z1, mat, chamfer=0.0):
        old = set(self.bm.faces)
        m = (Matrix.Translation(((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
             @ Matrix.Diagonal((x1 - x0, y1 - y0, z1 - z0, 1)))
        ret = bmesh.ops.create_cube(self.bm, size=1.0, matrix=m)
        if chamfer:
            edges = {e for v in ret["verts"] for e in v.link_edges}
            bmesh.ops.bevel(self.bm, geom=list(edges), offset=chamfer,
                            segments=1, affect="EDGES")
        self._tag(old, mat)

    def ico(self, r, center, mat, subdiv=1, scale=(1, 1, 1)):
        old = set(self.bm.faces)
        m = Matrix.Translation(center) @ Matrix.Diagonal((*scale, 1))
        bmesh.ops.create_icosphere(self.bm, subdivisions=subdiv, radius=r, matrix=m)
        self._tag(old, mat)

    def mesh(self, name):
        me = bpy.data.meshes.new(name)
        self.bm.to_mesh(me)
        self.bm.free()
        for p in me.polygons:
            p.use_smooth = False
        for m in self.mats:
            me.materials.append(m)
        return me


def new_collection(name, parent=None):
    c = bpy.data.collections.new(name)
    (parent or bpy.context.scene.collection).children.link(c)
    return c


def add_obj(name, data, coll, loc=(0, 0, 0), rot=(0, 0, 0)):
    o = bpy.data.objects.new(name, data)
    o.location, o.rotation_euler = loc, rot
    coll.objects.link(o)
    return o


# ---- master elements (modelled along +Z = out of the panel) -----------------------
def build_masters(M, elements):
    masters = {}

    b = Builder([M["bezel"], M["led_off"]])
    b.prism(5.0, 0.0, 2.2, 8, M["bezel"], chamfer=0.7, rot=math.pi / 8)
    b.prism(3.6, 1.5, 3.2, 8, M["led_off"], rot=math.pi / 8)
    b.ico(3.6, (0, 0, 3.2), M["led_off"], subdiv=1, scale=(1, 1, 0.75))
    led_me = b.mesh("LP_LED_mesh")
    for state in ("Off", "On"):
        c = new_collection("LP_LED_" + state, elements)
        o = add_obj("LP_LED_" + state + "_obj", led_me, c)
        if state == "On":
            o.material_slots[1].link = "OBJECT"
            o.material_slots[1].material = M["led_on"]
            ld = bpy.data.lights.new("LP_LED_light", "POINT")
            ld.color = srgb(PALETTE["led_on"])[:3]
            ld.energy, ld.shadow_soft_size = LED_LIGHT_W, 2.0
            add_obj("LP_LED_light", ld, c, loc=(0, 0, 7.5))
        masters["LED_" + state] = c

    b = Builder([M["nut"], M["metal"]])
    b.prism(5.6, 0.0, 1.2, 8, M["nut"], chamfer=0.4, rot=math.pi / 8)
    b.prism(4.6, 1.2, 4.2, 6, M["nut"], chamfer=0.8)
    b.prism(3.0, 4.2, LEVER_PIVOT_Z + 0.6, 8, M["metal"], chamfer=0.5, rot=math.pi / 8)
    body_me = b.mesh("LP_Toggle_Body_mesh")

    b = Builder([M["metal"], M["knob"]])
    b.prism(2.2, -1.0, 12.0, 6, M["metal"], r_top=1.4)
    b.ico(3.0, (0, 0, 14.0), M["knob"], subdiv=1)
    lever_me = b.mesh("LP_Toggle_Lever_mesh")

    for state, sign in (("Up", -1), ("Down", 1)):
        c = new_collection("LP_Toggle_" + state, elements)
        add_obj("LP_Toggle_" + state + "_body", body_me, c)
        add_obj("LP_Toggle_" + state + "_lever", lever_me, c,
                loc=(0, 0, LEVER_PIVOT_Z),
                rot=(sign * math.radians(LEVER_TILT), 0, 0))
        masters["Toggle_" + state] = c

    for i, c in enumerate(masters.values()):          # workbench below panel
        off = Vector((-60 + i * 40, -150, -120))
        c.instance_offset = off
        for o in c.objects:
            o.location += off
    return masters


def instance(name, coll, x, y, z, parent):
    e = bpy.data.objects.new(name, None)
    e.instance_type, e.instance_collection = "COLLECTION", coll
    e.empty_display_size = 4
    e.location, e.rotation_euler = (x, y, z), (math.pi / 2, 0, 0)
    parent.objects.link(e)
    return e


# ---- text ------------------------------------------------------------------------
TEXTS = []


def label(txt, x, z, size, mat, coll, y=0.0, depth=0.5, bevel=0.0, align="CENTER"):
    c = bpy.data.curves.new("t", "FONT")
    c.body, c.size, c.align_x, c.align_y = txt, size, align, "CENTER"
    c.extrude, c.resolution_u = depth, 2          # low-res curves = low poly
    c.bevel_depth, c.bevel_resolution = bevel, 0
    o = bpy.data.objects.new("txt_" + txt, c)
    coll.objects.link(o)
    o.rotation_euler, o.location = (math.pi / 2, 0, 0), (x, y - depth - bevel, z)
    c.materials.append(mat)
    TEXTS.append(o)
    return o


def texts_to_flat_meshes():
    dg = bpy.context.evaluated_depsgraph_get()
    for o in TEXTS:
        me = bpy.data.meshes.new_from_object(o.evaluated_get(dg))
        for p in me.polygons:
            p.use_smooth = False
        n = bpy.data.objects.new(o.name, me)
        n.matrix_world = o.matrix_world.copy()
        for c in o.users_collection:
            c.objects.link(n)
        bpy.data.objects.remove(o)


# ---- panel, case, desk -------------------------------------------------------------
def addr_x(bit):
    return 70.0 + (15 - bit) * SWITCH_PITCH + (5 - (bit + 2) // 3) * GROUP_GAP


def build_panel(M, masters, coll):
    z_stat, z_addr, z_sw = 134.0, 102.0, 44.0
    INSET = -1.5                                   # front of the inset plates

    b = Builder([M["panel"], M["inset"], M["group_a"], M["group_b"],
                 M["control"], M["power"]])
    b.box(0, PANEL_W, 0, PANEL_T, 0, PANEL_H, M["panel"], chamfer=3.0)

    def plate(x0, x1, z0, z1, mat):
        b.box(x0, x1, INSET, 0.5, z0, z1, mat, chamfer=1.0)

    plate(26, 194, z_stat - 9, z_stat + 9, M["inset"])           # status
    plate(240, 377, z_stat - 9, z_stat + 9, M["inset"])          # data
    plate(22, addr_x(0) + 9, z_addr - 9, z_addr + 9, M["inset"])  # address
    groups = [(15, 15), (14, 12), (11, 9), (8, 6), (5, 3), (2, 0)]
    for i, (hi, lo) in enumerate(groups):
        plate(addr_x(hi) - 6.5, addr_x(lo) + 6.5, z_sw - 17, z_sw + 17,
              M["group_a"] if i % 2 else M["group_b"])
    plate(12, 32, z_sw - 17, z_sw + 17, M["power"])
    plate(295, 417, z_sw - 17, z_sw + 17, M["control"])
    add_obj("LP_Panel", b.mesh("LP_Panel_mesh"), coll)

    tx = M["text"]
    label("ALTAIR 8800", 20, 160, 13, tx, coll, depth=1.2, bevel=0.4, align="LEFT")
    label("MITS", 410, 160, 9, tx, coll, depth=1.0, bevel=0.3, align="RIGHT")
    label("STATUS", 110, z_stat - 14, 4.5, tx, coll)
    label("DATA", 308, z_stat - 14, 4.5, tx, coll)
    label("ADDRESS", addr_x(8), z_addr - 14, 4.5, tx, coll)

    def led(name, x, z, on):
        instance("LP_LED_" + name, masters["LED_On" if on else "LED_Off"],
                 x, INSET, z, coll)

    status = ["INT", "WO", "STACK", "HLTA", "OUT", "M1", "INP", "MEMR", "PROT", "INTE"]
    for i, n in enumerate(status):
        led(n, 34.0 + i * 17.5, z_stat, n in STATUS_ON)
    for i in range(8):
        led(f"D{7 - i}", 249.0 + i * 17.0, z_stat, bool(DATA >> (7 - i) & 1))
    led("WAIT", 31, z_addr, False)
    led("HLDA", 48, z_addr, False)
    for bit in range(15, -1, -1):
        led(f"A{bit}", addr_x(bit), z_addr, bool(ADDRESS >> bit & 1))

    def toggle(name, x, up):
        instance("LP_SW_" + name, masters["Toggle_Up" if up else "Toggle_Down"],
                 x, INSET, z_sw, coll)

    for bit in range(15, -1, -1):
        toggle(f"A{bit}", addr_x(bit), bool(ADDRESS >> bit & 1))
        label(str(bit), addr_x(bit), z_sw - 22, 4.5, tx, coll)
    toggle("power", 22, True)
    label("ON", 22, z_sw + 22, 4, tx, coll)
    label("OFF", 22, z_sw - 22, 4, tx, coll)
    ctrl = [("STOP", "RUN"), ("STEP", "STEP"), ("EXAM", "NEXT"),
            ("DEP", "NEXT"), ("RESET", "CLR"), ("PROT", "UNPR"), ("AUX", "AUX")]
    for i, (top, bot) in enumerate(ctrl):
        x = 304.0 + i * 17.3
        toggle(f"ctrl{i}", x, False)
        label(top, x, z_sw + 22, 3.4, tx, coll)
        label(bot, x, z_sw - 22, 3.4, tx, coll)


def build_case_and_desk(M, coll):
    b = Builder([M["case"], M["cover"], M["feet"]])
    b.box(-6, PANEL_W + 6, PANEL_T, 460, -6, PANEL_H + 2, M["case"], chamfer=4.0)
    b.box(-9, PANEL_W + 9, PANEL_T + 4, 463, PANEL_H, PANEL_H + 14, M["cover"],
          chamfer=4.0)
    for x in (30, PANEL_W - 30):
        for y in (60, 420):
            old = set(b.bm.faces)
            bmesh.ops.create_cone(b.bm, cap_ends=True, cap_tris=False, segments=8,
                                  radius1=16, radius2=13, depth=12,
                                  matrix=Matrix.Translation((x, y, -12)))
            b._tag(old, M["feet"])
    add_obj("LP_Case", b.mesh("LP_Case_mesh"), coll)

    b = Builder([M["desk"], M["desk_edge"]])
    b.box(-320, PANEL_W + 320, -260, 720, -58, -18, M["desk"], chamfer=6.0)
    b.box(-300, PANEL_W + 300, -240, 700, -90, -58, M["desk_edge"], chamfer=4.0)
    add_obj("LP_Desk", b.mesh("LP_Desk_mesh"), coll)


# ---- scene ---------------------------------------------------------------------------
def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.scale_length = 0.001
    scene.unit_settings.length_unit = "MILLIMETERS"
    M = make_materials()

    elements = new_collection("Elements")
    masters = build_masters(M, elements)
    elements.hide_render = True
    panel = new_collection("LP_Altair")
    build_panel(M, masters, panel)
    build_case_and_desk(M, panel)
    texts_to_flat_meshes()

    sun_d = bpy.data.lights.new("Sun", "SUN")
    sun_d.energy, sun_d.angle = 4.5, math.radians(6)
    sun_d.color = (1.0, 0.96, 0.9)
    add_obj("Sun", sun_d, scene.collection,
            rot=(math.radians(48), 0, math.radians(-28)))

    scene.world = bpy.data.worlds.new("Sky")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs[0].default_value = srgb(SKY)
    scene.world.node_tree.nodes["Background"].inputs[1].default_value = 0.55

    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 64
    scene.cycles.use_denoising = True
    scene.view_settings.view_transform = "Standard"   # keeps colours punchy

    target = Vector((PANEL_W / 2 - 30, 200, 60))
    cams = {
        "hero": (target + Vector((-0.5, -1.0, 0.42)).normalized() * 3000, target,
                 860, (1600, 1000)),
        "front": (Vector((PANEL_W / 2, -3000, PANEL_H / 2)),
                  Vector((PANEL_W / 2, 0, PANEL_H / 2)), 470, (1600, 700)),
    }
    for name, (loc, tgt, ortho, res) in cams.items():
        cd = bpy.data.cameras.new("cam_lp_" + name)
        cd.type, cd.ortho_scale, cd.clip_end = "ORTHO", ortho, 10000
        cam = add_obj("cam_lp_" + name, cd, scene.collection, loc=loc)
        cam.rotation_euler = (tgt - loc).to_track_quat("-Z", "Y").to_euler()
        cam["res"] = res
    return scene


def render(scene, only):
    for name in ("hero", "front"):
        if only and name not in only:
            continue
        cam = bpy.data.objects["cam_lp_" + name]
        scene.camera = cam
        scene.render.resolution_x, scene.render.resolution_y = cam["res"]
        scene.render.filepath = os.path.join(OUT_DIR, f"altair_lowpoly_{name}.png")
        bpy.ops.render.render(write_still=True)


def arg(flag, default=None):
    return sys.argv[sys.argv.index(flag) + 1] if flag in sys.argv else default


if __name__ == "__main__":
    sc = build()
    sc.cycles.samples = int(arg("--samples", sc.cycles.samples))
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "altair_lowpoly.blend"))
    if "--no-render" not in sys.argv:
        only = arg("--only")
        render(sc, only.split(",") if only else None)
