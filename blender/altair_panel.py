"""Altair 8800 front panel, built procedurally with Blender's Python API.

Run with the `bpy` module (pip install bpy) or inside Blender:

    python3 altair_panel.py            # writes altair_panel.blend + renders
    blender -b -P altair_panel.py

Units: 1 Blender unit = 1 mm. The panel lies in the XZ plane, front face at
y = 0, and everything on the front sticks out towards -Y (towards the camera).
Real panel is about 17" x 7" (432 x 178 mm).
"""
import math
import os
import sys

import bpy
from mathutils import Vector

OUT_DIR = os.path.dirname(os.path.abspath(__file__))

# ---- Parameters ------------------------------------------------------------
PANEL_W, PANEL_H, PANEL_T = 432.0, 178.0, 3.0
ADDRESS = 0b0000_0001_1100_1010   # A15..A0 shown on switches and LEDs
DATA = 0xC3                        # D7..D0 shown on LEDs (JMP)
STATUS_ON = {"MEMR", "M1", "WO"}   # lit status LEDs
SWITCH_PITCH = 12.5
GROUP_GAP = 4.0

COL_PANEL = (0.02, 0.09, 0.30, 1)
COL_TEXT = (0.92, 0.92, 0.88, 1)
COL_LED_ON = (1.0, 0.05, 0.03, 1)
COL_LED_OFF = (0.18, 0.02, 0.02, 1)


# ---- Helpers ---------------------------------------------------------------
def material(name, color, metallic=0.0, rough=0.4, emit=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = color
    b.inputs["Metallic"].default_value = metallic
    b.inputs["Roughness"].default_value = rough
    if emit:
        b.inputs["Emission Color"].default_value = color
        b.inputs["Emission Strength"].default_value = emit
    return m


def assign(obj, mat):
    obj.data.materials.append(mat)
    return obj


def to_front(obj):
    """Rotate a Z-up primitive so its +Z axis points toward -Y (out of panel)."""
    obj.rotation_euler = (math.pi / 2, 0, 0)


def cyl(name, r, depth, x, y, z, mat, verts=48):
    """Cylinder whose axis is along Y, base at y."""
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth)
    o = bpy.context.object
    o.name = name
    to_front(o)
    o.location = (x, y - depth / 2, z)
    assign(o, mat)
    bpy.ops.object.shade_smooth()
    return o


def text(txt, x, z, size, mat, align="CENTER", y=-0.05):
    c = bpy.data.curves.new("t", "FONT")
    c.body = txt
    c.size = size
    c.align_x = align
    c.align_y = "CENTER"
    c.extrude = 0.04
    o = bpy.data.objects.new("txt_" + txt, c)
    bpy.context.collection.objects.link(o)
    o.rotation_euler = (math.pi / 2, 0, 0)
    o.location = (x, y, z)
    o.data.materials.append(mat)
    return o


def line(x0, z0, x1, z1, w, mat):
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    bpy.ops.mesh.primitive_cube_add(size=1)
    o = bpy.context.object
    o.name = "rule"
    o.scale = (abs(x1 - x0) + w, 0.1, abs(z1 - z0) + w)
    o.location = (cx, -0.05, cz)
    assign(o, mat)
    return o


def led(name, x, z, on, m_on, m_off, m_bezel):
    cyl(name + "_bezel", 3.1, 1.2, x, 0, z, m_bezel)
    o = cyl(name, 2.2, 1.6, x, 0, z, m_on if on else m_off)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=2.2, segments=32, ring_count=16)
    dome = bpy.context.object
    dome.name = name + "_dome"
    dome.scale = (1, 0.5, 1)
    dome.location = (x, -1.6, z)
    assign(dome, m_on if on else m_off)
    bpy.ops.object.shade_smooth()
    return o


