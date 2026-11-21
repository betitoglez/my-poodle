import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'pet_sprites.dart';
import '../../domain/haircuts.dart';

/// Silueta moderna 2D: deforma la textura de pelo compartida, conservando
/// facciones, color y transparencia. No genera imágenes durante la partida.
/// La cresta, el lomo, las botas y la pluma coinciden con las zonas del visor 3D.
class ModernHairMesh {
  final _meshes = <String, Vertices>{};
  static final _identity = Float64List.fromList([
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
  ]);

  void paint(
    Canvas canvas,
    Image image,
    Rect destination,
    SpritePose pose,
    String poseName,
    Paint fur, {
    bool standardTail = false,
    Set<HairZone> zones = const {
      HairZone.head,
      HairZone.legs,
      HairZone.back,
      HairZone.tail,
    },
  }) {
    final key =
        '${image.width}/${image.height}/$destination/$poseName/$standardTail/${zones.map((z) => z.name).join(',')}';
    final mesh = _meshes.putIfAbsent(
      key,
      () => _build(image, destination, pose, poseName, zones, standardTail),
    );
    final shader = ImageShader(
      image,
      TileMode.clamp,
      TileMode.clamp,
      _identity,
    );
    canvas.drawVertices(
      mesh,
      BlendMode.srcOver,
      Paint()
        ..filterQuality = fur.filterQuality
        ..colorFilter = fur.colorFilter
        ..shader = shader,
    );
    shader.dispose();
  }

  static Rect tailBounds(Rect destination, SpritePose pose, String poseName) {
    if (const {'front', 'eat', 'sleep'}.contains(poseName)) return Rect.zero;
    final crown = pose.landmarks['headTop'] ?? const Offset(0, -.94);
    final center = poseName == 'back'
        ? Offset(destination.center.dx, -.55)
        : Offset(crown.dx - destination.width * .67, crown.dy + .20);
    return Rect.fromCenter(center: center, width: .28, height: .32);
  }

  static Rect headBounds(Rect destination, SpritePose pose, String poseName) {
    final crown = pose.landmarks['headTop'] ?? const Offset(0, -.94);
    final bottom = poseName == 'back'
        ? -.64
        : pose.landmarks['neck']?.dy ?? -.54;
    return Rect.fromLTRB(
      crown.dx - .30,
      destination.top - .16,
      crown.dx + .32,
      bottom,
    );
  }

  Vertices _build(
    Image image,
    Rect destination,
    SpritePose pose,
    String poseName,
    Set<HairZone> zones,
    bool standardTail,
  ) {
    const columns = 32, rows = 64;
    final points = <Offset>[], texture = <Offset>[], indices = <int>[];
    final crown = pose.landmarks['headTop'] ?? const Offset(0, -.94);
    double bell(double value, double center, double radius) =>
        math.exp(-math.pow((value - center) / radius, 2));
    final tail = tailBounds(destination, pose, poseName);
    for (var row = 0; row <= rows; row++) {
      for (var column = 0; column <= columns; column++) {
        final u = column / columns, v = row / rows;
        final x = destination.left + u * destination.width;
        final y = destination.top + v * destination.height;
        // Narrow lifted crest with a gentle falloff towards the face.
        final crest = zones.contains(HairZone.head)
            ? bell(x, crown.dx, .105) * bell(y, crown.dy, .12)
            : 0.0;
        final boots = zones.contains(HairZone.legs)
            ? bell(y, -.115, .075)
            : 0.0;
        final spine = !zones.contains(HairZone.back)
            ? 0.0
            : bell(x, destination.center.dx, destination.width * .24) *
                  bell(y, poseName == 'side' ? -.61 : -.405, .075);
        final plume = !zones.contains(HairZone.tail) || tail.isEmpty
            ? 0.0
            : bell(x, tail.center.dx, .11) * bell(y, tail.center.dy, .12);
        final legCenter = x < destination.center.dx
            ? destination.center.dx - .11
            : destination.center.dx + .11;
        final dx =
            (x - legCenter).clamp(-.055, .055) * .32 * boots +
            (x - tail.center.dx) * .6 * plume;
        final dy =
            -.13 * crest -
            .065 * spine +
            ((y - tail.center.dy) * .5 - .025) * plume;
        var point = Offset(x + dx, y + dy);
        if (standardTail && !tail.isEmpty && tail.contains(Offset(x, y))) {
          final isBack = poseName == 'back';
          final root = tail.center + Offset(isBack ? 0 : .05, .13);
          final axis = isBack ? const Offset(0, -1) : const Offset(-.28, -.96);
          final normal = Offset(-axis.dy, axis.dx);
          final relative = Offset(x, y) - root;
          final along = (relative.dx * axis.dx + relative.dy * axis.dy).clamp(
            0.0,
            .245,
          );
          final across = relative.dx * normal.dx + relative.dy * normal.dy;
          final target = root + axis * along + normal * (across * .16);
          final blend = ((tail.center.dy + .15 - y) / .07).clamp(0.0, 1.0);
          point += (target - Offset(x, y)) * blend;
        }
        points.add(point);
        texture.add(Offset(u * image.width, v * image.height));
        if (row < rows && column < columns) {
          final a = row * (columns + 1) + column, b = a + columns + 1;
          indices.addAll([a, b, a + 1, a + 1, b, b + 1]);
        }
      }
    }
    return Vertices(
      VertexMode.triangles,
      points,
      textureCoordinates: texture,
      indices: indices,
    );
  }
}
