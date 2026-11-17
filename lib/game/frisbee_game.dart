import 'dart:math' as math;
import 'dart:ui' hide TextStyle;

import 'package:flame/game.dart';

import '../domain/games/frisbee_sim.dart';
import 'pet/appearance_catalog.dart';
import 'pet/pet_component.dart';
import 'pet/pet_painter.dart';
import 'scenes/stage_game.dart';

/// Frisbee en el prado: proyección afín 2D del campo lógico. La guía, el
/// disco y la sombra usan [FrisbeeSim.pointAt] con la misma proyección.
class FrisbeeGame extends FlameGame {
  FrisbeeGame({
    required this.painter,
    required PetLook look,
    required this.reducedMotion,
    required this.sim,
    required this.onFinished,
    this.onHud,
    this.onEvent,
  }) : pet = PetComponent(
         painter: painter,
         look: look,
         pose: PetPose.front,
         reducedMotion: reducedMotion,
       )..priority = 10;

  final PetPainter painter;
  final bool reducedMotion;
  final FrisbeeSim sim;
  final PetComponent pet;
  final void Function(int catches) onFinished;
  final void Function()? onHud;
  final void Function(String event)? onEvent;
  Image? _bg;
  bool _reported = false;
  double time = 0;

  /// Destino previsto mientras se arrastra (null si no hay arrastre válido).
  FieldPoint? aimPreview;
  bool aimTooShort = false;

  // Proyección del campo: x ∈ [-3.6, 3.6], profundidad ∈ [0, 9].
  Rect get fieldRect =>
      Rect.fromLTRB(size.x * 0.04, size.y * 0.30, size.x * 0.96, size.y * 0.9);
  double get sx => fieldRect.width / 7.2;
  double get sd => fieldRect.height / 9;
  Offset project(FieldPoint p) =>
      Offset(fieldRect.center.dx + p.x * sx, fieldRect.bottom - p.depth * sd);
  Offset projectWithElevation(FieldPoint p, double elevation) =>
      project(p) - Offset(0, elevation * sd);

  @override
  Color backgroundColor() => const Color(0xFFBFE0F5);

  @override
  Future<void> onLoad() async {
    try {
      _bg = await images.load('scenes/meadow.jpg');
    } catch (_) {
      _bg = null;
    }
    add(Painted(_background, priority: 0));
    add(Painted(_field, priority: 5));
    add(pet);
    add(Painted(_disc, priority: 20));
  }

  void setAim(FieldPoint? p, {bool tooShort = false}) {
    aimPreview = p;
    aimTooShort = tooShort;
  }

  bool launch(FieldPoint dest) {
    if (paused || !sim.launch(dest)) return false;
    aimPreview = null;
    onEvent?.call('throw');
    return true;
  }

  bool launchAssisted() => launch(sim.currentTarget);

  FieldPoint? _lastDest;
  bool? _lastCaught;

  @override
  void update(double dt) {
    super.update(dt);
    time += dt;
    final before = sim.phase;
    if (sim.destination != null) _lastDest = sim.destination;
    sim.advance(dt);
    if (before == FrisbeePhase.flight && sim.phase == FrisbeePhase.catchAnim) {
      _lastCaught = sim.lastCaught;
      onEvent?.call(sim.lastCaught! ? 'catch' : 'miss');
    }
    _placePet();
    onHud?.call();
    if (sim.finished && !_reported) {
      _reported = true;
      onFinished(sim.catches);
    }
  }

  /// El caniche espera en el aro, corre hacia el disco y vuelve.
  /// Momento del vuelo (0..1) en que el caniche intercepta el disco en el
  /// aire. El resultado lo decide la simulación; esto solo lo representa.
  static const double interceptT = 0.82;

  /// El disco va en la boca: durante la caída tras atraparlo y al volver.
  bool discInMouth = false;

  double _dogSize(FieldPoint p) => (size.y * 0.27) * (1 - p.depth / 14);

  static double _smooth(double x) => x * x * (3 - 2 * x);

  FieldPoint _lerp(FieldPoint a, FieldPoint b, double k) =>
      FieldPoint(a.x + (b.x - a.x) * k, a.depth + (b.depth - a.depth) * k);

