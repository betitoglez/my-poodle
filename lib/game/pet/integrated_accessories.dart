import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/services.dart';

import '../../domain/appearance.dart';
import 'appearance_catalog.dart';
import 'pet_sprites.dart';

class _Cloth {
  _Cloth(this.image, this.source);
  final Image image;
  final Rect source;
  late final ImageShader shader = ImageShader(
    image,
    TileMode.clamp,
    TileMode.clamp,
    Float64List.fromList([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]),
  );
}

/// Piloto acotado: prendas ilustradas completas, sin píxeles del perro.
/// La malla sigue torso y mangas; sombras y pelaje se componen por separado.
class IntegratedAccessories {
  static const assetDirectory = 'assets/images/materials/';
  static bool sweater(Appearance ids) =>
      ids.outfit.startsWith('outfit.sweater_');
  static bool beanie(Appearance ids) => ids.head == 'head.beanie';
  static bool bandana(Appearance ids) => ids.neck == 'neck.coral';
  static bool supportsPose(String pose) =>
      const {'front', 'side', 'run_a', 'run_b', 'jump'}.contains(pose);

  final Map<String, _Cloth> _images = {};
  final Map<String, Future<void>> _loading = {};
  final Map<String, Vertices> _mesh = {};

  Set<String> _required(Appearance ids) => {
    if (sweater(ids)) ...['sweater-front', 'sweater-side'],
    if (beanie(ids)) ...['beanie-front', 'beanie-side'],
    if (bandana(ids)) ...['bandana-front', 'bandana-side'],
  };
  bool readyFor(Appearance ids) => _required(ids).every(_images.containsKey);
  Future<void> warm(Appearance ids) => Future.wait(_required(ids).map(_load));

  Future<void> _load(String name) {
    if (_images.containsKey(name)) return Future.value();
    return _loading[name] ??= () async {
      try {
        final bytes = await rootBundle.load('$assetDirectory$name-v1.png');
        // Se limita la memoria decodificada, compartida entre poses y colores.
        final codec = await instantiateImageCodec(
          bytes.buffer.asUint8List(),
          targetWidth: 512,
        );
        final image = (await codec.getNextFrame()).image;
        codec.dispose();
        final rgba = await image.toByteData(
          format: ImageByteFormat.rawStraightRgba,
        );
        var left = image.width, top = image.height, right = 0, bottom = 0;
        final data = rgba!.buffer.asUint8List();
        for (var y = 0; y < image.height; y++) {
          for (var x = 0; x < image.width; x++) {
            if (data[(y * image.width + x) * 4 + 3] <= 24) continue;
            left = math.min(left, x);
            top = math.min(top, y);
            right = math.max(right, x + 1);
            bottom = math.max(bottom, y + 1);
          }
        }
        if (right <= left || bottom <= top) {
          throw StateError('Prenda vacía: $name');
        }
        _images[name] = _Cloth(
          image,
          Rect.fromLTRB(
            left.toDouble(),
            top.toDouble(),
            right.toDouble(),
            bottom.toDouble(),
          ),
        );
      } finally {
        _loading.remove(name);
      }
    }();
  }

  // Las máscaras y el tejido se deforman con la misma función. Así el hueco
  // del puño conserva su posición al cambiar de fotograma.
  Offset _placed(Rect dst, String pose, double u, double v) {
    final p = Offset(dst.left + u * dst.width, dst.top + v * dst.height);
    final (cuff, angle) = switch (pose) {
      'side' => (const Offset(0.222, -0.185), -0.10),
      'run_a' => (const Offset(0.285, -0.152), -0.76),
      'run_b' => (const Offset(0.221, -0.203), -0.55),
      'jump' => (const Offset(0.285, -0.256), -0.77),
      _ => (null, 0.0),
    };
    if (cuff == null) return p;

    // Centro del puño en el PNG de perfil y dirección de la pata en el sprite.
    final center = Offset(
      dst.left + dst.width * 0.583,
      dst.top + dst.height * 0.973,
    );
    final d = p - center;
    final cs = math.cos(angle), sn = math.sin(angle);
    final target = cuff + Offset(d.dx * cs - d.dy * sn, d.dx * sn + d.dy * cs);
    final x = (1 - ((u - 0.583).abs() - 0.15) / 0.19).clamp(0.0, 1.0);
    final y = ((v - 0.5) / 0.43).clamp(0.0, 1.0);
    final weight = x * y * y * (3 - 2 * y);
    return Offset.lerp(p, target, weight)!;
  }

