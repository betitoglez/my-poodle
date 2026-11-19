import 'dart:math' as math;
import 'dart:ui' hide TextStyle;

import 'package:flame/components.dart';
import 'package:flutter/animation.dart' show Curves;

import '../../domain/activities.dart';
import 'care_tools.dart';
import '../pet/appearance_catalog.dart';
import '../pet/pet_painter.dart';
import '../scenes/room_painter.dart';
import '../scenes/stage_game.dart';

// ======================================================================
// Cocina
// ======================================================================

/// Carga una imagen de atrezo; null si falta (se usa el dibujo vectorial).
Future<Image?> _prop(StageGame g, String path) async {
  try {
    return await g.images.load(path);
  } catch (_) {
    return null;
  }
}

mixin _CareToolArt on StageGame {
  Image? _toolAtlas;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _prop(this, 'props/care_tools.webp').then((atlas) => _toolAtlas = atlas);
  }

  void paintTool(
    Canvas canvas,
    CareTool tool,
    Offset at,
    double size,
    double time,
  ) => paintCareTool(canvas, tool, at, size, time, _toolAtlas);
}

void _drawImage(
  Canvas c,
  Image img,
  Rect dst, {
  Rect? clip,
  double opacity = 1,
}) {
  c.save();
  if (clip != null) c.clipRect(clip);
  c.drawImageRect(
    img,
    Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
    dst,
    Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Color.fromARGB((255 * opacity).round(), 255, 255, 255),
  );
  c.restore();
}

/// Cuenco gratuito y tres bocados. La masticación usa tiempo de juego, de
/// modo que la pausa también la detiene.
class FeedGame extends StageGame {
  FeedGame({
    required super.painter,
    required super.look,
    super.reducedMotion,
    super.onChanged,
    required this.activity,
  }) : super(room: RoomKind.kitchen, floorY: 0.66, petScale: 0.56);

  final FeedActivity activity;
  double _chewLeft = 0;
  double _visualElapsed = 0;
  bool _useLiveModel = false;
  void Function()? onBite;
  void Function()? onChewFrame;
  Image? _bowlFull;
  Image? _bowlEmpty;

  double get chewSeconds => reducedMotion ? 0.7 : 1.3;
  double get biteProgress =>
      _chewLeft > 0 ? (1 - _chewLeft / chewSeconds).clamp(0.0, 1.0) : 0;

  double get liveBowlFill => activity.chewing && biteProgress < 0.45
      ? activity.bowlFill + 1 / activity.total
      : activity.bowlFill;

  set useLiveModel(bool value) {
    _useLiveModel = value;
    pet.showSprite = !value;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Sin bloquear la escena: mientras llega, cuenco vectorial.
    _prop(this, 'props/bowl_full.webp').then((i) => _bowlFull = i);
    _prop(this, 'props/bowl_empty.webp').then((i) => _bowlEmpty = i);
    add(
      Painted((c) {
        if (!_useLiveModel) _bowl(c);
      }, priority: 5),
    );
    add(
      Painted((c) {
        if (_useLiveModel) return;
        final r = bowlRect;
        c.save();
        c.clipRect(
          Rect.fromLTRB(r.left, r.top + r.height * 0.5, r.right, r.bottom),
        );
        _bowl(c);
        c.restore();
      }, priority: 15),
    );
  }

  /// Cuenco delante de las patas: al comer, el hocico queda sobre él.
  Rect get bowlRect {
    final f = pet.position.toOffset();
    final w = pet.petSize * 0.45;
    final img = _bowlFull;
    final h = img == null ? w * 0.36 : w * img.height / img.width;
    return Rect.fromCenter(
      center:
          f +
          painter.landmark(
                PetPose.front,
                'mouth',
                anim: PetAnim.eat,
                ids: pet.look.ids,
              ) *
              pet.petSize +
          Offset(0, h * 0.12),
      width: w,
      height: h,
    );
  }

  void _bowl(Canvas c) {
    final r = bowlRect;
    final full = _bowlFull, empty = _bowlEmpty;
    if (full != null && empty != null) {
      c.drawOval(
        Rect.fromCenter(
          center: r.bottomCenter - Offset(0, r.height * 0.06),
          width: r.width * 0.9,
          height: r.height * 0.2,
        ),
        Paint()..color = const Color(0x3334283B),
      );
      _drawImage(c, empty, r);
      // La comida se recorta por arriba a tercios: el montón baja con cada bocado.
      final fill = activity.bowlFill;
      if (fill > 0) {
        final cut = r.top + (1 - fill) * r.height * 0.42;
        _drawImage(
          c,
          full,
          r,
          clip: Rect.fromLTRB(r.left, cut, r.right, r.bottom),
        );
      }
      return;
    }
    _vectorBowl(c, r);
  }

  void _vectorBowl(Canvas c, Rect r) {
    c.drawOval(
      r.translate(0, r.height * 0.3),
      Paint()..color = const Color(0x2234283B),
    );
    final fill = activity.bowlFill;
    if (fill > 0) {
      final mound = Rect.fromCenter(
        center:
            r.topCenter + Offset(0, r.height * 0.18 - fill * r.height * 0.22),
        width: r.width * (0.55 + 0.3 * fill),
        height: r.height * (0.25 + 0.55 * fill),
      );
      c.drawOval(mound, Paint()..color = const Color(0xFF9C6A3C));
    }
    final body = Path()
      ..moveTo(r.left, r.top + r.height * 0.2)
      ..lineTo(r.right, r.top + r.height * 0.2)
      ..quadraticBezierTo(
        r.right - r.width * 0.06,
        r.bottom,
        r.center.dx,
        r.bottom,
      )
      ..quadraticBezierTo(
        r.left + r.width * 0.06,
        r.bottom,
        r.left,
        r.top + r.height * 0.2,
      )
      ..close();
    c.drawPath(body, Paint()..color = const Color(0xFFC86F4A));
  }

  /// Intento de bocado (botón o toque en el cuenco).
  bool bite() {
    if (!activity.bite()) return false;
    _chewLeft = chewSeconds;
    _visualElapsed = 0;
    pet.react(PetAnim.eat, seconds: chewSeconds);
    onBite?.call();
    onChewFrame?.call();
    notify();
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_chewLeft > 0) {
      _chewLeft -= dt;
      if (_chewLeft <= 0) {
        activity.chewDone();
        if (activity.completed) pet.react(PetAnim.happy, seconds: 2);
        onChewFrame?.call();
        notify();
      } else {
        _visualElapsed += dt;
        if (_visualElapsed >= 1 / 30) {
          _visualElapsed = 0;
          onChewFrame?.call();
        }
      }
    }
  }

  @override
  void tapAt(Offset p) {
    if (bowlRect.inflate(16).contains(p)) bite();
  }
}

// ======================================================================
// Baño
// ======================================================================

class BathGame extends StageGame with _CareToolArt {
  BathGame({
    required super.painter,
    required super.look,
    super.reducedMotion,
    super.onChanged,
    required this.activity,
  }) : super(room: RoomKind.bath, floorY: 0.7, petScale: 0.56);

