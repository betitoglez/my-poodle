"""Export the modular poodle and its care animations from Blender."""
import math
from pathlib import Path
import sys

import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

sys.path.insert(0, str(Path(__file__).resolve().parent))
from catalog import Catalog, puppy_hair
from materials import finish_acetate
from model import anatomy, body_weights, leg_weights, smoothstep


TEXTILE_MAP_SIZE = {
    "peto · malla continua": 1024,
    "Peto · bolsillo de parche": 256,
    "Peto · bolsillo de parche.001": 256,
    "vestido · malla continua": 1024,
    "Vestido · volante 1 de popelina": 512,
    "Vestido · volante 2 de popelina": 512,
    "impermeable · malla continua": 1024,
    "jersey · malla continua": 1024,
}
DETAIL_MAP_SIZE = {
    "outfit.teal": 256,
    "outfit.dress_pink": 256,
    "outfit.raincoat_blue": 256,
    "neck.coral": 512,
    "head.bow": 256,
    "head.beanie": 512,
    "eyes.round": 512,
    "paws.rain": 512,
    "outfit.sweater_red": 256,
    "neck.bowtie": 256,
    "neck.knit": 512,
    "collar.tag": 256,
    "collar.bell": 256,
    "paws.booties": 512,
    "paws.sneakers": 512,
}
DYE_MATERIALS = {
    "Peto · pana verde bosque": "fabric",
    "Peto · lona del ribete": "binding",
    "Vestido · popelina rosa antiguo": "fabric",
    "Vestido · cinta de grosgrain": "binding",
    "Impermeable · lona encerada azul": "fabric",
    "Impermeable · ribete azul noche": "binding",
    "Jersey · lana roja con cenefa": "fabric",
    "Jersey · borde acanalado": "binding",
}


def angle(a, b):
    return math.atan2(b.y - a.y, a.z - b.z)


def pose_leg(leg, a, target, trunk_pitch=0):
    first, second = (leg.knee - leg.root).length, (leg.ankle - leg.knee).length
    dy, dz = target.y - a.y, target.z - a.z
    distance = math.hypot(dy, dz)
    along = (first**2 - second**2 + distance**2) / (2 * distance)
    across = math.sqrt(max(0, first**2 - along**2))
    sign = 1 if leg.front else -1
    knee = Vector((leg.knee.x, a.y + (dy * along - sign * dz * across) / distance,
                   a.z + (dz * along + sign * dy * across) / distance))
    thigh = angle(a, knee) - angle(leg.root, leg.knee) - trunk_pitch
    shin = angle(knee, target) - angle(leg.knee, leg.ankle) - thigh - trunk_pitch
    return ((leg.thigh, thigh), (leg.shin, shin), (leg.foot, -thigh - shin - trunk_pitch))


def key_pose(rig, frame, location, angles):
    rig.location = location
    rig.keyframe_insert(data_path="location", frame=frame)
    for bone in rig.pose.bones:
        axis = bone.bone.matrix_local.to_3x3().inverted() @ Vector((1, 0, 0))
        bone.rotation_mode = "XYZ"
        bone.rotation_euler = axis * angles.get(bone.name, 0)
        bone.keyframe_insert(data_path="rotation_euler", frame=frame)


def lay_down(rig, dog, name="Tumbarse", *, front_reach=-0.167, rear_reach=0.094):
    rig.animation_data_clear()
    legs, *_ = anatomy(dog)
    for frame in range(25):
        t = frame / 24
        t = t * t * (3 - 2 * t)
        drop = 0.322 * t
        location = Vector((0, 0, -drop))
        angles = {"cuello": -0.06 * t, "cabeza": 0.19 * t, "cola": -0.20 * t}
        for leg in legs:
            if frame:
                reach = front_reach if leg.front else rear_reach
                ankle = leg.ankle.lerp(Vector((leg.ankle.x, leg.root.y + reach, 0.105)), t)
                angles.update(pose_leg(leg, leg.root + location, ankle))
        key_pose(rig, frame, location, angles)
    rig.animation_data.action.name = name
    scene = bpy.context.scene
    scene.frame_start, scene.frame_end = 0, 24
    scene.frame_set(0)