  void _draw(
    Canvas c,
    String name,
    Rect dst, {
    String deformation = '',
    ColorFilter? colorFilter,
  }) {
    final cloth = _images[name];
    if (cloth == null) return;
    final key =
        '$name/${dst.left}/${dst.top}/${dst.right}/${dst.bottom}/$deformation';
    final mesh = _mesh.putIfAbsent(key, () {
      const n = 10;
      final positions = <Offset>[], uv = <Offset>[];
      final triangles = <int>[];
      for (var row = 0; row <= n; row++) {
        final v = row / n;
        for (var col = 0; col <= n; col++) {
          final u = col / n;
          positions.add(_placed(dst, deformation, u, v));
          uv.add(
            Offset(
              cloth.source.left + u * cloth.source.width,
              cloth.source.top + v * cloth.source.height,
            ),
          );
          if (col < n && row < n) {
            final p = row * (n + 1) + col;
            triangles.addAll([
              p,
              p + 1,
              p + n + 1,
              p + 1,
              p + n + 2,
              p + n + 1,
            ]);
          }
        }
      }
      return Vertices(
        VertexMode.triangles,
        positions,
        textureCoordinates: uv,
        indices: triangles,
      );
    });
    c.drawVertices(
      mesh,
      BlendMode.modulate,
      Paint()
        ..shader = cloth.shader
        ..filterQuality = FilterQuality.medium
        ..colorFilter = colorFilter,
    );
  }

  void _base(Canvas c, SpriteLayer base, Rect dst, Paint paint) =>
      c.drawImageRect(
        base.image,
        Rect.fromLTWH(
          0,
          0,
          base.image.width.toDouble(),
          base.image.height.toDouble(),
        ),
        dst,
        paint,
      );

  void _shadow(
    Canvas c,
    String name,
    Rect clothRect,
    String deformation,
    SpriteLayer pet,
    Rect petRect,
  ) {
    final bounds = petRect.inflate(0.04);
    c.saveLayer(bounds, Paint());
    c.saveLayer(
      bounds,
      Paint()..imageFilter = ImageFilter.blur(sigmaX: 0.006, sigmaY: 0.008),
    );
    c.save();
    c.translate(0.004, 0.010);
    _draw(
      c,
      name,
      clothRect,
      deformation: deformation,
      colorFilter: const ColorFilter.mode(Color(0x88432F2A), BlendMode.srcIn),
    );
    c.restore();
    c.restore();
    // El accesorio proyecta sombra sobre la mascota, sin manchar el fondo.
    c.saveLayer(bounds, Paint()..blendMode = BlendMode.dstIn);
    _base(c, pet, petRect, Paint());
    c.restore();
    c.restore();
  }

  void _fur(Canvas c, Path path, SpriteLayer base, Rect dst, Paint coatPaint) {
    c.save();
    c.clipPath(path);
    _base(c, base, dst, coatPaint);
    c.restore();
  }

  Path _ear(String pose, Offset head) {
    final offset = switch (pose) {
      'run_a' => const Offset(-0.11, 0.11),
      'run_b' => const Offset(-0.12, 0.145),
      'jump' => const Offset(-0.13, 0.17),
      _ => const Offset(-0.095, 0.24),
    };
    final flying = pose == 'run_a' || pose == 'run_b' || pose == 'jump';
    return Path()..addOval(
      Rect.fromCenter(
        center: head + offset,
        width: flying ? 0.22 : 0.18,
        height: flying ? 0.14 : 0.21,
      ),
    );
  }

