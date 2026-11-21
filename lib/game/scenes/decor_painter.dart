import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/services.dart';

import '../../domain/balance.dart';

/// Geometría de la sala para colocar la decoración: la ilustración ([art]),
/// la parte visible en pantalla ([view]) y el caniche ([feet], [petSize]).
class DecorScene {
  const DecorScene({
    required this.art,
    required this.view,
    required this.feet,
    required this.petSize,
    this.illustrated = false,
  });

  /// Rectángulo de la ilustración (puede salirse de la escena por arriba o
  /// los lados) o, sin ilustración, la escena entera.
  final Rect art;

  /// Parte visible de [art].
  final Rect view;
  final Offset feet;
  final double petSize;

  /// Con la ilustración del salón (el cuadro se cuelga en el pilar entre
  /// ventanas); sin ella, en el hueco de pared entre los arcos vectoriales.
  final bool illustrated;
}

/// Decoración ilustrada del salón, con respaldo vectorial:
/// alfombra bajo el caniche, un elemento en la pared y una maceta en el suelo
/// a la derecha. Los artículos «none» no dibujan nada.
abstract final class DecorPainter {
  static const artworkIds = [
    'rug.round',
    'rug.stripes',
    'rug.bone',
    'wall.frame',
    'wall.garland',
    'wall.stars',
    'plant.fern',
    'plant.flowers',
    'plant.cactus',
  ];
  static final _artwork = <String, Image>{};
  static final _stripSources = <String, Rect>{};
  static const _wallStrips = {'wall.garland', 'wall.stars'};
  static Future<void>? _loading;
  static Future<void> loadAssets() {
    if (_artwork.length == artworkIds.length) return Future.value();
    return _loading ??= _loadAssets();
  }

  static Future<void> _loadAssets() async {
    await Future.wait(
      artworkIds.map((id) async {
        final bytes = await rootBundle.load('assets/images/decor/$id.webp');
        final codec = await instantiateImageCodec(
          bytes.buffer.asUint8List(),
          targetWidth: _wallStrips.contains(id) ? 1536 : 768,
        );
        final image = (await codec.getNextFrame()).image;
        _artwork[id] = image;
        if (_wallStrips.contains(id)) {
          final pixels = await image.toByteData(
            format: ImageByteFormat.rawRgba,
          );
          if (pixels != null) {
            var left = image.width, top = image.height, right = 0, bottom = 0;
            for (var y = 0; y < image.height; y++) {
              for (var x = 0; x < image.width; x++) {
                if (pixels.getUint8((y * image.width + x) * 4 + 3) <= 8) {
                  continue;
                }
                left = math.min(left, x);
                top = math.min(top, y);
                right = math.max(right, x + 1);
                bottom = math.max(bottom, y + 1);
              }
            }
            if (right > left && bottom > top) {
              _stripSources[id] = Rect.fromLTRB(
                left.toDouble(),
                top.toDouble(),
                right.toDouble(),
                bottom.toDouble(),
              );
            }
          }
        }
        codec.dispose();
      }),
    );
  }

  static Paint _p(int c) => Paint()..color = Color(c);
  static Paint _stroke(int c, double w) => Paint()
    ..color = Color(c)
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static bool isEmpty(String id) => id.endsWith('.none');

  /// Pinta el artículo [id] del hueco [slot] en la sala.
  static void paint(
    Canvas c,
    DecorSlot slot,
    String id,
    DecorScene s, {
    double t = 0,
    bool reducedMotion = false,
  }) {
    if (isEmpty(id) || s.petSize <= 0 || s.view.isEmpty) return;
    final box = boxIn(slot, id, s);
    paintItem(c, id, box, t: t, reducedMotion: reducedMotion);
  }

  /// Caja del artículo dentro de la sala.
  static Rect boxIn(DecorSlot slot, String id, DecorScene s) {
    final ps = s.petSize;
    final v = s.view;
    switch (slot) {
      case DecorSlot.rug:
        final wide = id == 'rug.bone' || id == 'rug.persian';
        final w = ps * (wide ? 1.5 : 1.3);
        final h = ps * (wide ? 0.36 : 0.32);
        return Rect.fromCenter(
          center: s.feet + Offset(0, ps * 0.02),
          width: w,
          height: h,
        );
      case DecorSlot.plant:
        final tall = id == 'plant.lights' || id == 'plant.sunflower';
        final h = math.min(ps * (tall ? 0.8 : 0.62), v.height * 0.6);
        final w = h * 0.62;
        final margin = v.width * 0.05;
        // Junto al borde derecho, sin alejarse demasiado del caniche.
        final cx = math.max(
          math.min(v.right - margin - w / 2, s.feet.dx + ps * 0.95),
          v.left + w / 2,
        );
        final baseY = math.min(s.feet.dy - ps * 0.05, v.bottom - 2);
        return Rect.fromLTRB(cx - w / 2, baseY - h, cx + w / 2, baseY);
      case DecorSlot.wall:
        // Franja de pared visible entre el borde superior y la cabeza.
        final bandTop = v.top;
        final bandBottom = math.max(
          s.feet.dy - ps * 0.98,
          bandTop + math.max(ps * 0.35, v.height * 0.28),
        );
        final band = Rect.fromLTRB(v.left, bandTop, v.right, bandBottom);
        switch (id) {
          case 'wall.frame' || 'wall.goldframe' || 'wall.clock':
            // Cuelgan del mismo punto; el retrato dorado es más grande.
            final k = switch (id) {
              'wall.goldframe' => 1.3,
              'wall.clock' => 0.95,
              _ => 1.0,
            };
            final w =
                k *
                (s.illustrated
                    ? math.min(ps * 0.34, v.width * 0.2)
                    : math.min(ps * 0.3, v.width * 0.14));
            final h = w * _hangAspect(id);
            final fx = s.illustrated ? 0.775 : 0.5;
            final fy = s.illustrated ? 0.33 : 0.2;
            final cx = (s.art.left + fx * s.art.width)
                .clamp(v.left + w / 2 + 4, v.right - w / 2 - 4)
                .toDouble();
            final cy = math.max(
              s.art.top + fy * s.art.height,
              v.top + h / 2 + math.max(6.0, ps * 0.05),
            );
            return Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
          case 'wall.rainbow':
            final w = math.min(v.width * 0.46, ps * 1.1);
            final h = math.min(w * 0.55, band.height * 0.6);
            return Rect.fromCenter(
              center: Offset(
                v.center.dx,
                v.top + math.max(6.0, band.height * 0.06) + h / 2,
              ),
              width: h / 0.55,
              height: h,
            );
          case 'wall.garland':
          case 'wall.stars':
            final h = math.min(band.height * 0.45, ps * 0.32);
            return Rect.fromLTWH(
              v.left,
              v.top + math.max(4.0, band.height * 0.04),
              v.width,
              h,
            );
          default:
            return Rect.fromLTRB(
              v.left + v.width * 0.04,
              v.top + math.max(4.0, band.height * 0.05),
              v.right - v.width * 0.04,
              v.top + band.height * 0.7,
            );
        }
    }
  }