def toggle(name, x, z, up, m_metal, m_nut, tilt_deg=40):
    """Toggle switch: hex nut, tilted shaft, round tip. up=True flips it up."""
    bpy.ops.object.empty_add(location=(x, 0, z))
    pivot = bpy.context.object
    pivot.name = name
    t = math.radians(tilt_deg if up else -tilt_deg)
    pivot.rotation_euler = (math.pi / 2 - t, 0, 0)
    cyl(name + "_nut", 4.2, 2.2, x, 0, z, m_nut, verts=6)
    cyl(name + "_collar", 2.6, 4.0, x, -2.2, z, m_metal)
    parts = []
    bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=1.9, radius2=1.2, depth=11)
    shaft = bpy.context.object
    shaft.location = (0, 0, 5.5)
    parts.append(shaft)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=2.1, segments=24, ring_count=12)
    tip = bpy.context.object
    tip.location = (0, 0, 11)
    parts.append(tip)
    for p in parts:
        assign(p, m_metal)
        p.parent = pivot
        bpy.context.view_layer.objects.active = p
        p.select_set(True)
        bpy.ops.object.shade_smooth()
    # move pivot out so shaft starts on the collar
    pivot.location = (x, -4.2, z)
    return pivot


# ---- Scene -----------------------------------------------------------------
def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.scale_length = 0.001
    scene.unit_settings.length_unit = "MILLIMETERS"

    m_panel = material("panel", COL_PANEL, rough=0.45)
    m_text = material("silkscreen", COL_TEXT, rough=0.6)
    m_on = material("led_on", COL_LED_ON, rough=0.2, emit=12.0)
    m_off = material("led_off", COL_LED_OFF, rough=0.15)
    m_bezel = material("bezel", (0.7, 0.7, 0.72, 1), metallic=1.0, rough=0.25)
    m_metal = material("chrome", (0.85, 0.85, 0.88, 1), metallic=1.0, rough=0.12)
    m_nut = material("nut", (0.55, 0.55, 0.58, 1), metallic=1.0, rough=0.3)
    m_dark = material("dark", (0.02, 0.02, 0.03, 1), rough=0.5)

    # Panel plate (front at y=0, extends to +Y) with a slightly rounded edge.
    bpy.ops.mesh.primitive_cube_add(size=1)
    p = bpy.context.object
    p.name = "front_panel"
    p.scale = (PANEL_W, PANEL_T, PANEL_H)
    p.location = (PANEL_W / 2, PANEL_T / 2, PANEL_H / 2)
    bpy.ops.object.transform_apply(scale=True)
    bev = p.modifiers.new("bevel", "BEVEL")
    bev.width = 1.2
    bev.segments = 4
    assign(p, m_panel)

    # Layout rows (z from bottom of panel)
    z_stat, z_addr, z_sw = 140.0, 113.0, 40.0

    # Logo
    text("ALTAIR 8800", 76, 160, 8.5, m_text)
    text("MITS", 380, 160, 6, m_text)
    line(14, 154, PANEL_W - 14, 154, 0.5, m_text)

    # Status / data LEDs (row 1), spaced from x=40 .. 410
    status = ["INT", "WO", "STACK", "HLTA", "OUT", "M1", "INP", "MEMR", "PROT", "INTE"]
    sx0, spitch = 38.0, 16.0
    for i, name in enumerate(status):
        x = sx0 + i * spitch
        led("led_" + name, x, z_stat, name in STATUS_ON, m_on, m_off, m_bezel)
        text(name, x, z_stat + 8, 2.6, m_text)

    dx0 = 250.0
    for i in range(8):
        bit = 7 - i
        x = dx0 + i * 17.0
        led(f"led_D{bit}", x, z_stat, bool(DATA >> bit & 1), m_on, m_off, m_bezel)
        text(f"D{bit}", x, z_stat + 8, 2.6, m_text)
    text("DATA", dx0 + 3.5 * 17.0, z_stat - 8.5, 3.2, m_text)

    # Address LEDs (row 2): WAIT, HLDA then A15..A0 grouped by 3 (octal)
    led("led_WAIT", 32, z_addr, False, m_on, m_off, m_bezel)
    text("WAIT", 32, z_addr + 8, 2.6, m_text)
    led("led_HLDA", 48, z_addr, False, m_on, m_off, m_bezel)
    text("HLDA", 48, z_addr + 8, 2.6, m_text)

    def addr_x(bit):
        """X for address bit (15..0); groups of 3 counted from the LSB."""
        idx = 15 - bit
        group = (bit + 2) // 3          # number of group boundaries to its right
        gaps = 5 - group                # boundaries passed from left edge
        return 70.0 + idx * SWITCH_PITCH + gaps * GROUP_GAP

    for bit in range(15, -1, -1):
        x = addr_x(bit)
        led(f"led_A{bit}", x, z_addr, bool(ADDRESS >> bit & 1), m_on, m_off, m_bezel)
        text(f"A{bit}", x, z_addr + 8, 2.6, m_text)
    text("ADDRESS", addr_x(8), z_addr - 8.5, 3.2, m_text)

    # Address / sense switches (bottom row) with octal group numbers
    for bit in range(15, -1, -1):
        x = addr_x(bit)
        toggle(f"sw_A{bit}", x, z_sw, bool(ADDRESS >> bit & 1), m_metal, m_nut)
        text(f"{bit}", x, z_sw - 19, 3.2, m_text)
    text("ON", 22, z_sw + 14, 3.2, m_text)
    text("OFF", 22, z_sw - 14, 3.2, m_text)
    toggle("sw_power", 22, z_sw, True, m_metal, m_nut)
    text("SENSE / ADDRESS", addr_x(8), z_sw + 20, 3.2, m_text)

    # Control switches (right): two-way momentary-style toggles
    ctrl = [
        ("STOP", "RUN"),
        ("SINGLE\nSTEP", "SINGLE\nSTEP"),
        ("EXAMINE", "EXAMINE\nNEXT"),
        ("DEPOSIT", "DEPOSIT\nNEXT"),
        ("RESET", "CLR"),
        ("PROTECT", "UNPROTECT"),
        ("AUX", "AUX"),
    ]
    cx0, cpitch = 305.0, 17.0
    for i, (top, bot) in enumerate(ctrl):
        x = cx0 + i * cpitch
        toggle(f"sw_ctrl{i}", x, z_sw, False, m_metal, m_nut)
        text(top.split("\n")[0], x, z_sw + 17, 2.4, m_text)
        text(bot.split("\n")[-1], x, z_sw - 19, 2.4, m_text)

    # Row separators
    line(14, 77, PANEL_W - 14, 77, 0.4, m_text)

    # Ground plane/backdrop
    bpy.ops.mesh.primitive_plane_add(size=4000, location=(PANEL_W / 2, 60, -0.1))
    bpy.context.object.rotation_euler = (math.pi / 2, 0, 0)
    bpy.context.object.location = (PANEL_W / 2, 400, PANEL_H / 2)
    assign(bpy.context.object, material("backdrop", (0.12, 0.12, 0.13, 1), rough=0.9))

    # Lights
    bpy.ops.object.light_add(type="AREA", location=(PANEL_W / 2, -500, 380))
    key = bpy.context.object
    key.data.energy = 2.2e6
    key.data.size = 400
    key.rotation_euler = (math.radians(60), 0, 0)
    bpy.ops.object.light_add(type="AREA", location=(-250, -450, 120))
    fill = bpy.context.object
    fill.data.energy = 6e5
    fill.data.size = 300
    fill.rotation_euler = (math.pi / 2, 0, math.radians(-35))

    # Cameras
    center = Vector((PANEL_W / 2, 0, PANEL_H / 2))
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 48
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = 1800, 760
    for name, loc in (("front", (PANEL_W / 2, -720, PANEL_H / 2)),
                      ("angle", (PANEL_W / 2 + 330, -600, PANEL_H / 2 + 200))):
        cam_data = bpy.data.cameras.new("cam_" + name)
        cam_data.lens = 50
        cam = bpy.data.objects.new("cam_" + name, cam_data)
        scene.collection.objects.link(cam)
        cam.location = loc
        direction = center - Vector(loc)
        cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()

    scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs[0].default_value = (0.03, 0.03, 0.035, 1)
    return scene


def render(scene):
    for name in ("front", "angle"):
        scene.camera = bpy.data.objects["cam_" + name]
        scene.render.filepath = os.path.join(OUT_DIR, f"altair_panel_{name}.png")
        bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    sc = build()
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "altair_panel.blend"))
    if "--no-render" not in sys.argv:
        render(sc)
