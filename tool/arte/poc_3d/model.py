"""Import and normalize the Meshy mesh in a frame where the nose points to -Y."""
from dataclasses import dataclass
import math
import statistics

import bmesh
import bpy
from mathutils import Vector


def reset():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def import_dog(source, triangle_limit=110_000):
    bpy.ops.import_scene.gltf(filepath=str(source))
    meshes = [obj for obj in bpy.context.selected_objects if obj.type == "MESH"]
    if not meshes:
        raise ValueError(f"No hay malla en {source}")
    bpy.ops.object.select_all(action="DESELECT")
    for mesh in meshes:
        # Apply the importer parent transform to the vertices before joining.
        world = mesh.matrix_world.copy()
        mesh.parent = None
        mesh.matrix_world = world
        mesh.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if len(meshes) > 1:
        bpy.ops.object.join()
    dog = meshes[0]
    dog.name = "Caniche · malla Meshy"

    vertices = [v.co.copy() for v in dog.data.vertices]
    bounds = [(min(v[i] for v in vertices), max(v[i] for v in vertices)) for i in range(3)]
    length_axis = 0 if bounds[0][1] - bounds[0][0] > bounds[1][1] - bounds[1][0] else 1
    cross = 1 - length_axis
    cx = sum(bounds[cross]) / 2
    cy = sum(bounds[length_axis]) / 2
    floor, ceiling = bounds[2]
    height = ceiling - floor
    crown = [v[length_axis] for v in vertices if v.z > floor + height * 0.84]
    sign = -1 if statistics.median(crown) > cy else 1
    cross_sign = sign if length_axis == 1 else -sign
    for vertex, source in zip(dog.data.vertices, vertices):
        vertex.co = (
            (source[cross] - cx) * cross_sign / height,
            (source[length_axis] - cy) * sign / height,
            (source.z - floor) / height,
        )
    dog.data.update()
    # GLB can duplicate vertices at UV island borders. Join the geometry
    # before simplification while preserving each face corner's texture UV.
    bm = bmesh.new()
    bm.from_mesh(dog.data)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=0.00005)
    bm.normal_update()
    bm.to_mesh(dog.data)
    bm.free()
    if triangles(dog) > triangle_limit:
        bpy.context.view_layer.objects.active = dog
        decimate = dog.modifiers.new("Presupuesto de triángulos", "DECIMATE")
        decimate.ratio = triangle_limit / triangles(dog)
        bpy.ops.object.modifier_apply(modifier=decimate.name)
    for polygon in dog.data.polygons:
        polygon.use_smooth = True
    return dog


def triangles(obj):
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


@dataclass(frozen=True)
class Leg:
    key: str
    root: Vector
    knee: Vector
    ankle: Vector
    toe: Vector
    front: bool

    @property
    def thigh(self):
        return f"muslo.{self.key}"

    @property
    def shin(self):
        return f"pierna.{self.key}"

    @property
    def foot(self):
        return f"pata.{self.key}"


def paw_positions(dog):
    """Split vertices close to the ground into four clusters seeded by quadrant."""
    low = [v.co.copy() for v in dog.data.vertices if v.co.z < 0.125]
    if len(low) < 20:
        raise ValueError("La malla no contiene suficientes vértices cerca del suelo")
    mid_y = (min(p.y for p in low) + max(p.y for p in low)) / 2
    result = []
    for front in (True, False):
        for left in (True, False):
            region = [p for p in low if (p.y < mid_y) == front and (p.x > 0) == left]
            if len(region) < 5:
                raise ValueError("Las cuatro patas necesitan una postura de apoyo separada")
            x = statistics.median(p.x for p in region)
            y = statistics.median(p.y for p in region)
            result.append((front, left, x, y))
    return result


def anatomy(dog):
    """Landmarks measured from the imported model plus joint height estimates."""
    paws = paw_positions(dog)
    legs = []
    for front, left, x, y in paws:
        label = ("del" if front else "tras") + (".izq" if left else ".der")
        root = Vector((x * (1.06 if front else 1.10), y + (0.025 if front else 0.015), 0.545))
        knee = Vector((x * 1.02, y + (0.010 if front else -0.082), 0.317))
        ankle = Vector((x, y + 0.015, 0.103))
        toe = Vector((x, y - 0.056, 0.039))
        legs.append(Leg(label, root, knee, ankle, toe, front))
    front_y = statistics.mean(leg.root.y for leg in legs if leg.front)
    rear_y = statistics.mean(leg.root.y for leg in legs if not leg.front)
    head_y = statistics.median(v.co.y for v in dog.data.vertices if v.co.z > 0.86)
    return legs, front_y, rear_y, head_y