  /// Alto/ancho de las piezas que cuelgan en la pared.
  static double _hangAspect(String id) => switch (id) {
    'wall.goldframe' => 1.25,
    'wall.clock' => 1.0,
    _ => 1.18,
  };

  /// Caja para una miniatura de [size] con la proporción del artículo.
  static Rect thumbBox(String id, Size size) {
    final aspect = switch (id.split('.').first) {
      'rug' => id == 'rug.bone' || id == 'rug.persian' ? 3.2 : 2.6,
      'plant' => 0.62,
      _ => switch (id) {
        'wall.frame' || 'wall.goldframe' || 'wall.clock' => 1 / _hangAspect(id),
        'wall.garland' || 'wall.stars' => 3.0,
        'wall.rainbow' => 1 / 0.55,
        _ => 1.5,
      },
    };
    final area = (Offset.zero & size).deflate(size.shortestSide * 0.08);
    var w = area.width, h = w / aspect;
    if (h > area.height) {
      h = area.height;
      w = h * aspect;
    }
    return Rect.fromCenter(center: area.center, width: w, height: h);
  }

  /// Miniatura estática del artículo (fichas de la tienda).
  static void paintThumb(Canvas c, Size size, String id) {
    if (isEmpty(id)) return;
    c.save();
    c.clipRect(Offset.zero & size);
    paintItem(c, id, thumbBox(id, size), reducedMotion: true);
    c.restore();
  }

  /// Dibuja el artículo [id] dentro de [box].
  static void paintItem(
    Canvas c,
    String id,
    Rect box, {
    double t = 0,
    bool reducedMotion = false,
  }) {
    final image = _artwork[id];
    if (image != null) {
      final source =
          _stripSources[id] ??
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      if (_wallStrips.contains(id)) {
        _paintWallStrip(c, id, image, source, box, t, reducedMotion);
        return;
      }
      // Rugs follow the perspective of the floor; wall art and plants keep their aspect ratio.
      final scale = math.min(
        box.width / source.width,
        box.height / source.height,
      );
      final target = id.startsWith('rug.')
          ? box
          : Rect.fromCenter(
              center: box.center,
              width: source.width * scale,
              height: source.height * scale,
            );
      c.drawImageRect(
        image,
        source,
        target,
        Paint()..filterQuality = FilterQuality.medium,
      );
      return;
    }
    switch (id) {
      case 'rug.round':
        _rugRound(c, box);
      case 'rug.stripes':
        _rugStripes(c, box);
      case 'rug.bone':
        _rugBone(c, box);
      case 'wall.frame':
        _frame(c, box);
      case 'wall.garland':
        _garland(c, box, reducedMotion ? 0 : t);
      case 'wall.stars':
        _stars(c, box, reducedMotion ? null : t);
      case 'plant.fern':
        _fern(c, box);
      case 'plant.flowers':
        _flowers(c, box);
      case 'plant.cactus':
        _cactus(c, box);
      case 'rug.checks':
        _rugChecks(c, box);
      case 'rug.cloud':
        _rugCloud(c, box);
      case 'rug.persian':
        _rugPersian(c, box);
      case 'wall.rainbow':
        _rainbow(c, box);
      case 'wall.clock':
        _clock(c, box);
      case 'wall.goldframe':
        _goldFrame(c, box, reducedMotion ? null : t);
      case 'plant.sunflower':
        _sunflower(c, box);
      case 'plant.bonsai':
        _bonsai(c, box);
      case 'plant.lights':
        _lightsTree(c, box, reducedMotion ? null : t);
    }
  }

  /// ¿Dibuja algo este artículo? (los «none» y los desconocidos, no).
  static bool paints(String id) => const {
    'rug.round',
    'rug.stripes',
    'rug.bone',
    'rug.checks',
    'rug.cloud',
    'rug.persian',
    'wall.frame',
    'wall.garland',
    'wall.stars',
    'wall.rainbow',
    'wall.clock',
    'wall.goldframe',
    'plant.fern',
    'plant.flowers',
    'plant.cactus',
    'plant.sunflower',
    'plant.bonsai',
    'plant.lights',
  }.contains(id);