  final BathActivity activity;
  double _waterLeft = 0;
  bool _holding = false;
  bool _awaitFreshGesture = false;
  bool _useLiveModel = false;
  Offset? _toolAt;
  List<Offset>? _liveTargets;

  set useLiveModel(bool value) {
    _useLiveModel = value;
    pet.showSprite = !value;
  }

  void setLiveTargets(List<Offset> targets) {
    _liveTargets = targets;
    notify();
  }

  void holdTool() {
    _awaitFreshGesture = false;
    _holding = true;
    _toolAt = null;
  }

  void releaseTool() {
    _awaitFreshGesture = false;
    _holding = false;
    _toolAt = null;
    if (_useLiveModel) notify();
  }

  void pressAt(Offset p) {
    _awaitFreshGesture = false;
    _toolAt = p;
    _holding = _insidePet(p);
    if (_useLiveModel) notify();
  }

  bool _insidePet(Offset p) => _useLiveModel
      ? BathZone.values.any(
          (z) => (_markerCenter(z) - p).distance < pet.petSize * 0.23,
        )
      : pet.hits(p);

  void Function(BathZone zone)? onSoap;
  void Function()? onBathFrame;
  Image? _tubImg;
  Image? _foamImg;

  /// Altura (fracción) del labio delantero en la imagen de la bañera.
  static const double _rim = 0.17;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Sin bloquear la escena: mientras llegan, bañera y espuma vectoriales.
    _prop(this, 'props/tub.webp').then((i) => _tubImg = i);
    _prop(this, 'props/foam.webp').then((i) {
      _foamImg = i;
      _refreshFx();
    });
    add(
      Painted((c) {
        if (!_useLiveModel) _tubBack(c);
      }, priority: 5),
    );
    add(
      Painted((c) {
        if (!_useLiveModel) _foreground(c);
      }, priority: 15),
    );
    _refreshFx();
  }

  /// Bañera alrededor del caniche: el agua le llega por los tobillos.
  Rect get _tub {
    final f = pet.position.toOffset();
    final w = pet.petSize * 1.3;
    final img = _tubImg;
    final h = img == null ? pet.petSize * 0.36 : w * img.height / img.width;
    final rimY = f.dy - pet.petSize * 0.1;
    return Rect.fromLTWH(f.dx - w / 2, rimY - h * _rim, w, h);
  }

  double get _rimY => _tub.top + _tub.height * _rim;

  void _tubBack(Canvas c) {
    final img = _tubImg;
    if (img != null) {
      _drawImage(c, img, _tub);
      return;
    }
    final r = _tub;
    c.drawOval(
      Rect.fromLTWH(r.left, r.top - r.height * 0.25, r.width, r.height * 0.5),
      Paint()..color = const Color(0xFFBFD8EC),
    );
  }

  void _foreground(Canvas c) {
    final r = _tub;
    final img = _tubImg;
    if (img != null) {
      // Frente de la bañera por delante de las patas.
      _drawImage(
        c,
        img,
        r,
        clip: Rect.fromLTRB(r.left - 2, _rimY, r.right + 2, r.bottom + 2),
      );
    } else {
      final front = RRect.fromRectAndCorners(
        r,
        bottomLeft: Radius.circular(r.height * 0.8),
        bottomRight: Radius.circular(r.height * 0.8),
      );
      c.drawRRect(front, Paint()..color = const Color(0xFFFBF7F2));
    }
    // Espuma ilustrada estampada en cada zona enjabonada.
    final foam = _foamImg;
    if (foam != null) {
      for (final z in BathZone.values) {
        final f = activity.foam(z);
        if (f <= 0) continue;
        for (final (i, center) in _zoneCenters(z).indexed) {
          final w =
              pet.petSize * (z == BathZone.paws ? 0.32 : 0.2) * (0.6 + 0.4 * f);
          final h = w * foam.height / foam.width;
          final jitter = Offset((i.isEven ? -1 : 1) * w * 0.08, 0);
          _drawImage(
            c,
            foam,
            Rect.fromCenter(center: center + jitter, width: w, height: h),
            opacity: 0.95,
          );
        }
      }
    }
    if (_holding || _toolAt != null) {
      final at = _toolAt ?? pet.landmarkScene('headTop');
      final dry = activity.phase == BathPhase.dry;
      paintTool(
        c,
        activity.phase == BathPhase.soap
            ? CareTool.sponge
            : dry
            ? CareTool.dryer
            : CareTool.shower,
        at,
        38,
        time,
      );
      if (dry) {
        for (var i = 0; i < 4; i++) {
          final y = at.dy + i * 9;
          c.drawArc(
            Rect.fromLTWH(at.dx - 30, y, 60, 12),
            0,
            math.pi,
            false,
            Paint()
              ..color = const Color(0xAFFFF2CE)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
        }
      }
    }
    // Agua de la ducha al mojar o aclarar: trazos translúcidos.
    if (_waterLeft > 0) {
      final top = Offset(
        pet.position.x + pet.petSize * 0.28,
        pet.position.y - pet.petSize * 1.25,
      );
      final k = (_waterLeft).clamp(0.0, 1.0);
      for (var i = 0; i < 12; i++) {
        final phase = (time * 1.8 + i * 0.17) % 1;
        final x = top.dx - pet.petSize * (0.05 + i * 0.03);
        final y0 = top.dy + phase * pet.petSize * 0.9;
        c.drawLine(
          Offset(x, y0),
          Offset(x - pet.petSize * 0.02, y0 + pet.petSize * 0.12),
          Paint()
            ..color = Color.fromARGB((120 * k).round(), 220, 238, 250)
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    _paintZoneMarkers(c);
  }

  void paintLiveOverlay(Canvas c) {
    _paintZoneMarkers(c);
    if (!_holding && _toolAt == null) return;
    final phase = activity.phase;
    if (phase == BathPhase.done) return;
    final at = _toolAt ?? _markerCenter(BathZone.back);
    if (phase == BathPhase.soap) {
      paintTool(c, CareTool.sponge, at + const Offset(10, -13), 46, time);
      return;
    }
    final dry = phase == BathPhase.dry;
    final source = dry ? at - const Offset(68, 4) : at + const Offset(12, -65);
    paintTool(c, dry ? CareTool.dryer : CareTool.shower, source, 48, time);
    if (!_holding) return;
    for (var i = 0; i < (dry ? 7 : 15); i++) {
      final t = (time * 2.5 + i * 0.17) % 1;
      final start = source + (dry ? const Offset(27, 0) : const Offset(8, 12));
      final end = at + Offset((i % 5 - 2) * (dry ? 3 : 8), (i % 3 - 1) * 7);
      final p = Offset.lerp(start, end, t)!;
      c.drawLine(
        p,
        Offset.lerp(p, end, 0.19)!,
        Paint()
          ..color = dry ? const Color(0xDCF6DBAA) : const Color(0xDA9BDDFA)
          ..strokeWidth = dry ? 2.7 : 2.3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // Marcas de zona durante el enjabonado (forma + texto, no solo color).
  void _paintZoneMarkers(Canvas c) {
    if (activity.phase == BathPhase.soap) {
      for (final z in BathZone.values) {
        final done = activity.zoneDone(z);
        final center = _markerCenter(z);
        final ring = Paint()
          ..color = done ? const Color(0xFF375E50) : const Color(0xFF5C354E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        final pulse = done || reducedMotion ? 0.0 : math.sin(time * 4) * 3;
        c.drawCircle(center, pet.petSize * 0.07 + pulse, ring);
        if (done) {
          c.drawCircle(center, 9, Paint()..color = const Color(0xFF375E50));
          sceneText(
            '✓',
            13,
            const Color(0xFFFFFFFF),
          ).paint(c, center - const Offset(4.5, 8));
        }
      }
    }
  }

  /// Puntos de cada zona según el caniche dibujado (atlas o vectorial).
  List<Offset> _zoneCenters(BathZone z) {
    final targets = _liveTargets;
    if (_useLiveModel && targets != null) {
      final target = targets[z.index];
      return [Offset(target.dx * size.x, target.dy * size.y)];
    }
    return switch (z) {
      BathZone.back => [
        pet.landmarkScene('flankLeft'),
        pet.landmarkScene('flankRight'),
      ],
      BathZone.head => [
        pet.landmarkScene('headTop') + Offset(0, pet.petSize * 0.1),
      ],
      BathZone.chest => [pet.landmarkScene('chest')],
      BathZone.paws => [Offset(pet.landmarkScene('paws').dx, _rimY)],
    };
  }

  Offset _markerCenter(BathZone z) => _zoneCenters(z).last;

  BathZone? zoneAt(Offset p) {
    BathZone? best;
    var bestD = pet.petSize * 0.17;
    for (final z in BathZone.values) {
      for (final c in _zoneCenters(z)) {
        final d = (p - c).distance;
        if (d < bestD) {
          bestD = d;
          best = z;
        }
      }
    }
    return best;
  }

  void _refreshFx() {
    pet.fx = PetFx(
      sick: pet.fx.sick,
      hygiene: activity.phase == BathPhase.done ? 100 : pet.fx.hygiene,
      wet:
          activity.phase == BathPhase.soap ||
          activity.phase == BathPhase.rinse ||
          activity.phase == BathPhase.dry,
      // Con espuma ilustrada la estampa la escena; si no, el pintor.
      foam: _foamImg != null
          ? const [0, 0, 0]
          : [for (final z in BathZone.values) activity.foam(z)],
    );
    onBathFrame?.call();
  }

  bool wet([double seconds = 0.1]) {
    if (!activity.wet(seconds)) return false;
    _waterLeft = reducedMotion ? 0.5 : 1.0;
    _refreshFx();
    notify();
    return true;
  }

  bool soap(BathZone z, [double amount = 0.15]) {
    if (!activity.soap(z, amount)) return false;
    if (activity.phase != BathPhase.soap) _finishToolGesture();
    _refreshFx();
    onSoap?.call(z);
    notify();
    return true;
  }

  bool rinse([double seconds = 0.1]) {
    if (!activity.rinse(seconds)) return false;
    _waterLeft = reducedMotion ? 0.5 : 1.0;
    pet.react(PetAnim.bath, seconds: 1.2);
    _refreshFx();
    notify();
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_waterLeft > 0) _waterLeft -= dt;
    if (_holding) {
      final phase = activity.phase;
      switch (phase) {
        case BathPhase.wet:
          wet(dt);
        case BathPhase.rinse:
          rinse(dt);
        case BathPhase.dry:
          activity.dry(dt);
          _refreshFx();
          notify();
        case BathPhase.soap || BathPhase.done:
          break;
      }
      // A new phase always needs a new gesture.
      if (phase != activity.phase) _finishToolGesture();
    }
  }

  void _finishToolGesture() {
    _holding = false;
    _toolAt = null;
    _awaitFreshGesture = true;
  }

  @override
  void tapAt(Offset p) {
    if (_awaitFreshGesture) return;
    if (activity.phase == BathPhase.soap) {
      final z = zoneAt(p);
      if (z != null) soap(z);
    }
  }

  @override
  void dragAt(Offset p, Offset delta) {
    if (_awaitFreshGesture) return;
    _toolAt = p;
    _holding = _insidePet(p);
    if (_useLiveModel) notify();
    if (activity.phase != BathPhase.soap) return;
    final z = zoneAt(p);
    if (z != null) soap(z, delta.distance / (pet.petSize * 1.5));
  }
}

// ======================================================================
// Paseo
// ======================================================================

class WalkGame extends StageGame {
  WalkGame({
    required super.painter,
    required super.look,
    super.reducedMotion,
    super.onChanged,
    required this.activity,
  }) : super(room: null, floorY: 0.8, petScale: 0.42, pose: PetPose.side);

  final WalkActivity activity;
  double petWorldX = 0;
  double camX = 0;
  double _layoutWidth = 0;
  double _sniffLeft = 0;
  bool _useLiveModel = false;
  Image? _panorama;
  void Function()? onSniff;
  void Function()? onWalkFrame;

  set useLiveModel(bool value) {
    _useLiveModel = value;
    pet.showSprite = !value;
  }

  double get _sniffSeconds => reducedMotion ? 0.6 : 1.45;

  List<double> get liveWalkFrame => [
    size.x == 0 ? 0.22 : petWorldX / size.x,
    size.x == 0 ? 0 : camX / size.x,
    activity.phase == WalkPhase.moving ? 1 : 0,
    activity.phase == WalkPhase.sniffing ? 1 - _sniffLeft / _sniffSeconds : -1,
  ];

  static const stopNames = ['Flores', 'Banco', 'Fuente'];

  double get groundY => size.y * 0.8;
  double stopX(int i) => size.x * (0.82 + i * 0.85);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    petWorldX = size.x * 0.22;
    _prop(this, 'scenes/orchard.jpg').then((image) => _panorama = image);
    add(
      Painted((c) {
        if (_useLiveModel) {
          _landscape(c);
        } else {
          _world(c);
        }
      }, priority: 0),
    );
    add(
      Painted((c) {
        if (!_useLiveModel) paintMarkers(c);
      }, priority: 15),
    );
  }

  @override
  void layoutPet() {
    pet.petSize = math.min(size.y * petScale, size.x * 0.42);
    pet.position = Vector2(petWorldX - camX, size.y * 0.82);
  }

  @override
  void onGameResize(Vector2 size) {
    if (_layoutWidth > 0) {
      petWorldX *= size.x / _layoutWidth;
      camX *= size.x / _layoutWidth;
    }
    _layoutWidth = size.x;
    super.onGameResize(size);
  }

  void _landscape(Canvas c) {
    final image = _panorama;
    if (image == null) {
      c.drawColor(const Color(0xFFA2C9E7), BlendMode.src);
      return;
    }
    final w = image.width.toDouble(), h = image.height.toDouble();
    final pan = (camX / size.x * 0.08).clamp(0.0, 0.15);
    c.drawImageRect(
      image,
      Rect.fromLTWH(w * (0.11 + pan), h * 0.12, w * 0.74, h * 0.63),
      Rect.fromLTWH(0, 0, size.x, size.y * 0.78),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  void _world(Canvas c) {
    final w = size.x, h = size.y;
    c.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = Gradient.linear(Offset.zero, Offset(0, h * 0.6), [
          const Color(0xFF9CC9EE),
          const Color(0xFFEAF2DE),
        ]),
    );
    // Colinas con paralaje.
    final hill = Paint()..color = const Color(0xFFA8C38C);
    for (var i = -1; i < 6; i++) {
      final x = i * w * 0.7 - (camX * 0.3) % (w * 0.7);
      c.drawOval(Rect.fromLTWH(x, h * 0.42, w * 0.9, h * 0.4), hill);
    }
    final near = Paint()..color = const Color(0xFF84A86E);
    for (var i = -1; i < 8; i++) {
      final x = i * w * 0.55 - (camX * 0.6) % (w * 0.55);
      c.drawOval(Rect.fromLTWH(x, h * 0.55, w * 0.7, h * 0.35), near);
      // Ciprés.
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x + w * 0.2, h * 0.52),
          width: 10,
          height: h * 0.14,
        ),
        Paint()..color = const Color(0xFF3F6A4A),
      );
    }
    // Sendero empedrado.
    final path = Rect.fromLTWH(0, h * 0.74, w, h * 0.16);
    c.drawRect(path, Paint()..color = const Color(0xFFE2D3B5));
    final stone = Paint()..color = const Color(0xFFCDBB98);
    for (var i = 0; i < 40; i++) {
      final x = (i * 37.0 - camX) % (w + 40) - 20;
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x, h * (0.77 + (i % 3) * 0.04)),
          width: 22,
          height: 9,
        ),
        stone,
      );
    }
    c.drawRect(
      Rect.fromLTWH(0, h * 0.9, w, h * 0.1),
      Paint()..color = const Color(0xFF7FA06A),
    );
    // Lavanda en el borde.
    for (var i = 0; i < 24; i++) {
      final x = (i * 53.0 - camX * 1.0) % (w + 60) - 30;
      c.drawOval(
        Rect.fromCenter(center: Offset(x, h * 0.92), width: 8, height: 22),
        Paint()..color = const Color(0xFF9A7CC8),
      );
    }
    // Paradas.
    for (var i = 0; i < 3; i++) {
      final x = stopX(i) - camX + 40;
      if (x < -120 || x > w + 120) continue;
      _stopProp(c, i, Offset(x, h * 0.76));
    }
  }

  void _stopProp(Canvas c, int i, Offset base) {
    switch (i) {
      case 0:
        const colors = [0xFFF2A7B5, 0xFFFFFFFF, 0xFFE58FA0, 0xFFF6C7D0];
        for (var k = 0; k < 8; k++) {
          c.drawCircle(
            base + Offset((k - 4) * 9.0, -16.0 - (k % 3) * 9),
            9,
            Paint()..color = Color(colors[k % 4]),
          );
        }
        c.drawRect(
          Rect.fromCenter(
            center: base + const Offset(0, -4),
            width: 80,
            height: 10,
          ),
          Paint()..color = const Color(0xFF6B8A57),
        );
      case 1:
        final wood = Paint()..color = const Color(0xFF9A6B3F);
        c.drawRect(Rect.fromLTWH(base.dx - 45, base.dy - 34, 90, 10), wood);
        c.drawRect(Rect.fromLTWH(base.dx - 45, base.dy - 56, 90, 8), wood);
        c.drawRect(Rect.fromLTWH(base.dx - 40, base.dy - 26, 7, 26), wood);
        c.drawRect(Rect.fromLTWH(base.dx + 33, base.dy - 26, 7, 26), wood);
      case 2:
        c.drawOval(
          Rect.fromCenter(
            center: base + const Offset(0, -10),
            width: 96,
            height: 30,
          ),
          Paint()..color = const Color(0xFFBFB6A6),
        );
        c.drawOval(
          Rect.fromCenter(
            center: base + const Offset(0, -14),
            width: 80,
            height: 18,
          ),
          Paint()..color = const Color(0xFF8FC7E8),
        );
        c.drawRect(
          Rect.fromCenter(
            center: base + const Offset(0, -38),
            width: 14,
            height: 40,
          ),
          Paint()..color = const Color(0xFFBFB6A6),
        );
        final k = (time * 1.5) % 1;
        c.drawCircle(
          base + Offset(0, -60 + k * 8),
          6,
          Paint()..color = const Color(0xAA8FC7E8),
        );
    }
  }

  void paintMarkers(Canvas c) {
    for (var i = 0; i < 3; i++) {
      final center = _markerCenter(i);
      if (center.dx < -60 || center.dx > size.x + 60) continue;
      final done = i < activity.done;
      final enabled =
          activity.enabledStop == i ||
          (activity.phase == WalkPhase.atStop && activity.done == i);
      final r = 22.0 + (enabled && !reducedMotion ? math.sin(time * 5) * 3 : 0);
      c.drawCircle(
        center,
        r,
        Paint()
          ..color = done
              ? const Color(0xFF375E50)
              : (enabled ? const Color(0xFFFFF8E9) : const Color(0x88FFF8E9)),
      );
      c.drawCircle(
        center,
        r,
        Paint()
          ..color = enabled ? const Color(0xFF5C354E) : const Color(0xFF8F8597)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      // Huella (forma) o marca de hecho.
      if (done) {
        sceneText(
          '✓',
          20,
          const Color(0xFFFFFFFF),
        ).paint(c, center - const Offset(7, 13));
      } else {
        final paw = Paint()
          ..color = enabled ? const Color(0xFF5C354E) : const Color(0xFF8F8597);
        c.drawOval(
          Rect.fromCenter(
            center: center + const Offset(0, 4),
            width: 14,
            height: 11,
          ),
          paw,
        );
        for (var k = 0; k < 4; k++) {
          c.drawCircle(
            center + Offset(-9.0 + k * 6, -6.0 - (k == 1 || k == 2 ? 3 : 0)),
            3,
            paw,
          );
        }
      }
      final label = sceneText(stopNames[i], 13, const Color(0xFF34283B));
      label.paint(c, center + Offset(-label.width / 2, r + 4));
    }
  }

  Offset _markerCenter(int stop) {
    final x = stopX(stop) - camX;
    final reachable = stop == activity.enabledStop && size.x > 74;
    return Offset(reachable ? x.clamp(36, size.x - 36) : x, size.y * 0.87);
  }

  bool goTo(int stop) {
    if (!activity.tapStop(stop)) return false;
    pet.baseAnim = PetAnim.trot;
    notify();
    return true;
  }

  bool sniff() {
    if (!activity.beginSniff()) return false;
    _sniffLeft = _sniffSeconds;
    pet.baseAnim = PetAnim.sniff;
    onSniff?.call();
    notify();
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final speed = reducedMotion ? size.x * 1.15 : size.x * 0.42;
    if (activity.phase == WalkPhase.moving) {
      final target = stopX(activity.done) - pet.petSize * 0.45;
      petWorldX = math.min(target, petWorldX + speed * dt);
      if (petWorldX >= target) {
        activity.arrived();
        pet.baseAnim = PetAnim.idle;
        notify();
      }
    } else if (activity.phase == WalkPhase.sniffing) {
      _sniffLeft -= dt;
      if (_sniffLeft <= 0) {
        activity.sniffDone();
        pet.baseAnim = PetAnim.idle;
        if (activity.completed) pet.react(PetAnim.happy, seconds: 2);
        notify();
      }
    }
    final targetCam = math.max(0.0, petWorldX - size.x * 0.3);
    camX = reducedMotion
        ? targetCam
        : camX + (targetCam - camX) * math.min(1, dt * 4);
    pet.position = Vector2(petWorldX - camX, size.y * 0.82);
    if (_useLiveModel) onWalkFrame?.call();
  }

  @override
  void tapAt(Offset p) {
    final atStop = activity.phase == WalkPhase.atStop;
    final stop = atStop ? activity.done : activity.enabledStop;
    if (stop == null) return;
    final center = _markerCenter(stop);
    // El destino activo o su objeto en el sendero.
    if ((p - center).distance < 56 ||
        ((p.dx - (center.dx + 40)).abs() < 60 && p.dy > size.y * 0.55)) {
      if (atStop) {
        sniff();
      } else {
        goTo(stop);
      }
    }
  }
}

// ======================================================================
// Peluquería
// ======================================================================

class GroomGame extends StageGame with _CareToolArt {
  GroomGame({
    required super.painter,
    required super.look,
    super.reducedMotion,
    super.onChanged,
    required this.activity,
  }) : super(
         room: RoomKind.salon,
         floorY: 0.72,
         petX: 0.36,
         petScale: 0.58,
         anim: PetAnim.brush,
       ) {
    _refresh();
  }

  final GroomActivity activity;
  void Function(Strand s)? onBrushed;
  void Function()? onGroomFrame;
  Offset? _toolPoint;
  List<Offset>? _liveTargets;
  bool _useLiveModel = false;
  bool _awaitFreshGesture = false;

  set useLiveModel(bool value) {
    _useLiveModel = value;
    pet.showSprite = !value;
  }

  void setLiveTargets(List<Offset> targets) {
    _liveTargets = targets;
    notify();
  }

  void pressAt(Offset point) {
    _awaitFreshGesture = false;
    _toolPoint = point;
    if (_useLiveModel) notify();
  }

  void releaseTool() {
    _toolPoint = null;
    if (_useLiveModel) notify();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(
      Painted((c) {
        if (!_useLiveModel) _mirror(c);
      }, priority: 5),
    );
    add(
      Painted((c) {
        if (!_useLiveModel) paintTools(c);
      }, priority: 15),
    );
  }

  void _mirror(Canvas c) {
    final art = roomArt?.mirror;
    final glass = art == null ? null : imageFraction(art);
    if (glass == null) {
      _vectorMirror(c);
      return;
    }
    // Reflejo en el espejo pintado: el caniche de perfil, más pequeño y
    // apagado, mirando hacia la sala.
    c.save();
    c.clipPath(Path()..addOval(glass.deflate(glass.width * 0.06)));
    c.saveLayer(glass, Paint()..color = const Color(0xBFFFFFFF));
    c.translate(glass.center.dx, glass.top + glass.height * 0.86);
    c.scale(-1, 1);
    painter.paint(
      c,
      pet.look,
      pose: PetPose.side,
      anim: pet.anim == PetAnim.happy ? PetAnim.happy : PetAnim.idle,
      t: time,
      size: glass.height * 0.42,
      reducedMotion: reducedMotion,
      fx: pet.fx,
    );
    c.restore();
    // Brillo del cristal.
    c.drawRect(
      glass,
      Paint()
        ..shader = Gradient.linear(
          glass.topLeft,
          glass.bottomRight,
          [
            const Color(0x33FFFFFF),
            const Color(0x00FFFFFF),
            const Color(0x22FFF3D6),
          ],
          [0, 0.55, 1],
        ),
    );
    c.restore();
  }

  void _vectorMirror(Canvas c) {
    final s = size.toSize();
    RoomPainter.paintSalonMirror(c, s, floorY);
    final r = RoomPainter.salonMirror(s, floorY).deflate(10);
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(r, Radius.circular(r.width / 2)));
    c.translate(r.center.dx, r.bottom - r.height * 0.06);
    c.scale(-1, 1);
    painter.paint(
      c,
      pet.look,
      pose: PetPose.front,
      anim: pet.anim,
      t: time,
      size: math.min(r.height * 0.75, r.width * 1.3),
      reducedMotion: reducedMotion,
      fx: pet.fx,
    );
    c.restore();
  }

  /// Centros de cada mechón según el caniche dibujado (atlas o vectorial).
  List<Offset> _strandCenters(Strand s) {
    final targets = _liveTargets;
    if (_useLiveModel && targets != null) {
      final target = targets[s.index];
      return [Offset(target.dx * size.x, target.dy * size.y)];
    }
    return switch (s) {
      Strand.forelock => [pet.landmarkScene('headTop')],
      Strand.ears => [
        pet.landmarkScene('earRight'),
        pet.landmarkScene('earLeft'),
      ],
      Strand.back => [
        pet.landmarkScene('shoulderLeft'),
        pet.landmarkScene('shoulderRight'),
      ],
    };
  }

  Offset _strandCenter(Strand s) => _strandCenters(s).first;

  void paintTools(Canvas c) {
    final point = _toolPoint;
    if (point != null && !activity.completed) {
      final tool = switch (activity.tool) {
        GroomTool.comb => CareTool.comb,
        GroomTool.scissors => CareTool.scissors,
        GroomTool.dryer => CareTool.dryer,
      };
      if (_useLiveModel) {
        final toolAt = point + const Offset(36, -22);
        paintTool(c, tool, toolAt, 56, time);
        if (activity.tool == GroomTool.dryer && strandAt(point) != null) {
          final air = Paint()
            ..color = const Color(0xC9FFF4D4)
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round;
          for (var i = 0; i < 3; i++) {
            c.drawLine(
              point + Offset(12, (i - 1) * 7 - 6),
              point + Offset(-5, (i - 1) * 11),
              air,
            );
          }
        }
      } else {
        paintTool(c, tool, point, 38, time);
      }
    }
    for (final s in Strand.values) {
      final center = _strandCenter(s);
      final done = activity.strandDone(s);
      if (done) {
        c.drawCircle(center, 10, Paint()..color = const Color(0xFF375E50));
        sceneText(
          '✓',
          13,
          const Color(0xFFFFFFFF),
        ).paint(c, center - const Offset(4.5, 8));
        continue;
      }
      final pulse = reducedMotion ? 0.0 : math.sin(time * 4 + s.index) * 3;
      c.drawCircle(
        center,
        pet.petSize * 0.08 + pulse,
        Paint()
          ..color = const Color(0xFF5C354E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      // Progreso parcial del mechón como arco.
      final prog = activity.brushed(s);
      if (prog > 0) {
        c.drawArc(
          Rect.fromCircle(center: center, radius: pet.petSize * 0.08 + 6),
          -math.pi / 2,
          prog * 2 * math.pi,
          false,
          Paint()
            ..color = const Color(0xFF375E50)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
      }
    }
  }

  void _refresh() {
    pet.fx = PetFx(
      sick: pet.fx.sick,
      messy: [
        for (final s in Strand.values)
          activity.strandDone(s) ? 0 : 1 - activity.brushed(s) * 0.6,
      ],
    );
  }

  Strand? strandAt(Offset p) {
    Strand? best;
    var bestD = pet.petSize * 0.16;
    for (final s in Strand.values) {
      for (final center in _strandCenters(s)) {
        final d = (p - center).distance;
        if (d < bestD) {
          bestD = d;
          best = s;
        }
      }
    }
    return best;
  }

  bool brush(Strand s, [double amount = 0.15]) {
    final tool = activity.tool;
    if (!activity.brush(s, amount)) return false;
    if (tool != activity.tool) {
      _awaitFreshGesture = true;
      _toolPoint = null;
    }
    _refresh();
    if (activity.strandProgress(tool, s) >= 1) {
      onBrushed?.call(s);
      if (activity.completed) pet.react(PetAnim.happy, seconds: 2);
    }
    onGroomFrame?.call();
    notify();
    return true;
  }

  @override
  void tapAt(Offset p) {
    if (_awaitFreshGesture) return;
    final s = strandAt(p);
    _toolPoint = p;
    if (s != null) brush(s);
  }

  @override
  void dragAt(Offset p, Offset delta) {
    if (_awaitFreshGesture) return;
    final s = strandAt(p);
    _toolPoint = p;
    final changed = s != null && brush(s, delta.distance / (pet.petSize * 1.5));
    if (!changed && _useLiveModel) notify();
  }
}

// ======================================================================
// Dormir
// ======================================================================

/// Llevarlo a su cama, arroparlo, apagar la luz y dejarlo dormir. El sueño
/// cuenta con tiempo de juego, de modo que la pausa también lo detiene.
class SleepGame extends StageGame {
  SleepGame({
    required super.painter,
    required super.look,
    super.reducedMotion,
    super.onChanged,
    required this.activity,
  }) : super(
         room: RoomKind.living,
         floorY: 0.74,
         petX: 0.24,
         petScale: 0.5,
         pose: PetPose.side,
       );

  final SleepActivity activity;
  final bed = BedProp();
  Image? _blanketImg;
  double? _bedPetSize;
  double _walkT = 0;
  bool _walking = false;
  double _startX = 0;
  double _blanket = 0;
  double _dark = 0;
  double _sleepLeft = 0;
  bool _useLiveModel = false;
  Rect? _liveBedBounds;
  void Function()? onStep;
  void Function()? onSleepFrame;

  set useLiveModel(bool value) {
    _useLiveModel = value;
    pet.showSprite = !value;
  }

  void setLiveBedBounds(Rect bounds) => _liveBedBounds = bounds;

  List<double> get liveSleepFrame => [_walkT.clamp(0.0, 1.0), _blanket, _dark];

  double get _walkSeconds => reducedMotion ? 0.2 : 1.3;
  double get _sleepSeconds => reducedMotion ? 1.5 : 4.5;

  Offset get _bedFeet =>
      Offset(size.x * 0.64, size.y * (floorY + (1 - floorY) * 0.55));
  Rect get _bedRect => bed.rect(_bedFeet, _bedPetSize ?? pet.petSize);

  /// ¿Ha llegado a la cama y se puede arropar?
  bool get atBed => !_walking && activity.phase != SleepPhase.toBed;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _startX = pet.position.x;
    _bedPetSize = pet.petSize;
    bed.load(this);
    _prop(this, 'props/blanket.webp').then((i) => _blanketImg = i);
    add(
      Painted((c) {
        if (!_useLiveModel) bed.paintBack(c, _bedRect);
      }, priority: 5),
    );
    add(
      Painted((c) {
        if (!_useLiveModel) {
          bed.paintFront(c, _bedRect);
          _blanketLayer(c);
        }
      }, priority: 15),
    );
    add(Painted(_night, priority: 30));
  }

  /// Paso 1: lo lleva a su cama.
  bool goToBed() {
    if (!activity.advance(SleepPhase.toBed)) return false;
    _walking = true;
    _walkT = 0;
    pet.setView(PetView.right);
    pet.baseAnim = PetAnim.trot;
    notify();
    return true;
  }

  /// Paso 2: lo arropa.
  bool tuckIn() {
    if (!atBed || !activity.advance(SleepPhase.blanket)) return false;
    notify();
    return true;
  }

  /// ¿Está la manta puesta del todo, lista para apagar la luz?
  bool get canLightsOff => atBed && (reducedMotion || _blanket >= 0.99);

  /// Paso 3: apaga la luz y empieza a dormir.
  bool lightsOff() {
    if (!canLightsOff) return false;
    if (!activity.advance(SleepPhase.lights)) return false;
    _sleepLeft = _sleepSeconds;
    notify();
    return true;
  }

  Offset get _body =>
      pet.position.toOffset() + Offset(-pet.petSize * 0.1, -pet.petSize * 0.2);

  void _blanketLayer(Canvas c) {
    if (_blanket <= 0) return;
    final feet = pet.position.toOffset();
    final w = pet.petSize * 0.57;
    final rect = Rect.fromCenter(
      center: feet + Offset(0, -pet.petSize * 0.47),
      width: w,
      height: pet.petSize * 0.23,
    );
    // La cara frontal queda por debajo del lomo, fuera de la manta.
    c.saveLayer(rect, Paint());
    c.save();
    c.clipRect(
      Rect.fromLTRB(
        rect.left,
        rect.top,
        rect.right,
        feet.dy - pet.petSize * 0.37,
      ),
    );
    final blanket = _blanketImg;
    if (blanket != null) {
      _drawImage(c, blanket, rect, opacity: _blanket.clamp(0, 1));
    } else {
      c.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(18)),
        Paint()
          ..shader = Gradient.linear(rect.topLeft, rect.bottomRight, [
            Color.fromRGBO(239, 183, 199, _blanket),
            Color.fromRGBO(174, 108, 143, _blanket),
          ]),
      );
      final seam = Paint()
        ..color = Color.fromRGBO(255, 231, 226, _blanket)
        ..strokeWidth = 1.5;
      for (var x = rect.left + 8; x < rect.right; x += 12) {
        c.drawLine(
          Offset(x, rect.top + 5),
          Offset(x - 6, rect.bottom - 4),
          seam,
        );
      }
    }
    c.restore();
    // Recortar la tela a la silueta real: queda apoyada sobre el lomo,
    // sin rectángulos suspendidos fuera de la mascota.
    final sprites = painter.sprites;
    final ids = pet.look.ids;
    if (sprites != null && ids != null) {
      final resolved = painter.resolve('sleep', ids);
      final pose = resolved?.pose ?? 'sleep';
      final layer = sprites.hairLayer(ids.hair, pose);
      final meta = sprites.poses[pose];
      if (layer != null && meta != null) {
        final scale = pet.petSize / sprites.unitHeightPx;
        final mask = Rect.fromLTWH(
          feet.dx - meta.anchor.dx * scale,
          feet.dy + pet.petSize * 0.04 - meta.anchor.dy * scale,
          meta.size.width * scale,
          meta.size.height * scale,
        );
        c.saveLayer(rect, Paint()..blendMode = BlendMode.dstIn);
        c.drawImageRect(
          layer.image,
          Rect.fromLTWH(
            0,
            0,
            layer.image.width.toDouble(),
            layer.image.height.toDouble(),
          ),
          mask,
          Paint(),
        );
        c.restore();
      }
    }
    c.restore();
  }

  void _night(Canvas c) {
    if (_dark <= 0) return;
    c.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Color.fromRGBO(22, 18, 54, 0.62 * _dark),
    );
    if (_useLiveModel) return;
    final a = (255 * _dark).round();
    // Luna.
    final moon = Offset(size.x * 0.84, size.y * 0.13);
    c.drawCircle(moon, 22, Paint()..color = Color.fromARGB(a, 255, 244, 208));
    c.drawCircle(
      moon + const Offset(9, -4),
      20,
      Paint()..color = Color.fromRGBO(22, 18, 54, 0.62 * _dark),
    );
    for (var i = 0; i < 6; i++) {
      final tw = reducedMotion ? 1.0 : 0.6 + 0.4 * math.sin(time * 2 + i);
      c.drawCircle(
        Offset(size.x * (0.1 + i * 0.15), size.y * (0.07 + (i % 3) * 0.05)),
        2.2,
        Paint()..color = Color.fromARGB((a * tw).round(), 255, 244, 208),
      );
    }
    // Zzz sobre la cabeza.
    if (activity.phase == SleepPhase.sleeping) {
      final head = _body + Offset(pet.petSize * 0.1, -pet.petSize * 0.25);
      for (var i = 0; i < 3; i++) {
        final k = (time * 0.5 + i / 3) % 1;
        sceneText(
          'z',
          16 + i * 6.0,
          const Color(0xFFFFF4D0),
        ).paint(c, head + Offset(k * 34 + i * 6, -k * 46 - i * 10));
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_walking) {
      _walkT += dt / _walkSeconds;
      final k = _walkT.clamp(0.0, 1.0);
      final target = _bedFeet.dx;
      pet.position.x = _startX + (target - _startX) * k;
      if (k >= 1) {
        _walking = false;
        // Se acurruca: pose de dormir sobre su cama.
        pet.setView(PetView.front);
        pet.baseAnim = PetAnim.sleep;
        pet.petSize *= 0.82;
        pet.position = Vector2(_bedFeet.dx, _bedFeet.dy - pet.petSize * 0.1);
        notify();
      }
    }
    final blanketOn = activity.phase.index >= SleepPhase.lights.index;
    final target = blanketOn ? 1.0 : 0.0;
    final couldSwitchOff = canLightsOff;
    _blanket = reducedMotion
        ? target
        : _blanket + (target - _blanket) * math.min(1, dt * 4);
    // El botón «Apagar la luz» se activa cuando la manta está puesta del todo.
    if (!couldSwitchOff && canLightsOff) notify();
    if (activity.phase == SleepPhase.sleeping ||
        activity.phase == SleepPhase.done) {
      _dark = reducedMotion ? 1 : math.min(1, _dark + dt * 1.2);
    }
    if (activity.phase == SleepPhase.sleeping) {
      _sleepLeft -= dt;
      if (_sleepLeft <= 0 && activity.wake()) notify();
    }
    if (_useLiveModel) onSleepFrame?.call();
  }

  bool _hitBed(Offset point) {
    final bounds = _liveBedBounds;
    if (_useLiveModel && bounds != null) {
      return bounds.contains(Offset(point.dx / size.x, point.dy / size.y));
    }
    return _bedRect.inflate(20).contains(point) || pet.hits(point);
  }

  @override
  void tapAt(Offset p) {
    switch (activity.phase) {
      case SleepPhase.toBed:
        if (_hitBed(p)) goToBed();
      case SleepPhase.blanket:
        if (atBed && _hitBed(p)) tuckIn();
      case SleepPhase.lights:
        if (!_useLiveModel) lightsOff();
      case SleepPhase.sleeping || SleepPhase.done:
        break;
    }
  }
}

