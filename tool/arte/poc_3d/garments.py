"""Reusable garment meshes built around the joints of the imported poodle."""
import math

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

from eyewear import aperture_rings, fit_frame, import_frame
from fitting import boundaries, cut_surface, reduce_detail, relax_cloth
from materials import finish_acetate, lenses, rubber, surface, textile
from model import bind, body_weights, smoothstep


def mesh_object(name, vertices, faces, mat, collection):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    collection.objects.link(obj)
    obj.data.materials.append(mat)
    for face in obj.data.polygons:
        face.use_smooth = True
    return obj


def loft(name, rings, mat, collection, caps=False, wall=0.0):
    count = len(rings[0])
    faces = [
        (row * count + i, row * count + (i + 1) % count,
         (row + 1) * count + (i + 1) % count, (row + 1) * count + i)
        for row in range(len(rings) - 1)
        for i in range(count)
    ]
    if caps:
        faces.extend([tuple(reversed(range(count))), tuple(range((len(rings) - 1) * count, len(rings) * count))])
    obj = mesh_object(name, [v for ring in rings for v in ring], faces, mat, collection)
    texture_uv = obj.data.uv_layers.new(name="Patrón")
    for face in obj.data.polygons:
        columns = [obj.data.loops[i].vertex_index % count for i in face.loop_indices]
        wraps = 0 in columns and count - 1 in columns
        for loop_index, col in zip(face.loop_indices, columns):
            row = obj.data.loops[loop_index].vertex_index // count
            u = 1 if wraps and col == 0 else col / count
            texture_uv.uv[loop_index].vector = (u, row / (len(rings) - 1))
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    obj.select_set(False)
    if wall:
        solidify = obj.modifiers.new("Grosor de la tela", "SOLIDIFY")
        solidify.thickness = wall
        solidify.offset = -0.65
    return obj


def elliptical_ring(center, width, height, axis="Y", points=48, pleats=0, phase=0):
    center = Vector(center)
    result = []
    for i in range(points):
        a = i * math.tau / points
        ripple = 1 + pleats * math.cos(a * 15 + phase)
        x, other = width * math.cos(a) * ripple, height * math.sin(a) * ripple
        offset = Vector((x, 0, other)) if axis == "Y" else Vector((x, other, 0))
        result.append(center + offset)
    return result


def trim_path(name, path, radius, mat, collection, *, closed=False):
    tube = []
    for i, point in enumerate(path):
        before = path[i - 1] if closed or i else point
        after = path[(i + 1) % len(path)] if closed or i < len(path) - 1 else point
        tangent = (after - before).normalized()
        normal = tangent.cross(Vector((0, 1, 0)))
        if normal.length < 0.05:
            normal = tangent.cross(Vector((1, 0, 0)))
        normal.normalize()
        binormal = tangent.cross(normal)
        tube.append([
            point + radius * (math.cos(a * math.tau / 6) * normal + math.sin(a * math.tau / 6) * binormal)
            for a in range(6)
        ])
    return loft(name, tube + tube[:1] if closed else tube, mat, collection, caps=not closed)


def trim_ring(name, ring, radius, mat, collection):
    return trim_path(name, ring, radius, mat, collection, closed=True)


def stitched_path(name, path, mat, collection, spacing=0.012, radius=0.0018):
    """A dashed saddle stitch with evenly spaced strands on the seam."""
    vertices, faces = [], []
    for a, b in zip(path, path[1:]):
        origin, target = Vector(a), Vector(b)
        delta = target - origin
        if delta.length < 0.003:
            continue
        count = max(1, round(delta.length / spacing))
        tangent = delta.normalized()
        side = tangent.cross(Vector((0, 0, 1)))
        if side.length < 0.1:
            side = tangent.cross(Vector((0, 1, 0)))
        side.normalize()
        lift = tangent.cross(side)
        for i in range(count):
            center = origin.lerp(target, (i + 0.5) / count)
            if delta.length / count < spacing * 0.40:
                continue
            index = len(vertices)
            for t in (-0.28, 0.28):
                end = center + delta * (t / count)
                vertices.extend(
                    end + radius * (side * math.cos(theta) + lift * math.sin(theta))
                    for theta in (0, math.pi / 2, math.pi, 3 * math.pi / 2)
                )
            faces.extend((index + j, index + (j + 1) % 4,
                          index + (j + 1) % 4 + 4, index + j + 4) for j in range(4))
    return mesh_object(name, vertices, faces, mat, collection)


