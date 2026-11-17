import 'dart:math' as math;
import 'dart:ui' hide TextStyle;

import 'package:flame/components.dart';

import '../../domain/activities.dart';
import '../pet/appearance_catalog.dart';
import '../pet/pet_painter.dart';
import '../scenes/room_painter.dart';
import '../scenes/stage_game.dart';

// ======================================================================
// Cocina
// ======================================================================

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
  void Function()? onBite;

  double get chewSeconds => reducedMotion ? 0.7 : 1.3;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(Painted(_bowl, priority: 15));
  }

  Rect get bowlRect {
    final f = pet.position.toOffset();
    final w = pet.petSize * 0.5;
    return Rect.fromCenter(
      center: f + Offset(0, pet.petSize * 0.06),
      width: w,
      height: w * 0.36,
    );
  }

  void _bowl(Canvas c) {
    final r = bowlRect;
    c.drawOval(
      r.translate(0, r.height * 0.3),
      Paint()..color = const Color(0x2234283B),
    );
    // Comida: se reduce por tercios.
    final fill = activity.bowlFill;
    if (fill > 0) {
      final mound = Rect.fromCenter(
        center:
            r.topCenter + Offset(0, r.height * 0.18 - fill * r.height * 0.22),
        width: r.width * (0.55 + 0.3 * fill),
        height: r.height * (0.25 + 0.55 * fill),
      );
      c.drawOval(mound, Paint()..color = const Color(0xFF9C6A3C));
      for (var i = 0; i < (10 * fill).round(); i++) {
        final a = i * 2.3;
        c.drawCircle(
          mound.center +
              Offset(
                math.cos(a) * mound.width * 0.3,
                math.sin(a) * mound.height * 0.25,
              ),
          3,
          Paint()..color = const Color(0xFF7A4E2A),
        );
      }
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
    c.drawOval(
      Rect.fromLTWH(r.left, r.top + r.height * 0.05, r.width, r.height * 0.3),
      Paint()
        ..color = const Color(0xFFE59A72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    // Cenefa decorativa.
    for (var i = 0; i < 6; i++) {
      c.drawCircle(
        Offset(r.left + r.width * (0.2 + i * 0.12), r.top + r.height * 0.62),
        3,
        Paint()..color = const Color(0xFFF3D2B8),
      );
    }
  }

  /// Intento de bocado (botón o toque en el cuenco).
  bool bite() {
    if (!activity.bite()) return false;
    _chewLeft = chewSeconds;
    pet.react(PetAnim.eat, seconds: chewSeconds);
    onBite?.call();
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
        notify();
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

class BathGame extends StageGame {
  BathGame({
    required super.painter,
    required super.look,
    super.reducedMotion,
    super.onChanged,
    required this.activity,
  }) : super(room: RoomKind.bath, floorY: 0.7, petScale: 0.56);

  final BathActivity activity;
  double _waterLeft = 0;
  void Function(BathZone zone)? onSoap;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(Painted(_tubBack, priority: 5));
    add(Painted(_foreground, priority: 15));
  }

  Rect get _tub {
    final f = pet.position.toOffset();
    return Rect.fromLTWH(
      f.dx - pet.petSize * 0.62,
      f.dy - pet.petSize * 0.02,
      pet.petSize * 1.24,
      pet.petSize * 0.36,
    );
  }

  void _tubBack(Canvas c) {
    final r = _tub;
    c.drawOval(
      Rect.fromLTWH(r.left, r.top - r.height * 0.25, r.width, r.height * 0.5),
      Paint()..color = const Color(0xFFBFD8EC),
    );
  }

  void _foreground(Canvas c) {
    final r = _tub;
    // Frente de la bañera de porcelana con lavanda.
    final front = RRect.fromRectAndCorners(
      r,
      bottomLeft: Radius.circular(r.height * 0.8),
      bottomRight: Radius.circular(r.height * 0.8),
    );
    c.drawRRect(front, Paint()..color = const Color(0xFFFBF7F2));
    c.drawLine(
      r.topLeft,
      r.topRight,
      Paint()
        ..color = const Color(0xFFE0D6EA)
        ..strokeWidth = 6,
    );
    for (var i = 0; i < 5; i++) {
      final x = r.left + r.width * (0.18 + i * 0.16);
      c.drawLine(
        Offset(x, r.bottom - r.height * 0.25),
        Offset(x + 6, r.top + r.height * 0.35),
        Paint()
          ..color = const Color(0xFF6B8A57)
          ..strokeWidth = 2,
      );
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x + 6, r.top + r.height * 0.32),
          width: 6,
          height: 16,
        ),
        Paint()..color = const Color(0xFF9A7CC8),
      );
    }
    // Agua de la ducha al mojar o aclarar.
    if (_waterLeft > 0) {
      final head =
          pet.position.toOffset() +
          Offset(pet.petSize * 0.32, -pet.petSize * 1.15);
      c.drawCircle(head, 12, Paint()..color = const Color(0xFFC9A54D));
      final drop = Paint()..color = const Color(0xCC8FC7E8);
      for (var i = 0; i < 14; i++) {
        final k = ((time * 2.2 + i * 0.13) % 1);
        c.drawOval(
          Rect.fromCenter(
            center:
                head +
                Offset(
                  -pet.petSize * 0.3 * k + (i % 4) * 6,
                  pet.petSize * 0.9 * k,
                ),
            width: 4,
            height: 9,
          ),
          drop,
        );
      }
    }
    // Marcas de zona durante el enjabonado (forma + texto, no solo color).
    if (activity.phase == BathPhase.soap) {
      for (final z in BathZone.values) {
        final center = _zoneCenter(z);
        final done = activity.zoneDone(z);
        final ring = Paint()
          ..color = done ? const Color(0xFF375E50) : const Color(0xFF5C354E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        final pulse = done || reducedMotion ? 0.0 : math.sin(time * 4) * 3;
        c.drawCircle(center, pet.petSize * 0.08 + pulse, ring);
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

  Offset _zoneCenter(BathZone z) {
    final f = pet.position.toOffset();
    final s = pet.petSize;
    return switch (z) {
      BathZone.back => f + Offset(s * 0.2, -s * 0.56),
      BathZone.chest => f + Offset(0, -s * 0.47),
      BathZone.paws => f + Offset(-s * 0.08, -s * 0.08),
    };
  }

  BathZone? zoneAt(Offset p) {
    final u = pet.toUnit(p);
    if (u.dy > -0.2 && u.dy < 0.08 && u.dx.abs() < 0.3) return BathZone.paws;
    if (u.dy < -0.36 && u.dy > -0.68 && u.dx.abs() <= 0.11) {
      return BathZone.chest;
    }
    if (u.dy < -0.36 && u.dy > -0.7 && u.dx.abs() > 0.11 && u.dx.abs() < 0.32) {
      return BathZone.back;
    }
    return null;
  }

  void _refreshFx() {
    pet.fx = PetFx(
      wet:
          activity.phase == BathPhase.soap || activity.phase == BathPhase.rinse,
      foam: [for (final z in BathZone.values) activity.foam(z)],
    );
  }

  bool wet() {
    if (!activity.wet()) return false;
    _waterLeft = reducedMotion ? 0.5 : 1.0;
    _refreshFx();
    notify();
    return true;
  }

  bool soap(BathZone z, [double amount = 1]) {
    if (!activity.soap(z, amount)) return false;
    _refreshFx();
    onSoap?.call(z);
    notify();
    return true;
  }

  bool rinse() {
    if (!activity.rinse()) return false;
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
  }

  @override
  void tapAt(Offset p) {
    switch (activity.phase) {
      case BathPhase.wet:
        if (pet.hits(p)) wet();
      case BathPhase.soap:
        final z = zoneAt(p);
        if (z != null) soap(z);
      case BathPhase.rinse:
        if (pet.hits(p)) rinse();
      case BathPhase.done:
        break;
    }
  }

  @override
  void dragAt(Offset p, Offset delta) {
    if (activity.phase != BathPhase.soap) return;
    final z = zoneAt(p);
    if (z != null) soap(z, delta.distance / (pet.petSize * 0.5));
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
  double _sniffLeft = 0;
  void Function(int stop)? onArrive;

  static const stopNames = ['Flores', 'Banco', 'Fuente'];

  double get groundY => size.y * 0.8;
  double stopX(int i) => size.x * (0.82 + i * 0.85);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    petWorldX = size.x * 0.22;
    add(Painted(_world, priority: 0));
    add(Painted(_markers, priority: 15));
  }

  @override
  void layoutPet() {
    pet.petSize = math.min(size.y * petScale, size.x * 0.42);
    pet.position = Vector2(petWorldX - camX, size.y * 0.82);
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

  void _markers(Canvas c) {
    for (var i = 0; i < 3; i++) {
      final center = Offset(stopX(i) - camX, size.y * 0.87);
      if (center.dx < -60 || center.dx > size.x + 60) continue;
      final done = i < activity.done;
      final enabled = activity.enabledStop == i;
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

  bool goTo(int stop) {
    if (!activity.tapStop(stop)) return false;
    pet.baseAnim = PetAnim.trot;
    notify();
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final speed = reducedMotion ? 900.0 : size.x * 0.42;
    if (activity.phase == WalkPhase.moving) {
      final target = stopX(activity.done) - pet.petSize * 0.45;
      petWorldX = math.min(target, petWorldX + speed * dt);
      if (petWorldX >= target) {
        activity.arrived();
        pet.baseAnim = PetAnim.sniff;
        _sniffLeft = reducedMotion ? 0.6 : 1.3;
        onArrive?.call(activity.done);
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
  }

  @override
  void tapAt(Offset p) {
    final stop = activity.enabledStop;
    if (stop == null) return;
    final center = Offset(stopX(stop) - camX, size.y * 0.87);
    // El destino activo o su objeto en el sendero.
    if ((p - center).distance < 56 ||
        ((p.dx - (center.dx + 40)).abs() < 60 && p.dy > size.y * 0.55)) {
      goTo(stop);
    }
  }
}

// ======================================================================
// Peluquería
// ======================================================================

class GroomGame extends StageGame {
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

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(Painted(_mirror, priority: 5));
    add(Painted(_markers, priority: 15));
  }

  void _mirror(Canvas c) {
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
    c.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: r.width * 3,
        height: r.height * 3,
      ),
      Paint()..color = const Color(0x22FFFFFF),
    );
    c.restore();
  }

  Offset _strandCenter(Strand s) {
    final f = pet.position.toOffset();
    final z = pet.petSize;
    return switch (s) {
      Strand.forelock => f + Offset(0, -z * 0.98),
      Strand.ears => f + Offset(z * 0.19, -z * 0.7),
      Strand.back => f + Offset(-z * 0.2, -z * 0.52),
    };
  }

  void _markers(Canvas c) {
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
      var center = _strandCenter(s);
      // Orejas y lomo son simétricos.
      if (s != Strand.forelock &&
          (p.dx < pet.position.x) != (center.dx < pet.position.x)) {
        center = Offset(2 * pet.position.x - center.dx, center.dy);
      }
      final d = (p - center).distance;
      if (d < bestD) {
        bestD = d;
        best = s;
      }
    }
    return best;
  }

  bool brush(Strand s, [double amount = 0.5]) {
    if (!activity.brush(s, amount)) return false;
    _refresh();
    if (activity.strandDone(s)) {
      onBrushed?.call(s);
      if (activity.completed) pet.react(PetAnim.happy, seconds: 2);
    }
    notify();
    return true;
  }

  @override
  void tapAt(Offset p) {
    final s = strandAt(p);
    if (s != null) brush(s);
  }

  @override
  void dragAt(Offset p, Offset delta) {
    final s = strandAt(p);
    if (s != null) brush(s, delta.distance / (pet.petSize * 0.6));
  }
}