// ======================================================================
// Veterinario
// ======================================================================

enum _VetFx { none, listen, paws, pill }

/// Escuchar el corazón, revisar las patas y, si está malito, darle la pastilla.
class VetGame extends StageGame with _CareToolArt {
  VetGame({
    required super.painter,
    required super.look,
    super.reducedMotion,
    super.onChanged,
    required this.activity,
  }) : super(room: RoomKind.vet, floorY: 0.72, petX: 0.4, petScale: 0.52) {
    pet.fx = PetFx(sick: activity.sick);
  }

  final VetActivity activity;
  _VetFx _fx = _VetFx.none;
  double _fxT = 0;
  bool _toolSelected = false;
  bool _holding = false;
  double _examSeconds = 0;
  Offset? _toolPoint;
  bool _useLiveModel = false;
  List<Offset>? _liveTargets;
  void Function()? onVetFrame;

  set useLiveModel(bool value) {
    _useLiveModel = value;
    pet.showSprite = !value;
  }

  void setLiveTargets(List<Offset> targets) {
    _liveTargets = targets;
    notify();
  }

  List<num> get liveVetFrame {
    final point = _toolPoint;
    return [
      busy ? _fx.index - 1 : activity.phase.index,
      _toolSelected ? 1 : 0,
      point == null || size.x == 0 ? 0.85 : point.dx / size.x,
      point == null || size.y == 0 ? 0.55 : point.dy / size.y,
      _holding ? 1 : 0,
      busy ? (32 * _fxT / _fxSeconds).round() / 32 : -1,
      (32 * _examSeconds / 3).floor() / 32,
    ];
  }

