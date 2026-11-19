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

/// Prendas ilustradas completas con aperturas ajustadas a cada pose.
/// La malla sigue torso y mangas; sombras y pelaje se componen por separado.
class IntegratedAccessories {
  static const assetDirectory = 'assets/images/materials/';
  static bool sweater(Appearance ids) =>
      ids.outfit.startsWith('outfit.sweater_');
  static bool beanie(Appearance ids) => ids.head == 'head.beanie';
  static bool bandana(Appearance ids) => ids.neck == 'neck.coral';
  static String? neckMaterial(String id) => switch (id) {
    'neck.bowtie' => 'bowtie',
    'neck.knit' => 'knit',
    _ => null,
  };
  static String? tailoredFamily(String outfit) => switch (outfit) {
    'outfit.teal' ||
    'outfit.overalls_red' ||
    'outfit.overalls_yellow' => 'overalls',
    'outfit.raincoat_yellow' ||
    'outfit.raincoat_blue' ||
    'outfit.raincoat_pink' => 'raincoat',
    'outfit.dress_pink' ||
    'outfit.dress_lilac' ||
    'outfit.dress_turquoise' => 'dress',
    _ => null,
  };
  static bool supportsPose(String pose) =>
      const {'front', 'side', 'back', 'run_a', 'run_b', 'jump'}.contains(pose);

  final Map<String, _Cloth> _images = {};
  final Map<String, Future<void>> _loading = {};
  final Map<String, Vertices> _mesh = {};

  Set<String> _required(Appearance ids) => {
    if (sweater(ids)) ...['sweater-front', 'sweater-side', 'sweater-back'],
    if (tailoredFamily(ids.outfit) case final family?)
      for (final view in ['front', 'side', 'back']) '$family-$view',
    if (beanie(ids)) ...['beanie-front', 'beanie-side', 'beanie-back'],
    if (bandana(ids)) ...['bandana-front', 'bandana-side', 'bandana-back'],
    if (neckMaterial(ids.neck) case final family?)
      for (final view in ['front', 'side', 'back']) '$family-$view',
  };
  bool readyFor(Appearance ids) => _required(ids).every(_images.containsKey);
  Future<void> warm(Appearance ids) => Future.wait(_required(ids).map(_load));