  void paintSweater(
    Canvas c,
    AppearanceCatalog catalog,
    Appearance ids,
    String pose,
    Map<String, Offset> lm,
    SpriteLayer base,
    Rect petRect,
    Paint coatPaint,
  ) {
    if (!sweater(ids) || !supportsPose(pose) || !readyFor(ids)) return;
    final front = pose == 'front' || pose == 'back';
    final name = front ? 'sweater-front' : 'sweater-side';
    final neck = lm['neck'] ?? const Offset(0, -0.55);
    final center = lm['headTop']!.dx;
    final rect = front
        ? Rect.fromLTRB(center - 0.205, -0.645, center + 0.205, -0.205)
        : switch (pose) {
            'run_a' => const Rect.fromLTRB(-0.355, -0.515, 0.305, -0.115),
            'run_b' => const Rect.fromLTRB(-0.335, -0.615, 0.31, -0.15),
            'jump' => const Rect.fromLTRB(-0.355, -0.64, 0.31, -0.205),
            _ => Rect.fromLTRB(
              neck.dx - 0.48,
              neck.dy - 0.14,
              neck.dx + 0.085,
              neck.dy + 0.37,
            ),
          };
    final filter = ids.outfit == 'outfit.sweater_blue'
        ? ColorFilter.matrix(PetSprites.hueMatrix(220))
        : ids.outfit == 'outfit.sweater_mustard'
        ? ColorFilter.matrix(PetSprites.hueMatrix(42, light: 1.1))
        : null;
    _shadow(c, name, rect, pose, base, petRect);
    _draw(c, name, rect, deformation: pose, colorFilter: filter);
    _openSweater(c, rect, pose, base, petRect, coatPaint);
    if (!front) {
      _fur(c, _ear(pose, lm['headTop']!), base, petRect, coatPaint);
    }
  }

  final Map<(Rect, String), Path> _openingCache = {};

  void _openSweater(
    Canvas c,
    Rect rect,
    String pose,
    SpriteLayer base,
    Rect petRect,
    Paint coatPaint,
  ) {
    final openings = _openingCache.putIfAbsent((rect, pose), () {
      final uv = Path();
      if (pose == 'front') {
        // La nuca oculta la pared trasera. Queda la curva de punto delantera.
        uv.moveTo(0.217, -0.04);
        uv.cubicTo(0.195, 0.052, 0.264, 0.105, 0.370, 0.118);
        uv.cubicTo(0.505, 0.145, 0.695, 0.124, 0.77, 0.072);
        uv.quadraticBezierTo(0.805, 0.035, 0.796, -0.04);
        uv.close();
        // El pelo entra en ambos puños hasta el borde enrollado.
        for (final (left, right) in [(0.080, 0.441), (0.589, 0.960)]) {
          final w = right - left;
          uv.moveTo(left, 1.04);
          uv.cubicTo(
            left - 0.012,
            0.970,
            left + w * 0.12,
            0.945,
            left + w * 0.45,
            0.940,
          );
          uv.cubicTo(
            right - w * 0.12,
            0.930,
            right + 0.014,
            0.961,
            right,
            1.04,
          );
          uv.close();
        }
      } else {
        // Cuello, boca de la manga y bajo. La tela exterior sigue visible
        // alrededor de cada unión en vez de cubrir la pata completa.
        uv.moveTo(0.557, -0.04);
        uv.cubicTo(0.526, 0.061, 0.60, 0.117, 0.717, 0.169);
        uv.cubicTo(0.810, 0.215, 0.919, 0.229, 0.966, 0.146);
        uv.lineTo(1.03, -0.04);
        uv.close();
        uv.moveTo(0.458, 1.04);
        uv.cubicTo(0.438, 0.985, 0.481, 0.943, 0.552, 0.938);
        uv.cubicTo(0.671, 0.925, 0.732, 0.946, 0.731, 1.04);
        uv.close();
        uv.moveTo(-0.04, 0.066);
        uv.cubicTo(0.071, 0.104, 0.082, 0.256, 0.061, 0.37);
        uv.quadraticBezierTo(0.028, 0.57, -0.03, 0.65);
        uv.close();
      }
      return _mapPath(uv, rect, pose);
    });
    _fur(c, openings, base, petRect, coatPaint);
  }