  /// El caniche espera en el aro, corre hacia el disco, salta a por él y
  /// vuelve con él en la boca.
  void _placePet() {
    final target = sim.currentTarget;
    FieldPoint where = target;
    var lift = 0.0;
    var shiftX = 0.0;
    discInMouth = false;
    switch (sim.phase) {
      case FrisbeePhase.aim:
        pet.pose = PetPose.front;
        pet.baseAnim = PetAnim.lookUp;
        pet.airborne = 0;
      case FrisbeePhase.flight:
        final dest = sim.destination!;
        final k = sim.flightProgress;
        if (sim.wouldCatch(dest)) {
          final (pI, eI) = FrisbeeSim.pointAt(dest, interceptT);
          where = _lerp(target, pI, _smooth((k / interceptT).clamp(0.0, 1.0)));
          pet.pose = PetPose.side;
          pet.facingLeft = pI.x < target.x - 0.05;
          final leapStart = interceptT - 0.28;
          final leaping = k > leapStart && !reducedMotion;
          pet.baseAnim = leaping ? PetAnim.catchDisc : PetAnim.run;
          pet.airborne = leaping ? 6 : 0;
          pet.petSize = _dogSize(where);
          // Altura del salto para que la boca llegue al disco.
          final mouth = painter.landmark(
            PetPose.side,
            'mouth',
            anim: PetAnim.catchDisc,
          );
          final ground = project(pI).dy;
          final discY = ground - eI * sd;
          final needed = math.max(0.0, ground + mouth.dy * pet.petSize - discY);
          if (leaping) {
            final curve = k < interceptT
                ? math.sin(
                    (k - leapStart) / (interceptT - leapStart) * math.pi / 2,
                  )
                : math.cos((k - interceptT) / (1 - interceptT) * math.pi / 2);
            lift = needed * curve;
          }
          // Desplaza al caniche para que su boca quede bajo la trayectoria.
          shiftX =
              -(pet.facingLeft ? -1 : 1) *
              mouth.dx *
              pet.petSize *
              _smooth((k / interceptT).clamp(0.0, 1.0));
          discInMouth = k >= interceptT;
        } else {
          // Fallo: corre un poco hacia donde caerá y se detiene.
          where = _lerp(target, dest, 0.45 * _smooth(k));
          pet.pose = PetPose.side;
          pet.facingLeft = dest.x < target.x;
          pet.baseAnim = k < 0.8 ? PetAnim.run : PetAnim.idle;
          pet.airborne = 0;
        }
      case FrisbeePhase.catchAnim:
        final dest = _lastDest ?? target;
        if (_lastCaught == true) {
          where = FrisbeeSim.pointAt(dest, interceptT).$1;
          pet.pose = PetPose.front;
          pet.baseAnim = PetAnim.celebrate;
          discInMouth = true;
        } else {
          where = _lerp(
            sim.targets[(sim.attempts - 1).clamp(0, sim.throws - 1)],
            dest,
            0.45,
          );
          pet.pose = PetPose.front;
          pet.baseAnim = PetAnim.idle;
        }
      case FrisbeePhase.returning:
        final next = sim.attempts < sim.throws
            ? sim.targets[sim.attempts]
            : target;
        final prev = sim.targets[(sim.attempts - 1).clamp(0, sim.throws - 1)];
        final from = _lastCaught == true
            ? FrisbeeSim.pointAt(_lastDest ?? prev, interceptT).$1
            : _lerp(prev, _lastDest ?? prev, 0.45);
        final k = (sim.phaseTime / FrisbeeSim.returnSeconds).clamp(0.0, 1.0);
        where = _lerp(from, next, k);
        pet.pose = PetPose.side;
        pet.facingLeft = next.x < from.x;
        pet.baseAnim = PetAnim.trot;
        discInMouth = _lastCaught == true;
      case FrisbeePhase.finished:
        pet.pose = PetPose.front;
        pet.baseAnim = PetAnim.celebrate;
    }
    final p = project(where);
    pet.position = Vector2(p.dx + shiftX, p.dy - lift);
    pet.petSize = _dogSize(where);
  }