def eat(rig, dog):
    rig.animation_data_clear()
    legs, *_ = anatomy(dog)
    pivot = rig.data.bones["tronco"].head_local
    for frame in range(25):
        t = frame / 24
        dip = smoothstep(0, 0.41, t) * (1 - smoothstep(0.76, 1, t))
        chewing = smoothstep(0.40, 0.47, t) * (1 - smoothstep(0.69, 0.78, t))
        chew = math.sin(t * math.tau * 7.0) * 0.027 * chewing
        pitch = 0.37 * dip
        rotation = Matrix.Rotation(pitch, 3, "X")
        location = Vector((0, 0, -0.022 * dip))
        angles = {"tronco": pitch, "cuello": 0.60 * dip, "cabeza": 0.012 * dip + chew,
                  "cola": -0.28 * dip}
        if dip > 0:
            for leg in legs:
                root = pivot + rotation @ (leg.root - pivot) + location
                ankle = leg.ankle.copy()
                ankle.y += (-0.052 if leg.front else 0.067) * dip
                angles.update(pose_leg(leg, root, ankle, pitch))
        key_pose(rig, frame, location, angles)
    action = rig.animation_data.action
    action.name = "Comer"
    bpy.context.scene.frame_set(0)
    return action


def part(obj, collection):
    name = obj.name
    if collection == "Peto":
        return "neck.coral" if name.startswith("Pañuelo") else "outfit.teal"
    if collection == "Vestido":
        return "head.bow" if name.startswith("Lazo") else "outfit.dress_pink"
    if collection == "Impermeable":
        if name.startswith("Gafas"):
            return "eyes.round"
        if name.startswith("Gorro"):
            return "head.beanie"
        return "outfit.raincoat_blue"
    return "paws.rain"


def base_surface(obj):
    return BVHTree.FromPolygons([v.co for v in obj.data.vertices],
                                [f.vertices[:] for f in obj.data.polygons])


def change_weights(obj, weights):
    obj.vertex_groups.clear()
    groups = {}
    for vertex in obj.data.vertices:
        for name, weight in weights(vertex.co).items():
            if weight > 0.0001:
                if name not in groups:
                    groups[name] = obj.vertex_groups.new(name=name)
                groups[name].add([vertex.index], weight, "REPLACE")


def fit_live_wardrobe(dog, clothes):
    legs, front, rear, head = anatomy(dog)
    skin = base_surface(dog)
    shells = [base_surface(obj) for obj in clothes if obj.name.endswith("· malla continua")]

    for obj in clothes:
        wear = obj["wear"]
        if wear.startswith("outfit.") and set(obj.vertex_groups.keys()) != {"tronco"}:
            # Give the cloth and its seams the weights of the skin beneath them.
            change_weights(obj, lambda p: body_weights(legs, front, rear, skin.find_nearest(p)[0]))
        elif wear == "paws.rain":
            leg = next(leg for leg in legs if obj.name.endswith(leg.key))
            # The lower shaft and paw need the same blend across the ankle.
            change_weights(obj, lambda p: leg_weights(leg, p.z))
        elif obj.name.startswith("Bufanda · frente"):
            for v in obj.data.vertices:
                p = v.co
                hits = [surface.ray_cast((p.x, -0.79, p.z), (0, 1, 0), 0.64)[0]
                        for surface in [skin, *shells]]
                front_y = min((hit.y for hit in hits if hit is not None), default=p.y)
                pleat = 0.006 * math.cos(72 * p.x + 24 * p.z)
                hang = 1 - smoothstep(0.558, 0.619, p.z)
                p.y = p.y * (1 - hang) + (front_y - 0.012 + pleat) * hang
        elif wear == "head.bow" or obj.name.startswith((
            "Pañuelo · pico", "Pañuelo · dobladillo bajo", "Pajarita · ala", "Pajarita · orillo",
            "Pajarita · nudo", "Bufanda · nudo",
        )):
            surfaces = [skin] if wear == "head.bow" else [skin, *shells]
            clearance = 0.003 if wear == "head.bow" else 0.009
            for v in obj.data.vertices:
                p = v.co
                for surface in surfaces:
                    hit = surface.ray_cast((p.x, p.y - 0.13, p.z), (0, 1, 0), 0.13 + clearance)[0]
                    if hit is not None:
                        p.y = min(p.y, hit.y - clearance)
        elif obj.name.startswith(("Pañuelo · vuelta", "Pañuelo · dobladillo de la vuelta")):
            for v in obj.data.vertices:
                p = v.co
                # Seat the nape over the top of the neck instead of inside the back.
                up = smoothstep(head + 0.12, front + 0.08, p.y)
                direction = Vector((p.x, 0, 0)).lerp(Vector((0, 0, 0.12)), up)
                direction.normalize()
                hit = skin.ray_cast(p + direction * 0.10, -direction, 0.106)[0]
                if hit is not None:
                    p[:] = hit + direction * 0.006