  Path _mapPath(Path uv, Rect rect, String pose) {
    final mapped = Path();
    for (final contour in uv.computeMetrics(forceClosed: true)) {
      // Muescas muy pequeñas rompen el borde de corte del pelaje. La malla
      // comparte la transformación en cada muestra de este contorno.
      for (var i = 0; i < 80; i++) {
        final tangent = contour.getTangentForOffset(contour.length * i / 80)!;
        final p =
            tangent.position +
            Offset(-tangent.vector.dy, tangent.vector.dx) *
                (0.003 + math.sin(i * 2.6) * 0.006);
        final pos = _placed(rect, pose, p.dx, p.dy);
        if (i == 0) {
          mapped.moveTo(pos.dx, pos.dy);
        } else {
          mapped.lineTo(pos.dx, pos.dy);
        }
      }
      mapped.close();
    }
    return mapped;
  }

  void paintBandana(
    Canvas c,
    Appearance ids,
    String pose,
    Map<String, Offset> lm,
    SpriteLayer base,
    Rect petRect,
    Paint coatPaint,
  ) {
    if (!bandana(ids) || !supportsPose(pose) || !readyFor(ids)) return;
    final front = pose == 'front' || pose == 'back';
    final center = lm['headTop']!.dx;
    final neck = front ? Offset(center, -0.558) : lm['neck']!;
    final name = front ? 'bandana-front' : 'bandana-side';
    final rect = front
        ? Rect.fromLTRB(center - 0.17, -0.605, center + 0.23, -0.337)
        : Rect.fromLTRB(
            neck.dx - 0.145,
            neck.dy - 0.12,
            neck.dx + 0.10,
            neck.dy + 0.17,
          );
    if (pose == 'back') return; // El triángulo queda al otro lado del cuello.
    _shadow(c, name, rect, '', base, petRect);
    _draw(c, name, rect);
    if (!front) {
      _fur(c, _ear(pose, lm['headTop']!), base, petRect, coatPaint);
    }
  }

  void paintBeanie(
    Canvas c,
    Appearance ids,
    String pose,
    Map<String, Offset> lm,
    SpriteLayer base,
    Rect petRect,
    Paint coatPaint,
  ) {
    if (!beanie(ids) || !supportsPose(pose) || !readyFor(ids)) return;
    final front = pose == 'front' || pose == 'back';
    final head = lm['headTop']!;
    final name = front ? 'beanie-front' : 'beanie-side';
    final rect = Rect.fromLTRB(
      head.dx - (front ? 0.19 : 0.18),
      head.dy - 0.17,
      head.dx + (front ? 0.19 : 0.14),
      head.dy + 0.145,
    );
    _shadow(c, name, rect, '', base, petRect);
    _draw(c, name, rect);
    if (pose == 'front') {
      final fringe = Path()
        ..moveTo(head.dx - 0.17, head.dy + 0.16)
        ..quadraticBezierTo(
          head.dx,
          head.dy - 0.01,
          head.dx + 0.17,
          head.dy + 0.16,
        )
        ..lineTo(head.dx + 0.17, head.dy + 0.27)
        ..lineTo(head.dx - 0.17, head.dy + 0.27)
        ..close();
      _fur(c, fringe, base, petRect, coatPaint);
    } else if (!front) {
      _fur(c, _ear(pose, head), base, petRect, coatPaint);
    }
  }
}
