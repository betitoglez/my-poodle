"""Cut a continuous garment from a relaxed copy of the dog's surface."""
from collections import Counter, defaultdict

import bmesh
import bpy


def relaxed_surface(dog):
    # Preserve the original curls on the dog. Cloth borrows its silhouette,
    # shoulders and leg spacing from a smoother version of that same mesh.
    bm = bmesh.new()
    bm.from_mesh(dog.data)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=0.00005)
    bmesh.ops.triangulate(bm, faces=list(bm.faces))
    verts = list(bm.verts)
    for _ in range(42):
        bmesh.ops.smooth_vert(bm, verts=verts, factor=0.5,
                              use_axis_x=True, use_axis_y=True, use_axis_z=True)
    bm.normal_update()
    bm.verts.index_update()
    triangles = [tuple(v.index for v in face.verts) for face in bm.faces]
    points = [(v.co.copy(), v.normal.copy()) for v in verts]
    bm.free()
    return points, triangles


def cut_surface(surface, clearance, limit):
    points, triangles = surface
    vertices, faces, index = [], [], {}
    fit = [(p + normal * clearance(p), limit(p)) for p, normal in points]

    def vertex(key, point):
        if key not in index:
            index[key] = len(vertices)
            vertices.append(point)
        return index[key]

    for triangle in triangles:
        distances = [fit[v][1] for v in triangle]
        if min(distances) > 0:
            continue
        face = []
        for i in range(3):
            a, b = triangle[i - 1], triangle[i]
            p, d = fit[a]
            q, e = fit[b]
            if (d < 0) != (e < 0):
                face.append(vertex(tuple(sorted((a, b))), p.lerp(q, d / (d - e))))
            if e <= 0:
                face.append(vertex(b, q))
        if len(set(face)) >= 3:
            faces.append(tuple(face))
    return vertices, faces


def boundaries(vertices, faces):
    counts = Counter(tuple(sorted((a, b))) for face in faces
                     for a, b in zip(face, (*face[1:], face[0])))
    graph = defaultdict(list)
    for (a, b), n in counts.items():
        if n == 1:
            graph[a].append(b)
            graph[b].append(a)
    unused = set(graph)
    while unused:
        start = unused.pop()
        loop = [vertices[start]]
        point = start
        while neighbors := [n for n in graph[point] if n in unused]:
            point = neighbors[0]
            unused.remove(point)
            loop.append(vertices[point])
        if len(loop) >= 6 and start in graph[point]:
            yield loop


def relax_cloth(obj):
    """Soften offset folds while preserving the outlined openings."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    interior = [vertex for vertex in bm.verts if not vertex.is_boundary]
    for _ in range(9):
        bmesh.ops.smooth_vert(bm, verts=interior, factor=0.47,
                              use_axis_x=True, use_axis_y=True, use_axis_z=True)
    bm.normal_update()
    bm.to_mesh(obj.data)
    bm.free()


def reduce_detail(obj, target):
    obj.data.calc_loop_triangles()
    face_count = len(obj.data.loop_triangles)
    if face_count <= target:
        return
    mod = obj.modifiers.new("Malla de tela optimizada", "DECIMATE")
    mod.ratio = target / face_count
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.select_set(False)
