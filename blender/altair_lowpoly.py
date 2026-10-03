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
SWITCH_PITCH, GROUP_GAP = 17.0, 6.0
LEVER_TILT = 30.0
LEVER_PIVOT_Z = 4.6
LED_LIGHT_W = 800.0

# Flat colours (sRGB hex).  Emission strength only applies to "led_on".
PALETTE = {
    "panel": "141518", "frame": "5FA8D8", "line": "E9E6DC", "text": "E9E6DC",
    "logo": "C9A24A", "logo_text": "1A1A1A", "metal": "D5DCE6", "nut": "AEB6C0",
    "led_off": "7A1414", "led_on": "FF2A1F",
    "case": "D8D4C8", "cover": "E6E2D6", "feet": "3A3F4B",
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
        if name in ("metal", "nut", "logo"):
            b.inputs["Metallic"].default_value = 0.6
            b.inputs["Roughness"].default_value = 0.3
        if name in ("panel", "frame"):                # glossy plastic / anodised trim
            b.inputs["Roughness"].default_value = 0.25
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

    def paddle(self, w0, w1, t, z0, z1, mat, chamfer=0.0):
        """Flat bat-handle lever: width w0 at z0 widening to w1 at z1."""
        old = set(self.bm.faces)
        m = (Matrix.Translation((0, 0, (z0 + z1) / 2))
             @ Matrix.Diagonal((w0, t, z1 - z0, 1)))
        ret = bmesh.ops.create_cube(self.bm, size=1.0, matrix=m)
        for v in ret["verts"]:
            if v.co.z > (z0 + z1) / 2:
                v.co.x *= w1 / w0
        if chamfer:
            edges = {e for v in ret["verts"] for e in v.link_edges}
            bmesh.ops.bevel(self.bm, geom=list(edges), offset=chamfer,
                            segments=1, affect="EDGES")
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

    # LED: plain red 5 mm-style dome with a rim, poking through the panel
    b = Builder([M["led_off"]])
    b.prism(4.3, 0.0, 0.9, 8, M["led_off"], chamfer=0.35, rot=math.pi / 8)
    b.prism(3.6, 0.9, 4.0, 8, M["led_off"], rot=math.pi / 8)
    b.ico(3.6, (0, 0, 4.0), M["led_off"], subdiv=1)
    led_me = b.mesh("LP_LED_mesh")
    for state in ("Off", "On"):
        c = new_collection("LP_LED_" + state, elements)
        o = add_obj("LP_LED_" + state + "_obj", led_me, c)
        if state == "On":
            o.material_slots[0].link = "OBJECT"
            o.material_slots[0].material = M["led_on"]
            ld = bpy.data.lights.new("LP_LED_light", "POINT")
            ld.color = srgb(PALETTE["led_on"])[:3]
            ld.energy, ld.shadow_soft_size = LED_LIGHT_W, 2.0
            add_obj("LP_LED_light", ld, c, loc=(0, 0, 9.0))
        masters["LED_" + state] = c

    # Toggle: bolted through the panel -> thin hex nut flush on the front,
    # short threaded bushing (ridges), flat bat-handle lever.
    b = Builder([M["nut"], M["metal"]])
    b.prism(5.4, 0.0, 1.8, 6, M["nut"], chamfer=0.55)
    b.prism(2.6, 1.6, LEVER_PIVOT_Z + 0.6, 8, M["metal"], rot=math.pi / 8)
    for z in (1.9, 3.0, 4.1):                                   # thread ridges
        b.prism(3.05, z, z + 0.5, 8, M["metal"], rot=math.pi / 8)
    body_me = b.mesh("LP_Toggle_Body_mesh")

    b = Builder([M["metal"]])
    b.paddle(3.2, 4.4, 1.9, -1.5, 13.5, M["metal"], chamfer=0.5)
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
    """Address LED and switch columns share the same x (LEDs sit above)."""
    return 92.0 + (15 - bit) * SWITCH_PITCH + (5 - (bit + 2) // 3) * GROUP_GAP


OCTAL_GROUPS = [(15, 15), (14, 12), (11, 9), (8, 6), (5, 3), (2, 0)]


def build_panel(M, masters, coll):
    """Layout after the real 8800: status LEDs top-left, D7..D0 above A7..A0,
    WAIT/HLDA + A15..A0 on the second row, address/sense switches straight
    below their LEDs, control switches on a lower row, logo strip at the
    bottom.  Black smoked-plastic front in a light-blue frame."""
    z_led1, z_led2, z_sw, z_ctrl = 150.0, 127.0, 96.0, 56.0
    F = 8.0                                        # frame width

    b = Builder([M["panel"], M["frame"], M["line"], M["logo"]])
    b.box(0, PANEL_W, 0, PANEL_T, 0, PANEL_H, M["panel"], chamfer=1.5)
    for x0, x1, z0, z1 in ((-F, 0, -F, PANEL_H + F), (PANEL_W, PANEL_W + F, -F, PANEL_H + F),
                           (0, PANEL_W, PANEL_H, PANEL_H + F), (0, PANEL_W, -F, 0)):
        b.box(x0, x1, -3.0, PANEL_T + 2, z0, z1, M["frame"], chamfer=1.5)

    def hline(x0, x1, z, w=0.9):
        b.box(x0, x1, -0.3, 0.2, z - w / 2, z + w / 2, M["line"])

    hline(20, 152, z_led1 - 8)                                    # status
    hline(addr_x(7) - 6, addr_x(0) + 6, z_led1 - 8)               # data
    for hi, lo in OCTAL_GROUPS:                                   # address
        hline(addr_x(hi) - 6, addr_x(lo) + 6, z_led2 - 8)
        hline(addr_x(hi) - 6, addr_x(lo) + 6, z_sw - 14)
    b.box(78, 300, -0.8, 0.2, 9, 27, M["logo"], chamfer=0.5)      # logo strip
    add_obj("LP_Panel", b.mesh("LP_Panel_mesh"), coll)

    tx = M["text"]
    label("ALTAIR 8800 COMPUTER", 189, 18, 9, M["logo_text"], coll, y=-0.8,
          depth=0.4, bevel=0.15)
    label("mits", 52, 18, 9, tx, coll, depth=0.6, bevel=0.2)
    label("STATUS", 86, z_led1 - 13, 3.4, tx, coll)
    label("DATA", (addr_x(7) + addr_x(0)) / 2, z_led1 - 13, 3.4, tx, coll)
    label("ADDRESS", addr_x(8), z_led2 - 13, 3.4, tx, coll)

    def led(name, x, z, on):
        instance("LP_LED_" + name, masters["LED_On" if on else "LED_Off"],
                 x, 0.0, z, coll)

    status = ["INTE", "PROT", "MEMR", "INP", "M1", "OUT", "HLTA", "STACK", "WO", "INT"]
    for i, n in enumerate(status):
        led(n, 26.0 + i * 13.0, z_led1, n in STATUS_ON)
    for bit in range(7, -1, -1):
        led(f"D{bit}", addr_x(bit), z_led1, bool(DATA >> bit & 1))
    led("WAIT", 40, z_led2, False)
    led("HLDA", 58, z_led2, False)
    for bit in range(15, -1, -1):
        led(f"A{bit}", addr_x(bit), z_led2, bool(ADDRESS >> bit & 1))

    def toggle(name, x, z, up):
        instance("LP_SW_" + name, masters["Toggle_Up" if up else "Toggle_Down"],
                 x, 0.0, z, coll)

    for bit in range(15, -1, -1):
        toggle(f"A{bit}", addr_x(bit), z_sw, bool(ADDRESS >> bit & 1))
        label(str(bit), addr_x(bit), z_sw - 19, 3.4, tx, coll)
    toggle("power", 40, z_ctrl, True)
    label("ON", 40, z_ctrl + 12, 3.0, tx, coll)
    label("OFF", 40, z_ctrl - 12, 3.0, tx, coll)
    tops = ["STOP", "STEP", "EXAMINE", "DEPOSIT", "RESET", "PROTECT", "AUX", "AUX"]
    bots = ["RUN", "", "NEXT", "NEXT", "CLR", "UNPROT", "", ""]
    for i, (top, bot) in enumerate(zip(tops, bots)):
        x = (addr_x(15 - 2 * i) + addr_x(14 - 2 * i)) / 2
        toggle(f"ctrl{i}", x, z_ctrl, False)
        label(top, x, z_ctrl + 12, 2.8, tx, coll)
        if bot:
            label(bot, x, z_ctrl - 12, 2.8, tx, coll)


def build_case_and_desk(M, coll):
    b = Builder([M["case"], M["cover"], M["feet"]])
    b.box(-8, PANEL_W + 8, PANEL_T, 460, -8, PANEL_H + 4, M["case"], chamfer=4.0)
    b.box(-10, PANEL_W + 10, PANEL_T + 3, 463, PANEL_H + 4, PANEL_H + 16, M["cover"],
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
                  Vector((PANEL_W / 2, 0, PANEL_H / 2)), 480, (1600, 760)),
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