  void selectTool() {
    if (busy || _target == null) return;
    _toolSelected = true;
    onVetFrame?.call();
    notify();
  }

  void pressAt(Offset p) {
    if (!_toolSelected || busy || _target == null) return;
    _toolPoint = p;
    _holding = (p - _at(_target!)).distance < pet.petSize * 0.2;
    onVetFrame?.call();
  }

  void releaseTool() {
    _holding = false;
    _toolPoint = null;
    onVetFrame?.call();
  }

  @override
  void dragAt(Offset p, Offset delta) {
    if (!_toolSelected || busy || _target == null) return;
    _toolPoint = p;
    final radius = _useLiveModel && activity.phase == VetPhase.pill
        ? 0.11
        : 0.16;
    final hit = (p - _at(_target!)).distance < pet.petSize * radius;
    _holding = hit;
    if (activity.phase == VetPhase.pill && hit) {
      givePill();
      _toolSelected = false;
      releaseTool();
    }
    onVetFrame?.call();
  }

  double get _fxSeconds => reducedMotion ? 0.5 : 1.3;

  /// Hay una animación en curso: la actividad no se cierra hasta que acabe.
  bool get busy => _fx != _VetFx.none;

  void _start(_VetFx fx) {
    _fx = fx;
    _fxT = 0;
  }