  Future<void> _load(String name) {
    if (_images.containsKey(name)) return Future.value();
    return _loading[name] ??= () async {
      try {
        final source = name.split('-').first;
        final extension =
            const {
              'overalls',
              'raincoat',
              'dress',
              'knit',
              'bowtie',
            }.contains(source)
            ? 'webp'
            : 'png';
        final bytes = await rootBundle.load(
          '$assetDirectory$name-v1.$extension',
        );
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
    if (pose.startsWith('cloth/')) {
      if (pose.endsWith('/front') || pose.endsWith('/back')) {
        final cuffs = _ease((v - 0.56) / 0.37);
        final shift = pose.startsWith('cloth/dress/') ? 0.0 : 0.028;
        return p + Offset(shift * cuffs * (1 - u), 0);
      }
      final movement = pose.endsWith('/run_a')
          ? Offset(0.040 * u * v, 0.066 * u * (1 - v))
          : pose.endsWith('/run_b') || pose.endsWith('/jump')
          ? Offset(-0.016 * v, 0.024 * u * (1 - v))
          : Offset.zero;
      if (!pose.startsWith('cloth/raincoat/') ||
          pose.endsWith('/front') ||
          pose.endsWith('/back')) {
        return p + movement;
      }
      // La manga cercana gira hacia el eje de la pata bajo el pecho.
      final sleeve =
          _ease((u - 0.38) / 0.15) *
          (1 - _ease((u - 0.61) / 0.35)) *
          _ease((v - 0.40) / 0.47);
      return p + movement + Offset(0.178 * sleeve, 0.022 * sleeve);
    }
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
    final (collarDrop, chestDrop) = switch (pose) {
      'run_a' => (0.087, 0.065),
      'run_b' => (0.068, 0.053),
      _ => (0.0, 0.0),
    };
    final collar = _ease((u - 0.43) / 0.12) * (1 - (v / 0.43).clamp(0.0, 1.0));
    final bib =
        _ease((u - 0.71) / 0.18) *
        _ease((v - 0.30) / 0.25) *
        (1 - _ease((v - 0.70) / 0.24));
    return sleeve +
        Offset(
          chest * chestWeight - hip * hipWeight - collarDrop * 0.20 * collar,
          hemDrop * hemWeight + collarDrop * collar + chestDrop * bib,
        );
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
          // La cara interior del bajo lateral queda doblada bajo la cadera.
          final sampleU = name == 'sweater-side'
              ? u + 0.067 * (1 - _ease(u / 0.27)) * _ease((v - 0.12) / 0.24)
              : u;
          uv.add(
            Offset(
              cloth.source.left + sampleU * cloth.source.width,
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
    if (pose == 'back') {
      _paintBackSeam(c, rect, filter);
    } else if (pose != 'front') {
      _paintHindSleeves(c, pose, filter);
    }
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

  void paintTailoredOutfit(
    Canvas c,
    AppearanceCatalog catalog,
    Appearance ids,
    String pose,
    Map<String, Offset> landmarks,
    SpriteLayer base,
    Rect petRect,
    Paint coatPaint,
  ) {
    final family = tailoredFamily(ids.outfit);
    if (family == null) return;
    final view = pose == 'front' || pose == 'back' ? pose : 'side';
    final neck = PetNeck.forPose(pose, ids.hair);
    final center = neck.at(0.5, drape: 0).dx + 0.006;
    final (width, top, bottom) = switch ((family, view)) {
      ('overalls', 'front') => (0.400, -0.705, -0.213),
      ('overalls', 'back') => (0.425, -0.690, -0.198),
      ('raincoat', 'front') => (0.424, -0.671, -0.229),
      ('raincoat', 'back') => (0.455, -0.676, -0.257),
      ('dress', 'front') => (0.445, -0.652, -0.268),
      _ => (0.502, -0.660, -0.223),
    };
    final rect = view == 'side'
        ? _sideOutfit(family, neck)
        : Rect.fromLTRB(center - width / 2, top, center + width / 2, bottom);
    final name = '$family-$view';
    final deformation = 'cloth/$family/$pose';
    final filter = _tailoredColor(catalog, ids.outfit, family);
    _shadow(c, name, rect, deformation, base, petRect);
    if (family == 'overalls') {
      if (view == 'back') {
        _paintBackSeam(c, rect, filter, family: family);
      } else if (view == 'side') {
        _paintHindSleeves(c, pose, filter, family: family);
      }
    }
    if (family == 'raincoat') {
      _raincoatLining(c, view, pose, neck, filter);
    }
    _draw(c, name, rect, deformation: deformation, colorFilter: filter);
    final openings = _openingCache.putIfAbsent((rect, '$family/$pose'), () {
      final uv = Path();
      if (view == 'front') {
        final (left, right, curve) = switch (family) {
          'overalls' => (0.25, 0.75, 0.25),
          'raincoat' => (0.24, 0.76, 0.27),
          _ => (0.35, 0.65, 0.20),
        };
        uv.moveTo(left, -0.035);
        uv.cubicTo(
          left - 0.04,
          curve * 0.7,
          right + 0.04,
          curve * 0.7,
          right,
          -0.035,
        );
        uv.close();
        if (family != 'dress') {
          _cuffOpening(uv, family == 'raincoat' ? 0.24 : 0.19, 0.103);
          _cuffOpening(uv, 0.81, 0.111);
        }
        if (family == 'raincoat') {
          uv.moveTo(0.37, 1.04);
          uv.cubicTo(0.34, 0.86, 0.66, 0.86, 0.65, 1.04);
          uv.close();
        }
        if (family == 'dress') {
          // Frente: las patas delanteras pasan por delante de la falda.
          _dressForeleg(uv, 0.27, 0.26, 0.18);
          _dressForeleg(uv, 0.81, 0.83, 0.19);
        }
      } else if (view == 'side' && family == 'dress') {
        uv.moveTo(0.79, -0.10);
        uv.cubicTo(0.77, 0.002, 0.91, 0.21, 1.02, 0.24);
        uv.lineTo(1.02, -0.10);
        uv.close();
      } else if (view == 'back' && family != 'dress') {
        _cuffOpening(uv, 0.24, 0.112);
        _cuffOpening(uv, 0.79, 0.110);
      }
      final openings = _mapPath(uv, rect, deformation);
      if (view == 'side' && family == 'overalls') {
        // La abertura continúa hasta el borde inferior del peto.
        openings.moveTo(rect.right - 0.226, rect.top + 0.184);
        openings.cubicTo(
          rect.right - 0.280,
          rect.top + 0.207,
          rect.right - 0.201,
          rect.top + 0.299,
          rect.right - 0.205,
          rect.bottom,
        );
        openings.lineTo(rect.right - 0.078, rect.bottom);
        openings.cubicTo(
          rect.right - 0.120,
          rect.top + 0.294,
          rect.right - 0.128,
          rect.top + 0.206,
          rect.right - 0.226,
          rect.top + 0.184,
        );
        openings.close();
      }
      return openings;
    });
    _fur(c, openings, base, petRect, coatPaint);
    if (view == 'back') {
      final tail = _tailOutline(ids, petRect);
      c.drawPath(
        tail.shift(const Offset(0.003, 0.006)),
        Paint()
          ..color = const Color(0x53432F2A)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.005),
      );
      _fur(c, tail, base, petRect, coatPaint);
    } else if (view == 'side') {
      _fur(
        c,
        PetNeck.earMask(pose, landmarks['headTop']!),
        base,
        petRect,
        coatPaint,
      );
    }
  }

  void _cuffOpening(Path path, double u, double radius) {
    path.moveTo(u - radius, 1.05);
    path.cubicTo(u - radius, 0.97, u - radius * 0.44, 0.928, u, 0.933);
    path.cubicTo(u + radius * 0.55, 0.915, u + radius, 0.971, u + radius, 1.05);
    path.close();
  }

  void _dressForeleg(Path path, double shoulder, double paw, double radius) {
    path.moveTo(shoulder - radius * 0.53, 0.88);
    path.quadraticBezierTo(
      shoulder - radius * 0.42,
      0.95,
      paw - radius * 0.53,
      1.08,
    );
    path.lineTo(paw + radius * 0.46, 1.08);
    path.quadraticBezierTo(
      shoulder + radius * 0.47,
      0.94,
      shoulder + radius * 0.32,
      0.87,
    );
    path.quadraticBezierTo(shoulder, 0.77, shoulder - radius * 0.53, 0.88);
    path.close();
  }

  void _raincoatLining(
    Canvas c,
    String view,
    String pose,
    PetNeck neck,
    ColorFilter? filter,
  ) {
    if (view == 'front') return;
    if (view == 'back') {
      final middle = neck.at(0.5, drape: 0).dx + 0.039;
      for (final x in [middle - 0.111, middle + 0.111]) {
        final cuff = Path()
          ..moveTo(x - 0.064, -0.378)
          ..quadraticBezierTo(x, -0.404, x + 0.064, -0.378)
          ..cubicTo(x + 0.066, -0.336, x + 0.053, -0.273, x + 0.058, -0.242)
          ..quadraticBezierTo(x, -0.225, x - 0.057, -0.242)
          ..quadraticBezierTo(x - 0.064, -0.310, x - 0.064, -0.378)
          ..close();
        _paintFabric(
          c,
          cuff,
          const Rect.fromLTRB(0.43, 0.47, 0.58, 0.67),
          filter,
          shaded: true,
          asset: 'raincoat-back',
        );
      }
    } else {
      final throat = neck.right;
      final lower = pose == 'side' ? 0.358 : 0.314;
      final lining = Path()
        ..moveTo(throat.dx - 0.105, throat.dy + 0.018)
        ..quadraticBezierTo(
          throat.dx - 0.038,
          throat.dy - 0.008,
          throat.dx - 0.013,
          throat.dy + 0.053,
        )
        ..quadraticBezierTo(
          throat.dx - 0.021,
          throat.dy + lower * 0.57,
          throat.dx - 0.086,
          throat.dy + lower,
        )
        ..quadraticBezierTo(
          throat.dx - 0.145,
          throat.dy + lower + 0.012,
          throat.dx - 0.180,
          throat.dy + lower - 0.029,
        )
        ..quadraticBezierTo(
          throat.dx - 0.120,
          throat.dy + 0.081,
          throat.dx - 0.105,
          throat.dy + 0.018,
        )
        ..close();
      _paintFabric(
        c,
        lining,
        const Rect.fromLTRB(0.47, 0.31, 0.58, 0.67),
        filter,
        shaded: false,
        asset: 'raincoat-side',
      );
    }
  }

  Rect _sideOutfit(String family, PetNeck neck) {
    final (left, top, right, bottom) = switch (family) {
      'overalls' => (-0.376, -0.668, 0.402, -0.153),
      'raincoat' => (-0.358, -0.647, 0.414, -0.222),
      _ => (-0.402, -0.661, 0.409, -0.235),
    };
    final dy = neck.left.dy + 0.652;
    final dx = neck.right.dx - 0.415;
    return Rect.fromLTRB(
      left + dx * 0.5,
      top + dy,
      right + dx,
      bottom + dy * 0.26,
    );
  }

  ColorFilter? _tailoredColor(
    AppearanceCatalog catalog,
    String id,
    String family,
  ) {
    if (const {
      'outfit.teal',
      'outfit.raincoat_yellow',
      'outfit.dress_pink',
    }.contains(id)) {
      return null;
    }
    final swatch = catalog.swatch(id);
    if (swatch == null) return null;
    final midpoint = switch (family) {
      'overalls' => 93,
      'raincoat' => 169,
      _ => 160,
    };
    return ColorFilter.matrix([
      for (final channel in [swatch.r, swatch.g, swatch.b]) ...[
        0.183,
        0.615,
        0.062,
        0.0,
        channel * 255 - midpoint * 0.86,
      ],
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  void _paintBackSeam(
    Canvas c,
    Rect rect,
    ColorFilter? filter, {
    String family = 'sweater',
  }) {
    // El tejido interior une las dos perneras por encima de los puños.
    final hem = rect.bottom - 0.021;
    final x = rect.center.dx + 0.010;
    final seamStart = hem - (family == 'overalls' ? 0.110 : 0.087);
    final seam = Path()
      ..moveTo(x - 0.069, seamStart)
      ..lineTo(x + 0.073, seamStart)
      ..lineTo(x + 0.053, hem + 0.015)
      ..quadraticBezierTo(x, hem - 0.012, x - 0.055, hem + 0.015)
      ..close();
    _paintFabric(
      c,
      seam,
      family == 'overalls'
          ? const Rect.fromLTRB(0.37, 0.59, 0.61, 0.69)
          : const Rect.fromLTRB(0.37, 0.71, 0.61, 0.83),
      filter,
      shaded: true,
      asset: '$family-back',
    );
  }

  void _paintHindSleeves(
    Canvas c,
    String pose,
    ColorFilter? filter, {
    String family = 'sweater',
  }) {
    // Ejes desde la cadera hasta cada puño, siguiendo las dos patas del sprite.
    final (farTop, farCuff, nearTop, nearCuff) = switch (pose) {
      'run_a' => (
        const Offset(-0.252, -0.285),
        const Offset(-0.332, -0.145),
        const Offset(-0.314, -0.260),
        const Offset(-0.451, -0.137),
      ),
      'run_b' => (
        const Offset(-0.236, -0.364),
        const Offset(-0.289, -0.219),
        const Offset(-0.324, -0.365),
        const Offset(-0.418, -0.192),
      ),
      'jump' => (
        const Offset(-0.234, -0.374),
        const Offset(-0.325, -0.205),
        const Offset(-0.335, -0.372),
        const Offset(-0.424, -0.192),
      ),
      _ => (
        const Offset(-0.181, -0.370),
        const Offset(-0.204, -0.207),
        const Offset(-0.270, -0.369),
        const Offset(-0.330, -0.183),
      ),
    };
    for (final (top, cuff, far) in [
      if (pose == 'side' && family == 'overalls')
        (const Offset(-0.132, -0.345), const Offset(-0.139, -0.177), true)
      else
        (farTop, farCuff, true),
      if (family == 'sweater') (nearTop, nearCuff, false),
    ]) {
      final axis = cuff - top;
      final length = axis.distance;
      final upper = far ? 0.064 : 0.075;
      final lower = far ? 0.043 : 0.056;
      final leg = Path()
        ..moveTo(-upper, 0)
        ..quadraticBezierTo(0, -0.020, upper, 0)
        ..cubicTo(
          upper,
          length * 0.40,
          lower,
          length * 0.70,
          lower,
          length - 0.012,
        )
        ..quadraticBezierTo(0, length + 0.012, -lower, length - 0.008)
        ..cubicTo(
          -lower - 0.004,
          length * 0.71,
          -upper,
          length * 0.34,
          -upper,
          0,
        )
        ..close();
      c.save();
      c.translate(top.dx, top.dy);
      c.rotate(math.atan2(-axis.dx, axis.dy));
      _paintFabric(
        c,
        leg,
        const Rect.fromLTRB(0.60, 0.73, 0.89, 0.985),
        filter,
        shaded: far,
        asset: '$family-back',
      );
      c.restore();
    }
  }

  void _paintFabric(
    Canvas c,
    Path shape,
    Rect uv,
    ColorFilter? filter, {
    required bool shaded,
    required String asset,
  }) {
    final cloth = _images[asset]!;
    final src = cloth.source;
    final bounds = shape.getBounds();
    c.save();
    c.clipPath(shape);
    if (shaded) {
      c.saveLayer(
        bounds,
        Paint()
          ..colorFilter = const ColorFilter.mode(
            Color(0xFFC7B7B2),
            BlendMode.modulate,
          ),
      );
    }
    c.drawImageRect(
      cloth.image,
      Rect.fromLTRB(
        src.left + src.width * uv.left,
        src.top + src.height * uv.top,
        src.left + src.width * uv.right,
        src.top + src.height * uv.bottom,
      ),
      bounds,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..colorFilter = filter,
    );
    if (shaded) c.restore();
    c.restore();
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

  Image get articulatedCorduroy => _images['overalls-side']!.image;

  /// El pañuelo se ajusta a los dos bordes del cuello del esqueleto.
  /// La cabeza y la cola se dibujan después y tapan la tela que queda detrás.
  void paintArticulatedBandana(
    Canvas c,
    PetNeck neck, {
    required bool side,
    required bool back,
  }) {
    if (back) {
      final cloth = _images['bandana-back']!;
      final src = cloth.source;
      final cotton = Rect.fromLTRB(
        src.left + src.width * 0.51,
        src.top + src.height * 0.43,
        src.left + src.width * 0.82,
        src.top + src.height * 0.59,
      );
      final hem = neck.band(7, drape: 5);
      c.drawPath(
        hem.shift(const Offset(0, 2)),
        Paint()..color = const Color(0x773D3130),
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
      return;
    }
    final (name, rect, shear) = _fitBandana(neck, side, side ? 58 : 59);
    c.save();
    c.translate(0, 2.3);
    _draw(
      c,
      name,
      rect,
      shear: shear,
      colorFilter: const ColorFilter.mode(Color(0x70482C28), BlendMode.srcIn),
    );
    c.restore();
    _draw(c, name, rect, shear: shear);
  }

  (String, Rect, double) _fitBandana(PetNeck neck, bool side, double height) {
    final (name, uvLeft, uvRight) = side
        ? (
            'bandana-side',
            const Offset(0.254, 0.166),
            const Offset(0.974, 0.336),
          )
        : (
            'bandana-front',
            const Offset(0.062, 0.083),
            const Offset(0.675, 0.079),
          );
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
    return (name, rect, shear);
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
    final side = pose != 'front';
    final (name, rect, shear) = _fitBandana(neck, side, side ? 0.248 : 0.245);
    _shadow(c, name, rect, '', base, petRect, shear: shear);
    _draw(c, name, rect, shear: shear);
    if (pose != 'front') {
      _fur(c, PetNeck.earMask(pose, lm['headTop']!), base, petRect, coatPaint);
    }
  }

  void paintTailoredNeck(
    Canvas c,
    Appearance ids,
    String pose,
    Offset head,
    SpriteLayer base,
    Rect petRect,
    Paint coatPaint,
  ) {
    final family = neckMaterial(ids.neck);
    if (family == null) return;
    final knit = family == 'knit';
    final front = pose == 'front';
    final back = pose == 'back';
    final view = front || back ? pose : 'side';
    final fit = PetNeck.forPose(pose, ids.hair);
    final name = '$family-$view';
    final height = switch ((family, view)) {
      ('knit', 'front') => 0.284,
      ('knit', 'side') => 0.249,
      ('knit', 'back') => 0.079,
      ('bowtie', 'back') => 0.043,
      ('bowtie', 'front') => 0.106,
      _ => 0.117,
    };
    final left = fit.at(back ? 0.10 : 0.02, drape: 0);
    final right = fit.at(back ? 0.90 : 0.98, drape: 0);
    final shear = knit || front || back
        ? 0.0
        : (right.dy - left.dy) / (right.dx - left.dx);
    final rise = back
        ? 0.061
        : front
        ? (knit ? 0.023 : 0.004)
        : 0.011;
    final width = right.dx - left.dx;
    final rect = Rect.fromLTWH(left.dx, left.dy - rise, width, height);
    _shadow(c, name, rect, '', base, petRect, shear: shear);
    _draw(c, name, rect, shear: shear);
    if (knit && (front || back)) {
      // El pelo oculta el interior de la vuelta y deja visible el borde de punto.
      final u = front ? 0.13 : 0.07;
      final rim = Path()
        ..moveTo(rect.left + width * u, rect.top - 0.004)
        ..cubicTo(
          rect.left + width * 0.13,
          rect.top + height * (front ? 0.15 : 0.17),
          rect.center.dx,
          rect.top + height * (front ? 0.31 : 0.35),
          rect.right - width * u,
          rect.top + height * 0.03,
        )
        ..lineTo(rect.right - width * u, rect.top - 0.004)
        ..close();
      _fur(c, rim, base, petRect, coatPaint);
    }
    if (!front && !back) {
      _fur(c, PetNeck.earMask(pose, head), base, petRect, coatPaint);
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
