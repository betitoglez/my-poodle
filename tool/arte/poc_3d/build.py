"""Run from Blender: blender -b --python build.py -- SOURCE.glb OUTPUT [--inspect]."""
import argparse
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

sys.path.insert(0, str(Path(__file__).resolve().parent))
from model import animate, anatomy, bind, body_weights, create_rig, import_dog, reset, smoothstep, triangles
from garments import Wardrobe
from fitting import relaxed_surface


VIEWS = {
    "frente": (0, -4, 0.68),
    "perfil": (-4, 0, 0.66),
    "perfil-izquierdo": (4, 0, 0.66),
    "arriba": (0, 0, 4.4),
    "espalda": (0, 4, 0.68),
    "extension": (-4, 0, 0.66),
    "recogida": (-4, 0, 0.66),
    "detalle": (-3.1, -2.15, 1.04),
}
OUTFITS = {
    "peto": {"Peto", "Botas"},
    "vestido": {"Vestido", "Botas"},
    "impermeable": {"Impermeable"},
}
POSES = {"frente": 0, "perfil": 0, "espalda": 0, "extension": 7, "recogida": 17}


def look_at(obj, location):
    obj.rotation_euler = (Vector(location) - obj.location).to_track_quat("-Z", "Y").to_euler()


def studio(size, samples):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    scene.render.resolution_x = scene.render.resolution_y = size
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.fps = 24
    scene.frame_start, scene.frame_end = 1, 24
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs[0].default_value = (0.57, 0.65, 0.84, 1)
    scene.world.node_tree.nodes["Background"].inputs[1].default_value = 0.24
    scene.view_settings.view_transform = "AgX"
    # Lighting and cameras are independent of the wardrobe collections.
    for name, pos, watt, diameter, color in (
        ("Principal", (1.3, -1.8, 2.8), 114, 1.45, (1.0, 0.85, 0.71)),
        ("Relleno", (-1.3, -0.7, 1.7), 62, 1.6, (0.81, 0.89, 1.0)),
        ("Contorno", (0.3, 1.5, 2.2), 115, 1.2, (1.0, 0.74, 0.53)),
        ("Espalda", (-1.7, 0.7, 1.6), 40, 1.2, (0.94, 0.95, 1.0)),
    ):
        light = bpy.data.lights.new(name, "AREA")
        light.energy, light.size, light.color = watt, diameter, color
        obj = bpy.data.objects.new(name, light)
        scene.collection.objects.link(obj)
        obj.location = pos
        look_at(obj, (0, 0, 0.45))
    # A separate matte floor allows clean PNGs with a ground shadow.
    bpy.ops.mesh.primitive_plane_add(size=3, location=(0, 0, -0.008))
    floor = bpy.context.object
    floor.name = "Suelo · sombra"
    floor.is_shadow_catcher = True
    floor.hide_render = True
    camera_data = bpy.data.cameras.new("Cámara ortográfica")
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 1.78
    camera = bpy.data.objects.new("Cámara ortográfica", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    return scene, camera


def aim(camera, view):
    camera.location = VIEWS[view]
    if view == "arriba":
        camera.rotation_euler = (0, 0, math.pi)
    else:
        look_at(camera, (0, -0.04 if view == "detalle" else 0, 0.53 if view == "detalle" else 0.51))


def render(scene, camera, frame, view, target):
    aim(camera, view)
    scene.frame_set(frame)
    scene.render.filepath = str(target)
    bpy.ops.render.render(write_still=True)


def render_detail(scene, camera, target):
    width, height = scene.render.resolution_x, scene.render.resolution_y
    scale, samples = camera.data.ortho_scale, scene.cycles.samples
    try:
        scene.render.resolution_x = scene.render.resolution_y = 720
        scene.cycles.samples = 40
        camera.data.ortho_scale = 1.30
        render(scene, camera, 0, "detalle", target)
    finally:
        scene.render.resolution_x, scene.render.resolution_y = width, height
        scene.cycles.samples = samples
        camera.data.ortho_scale = scale


def render_glasses_details(scene, camera, eyes, output):
    width, height = scene.render.resolution_x, scene.render.resolution_y
    scale, samples = camera.data.ortho_scale, scene.cycles.samples
    center = Vector((0, eyes[1] + 0.045, eyes[2] + 0.017))
    try:
        scene.render.resolution_x = scene.render.resolution_y = 560
        scene.cycles.samples = 96
        camera.data.ortho_scale = 0.58
        scene.frame_set(0)
        for view, direction in {
            "frente": (0, -4, 0.10),
            "tres-cuartos": (-3.1, -2.6, 0.36),
            "perfil": (-4, -0.24, 0.18),
        }.items():
            camera.location = center + Vector(direction)
            look_at(camera, center)
            scene.render.filepath = str(output / f"gafas-{view}.png")
            bpy.ops.render.render(write_still=True)
    finally:
        scene.render.resolution_x, scene.render.resolution_y = width, height
        scene.cycles.samples = samples
        camera.data.ortho_scale = scale


def span(points, axis):
    values = sorted(p[axis] for p in points)
    margin = int(len(values) * 0.015)
    return values[margin], values[-margin - 1]


def landmarks(dog, joints):
    legs, fore, _, head = joints
    points = [v.co.copy() for v in dog.data.vertices]
    polygons = [tuple(p.vertices) for p in dog.data.polygons]
    surface = BVHTree.FromPolygons(points, polygons)
    neck_z = 0.641
    neck_pts = [p for p in points if abs(p.z - neck_z) < 0.014 and p.y < fore + 0.02]
    nx0, nx1 = span(neck_pts, 0)
    ny0, ny1 = span(neck_pts, 1)
    neck = ((nx1 - nx0) * 0.50 + 0.027, (ny1 - ny0) * 0.50 + 0.025, (ny0 + ny1) / 2, neck_z)

    hat_z = 0.885
    crown = [p for p in points if p.z > hat_z - 0.016 and p.y < fore + 0.12]
    hx0, hx1 = span(crown, 0)
    hy0, hy1 = span(crown, 1)
    hat = ((hx0 + hx1) / 2, (hy0 + hy1) / 2, hat_z,
           (hx1 - hx0) / 2 + 0.014, (hy1 - hy0) / 2 + 0.011)

    eye_z = 0.804
    face_at_eye, _, _, _ = surface.ray_cast(Vector((0.067, -1.0, eye_z)), Vector((0, 1, 0)), 1.1)
    face_front = face_at_eye.y if face_at_eye else -0.475
    boot_points = {
        leg.key: [p for p in points if p.z < 0.25 and
                  min(legs, key=lambda limb: (p - limb.ankle).xy.length_squared) == leg]
        for leg in legs
    }

    def boot_bounds(leg, z):
        points_at_height = [p for p in boot_points[leg.key] if abs(p.z - z) < 0.022]
        if len(points_at_height) < 3:
            points_at_height = boot_points[leg.key]
        a, b = span(points_at_height, 0)
        front, back = span(points_at_height, 1)
        return a, b, back, front

    return {
        "boot_bounds": boot_bounds,
        "surface": surface,
        "neck": neck,
        "hat": hat,
        "eyes": (0.068, face_front - 0.016, eye_z),
        "bow": (-0.104, head - 0.06, 0.907),
    }


def hair_pom(dog, measure):
    dog.shape_key_add(name="Corte osito")
    pom = dog.shape_key_add(name="Corte pompón")
    x, y, _, rx, ry = measure["hat"]
    for v in pom.data:
        p = v.co
        crown = smoothstep(0.755, 0.95, p.z)
        crown *= 1 - smoothstep(rx * 0.36, rx * 1.1, abs(p.x - x))
        crown *= 1 - smoothstep(ry * 0.54, ry * 1.18, abs(p.y - y))
        p.z += crown * 0.082
        p.x += crown * (p.x - x) * 0.48
        ears = smoothstep(0.095, 0.185, abs(p.x - x)) * (1 - smoothstep(0.76, 0.87, p.z))
        ears *= smoothstep(0.64, 0.72, p.z) * (1 - smoothstep(0.08, 0.185, abs(p.y - y)))
        p.z -= ears * 0.045
    return pom


def evaluated_triangles(objects):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    total = 0
    for obj in objects:
        if obj.type == "MESH":
            evaluated = obj.evaluated_get(depsgraph)
            mesh = evaluated.to_mesh()
            mesh.calc_loop_triangles()
            total += len(mesh.loop_triangles)
            evaluated.to_mesh_clear()
    return total


def inspect(dog, scene, camera, output):
    points = [v.co.copy() for v in dog.data.vertices]
    print("MESH", json.dumps({
        "triangles": triangles(dog),
        "xyz": [span(points, d) for d in range(3)],
        "paws": [(leg.key, *leg.toe) for leg in anatomy(dog)[0]],
        "landmarks": {k: v for k, v in landmarks(dog, anatomy(dog)).items() if k not in {"surface", "boot_bounds"}},
    }), flush=True)
    for view in ("frente", "perfil", "espalda"):
        render(scene, camera, 0, view, output / f"base-{view}.png")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--glasses", type=Path, help="GLB de la montura de Meshy")
    parser.add_argument("--inspect", action="store_true")
    parser.add_argument("--draft", action="store_true")
    parser.add_argument("--build-only", action="store_true")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    args.output.mkdir(parents=True, exist_ok=True)
    reset()
    scene, camera = studio(330 if args.draft else 440, 8 if args.draft else 16)
    dog = import_dog(args.source)
    if args.inspect:
        inspect(dog, scene, camera, args.output)
        return

    joints = anatomy(dog)
    legs, fore, rear, head = joints
    measure = landmarks(dog, joints)
    rig = create_rig(*joints)
    bind(dog, rig, lambda point: body_weights(legs, fore, rear, point))
    animate(rig, legs)
    pom = hair_pom(dog, measure)
    frame_source = args.glasses or args.source.with_name("montura-meshy.glb")
    wardrobe = Wardrobe(rig, joints, measure, relaxed_surface(dog), glasses=frame_source)
    wardrobe.build()
    report = {}
    for haircut in ("osito", "pompon"):
        for key, clothes in OUTFITS.items():
            wardrobe.show(clothes)
            # Compress the pompón under the hat using the fitted close cut.
            pom.value = (0.10 if key == "impermeable" else 1.0) if haircut == "pompon" else 0.0
            bpy.context.view_layer.update()
            parts = [obj for name in clothes for obj in wardrobe.collections[name].objects]
            report[f"{haircut}-{key}"] = evaluated_triangles([dog, *parts])
            if not args.build_only:
                for view, frame in POSES.items():
                    render(scene, camera, frame, view, args.output / f"{haircut}-{key}-{view}.png")
                for view in ("perfil-izquierdo", "arriba"):
                    render(scene, camera, 0, view, args.output / f"{haircut}-{key}-{view}.png")
                if haircut == "osito" and not args.draft:
                    render_detail(scene, camera, args.output / f"detalle-{key}.png")
                    if key == "impermeable":
                        render_glasses_details(scene, camera, measure["eyes"], args.output)
    if max(report.values()) > 200_000:
        raise ValueError(f"Presupuesto superado: {report}")
    (args.output / "triangulos.json").write_text(json.dumps(report, indent=2) + "\n")
    wardrobe.show(OUTFITS["peto"])
    pom.value = 0.0
    scene.frame_set(0)
    aim(camera, "perfil")
    for obj in bpy.context.selected_objects:
        obj.select_set(False)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == "VIEW_3D":
                area.spaces.active.region_3d.view_perspective = "CAMERA"
                area.spaces.active.shading.color_type = "MATERIAL"
                area.spaces.active.overlay.show_overlays = False
    scene.render.filepath = "//renders/"
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output / "My-Poodle-vestuario.blend"))
    if not args.build_only:
        for idx, frame in enumerate(range(1, 25, 2)):
            render(scene, camera, frame, "perfil", args.output / f"carrera-{idx:02d}.png")


if __name__ == "__main__":
    main()
