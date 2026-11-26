#!/usr/bin/env python3
"""
Dört ayaklının gerçek kareleri: bitmiş GLB'yi temiz bir Blender sahnesine alır (dosyadaki iskelet, ağırlık ve klipler), Cycles CPU ile zeminli çizer,
paftayı ffmpeg ile birleştirir. Yalnız dosyayı okur, varlık yazmaz.

Kullanım (game/ klasöründe; Metal kum havuzunda açılmaz, kum havuzu dışında koşar):
  /opt/homebrew/bin/blender -b --python tools/blender/quadruped_preview.py -- <glb> <çıktı.jpg> \
      --shots=idle:0:side,idle:0:front,walk:0.1:side,walk:0.6:side,graze:3:side,graze:3:front [--cols=3] [--size=640x480] [--samples=16] [--far=<far.glb>] [--look=y,z] [--dist=5.2] [--titles=a,b,...]

Atış biçimi klip:saniye:görünüm. Saniye klip boyunun oranıysa "p" ile yazılır (walk:p0.25:side). Görünümler: side (sol yandan), right (sağ yandan),
front (önden), back (arkadan), game (oyun kamerası gibi yukarıdan, üç çeyrek), top. rest klibi dinlenme pozudur. far: uzak ağ.
"""
import math
import os
import subprocess
import sys
import tempfile

import bpy
from mathutils import Vector

VIEWS = {
    "side": (1.0, 0.0, 0.0), "right": (-1.0, 0.0, 0.0), "front": (0.0, 0.0, 1.0), "back": (0.0, 0.0, -1.0),
    "game": (0.62, 0.72, 0.62), "gameb": (-0.62, 0.72, -0.62), "top": (0.0, 1.0, 0.001), "q": (0.8, 0.28, 0.75), "qb": (-0.8, 0.28, -0.75),
    "low": (0.9, 0.08, 0.35), "lowb": (-0.9, 0.08, -0.35),
}


def to_blender(v):
    """Oyun uzayı (y yukarı, +z ileri) → Blender (z yukarı, -y ileri)."""
    return Vector((v[0], -v[2], v[1]))


def parse():
    argv = sys.argv[sys.argv.index("--") + 1:]
    positional = [a for a in argv if not a.startswith("--")]
    options = dict(a[2:].partition("=")[0::2] for a in argv if a.startswith("--"))
    if len(positional) != 2:
        sys.exit(__doc__)
    return positional[0], positional[1], options


def setup_scene(samples, width, height):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = False
    scene.render.resolution_x = width
    scene.render.resolution_y = height
    scene.render.image_settings.file_format = "PNG"
    scene.render.fps = 60
    # Karenin etiketi: Blender'ın damgası (kullanılan ffmpeg derlemesinde drawtext yok).
    scene.render.use_stamp = True
    scene.render.use_stamp_note = True
    scene.render.stamp_font_size = 22
    scene.render.stamp_foreground = (1.0, 1.0, 1.0, 1.0)
    scene.render.stamp_background = (0.0, 0.0, 0.0, 0.55)
    for flag in ("date", "time", "render_time", "frame", "frame_range", "memory", "hostname", "camera", "lens", "scene", "marker", "filename", "sequencer_strip"):
        setattr(scene.render, "use_stamp_" + flag, False)
    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.8, 0.84, 0.9, 1.0)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.65
    scene.world = world
    sun = bpy.data.lights.new("sun", "SUN")
    sun.energy = 3.0
    sun.angle = math.radians(12.0)
    sun_obj = bpy.data.objects.new("sun", sun)
    sun_obj.rotation_euler = (math.radians(50.0), math.radians(10.0), math.radians(35.0))
    scene.collection.objects.link(sun_obj)
    ground = bpy.data.meshes.new("ground")
    ground.from_pydata([(-6, -6, 0), (6, -6, 0), (6, 6, 0), (-6, 6, 0)], [], [(0, 1, 2, 3)])
    mat = bpy.data.materials.new("ground")
    mat.use_nodes = True
    mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.42, 0.45, 0.33, 1.0)
    mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 1.0
    ground.materials.append(mat)
    ground_obj = bpy.data.objects.new("ground", ground)
    scene.collection.objects.link(ground_obj)
    cam = bpy.data.cameras.new("cam")
    cam.lens = 85.0
    cam_obj = bpy.data.objects.new("cam", cam)
    scene.collection.objects.link(cam_obj)
    scene.camera = cam_obj
    return scene, cam_obj