def blob(name, center, scale, mat, collection, segments=24, rings=14):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=1)
    obj = bpy.context.object
    for source in list(obj.users_collection):
        source.objects.unlink(obj)
    collection.objects.link(obj)
    for v in obj.data.vertices:
        v.co.x = v.co.x * scale[0] + center[0]
        v.co.y = v.co.y * scale[1] + center[1]
        v.co.z = v.co.z * scale[2] + center[2]
    obj.data.update()
    obj.name = name
    obj.data.materials.append(mat)
    for face in obj.data.polygons:
        face.use_smooth = True
    obj.select_set(False)
    return obj


def patch(name, grid, mat, collection, solidify=0.006):
    cols = len(grid[0])
    obj = mesh_object(name, [co for row in grid for co in row], [
        (row * cols + i, (row + 1) * cols + i, (row + 1) * cols + i + 1, row * cols + i + 1)
        for row in range(len(grid) - 1)
        for i in range(cols - 1)
    ], mat, collection)
    modifier = obj.modifiers.new("Grosor", "SOLIDIFY")
    modifier.thickness = solidify
    return obj


class Wardrobe:
    def __init__(self, rig, anatomy, measure, relaxed, *, glasses=None):
        self.rig = rig
        self.legs, self.front, self.rear, self.head = anatomy
        self.measure = measure
        self.surface = relaxed
        self.glasses_source = glasses
        self.collections = {}
        self.green = textile("Peto · pana verde bosque", (0.024, 0.125, 0.086), "corduroy")
        self.green_edge = textile("Peto · lona del ribete", (0.019, 0.071, 0.047), "weave")
        self.thread = textile("Hilo de pespunte crudo", (0.53, 0.39, 0.214), "weave")
        self.gold, _ = surface("Latón cepillado", (0.50, 0.29, 0.102), 0.45, metallic=0.72)
        self.coral = textile("Pañuelo · algodón terracota", (0.55, 0.095, 0.061), "weave")
        self.coral_edge = textile("Pañuelo · orillo coral claro", (0.78, 0.28, 0.175), "weave")
        self.pink = textile("Vestido · popelina rosa antiguo", (0.59, 0.225, 0.31), "weave")
        self.pink_edge = textile("Vestido · cinta de grosgrain", (0.32, 0.071, 0.128), "weave")
        self.rubber = rubber("Botas · caucho natural mostaza", (0.57, 0.297, 0.043))
        self.sole = rubber("Botas · suela de caucho tostado", (0.102, 0.054, 0.024), outsole=True)
        self.raincoat = textile("Impermeable · lona encerada azul", (0.035, 0.165, 0.268), "weave", coated=True)
        self.rain_edge = textile("Impermeable · ribete azul noche", (0.023, 0.047, 0.069), "weave")
        self.knit = textile("Gorro · lana de punto color miel", (0.60, 0.278, 0.060), "knit")
        self.knit_edge = textile("Gorro · lana canela", (0.37, 0.135, 0.035), "knit")
        self.frame, _ = surface("Gafas · acetato carey", (0.113, 0.049, 0.025), 0.38)
        finish_acetate(self.frame)
        self.glass = lenses()
        self.shells = {}
        self.boot_cuffs = []

    def weights(self, obj, bone=None):
        if bone:
            weights = lambda _: {bone: 1}
        else:
            weights = lambda p: body_weights(self.legs, self.front, self.rear, p)
        bind(obj, self.rig, weights)
        return obj

    def add_collection(self, name):
        coll = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(coll)
        self.collections[name] = coll
        return coll

    def show(self, name):
        for key, collection in self.collections.items():
            collection.hide_render = key not in name
            collection.hide_viewport = key not in name
        for cuff in self.boot_cuffs:
            cuff.value = float("Peto" in name)

    def build(self):
        boots = self.add_collection("Botas")
        self.make_boots(boots)
        green = self.add_collection("Peto")
        self.make_body(green, self.green, self.green_edge, cover="peto")
        self.make_overall_details(green)
        self.make_bandana(green)
        pink = self.add_collection("Vestido")
        self.make_body(pink, self.pink, self.pink_edge, cover="vestido")
        self.make_skirt(pink)
        self.make_bow(pink)
        blue = self.add_collection("Impermeable")
        self.make_body(blue, self.raincoat, self.rain_edge, cover="impermeable")
        self.make_coat_details(blue)
        self.make_hat(blue)
        self.make_glasses(blue)

    def make_body(self, collection, main, edge, cover):
        def hem_limit(p):
            if cover == "peto":
                lower = 0.168
            elif cover == "jersey":
                lower = 0.220 + 0.025 * smoothstep(-0.22, 0.17, p.y)
            elif cover == "impermeable":
                lower = 0.238 + 0.045 * smoothstep(-0.2, 0.2, p.y)
            else:
                lower = 0.420 + 0.065 * smoothstep(-0.28, -0.16, p.y)
            tail = 0.705 - 1.53 * max(p.y - self.rear + 0.083, 0)
            tail += 0.037 * smoothstep(0.065, 0.140, abs(p.x))
            neck = 0.642 + 0.20 * max(p.y - self.front, 0)
            return max(lower - p.z, p.z - min(tail, neck))

        def clearance(p):
            sleeve = smoothstep(0.17, 0.22, p.z) * (1 - smoothstep(0.35, 0.49, p.z))
            shoulder = 1 - smoothstep(0.04, 0.18, abs(p.y - self.front))
            fold = 0.005 * math.sin(92 * p.z + 17 * p.y) * sleeve * (0.48 + shoulder * 0.52)
            tail_base = smoothstep(self.rear - 0.055, self.rear + 0.058, p.y)
            tail_base *= smoothstep(0.48, 0.605, p.z)
            chest_clearance = 0.017 if cover == "vestido" else 0.006
            return 0.026 + fold - 0.012 * tail_base + chest_clearance * shoulder * smoothstep(0.47, 0.58, p.z)

        vertices, faces = cut_surface(self.surface, clearance, hem_limit)
        shell = mesh_object(f"{cover} · malla continua", vertices, faces, main, collection)
        relax_cloth(shell)
        reduce_detail(shell, 13_000)
        self.shells[cover] = BVHTree.FromPolygons(
            [v.co for v in shell.data.vertices], [f.vertices[:] for f in shell.data.polygons],
        )
        self.weights(shell)
        shell.data.materials.append(edge)
        solidify = shell.modifiers.new("Espesor y canto forrado", "SOLIDIFY")
        solidify.thickness = 0.006
        solidify.offset = -0.65
        solidify.material_offset_rim = 1

        for i, border in enumerate(boundaries(vertices, faces)):
            # Borders come from the real neckline, tail opening and cuffs.
            if sum((b - a).length for a, b in zip(border, border[1:])) < 0.18:
                continue
            center_z = sum(v.z for v in border) / len(border)
            stride = max(1, len(border) // 47)
            rim = trim_ring(f"{cover} · ribete {i + 1}", border[::stride],
                            0.007 if center_z < 0.33 else 0.005, edge, collection)
            self.weights(rim)

    def on_shell(self, garment, location, direction, offset=0.006):
        base, normal = Vector(location), Vector(direction).normalized()
        hit, _, _, _ = self.shells[garment].ray_cast(base + normal * 0.42, -normal, 0.59)
        return hit + normal * offset if hit is not None else base + normal * 0.12

    def make_overall_details(self, collection):
        for sign in (-1, 1):
            normal = (sign, 0, 0)

            def point(y, z, lift=0.008):
                return self.on_shell("peto", (0, y, z), normal, lift)

            # A sewn patch pocket on each hip, with a rounded bottom and an
            # inset top edge. Projecting the grid keeps it flush on the body.
            pocket = []
            ys = self.rear - 0.14
            for j in range(8):
                v = j / 7
                row = [
                    point(ys + (i / 9 - 0.5) * (0.133 - 0.020 * v ** 3),
                          0.563 - 0.116 * v + 0.014 * v ** 5 * abs(2 * i / 9 - 1),
                          0.010 + 0.004 * math.sin(math.pi * i / 9))
                    for i in range(10)
                ]
                pocket.append(row)
            self.weights(patch("Peto · bolsillo de parche", pocket, self.green, collection, 0.003))
            outline = pocket[0] + [r[-1] for r in pocket[1:]] + list(reversed(pocket[-1][:-1])) + [
                r[0] for r in reversed(pocket[1:-1])
            ]
            self.weights(trim_ring("Peto · canto del bolsillo", outline, 0.0035, self.green_edge, collection))
            self.weights(stitched_path("Peto · pespunte", [
                v + Vector((sign * 0.004, 0, 0)) for v in (*outline, outline[0])
            ], self.thread, collection, spacing=0.010))

            tab = []
            for j in range(8):
                t = j / 7
                y = self.front + 0.065 + t * 0.026
                z = 0.562 + t * 0.101
                tab.append([point(y + side * 0.021, z, 0.010) for side in (-1, 1)])
            self.weights(patch("Peto · tirante con remate", tab, self.green_edge, collection, 0.004))
            for side in (0, 1):
                self.weights(stitched_path("Peto · pespunte del tirante", [
                    row[side] + Vector((sign * 0.003, 0, 0)) for row in tab
                ], self.thread, collection, spacing=0.012, radius=0.0014))
            button = point(self.front + 0.072, 0.572, 0.021)
            self.weights(blob("Peto · botón de latón sobre el tirante", button,
                              (0.009, 0.016, 0.016), self.gold, collection, segments=18, rings=10))

    def make_coat_details(self, collection):
        grid = []
        for i in range(18):
            z = 0.353 + i * 0.016
            grid.append([
                self.on_shell("impermeable", (x, -0.18, z), (0, -1, 0), 0.008)
                for x in (-0.032, -0.020, 0.020, 0.032)
            ])
        self.weights(patch("Impermeable · solapa de cierre", grid, self.rain_edge, collection, 0.005))
        for column in (0, -1):
            seam = [row[column] + Vector((0, -0.004, 0)) for row in grid]
            self.weights(stitched_path("Impermeable · costura de solapa",
                                        seam, self.thread, collection, radius=0.0014))
        for row in grid[2:-1:4]:
            center = (row[1] + row[2]) / 2 + Vector((0, -0.006, 0))
            self.weights(blob("Impermeable · automático", center, (0.011, 0.006, 0.011),
                              self.gold, collection, segments=16, rings=8))
        dorsal = [
            self.on_shell("impermeable", (0, self.front + 0.12 + 0.365 * i / 29, 0.50),
                          (0, 0, 1), 0.005)
            for i in range(30)
        ]
        self.weights(trim_path("Impermeable · costura dorsal", dorsal, 0.003,
                                self.rain_edge, collection))

    def make_boots(self, collection):
        for leg in self.legs:
            x, y, _ = leg.ankle
            y -= 0.010
            spec = [(0.005, 0.077, 0.094, -0.020), (0.030, 0.079, 0.096, -0.021),
                    (0.048, 0.077, 0.093, -0.021), (0.071, 0.071, 0.085, -0.017),
                    (0.104, 0.066, 0.074, 0), (0.157, 0.064, 0.070, 0.009),
                    (0.195, 0.065, 0.073, 0.014), (0.207, 0.067, 0.075, 0.014)]
            rings = []
            for z, w, depth, dy in spec:
                a, b, back, front = self.measure["boot_bounds"](leg, z)
                cx = (a + b) / 2
                cy = (back + front) / 2
                rings.append(elliptical_ring(
                    (0.28 * x + 0.72 * cx, 0.15 * (y + dy) + 0.85 * cy, z),
                    max(w, (b - a) * 0.61 + 0.008),
                    max(depth, (back - front) * 0.60 + 0.01), "Z",
                ))
            for obj in (
                loft(f"Bota · {leg.key}", rings[1:], self.rubber, collection, wall=0.006),
                loft(f"Suela antideslizante · {leg.key}", rings[:2], self.sole, collection, caps=True),
                trim_ring(f"Junta de la suela · {leg.key}", rings[1], 0.004, self.sole, collection),
                trim_ring(f"Vuelta de caucho · {leg.key}", rings[-1], 0.0048, self.rubber, collection),
            ):
                # The sole holds its shape. The shaft follows the lower leg.
                def boot_weights(p):
                    shin = smoothstep(0.075, 0.199, p.z)
                    return {leg.foot: 1 - shin, leg.shin: shin}
                bind(obj, self.rig, boot_weights)
                if max(v.co.z for v in obj.data.vertices) > 0.17:
                    obj.shape_key_add(name="Caña alta")
                    tucked = obj.shape_key_add(name="Caña bajo la pernera")
                    center = sum(rings[-1], Vector()) / len(rings[-1])
                    for vertex in tucked.data:
                        amount = smoothstep(0.12, 0.207, vertex.co.z)
                        vertex.co.z -= amount * 0.030
                        vertex.co.x -= (vertex.co.x - center.x) * amount * 0.07
                        vertex.co.y -= (vertex.co.y - center.y) * amount * 0.05
                    self.boot_cuffs.append(tucked)

    def make_bandana(self, collection):
        x_radius, y_radius, y, z = self.measure["neck"]
        upper, lower = [], []
        for i in range(46):
            # The draped triangle forms the front. The folded cloth runs
            # around the nape and overlaps the ends at the sides only.
            angle = math.pi * (-0.14 + 1.28 * i / 45)
            nape = max(0, math.sin(angle))
            drape = 0.007 * math.cos(2 * angle + 0.7)
            x = x_radius * math.cos(angle) * 0.95
            back = y + y_radius * math.sin(angle) * 0.91
            upper.append(Vector((x, back, z + drape + nape * 0.007)))
            lower.append(Vector((x * 1.02, back, z + drape - 0.023 + nape * 0.007)))
        self.weights(patch("Pañuelo · vuelta de algodón en la nuca", [upper, lower],
                           self.coral, collection, 0.003), bone="cuello")
        self.weights(trim_path("Pañuelo · dobladillo de la vuelta", upper, 0.0026,
                               self.coral_edge, collection), bone="cuello")
        rows = []
        for j in range(18):
            v = j / 17
            width = x_radius * (0.93 - v * 0.90)
            row = []
            for k in range(29):
                u = 2 * k / 28 - 1
                x = u * width - 0.008 * v
                height = z - 0.015 - v * 0.170 - 0.044 * (1 - u * u) * (1 - v)
                hit, _, _, _ = self.measure["surface"].ray_cast(
                    Vector((x, -0.9, height)), Vector((0, 1, 0)), 0.9,
                )
                depth = y - y_radius * (1 - 0.28 * u * u) - 0.010
                shell_hit, _, _, _ = self.shells["peto"].ray_cast(
                    Vector((x, -0.9, height)), Vector((0, 1, 0)), 0.86,
                )
                if shell_hit is not None:
                    depth = shell_hit.y - 0.018
                elif hit is not None:
                    depth = hit.y - 0.021
                fold = math.sin(math.tau * (v * 2.25 + 0.27 * u * u - 0.14 * u))
                depth -= 0.011 * (0.5 + 0.5 * fold) * (1 - 0.76 * v)
                row.append(Vector((x, depth, height)))
            rows.append(row)
        self.weights(patch("Pañuelo · pico con pliegues", rows, self.coral, collection, 0.003), bone="cuello")
        sides = [row[0] for row in rows] + list(reversed([row[-1] for row in rows]))
        self.weights(trim_path("Pañuelo · dobladillo bajo", sides, 0.0029,
                               self.coral_edge, collection), bone="cuello")
        knot = Vector((-x_radius * 0.94, y - y_radius * 0.43, z + 0.006))
        self.weights(blob("Pañuelo · nudo de algodón", knot, (0.024, 0.028, 0.019),
                          self.coral, collection, segments=18, rings=10), bone="cuello")
        for sign in (-1, 1):
            self.ribbon(collection, "Pañuelo · extremo del nudo", knot,
                        Vector((-0.063, sign * 0.039, -0.032 if sign == 1 else -0.059)),
                        0.038, self.coral, "cuello")

    def ribbon(self, collection, name, knot, span, width, material, bone):
        rows = []
        across = Vector((span.z, 0, -span.x)).normalized()
        for j in range(10):
            t = j / 9
            flare = math.sin(math.pi * (0.17 + 0.80 * t)) * 0.82 + 0.18
            center = knot + span * t + Vector((0, -0.013 * math.sin(math.pi * t), 0))
            rows.append([
                center + across * (width * flare * u / 2)
                + Vector((0, -0.008 * math.cos(math.pi * u) * math.sin(math.pi * t), 0))
                for u in (-1, -0.66, -0.33, 0, 0.33, 0.66, 1)
            ])
        self.weights(patch(name, rows, material, collection, 0.003), bone=bone)

    def make_skirt(self, collection):
        y = self.rear - 0.202
        for tier in (0, 1):
            rows = []
            for j in range(12):
                t = j / 11
                row = []
                for i in range(89):
                    angle = -0.20 * math.pi + 1.40 * math.pi * i / 88
                    pleat = math.cos(15 * angle + 0.85 * tier + t * 0.32)
                    fold = 1 + (0.019 + 0.078 * t) * pleat
                    x = math.cos(angle) * (0.134 + 0.030 * tier + 0.066 * t) * fold
                    z = 0.50 - 0.048 * tier - 0.061 * t
                    z += math.sin(angle) * (0.094 + 0.013 * tier + 0.071 * t) * fold
                    rear = y + 0.065 * tier + (0.166 + 0.016 * tier) * t + 0.016 * t * pleat
                    row.append(Vector((x, rear, z)))
                rows.append(row)
            self.weights(patch(f"Vestido · volante {tier + 1} de popelina", rows,
                               self.pink, collection, 0.0036), bone="tronco")
            self.weights(trim_path("Vestido · vivo del volante", rows[-1], 0.0029,
                                   self.pink_edge, collection), bone="tronco")
        sash = [
            self.on_shell("vestido", (0, y - 0.009, 0.49),
                          (math.cos(a), 0, math.sin(a)), 0.007)
            for a in (math.pi * i / 33 for i in range(34))
        ]
        self.weights(trim_path("Vestido · cintura de grosgrain", sash, 0.010,
                                self.pink_edge, collection), bone="tronco")

    def make_bow(self, collection):
        x, _, z = self.measure["bow"]
        hit, _, _, _ = self.measure["surface"].ray_cast(Vector((x, -0.86, z)), Vector((0, 1, 0)), 0.9)
        y = hit.y if hit is not None else self.head - 0.12
        knot = Vector((x, y - 0.022, z))
        for side in (-1, 1):
            self.ribbon(collection, "Lazo · ala plegada", knot, Vector((side * 0.064, -0.006, 0.023)),
                        0.045, self.pink, "cabeza")
            self.ribbon(collection, "Lazo · caída de cinta", knot, Vector((side * 0.035, -0.002, -0.050)),
                        0.032, self.pink_edge, "cabeza")
        self.weights(blob("Lazo · nudo", knot, (0.016, 0.013, 0.017),
                          self.pink_edge, collection, segments=16, rings=9), bone="cabeza")

    def make_hat(self, collection):
        x, y, z, rx, ry = self.measure["hat"]
        rings = []
        for h, scale in ((0, 1), (0.025, 1.005), (0.050, 0.99), (0.081, 0.90),
                         (0.114, 0.73), (0.141, 0.46), (0.155, 0.16), (0.159, 0.035)):
            ring = []
            for i in range(72):
                angle = i * math.tau / 72
                cable = 1 + 0.024 * math.cos(15 * angle + 4.4 * h)
                ring.append((x + rx * scale * cable * math.cos(angle),
                             y + h * 0.25 + ry * scale * cable * math.sin(angle),
                             z + h + 0.006 * math.cos(angle * 2)))
            rings.append(ring)
        self.weights(loft("Gorro · copa de punto redondeada", rings[1:], self.knit, collection, caps=True),
                     bone="cabeza")
        cuff = []
        for h, scale in ((-0.006, 0.986), (0.001, 1.035), (0.040, 1.040), (0.048, 1.002)):
            ring = elliptical_ring((x, y, z + h), rx * scale, ry * scale,
                                   "Z", points=72, pleats=0.024)
            cuff.append(ring)
        self.weights(loft("Gorro · vuelta de canalé", cuff, self.knit_edge, collection, wall=0.005),
                     bone="cabeza")
        center = (x, y + 0.050, z + 0.179)
        tuft = self.weights(blob("Gorro · borla de lana", center, (0.041, 0.041, 0.040),
                                 self.knit_edge, collection), bone="cabeza")
        for vertex in tuft.data.vertices:
            delta = vertex.co - Vector(center)
            ripple = math.sin(delta.x * 290) * math.sin(delta.y * 260) * math.sin(delta.z * 275)
            vertex.co += delta * ripple * 0.12

    def make_glasses(self, collection):
        frame = import_frame(self.glasses_source, collection)
        eyes = self.measure["eyes"]
        face_plane = fit_frame(frame, self.measure["surface"], eyes)
        frame.data.materials.clear()
        frame.data.materials.append(self.frame)
        self.weights(frame, bone="cabeza")
        for sign, side, ring in zip((-1, 1), ("derecha", "izquierda"), aperture_rings(frame, eyes, face_plane)):
            center = sum(ring, Vector()) / len(ring) + Vector((0, -0.0018, 0))
            glass = mesh_object(f"Gafas · lente clara {side}", [center, *ring],
                                [(0, i + 1, (i + 1) % len(ring) + 1) for i in range(len(ring))],
                                self.glass, collection)
            thickness = glass.modifiers.new("Espesor de la lente", "SOLIDIFY")
            thickness.thickness = 0.0014
            self.weights(glass, bone="cabeza")

            pad_x, pad_z = sign * 0.026, eyes[2] + 0.004
            skin, _, _, _ = self.measure["surface"].ray_cast(
                Vector((pad_x, -0.9, pad_z)), Vector((0, 1, 0)), 0.9,
            )
            if skin:
                pad = skin + Vector((0, -0.006, 0))
                attachment = min(ring, key=lambda p: (p.x - pad_x) ** 2 + (p.z - pad_z) ** 2)
                run = [attachment, attachment.lerp(pad, 0.50) + Vector((sign * 0.004, 0, -0.003)), pad]
                self.weights(trim_path(f"Gafas · soporte nasal {side}", run, 0.0024,
                                       self.gold, collection), bone="cabeza")
                self.weights(blob(f"Gafas · plaqueta {side}", pad, (0.0048, 0.0058, 0.009),
                                  self.frame, collection, segments=12, rings=8), bone="cabeza")