  /// Repite módulos nuevos a escala uniforme. El ancho añade adornos, sin
  /// ensanchar banderines ni estrellas; el último continúa fuera del visor.
  static void _paintWallStrip(
    Canvas c,
    String id,
    Image image,
    Rect source,
    Rect box,
    double t,
    bool reducedMotion,
  ) {
    if (box.isEmpty || source.isEmpty) return;
    final tileWidth = source.width * box.height / source.height;
    c.save();
    c.clipRect(
      Rect.fromLTRB(box.left, box.top - 12, box.right, box.bottom + 12),
    );
    for (var x = box.left; x < box.right; x += tileWidth) {
      final target = Rect.fromLTWH(x, box.top, tileWidth, box.height);
      final opacity = id == 'wall.stars' && !reducedMotion
          ? .96 + .04 * math.sin(t * 2.2)
          : 1.0;
      c.drawImageRect(
        image,
        source,
        target,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..color = Color.fromRGBO(255, 255, 255, opacity),
      );
    }
    c.restore();
  }

  // ---------------------------------------------------------------- Alfombras

  static void _rugShadow(Canvas c, Rect r) =>
      c.drawOval(r.shift(Offset(0, r.height * 0.08)), _p(0x2234283B));

  static void _rugRound(Canvas c, Rect r) {
    _rugShadow(c, r);
    c.drawOval(r, _p(0xFFD98C9C));
    c.drawOval(r.deflate(r.height * 0.1), _p(0xFFF6D9DE));
    c.drawOval(r.deflate(r.height * 0.22), _p(0xFFE8AAB6));
    c.drawOval(r.deflate(r.height * 0.34), _p(0xFFF6D9DE));
    // Borla de puntos en el borde.
    final dot = _p(0xFFFFF8E9);
    for (var i = 0; i < 18; i++) {
      final a = i / 18 * math.pi * 2;
      final p = Offset(
        r.center.dx + math.cos(a) * (r.width / 2 - r.height * 0.05),
        r.center.dy + math.sin(a) * (r.height / 2 - r.height * 0.05),
      );
      c.drawCircle(p, r.height * 0.025, dot);
    }
  }

  static void _rugStripes(Canvas c, Rect r) {
    _rugShadow(c, r);
    final rr = RRect.fromRectAndRadius(r, Radius.circular(r.height * 0.42));
    c.save();
    c.clipRRect(rr);
    c.drawRect(r, _p(0xFFFFF8E9));
    const colors = [0xFFB8D4C2, 0xFFFFF8E9, 0xFFC9B9E2, 0xFFFFF8E9];
    final n = 7;
    for (var i = 0; i < n; i++) {
      c.drawRect(
        Rect.fromLTWH(
          r.left,
          r.top + r.height * i / n,
          r.width,
          r.height / n + 0.5,
        ),
        _p(colors[i % colors.length]),
      );
    }
    c.restore();
    c.drawRRect(rr, _stroke(0xFF8FA98A, r.height * 0.05));
    // Flecos a los lados.
    final fringe = _stroke(0xFFD9C6A0, math.max(1, r.height * 0.025));
    for (var i = 1; i < 6; i++) {
      final y = r.top + r.height * i / 6;
      c.drawLine(Offset(r.left, y), Offset(r.left - r.height * 0.1, y), fringe);
      c.drawLine(
        Offset(r.right, y),
        Offset(r.right + r.height * 0.1, y),
        fringe,
      );
    }
  }

  static Path _bonePath(Rect r) {
    final h = r.height;
    final knob = h * 0.3;
    final bar = Rect.fromLTRB(
      r.left + knob * 1.2,
      r.top + h * 0.26,
      r.right - knob * 1.2,
      r.bottom - h * 0.26,
    );
    return Path()
      ..addRRect(RRect.fromRectAndRadius(bar, Radius.circular(h * 0.2)))
      ..addOval(
        Rect.fromCircle(
          center: Offset(r.left + knob, r.top + knob),
          radius: knob,
        ),
      )
      ..addOval(
        Rect.fromCircle(
          center: Offset(r.left + knob, r.bottom - knob),
          radius: knob,
        ),
      )
      ..addOval(
        Rect.fromCircle(
          center: Offset(r.right - knob, r.top + knob),
          radius: knob,
        ),
      )
      ..addOval(
        Rect.fromCircle(
          center: Offset(r.right - knob, r.bottom - knob),
          radius: knob,
        ),
      );
  }

  static void _rugBone(Canvas c, Rect r) {
    final shadow = _bonePath(r.shift(Offset(0, r.height * 0.08)));
    c.drawPath(shadow, _p(0x2234283B));
    final path = _bonePath(r);
    c.drawPath(path, _p(0xFFE9C989));
    c.drawPath(_bonePath(r.deflate(r.height * 0.09)), _p(0xFFF6E2B6));
    // Costura.
    final inner = r.deflate(r.height * 0.2);
    c.drawLine(
      Offset(inner.left + inner.height, r.center.dy),
      Offset(inner.right - inner.height, r.center.dy),
      _stroke(0xFFD9B26A, math.max(1, r.height * 0.03)),
    );
  }

  // ------------------------------------------------------------------- Pared