  /// Paso 1: el fonendo sobre el pecho.
  bool listen() {
    if (busy || !activity.listen()) return false;
    _start(_VetFx.listen);
    pet.react(PetAnim.idle, seconds: 0.1);
    notify();
    return true;
  }

  /// Paso 2: revisar las patas.
  bool checkPaws() {
    if (busy || !activity.checkPaws()) return false;
    _start(_VetFx.paws);
    notify();
    return true;
  }

  /// Paso 3 (solo malito): la pastilla.
  bool givePill() {
    if (busy || !activity.givePill()) return false;
    _start(_VetFx.pill);
    notify();
    return true;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(
      Painted((c) {
        if (!_useLiveModel) {
          _markers(c);
          _effects(c);
        }
      }, priority: 15),
    );
  }

  Offset _at(String landmark) {
    final targets = _liveTargets;
    if (!_useLiveModel || targets == null) return pet.landmarkScene(landmark);
    final index = switch (landmark) {
      'chest' => 0,
      'paws' => 1,
      _ => 2,
    };
    final target = targets[index];
    return Offset(target.dx * size.x, target.dy * size.y);
  }

  void paintLiveOverlay(Canvas c) {
    _markers(c);
    _effects(c);
  }

  /// A qué se toca ahora según la fase.
  String? get _target => switch (activity.phase) {
    VetPhase.heart => 'chest',
    VetPhase.paws => 'paws',
    VetPhase.pill => 'mouth',
    VetPhase.done => null,
  };