  void _background(Canvas c) {
    final bg = _bg;
    if (bg == null) return;
    final src = Rect.fromLTWH(0, 0, bg.width.toDouble(), bg.height.toDouble());
    // Cubrir manteniendo proporción.
    final scale = math.max(size.x / bg.width, size.y / bg.height);
    final w = bg.width * scale, h = bg.height * scale;
    c.drawImageRect(
      bg,
      src,
      Rect.fromLTWH((size.x - w) / 2, (size.y - h) / 2, w, h),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  void _ellipseAt(Canvas c, FieldPoint p, double radius, Paint paint) {
    final center = project(p);
    c.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * 2 * sx,
        height: radius * 2 * sd,
      ),
      paint,
    );
  }

  void _field(Canvas c) {
    if (sim.finished) return;
    // Aro de captura (tolerancia = radio lógico).
    final target = sim.currentTarget;
    _ellipseAt(
      c,
      target,
      sim.catchRadius,
      Paint()..color = const Color(0x55FFF3BF),
    );
    _ellipseAt(
      c,
      target,
      sim.catchRadius,
      Paint()
        ..color = const Color(0xFFFFF3BF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    _ellipseAt(
      c,
      target,
      sim.catchRadius * 0.5,
      Paint()
        ..color = const Color(0xAAFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Lanzador.
    final o = project(FrisbeeSim.origin);
    c.drawOval(
      Rect.fromCenter(center: o + const Offset(0, 6), width: 70, height: 18),
      Paint()..color = const Color(0x3334283B),
    );
    if (sim.canThrow) _drawDisc(c, o + const Offset(0, -6), 1);
  }

  void _drawDisc(Canvas c, Offset at, double k) {
    c.drawOval(
      Rect.fromCenter(center: at, width: 46 * k, height: 15 * k),
      Paint()..color = const Color(0xFFC55238),
    );
    c.drawOval(
      Rect.fromCenter(
        center: at + Offset(0, -2 * k),
        width: 32 * k,
        height: 7 * k,
      ),
      Paint()..color = const Color(0xFFFFAB69),
    );
  }

  void _disc(Canvas c) {
    final preview = aimPreview;
    if (preview != null && sim.canThrow) {
      final ok = sim.wouldCatch(preview);
      final dot = Paint()..color = const Color(0xFFFFF8E9);
      // 16 muestras de la misma función que anima el disco.
      for (var i = 1; i <= 16; i++) {
        final (p, e) = FrisbeeSim.pointAt(preview, i / 16);
        c.drawCircle(projectWithElevation(p, e), 3.5, dot);
      }
      final land = project(preview);
      final mark = Paint()
        ..color = ok ? const Color(0xFF375E50) : const Color(0xFFE0705A)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      c.drawLine(
        land + const Offset(-10, -10),
        land + const Offset(10, 10),
        mark,
      );
      c.drawLine(
        land + const Offset(10, -10),
        land + const Offset(-10, 10),
        mark,
      );
    }
    if (discInMouth) {
      final m = pet.landmarkScene('mouth');
      _drawDisc(
        c,
        m + Offset(0, pet.petSize * 0.02),
        pet.petSize / (size.y * 0.27) * 0.85,
      );
    } else if (sim.phase == FrisbeePhase.flight) {
      final (p, e) = FrisbeeSim.pointAt(sim.destination!, sim.flightProgress);
      final shadow = project(p);
      final k = 1 - p.depth / 14;
      c.drawOval(
        Rect.fromCenter(center: shadow, width: 34 * k, height: 10 * k),
        Paint()..color = const Color(0x4434283B),
      );
      _drawDisc(c, projectWithElevation(p, e), k);
    }
    if (sim.phase == FrisbeePhase.catchAnim) {
      final txt = sceneText(
        _lastCaught == true ? '¡Atrapado!' : '¡Casi!',
        22,
        const Color(0xFF5C354E),
      );
      final at = project(_lastDest ?? sim.currentTarget);
      txt.paint(c, at + Offset(-txt.width / 2, -sd * 3.6));
      if (_lastCaught != true && _lastDest != null) {
        // El disco queda en el suelo donde aterrizó.
        _drawDisc(c, project(_lastDest!), 1 - _lastDest!.depth / 14);
      }
    }
  }
}