def fit_resting_shells(dog, rig, shells):
    scene = bpy.context.scene
    for obj in [dog, *shells]:
        for modifier in obj.modifiers:
            if modifier.type == "ARMATURE":
                # Match the linear skinning used by glTF.
                modifier.use_deform_preserve_volume = False
            elif modifier.type == "SOLIDIFY":
                modifier.show_viewport = False
    scene.frame_set(scene.frame_end)
    graph = bpy.context.evaluated_depsgraph_get()
    skin = BVHTree.FromObject(dog, graph)
    transforms = {bone.name: (bone.matrix @ bone.bone.matrix_local.inverted()).to_3x3()
                  for bone in rig.pose.bones}
    corrections = []
    for obj in shells:
        posed = obj.evaluated_get(graph).data
        weights = [transforms[group.name] for group in obj.vertex_groups]
        offsets = []
        for vertex in posed.vertices:
            near, normal, _, _ = skin.find_nearest(vertex.co)
            clearance = 0.004 - (vertex.co - near).dot(normal)
            if clearance <= 0 or normal.dot(vertex.normal) < 0.15:
                continue
            blend = Matrix.Diagonal((0, 0, 0))
            for group in obj.data.vertices[vertex.index].groups:
                blend += weights[group.group] * group.weight
            offsets.append((vertex.index, blend.inverted_safe() @ normal * min(clearance, 0.026)))
        corrections.append((obj, offsets))
    scene.frame_set(scene.frame_start)
    for obj, offsets in corrections:
        obj.shape_key_add(name="Base")
        key = obj.shape_key_add(name="Holgura tumbado")
        for index, offset in offsets:
            key.data[index].co += offset


def fit_shoe_hems(wardrobe):
    for obj, wear in wardrobe:
        if wear == "outfit.teal":
            low, high, lift = 0.176, 0.31, 0.09
        elif obj.name.startswith(("Vestido · volante", "Vestido · vivo")):
            low, high, lift = 0.36, 0.55, 0.105
        else:
            continue
        if min(v.co.z for v in obj.data.vertices) >= high:
            continue
        if obj.data.shape_keys is None:
            obj.shape_key_add(name="Base")
        key = obj.shape_key_add(name="Dobladillo con calzado")
        for v in key.data:
            v.co.z += (1 - smoothstep(low, high, v.co.z)) * lift


def prepare_glass(mat):
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    shader = nodes.get("Principled BSDF")
    links.new(shader.outputs[0], nodes.get("Material Output").inputs["Surface"])
    opacity = 0.07
    shader.inputs["Alpha"].default_value = opacity
    mat.diffuse_color = (*mat.diffuse_color[:3], opacity)
    mat.surface_render_method = "BLENDED"


def needs_bake(material):
    shader = material.node_tree.nodes.get("Principled BSDF")
    return any(shader.inputs[name].is_linked for name in ("Base Color", "Normal"))


def unwrap_atlas(objects, padding):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        # Match the geometry exported with export_apply=False. A Solidify modifier
        # would bake the outer surface and the lining onto the same UVs.
        for modifier in tuple(obj.modifiers):
            if modifier.type == "SOLIDIFY":
                obj.modifiers.remove(modifier)
        obj.data.uv_layers.active = uv = obj.data.uv_layers.new(name="Atlas", do_init=False)
        uv.active_render = True
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(70), island_margin=padding,
                            margin_method="FRACTION")
    bpy.ops.object.mode_set(mode="OBJECT")