  static void _frame(Canvas c, Rect r) {
    // Cordel del que cuelga.
    final hook = Offset(r.center.dx, r.top - r.height * 0.14);
    final cord = _stroke(0xFF8A5A3A, math.max(1, r.width * 0.025));
    c.drawLine(hook, Offset(r.left + r.width * 0.25, r.top), cord);
    c.drawLine(hook, Offset(r.right - r.width * 0.25, r.top), cord);
    c.drawCircle(hook, r.width * 0.035, _p(0xFF8A5A3A));
    c.drawRRect(
      RRect.fromRectAndRadius(
        r.shift(Offset(r.width * 0.04, r.width * 0.05)),
        Radius.circular(r.width * 0.06),
      ),
      _p(0x2834283B),
    );
    final outer = RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.06));
    c.drawRRect(outer, _p(0xFFC08A5A));
    c.drawRRect(
      RRect.fromRectAndRadius(r.deflate(r.width * 0.06), Radius.circular(4)),
      _p(0xFFE2B47E),
    );
    final mat = r.deflate(r.width * 0.12);
    c.drawRect(mat, _p(0xFFFFF3E2));
    c.drawRect(mat.deflate(r.width * 0.05), _p(0xFFEBDDE6));
    _paw(
      c,
      mat.center + Offset(0, mat.height * 0.05),
      mat.width * 0.26,
      0xFF5C354E,
    );
  }

  /// Huella: almohadilla y cuatro dedos.
  static void _paw(Canvas c, Offset center, double size, int color) {
    final p = _p(color);
    c.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, size * 0.35),
        width: size * 1.15,
        height: size * 0.9,
      ),
      p,
    );
    const toes = [(-0.6, -0.25), (-0.22, -0.62), (0.22, -0.62), (0.6, -0.25)];
    for (final (dx, dy) in toes) {
      c.drawOval(
        Rect.fromCenter(
          center: center + Offset(dx * size, dy * size),
          width: size * 0.42,
          height: size * 0.52,
        ),
        p,
      );
    }
  }

  static void _garland(Canvas c, Rect r, double t) {
    final sag = r.height * 0.35;
    final cord = _stroke(0xFF8A5A3A, math.max(1.2, r.height * 0.04));
    Offset at(double k) =>
        Offset(r.left + r.width * k, r.top + 4 * sag * k * (1 - k));
    final path = Path()..moveTo(r.left, r.top);
    for (var i = 1; i <= 24; i++) {
      final p = at(i / 24);
      path.lineTo(p.dx, p.dy);
    }
    c.drawPath(path, cord);
    const colors = [0xFFE0705A, 0xFFE9B657, 0xFF8FB89A, 0xFFB8A6D9, 0xFFE8AAB6];
    const n = 9;
    final flagW = r.width / (n + 1) * 0.78;
    final flagH = math.min(r.height - sag * 0.6, flagW * 1.15);
    for (var i = 0; i < n; i++) {
      final k = (i + 1) / (n + 1);
      final a = at(k - 0.5 / (n + 1) * 0.78);
      final b = at(k + 0.5 / (n + 1) * 0.78);
      // Vaivén muy leve (nulo con movimiento reducido).
      final sway = t == 0 ? 0.0 : math.sin(t * 1.4 + i * 0.9) * flagW * 0.05;
      final tip = Offset((a.dx + b.dx) / 2 + sway, (a.dy + b.dy) / 2 + flagH);
      final flag = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(tip.dx, tip.dy)
        ..close();
      c.drawPath(flag, _p(colors[i % colors.length]));
      c.drawCircle(
        Offset(tip.dx, (a.dy + b.dy) / 2 + flagH * 0.38),
        flagW * 0.09,
        _p(0xCCFFF8E9),
      );
    }
    c.drawCircle(r.topLeft, r.height * 0.06, _p(0xFF8A5A3A));
    c.drawCircle(r.topRight, r.height * 0.06, _p(0xFF8A5A3A));
  }

  static const _starSpots = [
    (0.06, 0.2, 0.9),
    (0.2, 0.62, 0.6),
    (0.33, 0.12, 0.7),
    (0.66, 0.16, 0.75),
    (0.8, 0.6, 0.6),
    (0.94, 0.24, 0.9),
    (0.5, 0.05, 0.5),
  ];

  /// Estrellas luminosas; titilan suavemente con [t] (null: estáticas).
  static void _stars(Canvas c, Rect r, double? t) {
    final base = math.min(r.height * 0.32, r.width * 0.09);
    for (var i = 0; i < _starSpots.length; i++) {
      final (fx, fy, scale) = _starSpots[i];
      final twinkle = t == null
          ? 1.0
          : 0.82 + 0.18 * math.sin(t * 2.2 + i * 1.7);
      final size = base * scale * twinkle;
      final center = Offset(
        r.left + fx * r.width,
        r.top + fy * r.height + size,
      );
      c.drawCircle(
        center,
        size * 1.1,
        Paint()
          ..color = Color.fromRGBO(
            255,
            236,
            170,
            t == null ? 0.35 : 0.2 + 0.2 * twinkle,
          )
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.35),
      );
      c.drawPath(_star(center, size, size * 0.46), _p(0xFFF2C766));
      c.drawPath(_star(center, size * 0.55, size * 0.25), _p(0xFFFFE9A8));
    }
  }

  static Path _star(Offset center, double outer, double inner) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  // ------------------------------------------------------------------ Plantas

  /// Maceta en la parte baja de [r]; devuelve la boca (donde nace la planta).
  static Rect _pot(Canvas c, Rect r, int body, int rim) {
    final potH = r.height * 0.34;
    final top = r.bottom - potH;
    c.drawOval(
      Rect.fromCenter(
        center: Offset(r.center.dx, r.bottom),
        width: r.width * 0.9,
        height: r.height * 0.06,
      ),
      _p(0x2834283B),
    );
    final w = r.width * 0.78;
    final path = Path()
      ..moveTo(r.center.dx - w / 2, top + potH * 0.18)
      ..lineTo(r.center.dx + w / 2, top + potH * 0.18)
      ..lineTo(r.center.dx + w * 0.36, r.bottom)
      ..lineTo(r.center.dx - w * 0.36, r.bottom)
      ..close();
    c.drawPath(path, _p(body));
    final lip = Rect.fromLTWH(
      r.center.dx - w * 0.55,
      top,
      w * 1.1,
      potH * 0.24,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(lip, Radius.circular(potH * 0.08)),
      _p(rim),
    );
    return lip;
  }

  static void _fern(Canvas c, Rect r) {
    final mouth = _pot(c, r, 0xFFC97B5A, 0xFFDB9573);
    final root = Offset(mouth.center.dx, mouth.top + mouth.height * 0.3);
    final stem = _stroke(0xFF4E7A55, math.max(1.2, r.width * 0.035));
    final leaf = _p(0xFF7FAE7A);
    final leafDark = _p(0xFF5E8C61);
    const fronds = [-1.15, -0.65, -0.2, 0.2, 0.65, 1.15];
    for (var i = 0; i < fronds.length; i++) {
      final a = fronds[i];
      final len = r.height * (i == 2 || i == 3 ? 0.68 : 0.55);
      final tip = root + Offset(math.sin(a) * len, -math.cos(a) * len);
      final ctrl = root + Offset(math.sin(a) * len * 0.3, -len * 0.75);
      final path = Path()
        ..moveTo(root.dx, root.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, tip.dx, tip.dy);
      c.drawPath(path, stem);
      for (var k = 1; k <= 5; k++) {
        final u = k / 6;
        final p = _quad(root, ctrl, tip, u);
        final s = r.width * 0.09 * (1 - u * 0.6);
        for (final side in [-1.0, 1.0]) {
          c.drawOval(
            Rect.fromCenter(
              center: p + Offset(side * s * 0.8, s * 0.1),
              width: s * 1.5,
              height: s * 0.8,
            ),
            k.isEven ? leaf : leafDark,
          );
        }
      }
    }
  }

  static Offset _quad(Offset a, Offset b, Offset c, double u) => Offset(
    (1 - u) * (1 - u) * a.dx + 2 * (1 - u) * u * b.dx + u * u * c.dx,
    (1 - u) * (1 - u) * a.dy + 2 * (1 - u) * u * b.dy + u * u * c.dy,
  );

  static void _flowers(Canvas c, Rect r) {
    final mouth = _pot(c, r, 0xFFB8A6D9, 0xFFCDBFE6);
    final root = Offset(mouth.center.dx, mouth.top + mouth.height * 0.3);
    final stem = _stroke(0xFF5E8C61, math.max(1.2, r.width * 0.035));
    final leaf = _p(0xFF7FAE7A);
    const heads = [
      (-0.32, 0.58, 0xFFE8AAB6),
      (0.0, 0.7, 0xFFE0705A),
      (0.3, 0.55, 0xFFE9B657),
      (-0.14, 0.42, 0xFFF6D9DE),
      (0.18, 0.38, 0xFFD98C9C),
    ];
    for (final (dx, h, color) in heads) {
      final head = Offset(
        r.center.dx + dx * r.width,
        r.bottom - r.height * h - r.height * 0.3,
      );
      c.drawLine(root, head, stem);
      final mid = Offset.lerp(root, head, 0.5)!;
      c.drawOval(
        Rect.fromCenter(
          center: mid + Offset(dx >= 0 ? r.width * 0.05 : -r.width * 0.05, 0),
          width: r.width * 0.14,
          height: r.width * 0.07,
        ),
        leaf,
      );
      final pr = r.width * 0.075;
      for (var i = 0; i < 5; i++) {
        final a = i / 5 * math.pi * 2;
        c.drawCircle(
          head + Offset(math.cos(a) * pr, math.sin(a) * pr),
          pr * 0.8,
          _p(color),
        );
      }
      c.drawCircle(head, pr * 0.6, _p(0xFFFFF3C4));
    }
  }

  static void _cactus(Canvas c, Rect r) {
    final mouth = _pot(c, r, 0xFFE0705A, 0xFFEB8C78);
    final green = _p(0xFF7FAE7A);
    final w = r.width * 0.36;
    final body = Rect.fromLTRB(
      r.center.dx - w / 2,
      r.top + r.height * 0.12,
      r.center.dx + w / 2,
      mouth.top + mouth.height * 0.4,
    );
    // Brazos.
    final armW = w * 0.42;
    final left = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        body.left - armW * 1.35,
        body.top + body.height * 0.22,
        armW,
        body.height * 0.34,
      ),
      Radius.circular(armW / 2),
    );
    final right = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        body.right + armW * 0.35,
        body.top + body.height * 0.1,
        armW,
        body.height * 0.3,
      ),
      Radius.circular(armW / 2),
    );
    c.drawRRect(left, green);
    c.drawRRect(right, green);
    c.drawRect(
      Rect.fromLTWH(
        left.left + armW * 0.2,
        left.bottom - armW * 0.75,
        body.left - left.left,
        armW * 0.6,
      ),
      green,
    );
    c.drawRect(
      Rect.fromLTWH(
        body.right - armW * 0.2,
        right.bottom - armW * 0.75,
        right.right - body.right - armW * 0.1,
        armW * 0.6,
      ),
      green,
    );
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(w / 2)), green);
    // Costillas.
    final rib = _stroke(0xFF5E8C61, math.max(1, w * 0.04));
    c.drawLine(
      Offset(body.center.dx - w * 0.22, body.top + w * 0.5),
      Offset(body.center.dx - w * 0.22, body.bottom - w * 0.2),
      rib,
    );
    c.drawLine(
      Offset(body.center.dx + w * 0.22, body.top + w * 0.5),
      Offset(body.center.dx + w * 0.22, body.bottom - w * 0.2),
      rib,
    );
    // Cara sonriente.
    final face = Offset(body.center.dx, body.top + body.height * 0.36);
    c.drawCircle(face + Offset(-w * 0.16, 0), w * 0.06, _p(0xFF34283B));
    c.drawCircle(face + Offset(w * 0.16, 0), w * 0.06, _p(0xFF34283B));
    c.drawCircle(face + Offset(-w * 0.28, w * 0.14), w * 0.07, _p(0x66E8AAB6));
    c.drawCircle(face + Offset(w * 0.28, w * 0.14), w * 0.07, _p(0x66E8AAB6));
    c.drawArc(
      Rect.fromCenter(
        center: face + Offset(0, w * 0.08),
        width: w * 0.3,
        height: w * 0.22,
      ),
      0.2,
      math.pi - 0.4,
      false,
      _stroke(0xFF34283B, math.max(1, w * 0.05)),
    );
    // Flor en la cabeza.
    final top = Offset(body.center.dx, body.top + w * 0.05);
    for (var i = 0; i < 5; i++) {
      final a = i / 5 * math.pi * 2;
      c.drawCircle(
        top + Offset(math.cos(a) * w * 0.12, math.sin(a) * w * 0.12),
        w * 0.1,
        _p(0xFFE8AAB6),
      );
    }
    c.drawCircle(top, w * 0.08, _p(0xFFE9B657));
  }

  // ------------------------------------------------- Ampliación del catálogo

  static void _rugChecks(Canvas c, Rect r) {
    _rugShadow(c, r);
    final rr = RRect.fromRectAndRadius(r, Radius.circular(r.height * 0.18));
    c.save();
    c.clipRRect(rr);
    c.drawRect(r, _p(0xFFFFF3E2));
    const cols = 10, rows = 4;
    final cw = r.width / cols, ch = r.height / rows;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        if ((x + y).isEven) {
          c.drawRect(
            Rect.fromLTWH(r.left + x * cw, r.top + y * ch, cw + 0.5, ch + 0.5),
            _p(0xFF8FB89A),
          );
        }
      }
    }
    c.restore();
    c.drawRRect(rr, _stroke(0xFF5E8C61, r.height * 0.05));
  }

  static Path _cloudPath(Rect r) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(r.left, r.top + r.height * 0.3, r.right, r.bottom),
          Radius.circular(r.height * 0.35),
        ),
      );
    const bumps = [(0.22, 0.32), (0.45, 0.42), (0.7, 0.36)];
    for (final (fx, rad) in bumps) {
      path.addOval(
        Rect.fromCircle(
          center: Offset(r.left + fx * r.width, r.top + r.height * 0.42),
          radius: r.height * rad,
        ),
      );
    }
    return path;
  }

  static void _rugCloud(Canvas c, Rect r) {
    c.drawPath(_cloudPath(r.shift(Offset(0, r.height * 0.08))), _p(0x2234283B));
    c.drawPath(_cloudPath(r), _p(0xFFB9D3EC));
    c.drawPath(_cloudPath(r.deflate(r.height * 0.1)), _p(0xFFF2F7FC));
    // Gotitas de lluvia bordadas.
    final drop = _p(0xFF8FB3D9);
    for (var i = 0; i < 5; i++) {
      c.drawCircle(
        Offset(
          r.left + r.width * (0.2 + i * 0.15),
          r.center.dy + r.height * 0.15,
        ),
        r.height * 0.035,
        drop,
      );
    }
  }

  static void _rugPersian(Canvas c, Rect r) {
    _rugShadow(c, r);
    final outer = RRect.fromRectAndRadius(r, Radius.circular(r.height * 0.08));
    c.drawRRect(outer, _p(0xFF7A1F2B));
    final border = r.deflate(r.height * 0.09);
    c.drawRect(border, _p(0xFFE2B45A));
    final field = border.deflate(r.height * 0.06);
    c.drawRect(field, _p(0xFF9E2A36));
    c.drawRect(field.deflate(r.height * 0.05), _p(0xFF1F3F6E));
    // Medallón central y esquinas.
    final center = field.center;
    final med = Path()
      ..moveTo(center.dx - field.width * 0.22, center.dy)
      ..lineTo(center.dx, center.dy - field.height * 0.42)
      ..lineTo(center.dx + field.width * 0.22, center.dy)
      ..lineTo(center.dx, center.dy + field.height * 0.42)
      ..close();
    c.drawPath(med, _p(0xFFE2B45A));
    c.drawPath(
      Path()
        ..moveTo(center.dx - field.width * 0.13, center.dy)
        ..lineTo(center.dx, center.dy - field.height * 0.26)
        ..lineTo(center.dx + field.width * 0.13, center.dy)
        ..lineTo(center.dx, center.dy + field.height * 0.26)
        ..close(),
      _p(0xFF9E2A36),
    );
    c.drawCircle(center, field.height * 0.1, _p(0xFFFFF3E2));
    for (final corner in [
      field.topLeft,
      field.topRight,
      field.bottomLeft,
      field.bottomRight,
    ]) {
      c.drawCircle(corner, field.height * 0.18, _p(0xFFE2B45A));
    }
    // Flecos a los lados.
    final fringe = _stroke(0xFFF3E7CC, math.max(1, r.height * 0.025));
    for (var i = 1; i < 8; i++) {
      final y = r.top + r.height * i / 8;
      c.drawLine(Offset(r.left, y), Offset(r.left - r.height * 0.1, y), fringe);
      c.drawLine(
        Offset(r.right, y),
        Offset(r.right + r.height * 0.1, y),
        fringe,
      );
    }
  }

  static void _rainbow(Canvas c, Rect r) {
    const colors = [
      0xFFE0705A,
      0xFFE9B657,
      0xFFF2DC6B,
      0xFF8FB89A,
      0xFF6E8FD0,
      0xFFB8A6D9,
    ];
    final band = r.height / (colors.length + 2);
    final base = Offset(r.center.dx, r.bottom);
    for (var i = 0; i < colors.length; i++) {
      final radius = r.height - band * i - band / 2;
      c.drawArc(
        Rect.fromCircle(center: base, radius: radius),
        math.pi,
        math.pi,
        false,
        _stroke(colors[i], band)..strokeCap = StrokeCap.butt,
      );
    }
    // Nubes en los extremos.
    for (final x in [r.left + band * 2, r.right - band * 2]) {
      for (final (dx, dy, k) in const [
        (-1.0, 0.0, 1.0),
        (1.0, 0.0, 1.0),
        (0.0, -0.8, 1.2),
      ]) {
        c.drawCircle(
          Offset(x + dx * band, r.bottom - band + dy * band),
          band * 1.1 * k,
          _p(0xFFFFFCF6),
        );
      }
    }
  }

  static void _clock(Canvas c, Rect r) {
    final center = r.center;
    final radius = r.shortestSide / 2;
    c.drawCircle(
      center + Offset(radius * 0.06, radius * 0.08),
      radius,
      _p(0x2834283B),
    );
    c.drawCircle(center, radius, _p(0xFF8A5A3A));
    c.drawCircle(center, radius * 0.86, _p(0xFFFFF8E9));
    final tick = _stroke(0xFF5C354E, math.max(1, radius * 0.05));
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * math.pi * 2;
      final d = Offset(math.cos(a), math.sin(a));
      c.drawLine(
        center + d * radius * (i % 3 == 0 ? 0.62 : 0.7),
        center + d * radius * 0.78,
        tick,
      );
    }
    // Agujas con forma de hueso.
    void boneHand(double angle, double length, int color) {
      final d = Offset(math.sin(angle), -math.cos(angle));
      final tip = center + d * length;
      c.drawLine(center, tip, _stroke(color, radius * 0.08));
      final n = Offset(-d.dy, d.dx) * radius * 0.05;
      c.drawCircle(tip + n, radius * 0.06, _p(color));
      c.drawCircle(tip - n, radius * 0.06, _p(color));
    }

    boneHand(math.pi * 0.35, radius * 0.38, 0xFFC08A5A);
    boneHand(-math.pi * 0.6, radius * 0.58, 0xFFE2B47E);
    c.drawCircle(center, radius * 0.06, _p(0xFF5C354E));
  }

  /// Retrato con marco dorado; un destello recorre el marco con [t].
  static void _goldFrame(Canvas c, Rect r, double? t) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        r.shift(Offset(r.width * 0.04, r.width * 0.05)),
        Radius.circular(r.width * 0.05),
      ),
      _p(0x3034283B),
    );
    final outer = RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.05));
    c.drawRRect(
      outer,
      Paint()
        ..shader = Gradient.linear(
          r.topLeft,
          r.bottomRight,
          const [
            Color(0xFFFFE9A8),
            Color(0xFFD9A43A),
            Color(0xFF9C6B1E),
            Color(0xFFE9C060),
          ],
          const [0, 0.35, 0.7, 1],
        ),
    );
    // Bolitas del marco tallado.
    final bead = _p(0xFFFFE29A);
    for (var i = 0; i < 8; i++) {
      final k = (i + 0.5) / 8;
      for (final p in [
        Offset(r.left + r.width * k, r.top + r.width * 0.045),
        Offset(r.left + r.width * k, r.bottom - r.width * 0.045),
      ]) {
        c.drawCircle(p, r.width * 0.022, bead);
      }
    }
    final canvas = r.deflate(r.width * 0.12);
    c.drawRect(canvas, _p(0xFF2F4A5C));
    // Retrato: silueta de caniche con lazo, sobre fondo oscuro.
    final fur = _p(0xFFE2A066);
    final cx = canvas.center.dx;
    final w = canvas.width;
    c.drawOval(
      Rect.fromCenter(
        center: Offset(cx, canvas.bottom - w * 0.08),
        width: w * 0.8,
        height: w * 0.42,
      ),
      fur,
    );
    final head = Offset(cx, canvas.top + canvas.height * 0.42);
    c.drawCircle(head, w * 0.24, fur);
    c.drawCircle(head + Offset(0, -w * 0.2), w * 0.16, fur);
    for (final side in [-1.0, 1.0]) {
      c.drawOval(
        Rect.fromCenter(
          center: head + Offset(side * w * 0.25, w * 0.08),
          width: w * 0.18,
          height: w * 0.32,
        ),
        _p(0xFFC9884F),
      );
      c.drawCircle(
        head + Offset(side * w * 0.08, -w * 0.02),
        w * 0.025,
        _p(0xFF2B1D1F),
      );
    }
    c.drawCircle(head + Offset(0, w * 0.08), w * 0.035, _p(0xFF3A2526));
    // Brillo del marco.
    if (t != null) {
      final k = (t * 0.25) % 1.0;
      final p = Offset(r.left + r.width * k, r.top + r.height * (1 - k));
      c.drawCircle(
        p,
        r.width * 0.05,
        Paint()
          ..color = const Color(0xAAFFFFFF)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r.width * 0.03),
      );
    }
  }

  static void _sunflower(Canvas c, Rect r) {
    final mouth = _pot(c, r, 0xFF6E8FD0, 0xFF8FA9DC);
    final root = Offset(mouth.center.dx, mouth.top + mouth.height * 0.3);
    final head = Offset(r.center.dx, r.top + r.height * 0.2);
    c.drawLine(root, head, _stroke(0xFF4E7A55, math.max(1.5, r.width * 0.05)));
    for (final side in [-1.0, 1.0]) {
      final mid = Offset.lerp(root, head, side < 0 ? 0.45 : 0.62)!;
      c.drawOval(
        Rect.fromCenter(
          center: mid + Offset(side * r.width * 0.14, 0),
          width: r.width * 0.28,
          height: r.width * 0.12,
        ),
        _p(0xFF7FAE7A),
      );
    }
    final pr = r.width * 0.2;
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * math.pi * 2;
      c.drawOval(
        Rect.fromCenter(
          center: head + Offset(math.cos(a), math.sin(a)) * pr,
          width: pr * 0.7,
          height: pr * 0.7,
        ),
        _p(i.isEven ? 0xFFF2C43A : 0xFFE9B657),
      );
    }
    c.drawCircle(head, pr * 0.7, _p(0xFF6B4330));
    c.drawCircle(head, pr * 0.45, _p(0xFF8A5A3A));
  }

  static void _bonsai(Canvas c, Rect r) {
    // Bandeja baja en lugar de maceta.
    final tray = Rect.fromLTWH(
      r.left + r.width * 0.05,
      r.bottom - r.height * 0.14,
      r.width * 0.9,
      r.height * 0.14,
    );
    c.drawOval(
      Rect.fromCenter(
        center: Offset(r.center.dx, r.bottom),
        width: r.width,
        height: r.height * 0.05,
      ),
      _p(0x2834283B),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(tray, Radius.circular(tray.height * 0.3)),
      _p(0xFF5C354E),
    );
    final trunk = _stroke(0xFF7A5236, math.max(2, r.width * 0.09));
    final base = Offset(r.center.dx, tray.top);
    final bend = Offset(r.center.dx - r.width * 0.18, r.top + r.height * 0.55);
    final top = Offset(r.center.dx + r.width * 0.08, r.top + r.height * 0.32);
    c.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(bend.dx, bend.dy, top.dx, top.dy),
      trunk,
    );
    for (final (dx, dy, k) in const [
      (0.08, 0.26, 1.0),
      (-0.22, 0.4, 0.8),
      (0.3, 0.42, 0.75),
      (-0.02, 0.14, 0.7),
    ]) {
      final p = Offset(r.center.dx + dx * r.width, r.top + dy * r.height);
      c.drawOval(
        Rect.fromCenter(
          center: p,
          width: r.width * 0.42 * k,
          height: r.width * 0.24 * k,
        ),
        _p(0xFF5E8C61),
      );
      c.drawOval(
        Rect.fromCenter(
          center: p - Offset(0, r.width * 0.03 * k),
          width: r.width * 0.3 * k,
          height: r.width * 0.14 * k,
        ),
        _p(0xFF7FAE7A),
      );
    }
  }

  /// Árbol con luces de colores; parpadean con [t] (null: fijas).
  static void _lightsTree(Canvas c, Rect r, double? t) {
    final mouth = _pot(c, r, 0xFFB8433C, 0xFFD9675E);
    final apex = Offset(r.center.dx, r.top + r.height * 0.06);
    final bottom = mouth.top - r.height * 0.02;
    const tiers = 3;
    for (var i = 0; i < tiers; i++) {
      final y0 = apex.dy + (bottom - apex.dy) * i / tiers * 0.8;
      final y1 = apex.dy + (bottom - apex.dy) * (i + 1) / tiers;
      final half = r.width * (0.22 + 0.13 * i);
      c.drawPath(
        Path()
          ..moveTo(r.center.dx, y0)
          ..lineTo(r.center.dx + half, y1)
          ..lineTo(r.center.dx - half, y1)
          ..close(),
        _p(i.isEven ? 0xFF3F7D4F : 0xFF4E8C5C),
      );
    }
    c.drawPath(_star(apex, r.width * 0.09, r.width * 0.04), _p(0xFFF2C766));
    const bulbs = [0xFFE0705A, 0xFFF2C766, 0xFF6E8FD0, 0xFFE8AAB6, 0xFFFFF3C4];
    for (var i = 0; i < 14; i++) {
      final u = (i + 1) / 15;
      final y = apex.dy + (bottom - apex.dy) * u;
      final half = r.width * 0.5 * u * 0.95;
      final x = r.center.dx + half * math.sin(i * 2.3);
      final on = t == null ? 1.0 : 0.55 + 0.45 * math.sin(t * 3 + i * 1.3);
      final color = Color(bulbs[i % bulbs.length]);
      c.drawCircle(
        Offset(x, y),
        r.width * 0.06,
        Paint()
          ..color = color.withValues(alpha: 0.35 * on)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r.width * 0.03),
      );
      c.drawCircle(Offset(x, y), r.width * 0.03, Paint()..color = color);
    }
  }
}
