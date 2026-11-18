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
          var dx = dst.left + u * dst.width, dy = dst.top + v * dst.height;
          // Solo el extremo de la manga cambia de dirección: la trama y
          // las sombras del torso conservan continuidad en cada fotograma.
          final sleeve =
              ((u - 0.25) / 0.35).clamp(0.0, 1.0) *
              ((v - 0.50) / 0.50).clamp(0.0, 1.0);
          if (deformation == 'run_a') {
            dx += sleeve * 0.17;
            dy -= sleeve * 0.070;
          }
          if (deformation == 'run_b' || deformation == 'jump') {
            dx += sleeve * 0.070;
            dy -= sleeve * 0.055;
          }
          if (deformation == 'side') dx += sleeve * 0.055;
          positions.add(Offset(dx, dy));
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

  /// Borde con rizos de la propia imagen. Cada color conserva su pelaje:
  /// no se añaden mechones albaricoque a un caniche blanco o negro.
  Path _fringe(Offset a, Offset b, {double depth = 0.04, bool below = true}) {
    final delta = b - a;
    final normal = Offset(-delta.dy, delta.dx) / delta.distance;
    final p = Path()..moveTo(a.dx, a.dy);
    for (var i = 0; i < 20; i++) {
      final x = a + delta * (i / 20), y = a + delta * ((i + 1) / 20);
      final lift = normal * (0.003 + math.sin(i * 9.1) * 0.004);
      p.quadraticBezierTo(
        (x.dx + y.dx) / 2 + lift.dx,
        (x.dy + y.dy) / 2 + lift.dy,
        y.dx,
        y.dy,
      );
    }
    final n = normal * (below ? depth : -depth);
    p.lineTo(b.dx + n.dx, b.dy + n.dy);
    p.lineTo(a.dx + n.dx, a.dy + n.dy);
    return p..close();
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
    if (front) {
      _fur(
        c,
        _fringe(
          Offset(center - 0.13, -0.606),
          Offset(center + 0.13, -0.606),
          depth: 0.095,
          below: false,
        ),
        base,
        petRect,
        coatPaint,
      );
      for (final side in [-1.0, 1.0]) {
        final x = center + side * 0.104;
        _fur(
          c,
          _fringe(Offset(x - 0.06, -0.203), Offset(x + 0.06, -0.203)),
          base,
          petRect,
          coatPaint,
        );
      }
    } else {
      final head = lm['headTop']!;
      // La oreja y la garganta se sitúan delante del cuello del jersey.
      _fur(c, _ear(pose, head), base, petRect, coatPaint);
      final cuff = switch (pose) {
        'run_a' => (const Offset(0.20, -0.205), const Offset(0.30, -0.16)),
        'run_b' ||
        'jump' => (const Offset(0.105, -0.235), const Offset(0.205, -0.235)),
        _ => (
          Offset(neck.dx - 0.12, neck.dy + 0.37),
          Offset(neck.dx + 0.01, neck.dy + 0.37),
        ),
      };
      _fur(
        c,
        _fringe(cuff.$1, cuff.$2, depth: 0.045),
        base,
        petRect,
        coatPaint,
      );
      final chin = lm['mouth']!;
      _fur(
        c,
        Path()..addOval(
          Rect.fromCenter(
            center: chin + const Offset(-0.06, 0.025),
            width: 0.18,
            height: 0.075,
          ),
        ),
        base,
        petRect,
        coatPaint,
      );
    }
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
    if (front) {
      _fur(
        c,
        _fringe(
          Offset(center - 0.13, -0.590),
          Offset(center + 0.11, -0.590),
          depth: 0.08,
          below: false,
        ),
        base,
        petRect,
        coatPaint,
      );
    } else {
      final head = lm['headTop']!;
      _fur(c, _ear(pose, head), base, petRect, coatPaint);
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