def create_rig(legs, front_y, rear_y, head_y):
    data = bpy.data.armatures.new("Esqueleto cuadrúpedo")
    rig = bpy.data.objects.new("Caniche · esqueleto", data)
    bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    rig.show_in_front = True
    bpy.ops.object.mode_set(mode="EDIT")

    def bone(name, start, end, parent=None, connected=False):
        b = data.edit_bones.new(name)
        b.head = start
        b.tail = end
        if parent:
            b.parent = data.edit_bones[parent]
            b.use_connect = connected
        return b

    bone("tronco", (0, rear_y, 0.57), (0, front_y, 0.59))
    bone("cuello", (0, front_y, 0.59), (0, head_y, 0.78), "tronco")
    bone("cabeza", (0, head_y, 0.78), (0, head_y - 0.115, 0.90), "cuello", True)
    bone("cola", (0, rear_y + 0.075, 0.61), (0, rear_y + 0.22, 0.79), "tronco")
    for leg in legs:
        bone(leg.thigh, leg.root, leg.knee, "tronco")
        bone(leg.shin, leg.knee, leg.ankle, leg.thigh, True)
        bone(leg.foot, leg.ankle, leg.toe, leg.shin, True)
    bpy.ops.object.mode_set(mode="OBJECT")
    for pose_bone in rig.pose.bones:
        pose_bone.rotation_mode = "XYZ"
    return rig


def smoothstep(start, stop, value):
    t = max(0.0, min(1.0, (value - start) / (stop - start)))
    return t * t * (3.0 - 2.0 * t)


def leg_weights(leg, z):
    hip = smoothstep(0.45, 0.57, z)
    knee = smoothstep(0.266, 0.366, z)
    ankle = smoothstep(0.064, 0.145, z)
    return {
        "tronco": hip,
        leg.thigh: (1 - hip) * knee,
        leg.shin: (1 - hip) * (1 - knee) * ankle,
        leg.foot: (1 - hip) * (1 - knee) * (1 - ankle),
    }


def bind(obj, rig, weights):
    dynamic = {}
    for vertex in obj.data.vertices:
        for name, value in weights(vertex.co).items():
            if value < 0.0001:
                continue
            if name not in dynamic:
                dynamic[name] = obj.vertex_groups.new(name=name)
            dynamic[name].add([vertex.index], value, "REPLACE")
    modifier = obj.modifiers.new("Articulación compartida", "ARMATURE")
    modifier.object = rig
    modifier.use_deform_preserve_volume = True
    obj.parent = rig


def body_weights(legs, front_y, rear_y, p):
    if p.z < 0.57:
        leg = min(legs, key=lambda leg: (p.x - leg.ankle.x) ** 2 + (p.y - leg.ankle.y) ** 2)
        affinity = 1 - smoothstep(0.12, 0.23, abs(p.y - leg.root.y))
        weights = {name: value * affinity for name, value in leg_weights(leg, p.z).items()}
        weights["tronco"] += 1 - affinity
        return weights
    tail = smoothstep(rear_y + 0.08, rear_y + 0.18, p.y)
    head_zone = 1 - smoothstep(front_y - 0.045, front_y + 0.13, p.y)
    head = smoothstep(0.675, 0.825, p.z) * head_zone
    neck = smoothstep(0.57, 0.71, p.z) * head_zone * (1 - head)
    trunk = max(0.0, 1 - tail - head - neck)
    return {"tronco": trunk, "cuello": neck, "cabeza": head, "cola": tail}


# Keys describe a gallop in place. The two extremes are frames 7 and 17.
GAIT = (
    # frame, lift, trunk pitch, head nod, swings, bends
    (1, 0.000, 0.015, -0.02, (-0.16, 0.12, 0.13, -0.10), (0.18, 0.15, -0.11, -0.13)),
    (7, 0.105, 0.025, 0.04, (-0.95, -0.76, 0.87, 0.72), (0.06, 0.19, -0.06, -0.22)),
    (12, 0.057, -0.07, 0.05, (-0.27, -0.06, 0.39, 0.15), (0.34, 0.61, -0.26, -0.44)),
    (17, 0.13, -0.12, -0.03, (0.05, -0.015, -0.12, -0.21), (1.02, 0.76, -0.79, -0.66)),
    (21, 0.055, -0.05, -0.04, (0.17, 0.06, -0.33, -0.14), (0.71, 0.31, -0.59, -0.38)),
    (25, 0.000, 0.015, -0.02, (-0.16, 0.12, 0.13, -0.10), (0.18, 0.15, -0.11, -0.13)),
)


def animate(rig, legs):
    for frame, lift, pitch, nod, swings, bends in GAIT:
        for b in rig.pose.bones:
            b.rotation_euler = (0, 0, 0)
        rig.location.z = lift
        rig.keyframe_insert(data_path="location", frame=frame)
        rig.pose.bones["tronco"].rotation_euler.x = pitch
        rig.pose.bones["cabeza"].rotation_euler.x = nod
        rig.pose.bones["cola"].rotation_euler.x = -0.3 * pitch
        for i, leg in enumerate(legs):
            # All leg rest matrices have their perpendicular local axis
            # parallel to world X, regardless of knee distance in the YZ plane.
            for name, angle in ((leg.thigh, swings[i]), (leg.shin, bends[i]), (leg.foot, -bends[i] * 0.32)):
                b = rig.pose.bones[name]
                local_x = b.bone.matrix_local.to_3x3().inverted() @ Vector((1, 0, 0))
                b.rotation_euler = (angle * local_x.x, angle * local_x.y, angle * local_x.z)
        for b in rig.pose.bones:
            b.keyframe_insert(data_path="rotation_euler", frame=frame)
    rig.location = (0, 0, 0)
    rig.keyframe_insert(data_path="location", frame=0)
    for b in rig.pose.bones:
        b.rotation_euler = (0, 0, 0)
        b.keyframe_insert(data_path="rotation_euler", frame=0)