def bake_textile(objects, name, size):
    padding = 4 if size >= 512 else 2
    # Explicitly reference original UVs in the knitting shader before adding the atlas.
    materials = {}
    for obj in objects:
        original_uv = next((uv.name for uv in obj.data.uv_layers if uv.active_render), None)
        for index, source in enumerate(obj.data.materials):
            key = (source, original_uv)
            if key not in materials:
                material = source.copy()
                nodes, links = material.node_tree.nodes, material.node_tree.links
                for coords in tuple(node for node in nodes if node.type == "TEX_COORD"):
                    destinations = [link.to_socket for link in coords.outputs["UV"].links]
                    if destinations and original_uv is not None:
                        uv_map = nodes.new("ShaderNodeUVMap")
                        uv_map.uv_map = original_uv
                        for destination in destinations:
                            links.new(uv_map.outputs["UV"], destination)
                materials[key] = material, nodes.new("ShaderNodeTexImage")
            obj.data.materials[index] = materials[key][0]

    unwrap_atlas(objects, 2 * padding / size)
    targets = tuple(materials.values())
    color = None
    if any(mat.node_tree.nodes.get("Principled BSDF").inputs["Base Color"].is_linked
           for mat, _ in targets):
        color = bpy.data.images.new(f"{name} · color", width=size, height=size, alpha=False)
    normal = bpy.data.images.new(f"{name} · normal", width=size, height=size, alpha=False,
                                 is_data=True)
    for image, bake_type in ((color, "DIFFUSE"), (normal, "NORMAL")):
        if image is None:
            continue
        for material, target in targets:
            target.image = image
            material.node_tree.nodes.active = target
        bpy.ops.object.bake(type=bake_type, pass_filter={"COLOR"} if bake_type == "DIFFUSE" else set(),
                            normal_space="TANGENT", margin=padding, margin_type="EXTEND",
                            uv_layer="Atlas")
        image.pack()

    for material, target in targets:
        nodes, links = material.node_tree.nodes, material.node_tree.links
        shader = nodes.get("Principled BSDF")
        target.image = normal
        normal_map = nodes.new("ShaderNodeNormalMap")
        links.new(target.outputs["Color"], normal_map.inputs["Color"])
        links.new(normal_map.outputs["Normal"], shader.inputs["Normal"])
        if color is not None:
            base_map = nodes.new("ShaderNodeTexImage")
            base_map.image = color
            links.new(base_map.outputs["Color"], shader.inputs["Base Color"])
    for obj in objects:
        for uv in tuple(obj.data.uv_layers):
            if uv.name != "Atlas":
                obj.data.uv_layers.remove(uv)


def main():
    output = Path(sys.argv[sys.argv.index("--") + 1])
    output.parent.mkdir(parents=True, exist_ok=True)
    dog = bpy.data.objects["Caniche · malla Meshy"]
    rig = bpy.data.objects["Caniche · esqueleto"]
    dog["wear"] = "base"
    lay_down(rig, dog)
    puppy_hair(dog)
    finish_acetate(bpy.data.materials["Gafas · acetato carey"])
    prepare_glass(bpy.data.materials["Gafas · lentes claras"])
    selected = [dog, rig]
    textiles = []
    details = {wear: [] for wear in DETAIL_MAP_SIZE}
    wardrobe = []
    for name in ("Peto", "Vestido", "Impermeable", "Botas"):
        collection = bpy.data.collections[name]
        collection.hide_render = collection.hide_viewport = False
        for obj in collection.objects:
            wardrobe.append((obj, part(obj, name)))
    wardrobe.extend(Catalog(rig, dog).build())
    for obj, wear in wardrobe:
        obj["wear"] = wear
        if wear.startswith("outfit."):
            for material in obj.data.materials:
                if material.name in DYE_MATERIALS:
                    material["catalogDye"] = list(material.diffuse_color[:3])
                    material["dyeRole"] = DYE_MATERIALS[material.name]
        if obj.name in TEXTILE_MAP_SIZE:
            textiles.append(obj)
        elif any(needs_bake(material) for material in obj.data.materials):
            details[wear].append(obj)
        selected.append(obj)
    fit_live_wardrobe(dog, selected[2:])
    for obj in selected:
        if obj.type == "MESH" and obj.data.shape_keys:
            for key in list(obj.data.shape_keys.key_blocks)[1:]:
                key.value = 0
    fit_resting_shells(dog, rig, [obj for obj in textiles if obj.name.endswith("· malla continua")])
    fit_shoe_hems(wardrobe)
    lie_down = rig.animation_data.action
    # The thicker boots need a little more room in front of the chest and behind the cuffs.
    lay_down(rig, dog, "Tumbarse con botas", front_reach=-0.33, rear_reach=0.18)
    rain_lie_down = rig.animation_data.action
    eat_bite = eat(rig, dog)
    rig.animation_data.action = None
    for action in (lie_down, rain_lie_down, eat_bite):
        track = rig.animation_data.nla_tracks.new()
        track.name = action.name
        track.strips.new(action.name, 0, action)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 1
    for obj in textiles:
        bake_textile([obj], obj.name, TEXTILE_MAP_SIZE[obj.name])
    for wear, objects in details.items():
        if objects:
            bake_textile(objects, wear, DETAIL_MAP_SIZE[wear])
    bpy.ops.object.select_all(action="DESELECT")
    for obj in selected:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.export_scene.gltf(
        filepath=str(output), export_format="GLB", use_selection=True,
        export_extras=True, export_animation_mode="NLA_TRACKS",
        export_animations=True, export_frame_range=True,
        export_image_format="AUTO", export_apply=False,
    )


if __name__ == "__main__":
    main()
