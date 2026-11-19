"""Fit the Meshy frame around the poodle and trace lenses from its apertures."""
import math

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

from fitting import reduce_detail
from model import smoothstep


def import_frame(source, collection):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(source))
    imported = set(bpy.data.objects) - before
    meshes = [obj for obj in imported if obj.type == "MESH"]
    if not meshes:
        raise ValueError(f"El GLB no contiene una montura: {source}")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        world = obj.matrix_world.copy()
        obj.parent = None
        obj.matrix_world = world
        obj.select_set(True)
    frame = meshes[0]
    bpy.context.view_layer.objects.active = frame
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if len(meshes) > 1:
        bpy.ops.object.join()
    for obj in imported - set(meshes):
        bpy.data.objects.remove(obj, do_unlink=True)
    collection.objects.link(frame)
    for current in list(frame.users_collection):
        if current != collection:
            current.objects.unlink(frame)
    frame.name = "Gafas · montura de Meshy ajustada"
    reduce_detail(frame, 6_000)
    for polygon in frame.data.polygons:
        polygon.use_smooth = True
    return frame


def fit_frame(frame, skin, eyes):
    eye_x, eye_y, eye_z = eyes
    points = [vertex.co.copy() for vertex in frame.data.vertices]
    bounds = [(min(p[i] for p in points), max(p[i] for p in points)) for i in range(3)]
    cx = sum(bounds[0]) / 2
    cz = sum(bounds[2]) / 2
    # Meshy's front ring is perpendicular to Y. Use the optical centers to
    # scale width and height together, retaining the generated oval shape.
    width = bounds[0][1] - bounds[0][0]
    scale = eye_x / (width * 0.25)
    front = bounds[1][0] + 0.029 * width
    length = bounds[1][1] - front
    face_plane = eye_y - 0.012
    center_z = eye_z + 0.017
    fitted = []
    clearance = []
    for point in points:
        x = (point.x - cx) * scale
        depth = (point.y - front) / length
        front_weight = 1 - smoothstep(0.038, 0.40, depth)
        lens_height = (point.z - cz) * scale * 0.84
        z = center_z + lens_height - 0.010 * (1 - front_weight)
        bottom = smoothstep(0.009, 0.044, -lens_height)
        inner = 1 - smoothstep(0.026, 0.077, abs(x))
        z += 0.018 * inner * bottom * front_weight
        # A slight curve at the bottom clears the muzzle without moving the
        # bridge and both rims forward as one rigid plate.
        bow = (0.022 + 0.012 * inner) * bottom
        y = face_plane + 0.175 * depth + 0.011 * (abs(x) / (eye_x * 2)) ** 2 - bow * front_weight
        if depth < 0.062:
            muzzle, _, _, _ = skin.ray_cast(Vector((x, -0.9, z)), Vector((0, 1, 0)), 0.9)
            if muzzle:
                clearance.append(y - muzzle.y + 0.007)
        fitted.append((x, y, z, depth))

    # Keep the entire front in front of the brows and muzzle, preserving
    # its profile. The new clearance fades along the temples toward the tips.
    front_shift = max(0, sorted(clearance)[int(0.998 * (len(clearance) - 1))]) if clearance else 0
    print(f"Holgura de la montura hacia delante: {front_shift:.4f}", flush=True)
    for vertex, (x, y, z, depth) in zip(frame.data.vertices, fitted):
        side = -1 if x < 0 else 1
        y -= front_shift * (1 - smoothstep(0.06, 0.87, depth))

        # Temples flare around the ear bulge and narrow again toward the tip.
        taper = smoothstep(0.065, 0.53, depth)
        spread = taper * (0.030 - 0.009 * smoothstep(0.67, 1, depth))
        if taper:
            outer_skin, _, _, _ = skin.ray_cast(
                Vector((side * 0.35, y, z)), Vector((-side, 0, 0)), 0.35,
            )
            if outer_skin:
                required = abs(outer_skin.x) + 0.010 - abs(x)
                spread = max(spread, taper * min(0.057, required))
        vertex.co = (x + side * spread, y, z)
    frame.data.update()
    return face_plane - front_shift


def aperture_rings(frame, eyes, face_plane):
    """Measure each lens opening against the front part of the fitted mesh."""
    eye_x, _, eye_z = eyes
    eye_z += 0.017
    points = [v.co.copy() for v in frame.data.vertices]
    front_faces = [face.vertices[:] for face in frame.data.polygons
                   if max(points[i].y for i in face.vertices) < face_plane + 0.040]
    tree = BVHTree.FromPolygons(points, front_faces)
    for side in (-1, 1):
        center_x = side * eye_x
        ring = []
        for i in range(72):
            angle = i * math.tau / 72
            dx, dz = math.cos(angle), math.sin(angle)
            for step in range(15, 69):
                radius = step * 0.001
                x, z = center_x + dx * radius, eye_z + dz * radius
                hit, _, _, _ = tree.ray_cast(Vector((x, face_plane - 0.06, z)),
                                             Vector((0, 1, 0)), 0.105)
                if hit:
                    ring.append(hit + Vector((dx * 0.0008, 0.0045, dz * 0.0008)))
                    break
        if len(ring) != 72:
            raise ValueError("La abertura de la montura necesita un contorno cerrado")
        # Remove the minute steps introduced by ray sampling.
        yield [
            ring[i - 1] * 0.22 + point * 0.56 + ring[(i + 1) % len(ring)] * 0.22
            for i, point in enumerate(ring)
        ]
