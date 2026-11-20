"""Additional wardrobe meshes built on the same rig and fit landmarks."""
import math

from build import landmarks
from fitting import relaxed_surface
from garments import Wardrobe, blob, elliptical_ring, loft, mesh_object, patch, trim_path, trim_ring
from materials import rubber, surface, textile
from mathutils import Vector
from model import anatomy, bind, leg_weights, smoothstep


class Catalog(Wardrobe):
    def __init__(self, rig, dog):
        joints = anatomy(dog)
        super().__init__(rig, joints, landmarks(dog, joints), None)
        self.dog = dog

    def build(self):
        self.make_sweater(self.add_collection("outfit.sweater_red"))
        self.make_crown(self.add_collection("head.crown"))
        for shape in ("sun", "heart"):
            self.make_eyewear(self.add_collection(f"eyes.{shape}"), heart=shape == "heart")
        for design in ("tag", "bell", "pearls"):
            self.make_collar(self.add_collection(f"collar.{design}"), design)
        self.make_bowtie(self.add_collection("neck.bowtie"))
        self.make_scarf(self.add_collection("neck.knit"))
        self.make_shoes(self.add_collection("paws.booties"), knit=True)
        self.make_shoes(self.add_collection("paws.sneakers"), knit=False)
        return [(obj, wear) for wear, collection in self.collections.items() for obj in collection.objects]

    def make_sweater(self, collection):
        self.surface = relaxed_surface(self.dog)
        wool = textile("Jersey · lana roja con cenefa", (0.41, 0.052, 0.031), "wool")
        rib = textile("Jersey · borde acanalado", (0.29, 0.027, 0.017), "knit")
        self.make_body(collection, wool, rib, cover="jersey")

    def make_crown(self, collection):
        gold, _ = surface("Corona · latón pulido", (0.61, 0.337, 0.071), 0.33, metallic=0.62)
        ruby, shader = surface("Corona · granates", (0.48, 0.025, 0.043), 0.22)
        shader.inputs["Coat Weight"].default_value = 0.35
        cx, cy, _, rx, ry = self.measure["hat"]
        z = 0.949
        rx, ry = rx * 0.88, ry * 0.77
        base, shoulder, peaks = [], [], []
        for i in range(80):
            a = i * math.tau / 80
            x, y = math.cos(a) * rx, math.sin(a) * ry
            point = (0.5 + 0.5 * math.cos(5 * (a + math.pi / 2))) ** 3
            base.append(Vector((cx + x, cy + y, z)))
            shoulder.append(Vector((cx + 1.04 * x, cy + 1.04 * y, z + 0.028)))
            peaks.append(Vector((cx + 1.15 * x, cy + 1.15 * y, z + 0.047 + 0.066 * point)))
        self.weights(loft("Corona · cuerpo calado", [base, shoulder, peaks], gold, collection), bone="cabeza")
        self.weights(trim_ring("Corona · reborde", base, 0.005, gold, collection), bone="cabeza")
        for i in range(12, 80, 16):
            self.weights(blob("Corona · remate", peaks[i], (0.008, 0.008, 0.008),
                              gold, collection, segments=12, rings=7), bone="cabeza")
        for i in (46, 60, 74):
            center = shoulder[i].lerp(peaks[i], 0.27)
            outside = Vector((center.x - cx, center.y - cy, 0)).normalized()
            self.weights(blob("Corona · engaste", center + outside * 0.006, (0.009, 0.006, 0.012),
                              ruby, collection, segments=10, rings=6), bone="cabeza")

    def make_eyewear(self, collection, *, heart):
        frame, shader = surface("Montura · acetato cereza" if heart else "Montura · acetato negro",
                                (0.26, 0.028, 0.043) if heart else (0.022, 0.022, 0.027), 0.32)
        shader.inputs["Coat Weight"].default_value = 0.3
        lens, lens_shader = surface("Lente · rosa translúcido" if heart else "Lente · humo",
                                    (0.55, 0.09, 0.15) if heart else (0.038, 0.054, 0.065), 0.19)
        alpha = 0.24 if heart else 0.91
        lens_shader.inputs["Alpha"].default_value = alpha
        lens.diffuse_color = (*lens.diffuse_color[:3], alpha)
        lens.surface_render_method = "BLENDED"
        ex, ey, ez = self.measure["eyes"]
        ey -= 0.045
        ez += 0.015
        for side in (-1, 1):
            ring = []
            for i in range(56):
                a = i * math.tau / 56
                if heart:
                    x = 0.054 * math.sin(a) ** 3
                    z = 0.00285 * (13 * math.cos(a) - 5 * math.cos(2 * a)
                                   - 2 * math.cos(3 * a) - math.cos(4 * a)) + 0.008
                else:
                    x = 0.055 * math.copysign(abs(math.cos(a)) ** 0.82, math.cos(a))
                    z = 0.039 * math.copysign(abs(math.sin(a)) ** 0.90, math.sin(a))
                ring.append(Vector((side * ex + x, ey + side * x * 0.24 + z * 0.11, ez + z)))
            self.weights(trim_ring("Gafas · aro", ring, 0.0062 if heart else 0.0057,
                                   frame, collection), bone="cabeza")
            center = Vector((side * ex, ey - 0.003, ez))
            self.weights(mesh_object("Gafas · cristal curvo", [center, *ring],
                                     [(0, i + 1, (i + 1) % len(ring) + 1) for i in range(len(ring))],
                                     lens, collection), bone="cabeza")
            corner = max(ring, key=lambda point: point.x * side)
            temple = [corner, corner + Vector((side * 0.010, 0.011, 0.004))]
            for i in range(1, 11):
                t = i / 10
                y = corner.y + 0.20 * t
                z = corner.z + 0.006 * math.sin(math.pi * t) - 0.029 * smoothstep(0.69, 1, t)
                hit = self.measure["surface"].ray_cast((side * 0.37, y, z), (-side, 0, 0), 0.27)[0]
                outside = abs(hit.x) + 0.004 if hit is not None else abs(corner.x) + 0.015
                outer = min(max(abs(corner.x) + 0.012, outside), 0.164)
                tuck = smoothstep(0.47, 1, t)
                x = outer * (1 - tuck) + 0.092 * tuck
                temple.append(Vector((side * x, y, z)))
            self.weights(trim_path("Gafas · patilla", temple, 0.0044, frame, collection), bone="cabeza")
            hinge, _ = surface(f"Gafas · bisagra {side}", (0.46, 0.28, 0.13), 0.34, metallic=0.5)
            self.weights(blob("Gafas · bisagra", temple[1], (0.007, 0.008, 0.006), hinge,
                              collection, segments=10, rings=6), bone="cabeza")
        bridge = [Vector((0.018 * t, ey - 0.004, ez + 0.010 + 0.006 * (1 - t * t)))
                  for t in (-1.0, -0.5, 0, 0.5, 1.0)]
        self.weights(trim_path("Gafas · puente", bridge, 0.0048, frame, collection), bone="cabeza")

    def neck_loop(self, height, ease, count=64):
        rx, ry, y, _ = self.measure["neck"]
        result = []
        for i in range(count):
            a = i * math.tau / count
            radial = Vector((math.cos(a), math.sin(a), 0))
            # Raise the band over the nape, keeping it below the ears on both sides.
            z = height + 0.068 * max(0, radial.y) ** 2
            center = Vector((0, y, z))
            hit = self.measure["surface"].ray_cast(center + radial * 0.29, -radial, 0.29)[0]
            radius = (hit - center).dot(radial) if hit is not None else 0.10
            limit = math.hypot(rx * radial.x, ry * radial.y)
            radius = max(limit * 0.57, min(radius, limit * 1.31))
            result.append(center + radial * (radius + ease))
        return result

    def make_collar(self, collection, design):
        trim = "Cuero cereza" if design == "tag" else "Cuero azul"
        color = (0.24, 0.036, 0.035) if design == "tag" else (0.035, 0.13, 0.28)
        strap = rubber(f"Collar · {trim}", color)
        metal, _ = surface("Collar · latón", (0.59, 0.33, 0.071), 0.37, metallic=0.54)
        pearl, shader = surface("Collar · nácar", (0.78, 0.65, 0.52), 0.25)
        shader.inputs["Coat Weight"].default_value = 0.48
        positions = self.neck_loop(0.669, 0.020, count=28 if design == "pearls" else 64)
        if design == "pearls":
            self.weights(trim_ring("Collar · cordón de perlas", positions, 0.0027, metal, collection), bone="cuello")
            for center in positions:
                self.weights(blob("Collar · perla", center, (0.012, 0.012, 0.012), pearl,
                                  collection, segments=12, rings=7), bone="cuello")
            return
        rings = [[point + Vector((0, 0, offset)) for point in positions] for offset in (-0.011, 0.011)]
        self.weights(loft("Collar · correa", rings, strap, collection), bone="cuello")
        for ring in rings:
            self.weights(trim_ring("Collar · vivo de cuero", ring, 0.0035, strap, collection), bone="cuello")
        front = positions[48]
        buckle = self.weights(blob("Collar · hebilla", front + Vector((0, -0.004, 0)),
                                   (0.017, 0.006, 0.012), metal, collection), bone="cuello")
        buckle["underNeckwear"] = True
        drop = Vector((front.x, front.y - 0.014, front.z - 0.025))
        hanger = self.weights(trim_ring("Collar · argolla",
                                        elliptical_ring(drop + Vector((0, 0, 0.009)), 0.008, 0.012,
                                                        points=18), 0.0025, metal, collection), bone="cuello")
        hanger["underNeckwear"] = True
        if design == "bell":
            charm = blob("Collar · cascabel", drop + Vector((0, -0.004, -0.012)),
                         (0.014, 0.013, 0.014), metal, collection, segments=20, rings=10)
            sound_hole, _ = surface("Collar · ranura del cascabel", (0.061, 0.025, 0.009), 0.45)
            slit = trim_path("Collar · ranura", [drop + Vector((x, -0.015, -0.015))
                                                for x in (-0.010, 0, 0.010)],
                             0.002, sound_hole, collection)
            self.weights(slit, bone="cuello")["underNeckwear"] = True
        else:
            shape = []
            for i in range(32):
                a = i * math.tau / 32
                shape.append(Vector((drop.x + 0.014 * math.sin(a)**3, drop.y,
                                     drop.z - 0.012 + 0.0008 * (13 * math.cos(a) - 5 * math.cos(2*a)
                                                                - 2 * math.cos(3*a) - math.cos(4*a)))))
            charm = loft("Collar · chapa de corazón",
                         [[p + Vector((0, y, 0)) for p in shape] for y in (-0.003, 0.003)],
                         metal, collection, caps=True)
        self.weights(charm, bone="cuello")["underNeckwear"] = True

    def make_bowtie(self, collection):
        silk = textile("Pajarita · sarga de seda azul", (0.032, 0.058, 0.19), "weave", coated=True)
        piped = textile("Pajarita · ribete azul noche", (0.016, 0.023, 0.08), "weave")
        ring = self.neck_loop(0.652, 0.034)
        self.weights(loft("Pajarita · cinta", [[p + Vector((0, 0, h)) for p in ring]
                                              for h in (-0.009, 0.009)], piped, collection), bone="cuello")
        center = ring[48] + Vector((0, -0.029, -0.014))
        for side in (-1, 1):
            grid = []
            for i in range(11):
                t = i / 10
                width = 0.009 + 0.024 * t ** 0.75
                grid.append([center + Vector((side * 0.072 * t,
                                              -0.013 * math.sin(math.pi * t) + 0.009 * u * u,
                                              width * u + 0.005 * t))
                             for u in (-1, -0.65, -0.33, 0, 0.33, 0.65, 1)])
            self.weights(patch("Pajarita · ala de seda", grid, silk, collection), bone="cuello")
            self.weights(trim_path("Pajarita · orillo", grid[-1], 0.0029, piped,
                                   collection), bone="cuello")
        self.weights(blob("Pajarita · nudo", center + Vector((0, -0.010, 0)),
                          (0.017, 0.013, 0.018), silk, collection, segments=18, rings=10), bone="cuello")

    def make_scarf(self, collection):
        wool = textile("Bufanda · punto verde menta", (0.15, 0.37, 0.25), "knit")
        cream = textile("Bufanda · bandas de lana cruda", (0.62, 0.52, 0.34), "knit")
        paths = [self.neck_loop(0.635 + offset, ease)
                 for offset, ease in ((-0.028, 0.035), (-0.015, 0.045), (0, 0.048),
                                      (0.016, 0.041), (0.028, 0.035))]
        wrap = loft("Bufanda · vuelta trenzada", paths, wool, collection)
        wrap.data.materials.append(cream)
        for face in wrap.data.polygons:
            face.material_index = int(face.index // len(paths[0]) == 2)
        self.weights(wrap, bone="cuello")
        center = paths[2][45] + Vector((0, -0.017, -0.008))
        self.weights(blob("Bufanda · nudo envolvente", center, (0.040, 0.027, 0.036), wool,
                          collection, segments=24, rings=13), bone="cuello")
        for side in (-1, 1):
            grid = []
            for i in range(20):
                t = i / 19
                length = 0.133 if side == -1 else 0.182
                grid.append([center + Vector((side * 0.032 * t + u * (0.025 + 0.006*t),
                                              -0.014 - 0.013*math.sin(math.pi*t) + 0.013*u*u,
                                              -length*t + 0.006 * u * t))
                             for u in (-1, -0.67, -0.33, 0, 0.33, 0.67, 1)])
            end = patch("Bufanda · frente de caída", grid, wool, collection)
            end.data.materials.append(cream)
            for face in end.data.polygons:
                face.material_index = int((face.index // 6) in (11, 12, 13, 14, 15))
            # The ribbon has plain UVs so the stitch rows follow the weave.
            uv = end.data.uv_layers.new(name="Patrón")
            for loop in end.data.loops:
                row, col = divmod(loop.vertex_index, 7)
                uv.uv[loop.index].vector = (col / 6, row / 19)
            self.weights(end, bone="cuello")
            for p in grid[-1]:
                self.weights(trim_path("Bufanda · frente de fleco", [p, p + Vector((0.002, -0.003, -0.021)),
                                                                     p + Vector((0.004, -0.001, -0.031))],
                                       0.0026, wool, collection), bone="cuello")

    def make_shoes(self, collection, *, knit):
        if knit:
            top = textile("Patucos · lana rosa", (0.62, 0.26, 0.31), "knit")
            piping = textile("Patucos · canalé", (0.45, 0.13, 0.19), "knit")
            sole = rubber("Patucos · suela flexible", (0.31, 0.12, 0.12))
        else:
            top = textile("Zapatillas · lona marfil", (0.73, 0.64, 0.51), "weave")
            piping = rubber("Zapatillas · cuero burdeos", (0.32, 0.034, 0.045))
            sole = rubber("Zapatillas · suela de goma", (0.67, 0.55, 0.41))
            laces = textile("Zapatillas · cordón crudo", (0.65, 0.55, 0.42), "weave")
        for leg in self.legs:
            levels = (0.006, 0.027, 0.052, 0.083, 0.117, 0.139) if knit else (0.005, 0.026, 0.048, 0.072, 0.095, 0.114)
            rings = []
            for i, z in enumerate(levels):
                left, right, back, front = self.measure["boot_bounds"](leg, z)
                along = 0.008 if knit else 0.015
                width = max(0.059, (right-left)*0.57 + 0.010)
                depth = max(0.074, (back-front)*0.58 + 0.009)
                if i < 4:
                    depth += along * (1 - i / 5)
                rings.append(elliptical_ring(((left+right)/2, (back+front)/2 - along*(1-i/5), z),
                                             width, depth, "Z", points=40))
            pieces = [
                loft(f"Calzado · suela · {leg.key}", rings[:2], sole, collection, caps=True),
                loft(f"Calzado · pala · {leg.key}", rings[1:], top, collection),
                trim_ring(f"Calzado · vira · {leg.key}", rings[1], 0.0045, piping, collection),
                trim_ring(f"Calzado · cuello · {leg.key}", rings[-1], 0.0060, piping, collection),
            ]
            if not knit:
                for row in range(2, 5):
                    ring = rings[row]
                    path = [ring[i] + Vector((0, -0.003, 0.007 * (1 - abs(i - 30) / 5)))
                            for i in range(26, 35)]
                    pieces.append(trim_path(f"Zapatilla · cordón · {leg.key}", path, 0.0035, laces, collection))
                for row in (1, 2):
                    pieces.append(trim_path(f"Zapatilla · puntera · {leg.key}", rings[row][24:37], 0.008,
                                            piping, collection))
            for obj in pieces:
                bind(obj, self.rig, lambda p: leg_weights(leg, p.z))


def puppy_hair(dog):
    key = dog.shape_key_add(name="Corte cachorro")
    for v in key.data:
        p = v.co
        ears = smoothstep(0.082, 0.183, abs(p.x)) * smoothstep(0.64, 0.75, p.z)
        ears *= 1 - smoothstep(0.83, 0.92, p.z)
        ears *= 1 - smoothstep(-0.27, -0.15, p.y)
        p.x *= 1 - 0.105 * ears
        p.z += 0.027 * ears
        p.z -= 0.025 * smoothstep(0.87, 0.99, p.z)
