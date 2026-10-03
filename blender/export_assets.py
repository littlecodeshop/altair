"""Export the Altair panel parts as PNGs for an Xcode asset catalog.

    python3 export_assets.py                    # both styles
    python3 export_assets.py --style lowpoly    # or: realistic
    python3 export_assets.py --samples 64
    python3 export_assets.py --layout-only      # only regenerate the .swift files

For each style it builds the scene with altair_panel.py / altair_lowpoly.py
and renders, straight on with an orthographic camera:

    <p>_front_plate     plate + frame + silkscreen + logo (no LEDs/switches)
    <p>_led_on / <p>_led_off
    <p>_switch_up / <p>_switch_down / <p>_switch_neutral

(<p> = "real" or "lowpoly").  Every element sits centred on its own square
canvas with a transparent background; a shadow catcher at the panel surface
bakes the element's shadow into the alpha, so you just put the PNG on top of
the plate.  The light is a fixed directional sun (top-left), identical for
every part, so shadows match wherever you place them.

Scale is the same for every image: PT_PER_MM points per millimetre, rendered
at @3x and downscaled to @2x / @1x.  Output:

    xcode/Altair<Style>.xcassets/<name>.imageset/{name@1x,@2x,@3x.png, Contents.json}
    xcode/AltairLayout<Style>.swift   AltairPanelStyle.<style>: element centres
                                      (points, from the plate's top-left) + sizes
    xcode/AltairPanelView.swift       (hand-written) SwiftUI view using them
"""
import json
import math
import os
import sys

import bpy
from mathutils import Vector
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
OUT = os.path.join(HERE, "xcode")

PT_PER_MM = 2.0                 # 1 mm on the panel = 2 points in SwiftUI
SCALES = (3, 2, 1)
LED_CANVAS_MM = 20.0
SWITCH_CANVAS_MM = 44.0
FRAME = 8.0                     # frame width around the plate (both styles)
# light comes from the top-left, in front of the panel
SUN_DIR = Vector((0.30, 0.75, -0.60)).normalized()

STYLES = {
    "realistic": dict(
        module="altair_panel", prefix="real", swift="Realistic",
        panel_coll="Altair_Panel", master_prefix="",
        plate_exclude=("Case", "Cover", "Foot", "Plane"),
        inst_prefixes=("LED_", "SW_")),
    "lowpoly": dict(
        module="altair_lowpoly", prefix="lowpoly", swift="LowPoly",
        panel_coll="LP_Altair", master_prefix="LP_",
        plate_exclude=("LP_Case", "LP_Desk"),
        inst_prefixes=("LP_LED_", "LP_SW_")),
}


def studio(center):
    """Replace the scene's lights with a fixed studio around `center`."""
    for o in list(bpy.data.objects):
        if o.type == "LIGHT" and not o.users_collection[0].name.startswith(
                ("LED_", "LP_LED_")):
            bpy.data.objects.remove(o)
    sc = bpy.context.scene
    sun = bpy.data.objects.new("Export_Sun", bpy.data.lights.new("Export_Sun", "SUN"))
    sun.data.energy, sun.data.angle = 4.0, math.radians(6)
    sun.rotation_euler = SUN_DIR.to_track_quat("-Z", "Y").to_euler()
    sc.collection.objects.link(sun)
    # big soft light above-front: gives chrome something to reflect
    soft = bpy.data.objects.new("Export_Soft", bpy.data.lights.new("Export_Soft", "AREA"))
    soft.data.energy, soft.data.size = 3.0e5, 400
    soft.location = center + Vector((-80, -350, 250))
    soft.rotation_euler = (center - soft.location).to_track_quat("-Z", "Y").to_euler()
    sc.collection.objects.link(soft)
    return [sun, soft]