  void _markers(Canvas c) {
    final t = _target;
    if (t == null || _fx != _VetFx.none && _fxT < _fxSeconds) return;
    final center = _at(t);
    final pulse = reducedMotion ? 0.0 : math.sin(time * 4) * 3;
    c.drawCircle(
      center,
      pet.petSize * 0.1 + pulse,
      Paint()
        ..color = const Color(0xFF5C354E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _effects(Canvas c) {
    if (_toolSelected && !busy) {
      final point = _toolPoint ?? Offset(size.x * 0.82, size.y * 0.55);
      final tool = switch (activity.phase) {
        VetPhase.heart => CareTool.stethoscope,
        VetPhase.paws => CareTool.magnifier,
        _ => CareTool.pill,
      };
      paintTool(c, tool, point, 40, time);
      if (_holding) {
        c.drawArc(
          Rect.fromCircle(center: point, radius: 26),
          -math.pi / 2,
          _examSeconds / 3 * 2 * math.pi,
          false,
          Paint()
            ..color = const Color(0xFF375E50)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
      }
    }
    if (_fx == _VetFx.none) return;
    final k = (_fxT / _fxSeconds).clamp(0.0, 1.0);
    if (_useLiveModel && _toolAtlas != null) {
      switch (_fx) {
        case _VetFx.listen:
          paintTool(
            c,
            CareTool.stethoscope,
            _at('chest') + const Offset(30, -22),
            69,
            time,
          );
        case _VetFx.paws:
          paintTool(
            c,
            CareTool.magnifier,
            _at('paws') + Offset(19 + math.sin(k * 6) * 8, 5),
            61,
            time,
          );
        case _VetFx.pill:
          if (k < .67) {
            final mouth = _at('mouth');
            paintTool(
              c,
              CareTool.pill,
              Offset.lerp(mouth + const Offset(28, -14), mouth, k / .67)!,
              22,
              time,
            );
          }
        case _VetFx.none:
          break;
      }
      return;
    }
    switch (_fx) {
      case _VetFx.listen:
        final chest = _at('chest');
        // Fonendoscopio: tubo en arco hasta el pecho y campana plateada.
        final tube = Path()
          ..moveTo(size.x * 0.9, size.y * 0.1)
          ..quadraticBezierTo(size.x * 0.95, chest.dy, chest.dx + 10, chest.dy);
        c.drawPath(
          tube,
          Paint()
            ..color = const Color(0xFF34283B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
        c.drawCircle(chest, 14, Paint()..color = const Color(0xFFB9B9C4));
        c.drawCircle(
          chest,
          14,
          Paint()
            ..color = const Color(0xFF6E6E7C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        // Latidos.
        final beat = reducedMotion
            ? 1.0
            : 1 + 0.25 * math.max(0, math.sin(k * 10 * math.pi));
        final heart = sceneText('♥', 26 * beat, const Color(0xFFE0705A));
        heart.paint(
          c,
          chest + Offset(-heart.width / 2 - 30, -heart.height - 14),
        );
        final heart2 = sceneText('♥', 18 * beat, const Color(0xFFE0705A));
        heart2.paint(c, chest + Offset(18, -heart2.height - 26));
      case _VetFx.paws:
        final paws = _at('paws');
        // Lupa sobre las patas.
        final r = pet.petSize * 0.1;
        final center =
            paws + Offset(math.sin(k * math.pi * 2) * pet.petSize * 0.05, -r);
        c.drawCircle(center, r, Paint()..color = const Color(0x33FFFFFF));
        c.drawCircle(
          center,
          r,
          Paint()
            ..color = const Color(0xFF8E6B3F)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
        c.drawLine(
          center + Offset(r * 0.7, r * 0.7),
          center + Offset(r * 1.7, r * 1.7),
          Paint()
            ..color = const Color(0xFF8E6B3F)
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round,
        );
      case _VetFx.pill:
        final mouth = _at('mouth');
        final start = Offset(size.x * 0.85, size.y * 0.78);
        final e = Curves.easeInOut.transform(k);
        final pos =
            Offset.lerp(start, mouth, e)! +
            Offset(0, -math.sin(e * math.pi) * 40);
        if (k < 0.92) {
          c.save();
          c.translate(pos.dx, pos.dy);
          c.rotate(e * 6);
          final rr = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 26, height: 12),
            const Radius.circular(6),
          );
          c.drawRRect(rr, Paint()..color = const Color(0xFFFFFFFF));
          c.drawRRect(
            RRect.fromRectAndCorners(
              Rect.fromLTRB(-13, -6, 0, 6),
              topLeft: const Radius.circular(6),
              bottomLeft: const Radius.circular(6),
            ),
            Paint()..color = const Color(0xFFE0705A),
          );
          c.restore();
        }
      case _VetFx.none:
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final needsFrame = _holding || busy;
    if (_holding && !busy && activity.phase != VetPhase.pill) {
      _examSeconds += dt;
      if (_examSeconds >= 3) {
        if (activity.phase == VetPhase.heart) {
          listen();
        } else if (activity.phase == VetPhase.paws) {
          checkPaws();
        }
        _examSeconds = 0;
        _toolSelected = false;
        releaseTool();
      }
    }
    if (_fx != _VetFx.none) {
      _fxT += dt;
      if (_fxT >= _fxSeconds) {
        final finished = _fx;
        _fx = _VetFx.none;
        if (finished == _VetFx.pill || (!activity.sick && activity.completed)) {
          pet.fx = PetFx.none;
          pet.react(PetAnim.happy, seconds: 2);
        }
        notify();
      }
    }
    if (needsFrame) onVetFrame?.call();
  }

  @override
  void tapAt(Offset p) {
    // Selecting the instrument is separate from applying it to the pet.
    if (!busy && !_toolSelected) selectTool();
  }
}