def load_glb(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    arm = next((o for o in new if o.type == "ARMATURE"), None)
    mesh = next((o for o in new if o.type == "MESH"), None)
    return new, arm, mesh


def find_action(name):
    for action in bpy.data.actions:
        if action.name == name or action.name.startswith(name + "_") or action.name.startswith(name + "."):
            return action
    return None


def clip_length(action, fps):
    start, end = action.frame_range
    return (end - start) / fps


def apply_clip(scene, arm, clip, seconds, fps):
    if clip == "rest" or arm is None:
        if arm is not None and arm.animation_data:
            arm.animation_data.action = None
            for bone in arm.pose.bones:
                bone.rotation_mode = "QUATERNION"
                bone.rotation_quaternion = (1, 0, 0, 0)
                bone.location = (0, 0, 0)
                bone.scale = (1, 1, 1)
        scene.frame_set(1)
        return
    action = find_action(clip)
    if action is None:
        sys.exit("klip yok: %s (var: %s)" % (clip, [a.name for a in bpy.data.actions]))
    data = arm.animation_data or arm.animation_data_create()
    data.use_nla = False
    data.action = action
    if hasattr(data, "action_slot") and action.slots:
        data.action_slot = action.slots[0]
    if isinstance(seconds, str) and seconds.startswith("p"):
        seconds = float(seconds[1:]) * clip_length(action, fps)
    frame = action.frame_range[0] + float(seconds) * fps
    whole = int(math.floor(frame))
    scene.frame_set(whole, subframe=frame - whole)


def aim(cam_obj, direction, target, distance):
    d = to_blender(direction).normalized()
    t = to_blender(target)
    cam_obj.location = t + d * distance
    cam_obj.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()


def montage(paths, cols, out, size):
    """PNG'leri ızgara yapar, jpg yazar."""
    inputs = []
    filters = []
    for path in paths:
        inputs += ["-i", path]
    rows = [list(range(i, min(i + cols, len(paths)))) for i in range(0, len(paths), cols)]
    chains = []
    for r, row in enumerate(rows):
        names = ["[%d:v]" % k for k in row]
        while len(names) < cols:
            filters.append("color=c=gray:s=%s,trim=end_frame=1[pad%d_%d]" % (size, r, len(names)))
            names.append("[pad%d_%d]" % (r, len(names)))
        filters.append("%shstack=inputs=%d[row%d]" % ("".join(names), cols, r))
        chains.append("[row%d]" % r)
    if len(rows) > 1:
        filters.append("%svstack=inputs=%d[out]" % ("".join(chains), len(rows)))
    else:
        filters.append("[row0]copy[out]")
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y"] + inputs + ["-filter_complex", ";".join(filters), "-map", "[out]", "-q:v", "3", out], check=True)


def main():
    glb, out, options = parse()
    shots = options.get("shots", "rest:0:side,rest:0:front").split(",")
    cols = int(options.get("cols", 3))
    width, height = (int(v) for v in options.get("size", "640x480").split("x"))
    samples = int(options.get("samples", 16))
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene, cam_obj = setup_scene(samples, width, height)
    objects, arm, mesh = load_glb(glb)
    far_objects = []
    if options.get("far"):
        far_objects, _, _ = load_glb(options["far"])
        for o in far_objects:
            o.hide_render = True
            o.hide_viewport = True
    # Blender'ın kendi argüman ayrıştırıcısı --c... öneklerini kendine sayar: bakış noktası --look=y,z.
    look = [float(v) for v in options.get("look", "0.47,0.0").split(",")]
    target_body = (0.0, look[0], look[1])
    distance = float(options.get("dist", 5.2))
    fps = scene.render.fps
    frames = []
    tmp = tempfile.mkdtemp()
    titles = options["titles"].split(",") if options.get("titles") else shots
    for n, shot in enumerate(shots):
        parts = shot.split(":")
        clip, seconds, view = parts[0], parts[1], parts[2]
        if not seconds.startswith("p"):
            seconds = float(seconds)
        if clip == "far":
            for o in objects:
                o.hide_render = True
            for o in far_objects:
                if o.type == "MESH":
                    o.hide_render = False
        else:
            for o in objects:
                if o.type == "MESH":
                    o.hide_render = False
            for o in far_objects:
                o.hide_render = True
            apply_clip(scene, arm, clip, seconds, fps)
        aim(cam_obj, VIEWS[view], target_body, distance)
        path = os.path.join(tmp, "%03d.png" % n)
        scene.render.filepath = path
        scene.render.stamp_note_text = titles[n]
        bpy.ops.render.render(write_still=True)
        frames.append(path)
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    montage(frames, cols, out, "%dx%d" % (width, height))
    print("pafta:", out, len(frames), "kare")


if __name__ == "__main__":
    main()