def ortho_camera(center_x, center_z, width_mm, height_mm):
    sc = bpy.context.scene
    cd = bpy.data.cameras.new("Export_Cam")
    cd.type, cd.ortho_scale = "ORTHO", max(width_mm, height_mm)
    cd.clip_start, cd.clip_end = 1.0, 5000.0
    cam = bpy.data.objects.new("Export_Cam", cd)
    cam.location = (center_x, -1000.0, center_z)
    cam.rotation_euler = (math.pi / 2, 0, 0)           # look along +Y
    sc.collection.objects.link(cam)
    sc.camera = cam
    px = PT_PER_MM * SCALES[0]
    sc.render.resolution_x = round(width_mm * px)
    sc.render.resolution_y = round(height_mm * px)
    sc.render.resolution_percentage = 100
    return cam


def remove_catcher_tint(img):
    """The shadow catcher leaves a faint uniform tint over the whole canvas,
    which would show as a square edge on the plate.  Take the alpha found
    along the border as 'no shadow' and remap it to fully transparent."""
    r, g, b, a = img.split()
    w, h = img.size
    px = a.load()
    border = sorted([px[x, 0] for x in range(w)] + [px[x, h - 1] for x in range(w)] +
                    [px[0, y] for y in range(h)] + [px[w - 1, y] for y in range(h)])
    base = border[len(border) // 2]
    if base:
        a = a.point(lambda v: 0 if v <= base else round((v - base) * 255 / (255 - base)))
    return Image.merge("RGBA", (r, g, b, a))


def write_imageset(catalog, name, png3x, clean=False):
    d = os.path.join(catalog, name + ".imageset")
    os.makedirs(d, exist_ok=True)
    img = Image.open(png3x).convert("RGBA")
    if clean:
        img = remove_catcher_tint(img)
    images = []
    for s in SCALES:
        fn = f"{name}@{s}x.png"
        if s == SCALES[0]:
            out = img
        else:
            out = img.resize((round(img.width * s / SCALES[0]),
                              round(img.height * s / SCALES[0])), Image.LANCZOS)
        out.save(os.path.join(d, fn), optimize=True)
        images.append({"idiom": "universal", "filename": fn, "scale": f"{s}x"})
    with open(os.path.join(d, "Contents.json"), "w") as f:
        json.dump({"images": images, "info": {"author": "xcode", "version": 1}}, f, indent=2)
    os.remove(png3x)


def render_to(path):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def export_style(key, samples):
    cfg = STYLES[key]
    mod = __import__(cfg["module"])
    scene = mod.build()
    scene.cycles.samples = samples
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    W, H = mod.PANEL_W, mod.PANEL_H
    layout_only = "--layout-only" in sys.argv

    catalog = os.path.join(OUT, f"Altair{cfg['swift']}.xcassets")
    os.makedirs(catalog, exist_ok=True)
    with open(os.path.join(catalog, "Contents.json"), "w") as f:
        json.dump({"info": {"author": "xcode", "version": 1}}, f, indent=2)

    panel = bpy.data.collections[cfg["panel_coll"]]
    instances = [o for o in panel.objects if o.instance_type == "COLLECTION"]

    # collect the layout before hiding anything
    layout = []
    for o in instances:
        name = o.name
        for p in cfg["inst_prefixes"]:
            if name.startswith(p):
                kind = "led" if "LED" in p else "switch"
                name = name[len(p):]
        state = o.instance_collection.name.split("_")[-1].lower()  # on/off/up/down
        layout.append(dict(name=name, kind=kind, state=state,
                           x=(o.location.x + FRAME) * PT_PER_MM,
                           y=(H + FRAME - o.location.z) * PT_PER_MM))

    if layout_only:
        write_swift(cfg, layout, W, H)
        return

    # ---- front plate ---------------------------------------------------------
    for o in scene.objects:
        o.hide_render = (o.type == "EMPTY" or o.name.startswith(cfg["plate_exclude"]))
    studio(Vector((W / 2, 0, H / 2)))
    ortho_camera(W / 2, H / 2, W + 2 * FRAME, H + 2 * FRAME)
    tmp = os.path.join(OUT, "_tmp.png")
    render_to(tmp)
    write_imageset(catalog, f"{cfg['prefix']}_front_plate", tmp)

    # ---- single elements over a shadow catcher --------------------------------
    # hide everything except the studio lights and the master elements
    # (the masters' own "Elements" collection already keeps them out of the
    # render; only their instances below are seen)
    elements = bpy.data.collections["Elements"]
    master_objs = {o for c in elements.children for o in c.objects}
    for o in scene.objects:
        o.hide_render = not (o in master_objs or o.name.startswith("Export_"))
    bpy.ops.mesh.primitive_plane_add(size=SWITCH_CANVAS_MM * 3, location=(0, 0, 0),
                                     rotation=(math.pi / 2, 0, 0))
    catcher = bpy.context.object
    catcher.name = "Shadow_Catcher"
    catcher.is_shadow_catcher = True
    catcher.location.y = -0.01                   # at the panel surface

    mp = cfg["master_prefix"]
    lever = bpy.data.objects[mp + "Toggle_Up_lever"]
    shots = [("led_on", mp + "LED_On", LED_CANVAS_MM, None),
             ("led_off", mp + "LED_Off", LED_CANVAS_MM, None),
             ("switch_up", mp + "Toggle_Up", SWITCH_CANVAS_MM, None),
             ("switch_down", mp + "Toggle_Down", SWITCH_CANVAS_MM, None),
             ("switch_neutral", mp + "Toggle_Up", SWITCH_CANVAS_MM, 0.0)]
    for name, coll, canvas, lever_rot in shots:
        e = bpy.data.objects.new("Export_" + name, None)
        e.instance_type, e.instance_collection = "COLLECTION", bpy.data.collections[coll]
        e.rotation_euler = (math.pi / 2, 0, 0)   # master +Z -> out of the panel
        scene.collection.objects.link(e)
        saved = lever.rotation_euler.x
        if lever_rot is not None:
            lever.rotation_euler.x = lever_rot
        for c in list(bpy.data.objects):
            if c.name.startswith("Export_Cam"):
                bpy.data.objects.remove(c)
        ortho_camera(0, 0, canvas, canvas)
        render_to(tmp)
        write_imageset(catalog, f"{cfg['prefix']}_{name}", tmp, clean=True)
        lever.rotation_euler.x = saved
        bpy.data.objects.remove(e)

    write_swift(cfg, layout, W, H)


def write_swift(cfg, layout, W, H):
    """AltairLayout<Style>.swift: an AltairPanelStyle (see AltairPanelView.swift)."""
    S, p = cfg["swift"], cfg["prefix"]
    var = S[0].lower() + S[1:]
    lines = [
        "// Generated by blender/export_assets.py - do not edit by hand.",
        "import CoreGraphics",
        "",
        "extension AltairPanelStyle {",
        f"    /// 1 mm on the panel = {PT_PER_MM:g} pt. Centres are measured from the",
        f"    /// top-left corner of \"{p}_front_plate\".",
        f"    static let {var} = AltairPanelStyle(",
        f'        assetPrefix: "{p}",',
        f"        plateSize: CGSize(width: {(W + 2 * FRAME) * PT_PER_MM:.1f}, "
        f"height: {(H + 2 * FRAME) * PT_PER_MM:.1f}),",
        f"        ledCanvas: {LED_CANVAS_MM * PT_PER_MM:.1f},",
        f"        switchCanvas: {SWITCH_CANVAS_MM * PT_PER_MM:.1f},",
        "        elements: [",
    ]
    for e in sorted(layout, key=lambda e: (e["kind"], e["y"], e["x"])):
        k = ".led" if e["kind"] == "led" else ".toggle"
        lines.append(f'            AltairElement(name: "{e["name"]}", kind: {k}, '
                     f'center: CGPoint(x: {e["x"]:.1f}, y: {e["y"]:.1f})),')
    lines += ["        ]", "    )", "}", ""]
    with open(os.path.join(OUT, f"AltairLayout{S}.swift"), "w") as f:
        f.write("\n".join(lines))


if __name__ == "__main__":
    style = sys.argv[sys.argv.index("--style") + 1] if "--style" in sys.argv else None
    samples = int(sys.argv[sys.argv.index("--samples") + 1]) if "--samples" in sys.argv else 96
    os.makedirs(OUT, exist_ok=True)
    for key in ([style] if style else ["lowpoly", "realistic"]):
        export_style(key, samples)
