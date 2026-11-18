import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/services.dart';

import '../../domain/appearance.dart';
import 'appearance_catalog.dart';
import 'pet_sprites.dart';
import 'pet_neck.dart';

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
      const {'front', 'side', 'back', 'run_a', 'run_b', 'jump'}.contains(pose);

  final Map<String, _Cloth> _images = {};
  final Map<String, Future<void>> _loading = {};
  final Map<String, Vertices> _mesh = {};

  Set<String> _required(Appearance ids) => {
    if (sweater(ids)) ...['sweater-front', 'sweater-side', 'sweater-back'],
    if (beanie(ids)) ...['beanie-front', 'beanie-side', 'beanie-back'],
    if (bandana(ids)) ...['bandana-front', 'bandana-side', 'bandana-back'],
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
    if (pose == 'back') {
      // Ensancha los dos puños inferiores hacia sus patas correspondientes.
      final lower = _ease((v - 0.54) / 0.37);
      return p + Offset(((u - 0.5) * 0.053 + 0.010) * lower, 0);
    }
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
    final sleeve = Offset.lerp(p, target, weight)!;
    // Extiende el peto hasta el contorno del pecho y abraza la cadera. La
    // deformación no arrastra el puño, que sigue el eje de su pata.
    final (chest, hip, hemDrop) = switch (pose) {
      'side' => (0.110, 0.143, 0.086),
      'run_a' => (0.065, 0.038, 0.045),
      'run_b' => (0.080, 0.063, 0.055),
      _ => (0.084, 0.054, 0.058),
    };
    final chestWeight =
        _ease((u - 0.57) / 0.32) *
        (0.55 + _ease((v - 0.11) / 0.30) * 0.45) *
        (1 - _ease((v - 0.58) / 0.25));
    final hindQuarter = 1 - _ease((u - 0.12) / 0.33);
    final hipWeight = hindQuarter * _ease((v - 0.06) / 0.34);
    final hemWeight = hindQuarter * _ease((v - 0.26) / 0.36);
    return sleeve +
        Offset(chest * chestWeight - hip * hipWeight, hemDrop * hemWeight);
  }

  double _ease(double value) {
    final t = value.clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  void _draw(
    Canvas c,
    String name,
    Rect dst, {
    String deformation = '',
    double shear = 0,
    ColorFilter? colorFilter,
  }) {
    final cloth = _images[name];
    if (cloth == null) return;
    final key =
        '$name/${dst.left}/${dst.top}/${dst.right}/${dst.bottom}/$deformation/$shear';
    final mesh = _mesh.putIfAbsent(key, () {
      const n = 10;
      final positions = <Offset>[], uv = <Offset>[];
      final triangles = <int>[];
      for (var row = 0; row <= n; row++) {
        final v = row / n;
        for (var col = 0; col <= n; col++) {
          final u = col / n;
          positions.add(
            _placed(dst, deformation, u, v) + Offset(0, u * dst.width * shear),
          );
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
    Rect petRect, {
    double shear = 0,
  }) {
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
      shear: shear,
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
    final neck = PetNeck.forPose(pose, ids.hair);
    final center = neck.at(0.5, drape: 0).dx;
    final name = switch (pose) {
      'front' => 'sweater-front',
      'back' => 'sweater-back',
      _ => 'sweater-side',
    };
    final rect = switch (pose) {
      'front' => Rect.fromLTRB(
        center - 0.198,
        neck.left.dy - 0.023,
        center + 0.212,
        -0.205,
      ),
      'back' => Rect.fromLTRB(
        center - 0.206,
        neck.left.dy - 0.030,
        center + 0.213,
        -0.197,
      ),
      'run_a' => const Rect.fromLTRB(-0.355, -0.515, 0.305, -0.115),
      'run_b' => const Rect.fromLTRB(-0.335, -0.615, 0.31, -0.15),
      'jump' => const Rect.fromLTRB(-0.355, -0.64, 0.31, -0.205),
      _ => Rect.fromLTRB(
        neck.left.dx - 0.335,
        neck.left.dy - 0.039,
        neck.right.dx - 0.052,
        -0.181,
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
    if (pose == 'back') {
      final outline = _tailOutline(ids, petRect);
      c.drawPath(
        outline.shift(const Offset(0.003, 0.007)),
        Paint()
          ..color = const Color(0x60432F2A)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.005),
      );
      _fur(c, outline, base, petRect, coatPaint);
    } else if (pose != 'front') {
      _fur(c, PetNeck.earMask(pose, lm['headTop']!), base, petRect, coatPaint);
    }
  }

  Path _tailOutline(Appearance ids, Rect petRect) {
    final halfWidth = ids.hair == 'hair.teddy' ? 0.078 : 0.097;
    final tail = Offset(petRect.center.dx - 0.014, -0.555);
    return Path()
      ..moveTo(tail.dx - halfWidth, tail.dy)
      ..cubicTo(
        tail.dx - halfWidth,
        tail.dy - 0.063,
        tail.dx - 0.047,
        tail.dy - 0.096,
        tail.dx,
        tail.dy - 0.096,
      )
      ..cubicTo(
        tail.dx + 0.059,
        tail.dy - 0.106,
        tail.dx + halfWidth,
        tail.dy - 0.056,
        tail.dx + halfWidth,
        tail.dy + 0.007,
      )
      ..cubicTo(
        tail.dx + halfWidth,
        tail.dy + 0.058,
        tail.dx + 0.057,
        tail.dy + 0.092,
        tail.dx + 0.005,
        tail.dy + 0.093,
      )
      ..cubicTo(
        tail.dx - 0.068,
        tail.dy + 0.099,
        tail.dx - halfWidth,
        tail.dy + 0.05,
        tail.dx - halfWidth,
        tail.dy,
      )
      ..close();
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
      if (pose == 'back') {
        uv.moveTo(0.26, -0.06);
        uv.quadraticBezierTo(0.50, 0.10, 0.74, -0.06);
        uv.close();
      } else if (pose == 'front') {
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
        // Solo se descubre la garganta por encima del cuello, y la pata
        // al salir de su puño. La cadera y el pecho quedan vestidos.
        uv.moveTo(0.557, -0.04);
        uv.cubicTo(0.526, 0.061, 0.60, 0.117, 0.717, 0.169);
        uv.cubicTo(0.810, 0.215, 0.919, 0.229, 0.966, 0.146);
        uv.lineTo(1.03, -0.04);
        uv.close();
        uv.moveTo(0.458, 1.04);
        uv.cubicTo(0.438, 0.985, 0.481, 0.943, 0.552, 0.938);
        uv.cubicTo(0.671, 0.925, 0.732, 0.946, 0.731, 1.04);
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
    final neck = PetNeck.forPose(pose, ids.hair);
    if (pose == 'back') {
      _paintNapeBand(c, neck, base, petRect, coatPaint, ids);
      return;
    }
    final (name, uvLeft, uvRight, height) = switch (pose) {
      'front' => (
        'bandana-front',
        const Offset(0.062, 0.083),
        const Offset(0.675, 0.079),
        0.245,
      ),
      _ => (
        'bandana-side',
        const Offset(0.254, 0.166),
        const Offset(0.974, 0.336),
        0.248,
      ),
    };
    // Dos puntos del borde de la ilustración coinciden con los dos extremos
    // del cuello. El vuelo del nudo se extiende fuera de esos puntos.
    final width = neck.width / (uvRight.dx - uvLeft.dx);
    final shear =
        (neck.right.dy - neck.left.dy - (uvRight.dy - uvLeft.dy) * height) /
        neck.width;
    final rect = Rect.fromLTWH(
      neck.left.dx - uvLeft.dx * width,
      neck.left.dy - uvLeft.dy * height - uvLeft.dx * width * shear,
      width,
      height,
    );
    _shadow(c, name, rect, '', base, petRect, shear: shear);
    _draw(c, name, rect, shear: shear);
    if (pose != 'front') {
      _fur(c, PetNeck.earMask(pose, lm['headTop']!), base, petRect, coatPaint);
    }
  }

  void _paintNapeBand(
    Canvas c,
    PetNeck neck,
    SpriteLayer base,
    Rect petRect,
    Paint coatPaint,
    Appearance ids,
  ) {
    // Desde atrás solo asoma un borde de tela bajo las orejas. Se toma
    // una franja limpia de la misma ilustración, al lado del nudo.
    final cloth = _images['bandana-back']!;
    final src = cloth.source;
    final cotton = Rect.fromLTRB(
      src.left + src.width * 0.51,
      src.top + src.height * 0.43,
      src.left + src.width * 0.82,
      src.top + src.height * 0.59,
    );
    final napeLift = const Offset(0, 0.064);
    final nape = PetNeck(
      neck.at(0.12, drape: 0) - napeLift,
      neck.at(0.88, drape: 0) - napeLift,
    );
    final hem = nape.band(0.018, drape: 0.009);
    c.drawPath(
      hem.shift(const Offset(0, 0.003)),
      Paint()
        ..color = const Color(0x77432F2A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.004),
    );
    c.save();
    c.clipPath(hem);
    c.drawImageRect(
      cloth.image,
      cotton,
      hem.getBounds(),
      Paint()..filterQuality = FilterQuality.medium,
    );
    c.restore();
    _fur(c, _tailOutline(ids, petRect), base, petRect, coatPaint);
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
    final name = switch (pose) {
      'front' => 'beanie-front',
      'back' => 'beanie-back',
      _ => 'beanie-side',
    };
    final rect = Rect.fromLTRB(
      head.dx - (front ? 0.19 : 0.18),
      head.dy - 0.17,
      head.dx + (front ? 0.19 : 0.14),
      head.dy + (pose == 'back' ? 0.142 : 0.145),
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
      _fur(c, PetNeck.earMask(pose, head), base, petRect, coatPaint);
    }
  }
}
