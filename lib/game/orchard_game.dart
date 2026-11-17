import 'dart:math' as math;
import 'dart:ui' hide TextStyle;

import 'package:flame/game.dart';

import '../domain/games/orchard_sim.dart';
import 'pet/appearance_catalog.dart';
import 'pet/pet_component.dart';
import 'pet/pet_painter.dart';
import 'scenes/stage_game.dart';

/// Huerto saltarín: dibuja [OrchardSim] con cámara lateral. Los premios se
/// calculan fuera, a partir de la métrica entera entregada en [onFinished].
class OrchardGame extends FlameGame {
  OrchardGame({
    required this.painter,
    required PetLook look,
    required this.reducedMotion,
    required this.onFinished,
    this.onHud,
    this.onEvent,
    OrchardSim? sim,
  }) : sim = sim ?? OrchardSim(),
       pet = PetComponent(
         painter: painter,
         look: look,
         pose: PetPose.side,
         baseAnim: PetAnim.run,
         reducedMotion: reducedMotion,
       )..priority = 10;

  final PetPainter painter;
  final bool reducedMotion;
  final OrchardSim sim;
  final PetComponent pet;
  final void Function(int apples) onFinished;
  final void Function()? onHud;
  final void Function(String event)? onEvent;
  bool _reported = false;
  double camX = 0;
  double time = 0;
  Image? _bg;
  final List<(Offset, double)> _sparkles = [];

  /// Escala: píxeles por unidad de juego, ajustada para ver el siguiente salto.
  double get scale => math.min(size.x / 4.8, size.y / 3.4);
  double get groundScreenY => size.y * 0.8;

  Offset toScreen(double x, double y) =>
      Offset((x - camX) * scale, groundScreenY - y * scale);

  @override
  Color backgroundColor() => const Color(0xFFBFE0F5);

  @override
  Future<void> onLoad() async {
    try {
      _bg = await images.load('scenes/orchard.jpg');
    } catch (_) {
      _bg = null; // Fallback visible: cielo liso.
    }
    add(Painted(_background, priority: 0));
    add(Painted(_world, priority: 5));
    add(pet);
    add(Painted(_effects, priority: 20));
  }

  /// Toque en el campo o botón Saltar: misma intención.
  void jump() {
    if (paused || sim.finished) return;
    sim.jump();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (sim.finished) {
      pet.baseAnim = PetAnim.celebrate;
      pet.pose = PetPose.front;
      if (!_reported) {
        _reported = true;
        onFinished(sim.score);
      }
      return;
    }
    time += dt;
    final jumpsBefore = sim.jumpsStarted, fallsBefore = sim.falls;
    sim.advance(dt);
    for (final id in sim.justCollected) {
      final a = sim.level.apples.firstWhere((e) => e.id == id);
      _sparkles.add((Offset(a.x, a.y), 0));
      onEvent?.call('apple');
    }
    if (sim.jumpsStarted != jumpsBefore) onEvent?.call('jump');
    if (sim.falls != fallsBefore) onEvent?.call('fall');
    for (var i = _sparkles.length - 1; i >= 0; i--) {
      final (p, age) = _sparkles[i];
      if (age > 0.6) {
        _sparkles.removeAt(i);
      } else {
        _sparkles[i] = (p, age + dt);
      }
    }
    // Cámara: caniche al 28 % para ver el siguiente apoyo.
    final target = sim.x - (size.x / scale) * 0.28;
    camX = reducedMotion
        ? target
        : camX + (target - camX) * math.min(1, dt * 8);
    pet.petSize = scale * 0.9;
    pet.position = Vector2(
      (sim.x - camX) * scale,
      groundScreenY - sim.y * scale,
    );
    pet.airborne = sim.vy;
    pet.baseAnim = sim.respawning
        ? PetAnim.idle
        : sim.grounded
        ? (sim.blocked ? PetAnim.idle : PetAnim.run)
        : PetAnim.jump;
    onHud?.call();
  }

  void _background(Canvas c) {
    // Fondo del hueco: tierra en sombra bajo el nivel del suelo.
    c.drawRect(
      Rect.fromLTWH(0, groundScreenY + scale * 0.3, size.x, size.y),
      Paint()..color = const Color(0xFF4F6B3A),
    );
    final bg = _bg;
    if (bg == null) return;
    final h = groundScreenY + scale * 0.4;
    final w = h * bg.width / bg.height;
    final offset = (camX * scale * 0.25) % w;
    for (var x = -offset; x < size.x; x += w) {
      c.drawImageRect(
        bg,
        Rect.fromLTWH(0, 0, bg.width.toDouble(), bg.height.toDouble()),
        Rect.fromLTWH(x, 0, w + 1, h),
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
  }

  void _world(Canvas c) {
    for (final p in sim.level.platforms) {
      final a = toScreen(p.x0, p.top), b = toScreen(p.x1, -4);
      if (b.dx < -10 || a.dx > size.x + 10) continue;
      final r = Rect.fromLTRB(a.dx, a.dy, b.dx, size.y + 10);
      c.save();
      c.clipRect(r);
      c.drawRect(
        r,
        Paint()
          ..shader = Gradient.linear(
            r.topLeft,
            r.bottomLeft,
            [
              const Color(0xFF765039),
              const Color(0xFFB48258),
              const Color(0xFF654737),
            ],
            [0, 0.45, 1],
          ),
      );
      // Estratos ondulados de tierra; textura estable en coordenadas del mundo.
      for (var layer = 0; layer < 5; layer++) {
        final y = r.top + scale * (0.16 + layer * 0.23);
        final path = Path()..moveTo(r.left, y);
        for (
          var wx = math.max(p.x0, camX - 1);
          wx <= math.min(p.x1, camX + size.x / scale + 1);
          wx += 0.08
        ) {
          final x = toScreen(wx, 0).dx;
          path.lineTo(x, y + math.sin(wx * 2 + layer) * scale * 0.025);
        }
        c.drawPath(
          path,
          Paint()
            ..color = layer.isEven
                ? const Color(0x66734D38)
                : const Color(0x66E3B482)
            ..style = PaintingStyle.stroke
            ..strokeWidth = scale * 0.05,
        );
      }
      final start = math.max(p.x0, camX - 0.3);
      final end = math.min(p.x1, camX + size.x / scale + 0.3);
      for (var wx = (start * 10).floor() / 10; wx < end; wx += 0.17) {
        final seed = wx * 35.73;
        final x = toScreen(wx, 0).dx;
        final depth = (math.sin(seed) * 0.5 + 0.5) * (size.y - r.top);
        c.drawOval(
          Rect.fromCenter(
            center: Offset(x, r.top + depth),
            width: scale * 0.055,
            height: scale * 0.025,
          ),
          Paint()..color = const Color(0x99D5B28C),
        );
        // Raíces sous la couronne d'herbe.
        final root = Path()
          ..moveTo(x, r.top + 3)
          ..quadraticBezierTo(
            x - 5,
            r.top + scale * 0.08,
            x + 3,
            r.top + scale * 0.19,
          );
        c.drawPath(
          root,
          Paint()
            ..color = const Color(0x998F774F)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
      if (p.top > 0) {
        // Bancals de brique: joints décalés, faces lumineuses et arêtes.
        final joint = Paint()
          ..color = const Color(0xFF594C45)
          ..strokeWidth = 2;
        for (var row = 0; row * scale * 0.24 < r.height; row++) {
          final y = r.top + row * scale * 0.24;
          c.drawLine(Offset(r.left, y), Offset(r.right, y), joint);
          for (
            var wx = (start / 0.5).floor() * 0.5;
            wx < end + 0.5;
            wx += 0.5
          ) {
            final x = toScreen(wx + (row.isEven ? 0 : 0.25), 0).dx;
            c.drawLine(Offset(x, y), Offset(x, y + scale * 0.24), joint);
            c.drawLine(
              Offset(x + 3, y + 3),
              Offset(x + scale * 0.45, y + 3),
              Paint()
                ..color = const Color(0x66E2BC94)
                ..strokeWidth = 2,
            );
          }
        }
      }
      c.restore();
      final turf = Rect.fromLTWH(r.left, r.top - 5, r.width, 12);
      c.drawRRect(
        RRect.fromRectAndRadius(turf, const Radius.circular(4)),
        Paint()
          ..shader = Gradient.linear(turf.topLeft, turf.bottomLeft, [
            const Color(0xFFA3C563),
            const Color(0xFF436539),
          ]),
      );
      for (var wx = (start * 22).floor() / 22; wx < end; wx += 0.045) {
        final x = toScreen(wx, 0).dx;
        final blade = 4 + (math.sin(wx * 91) * 0.5 + 0.5) * 7;
        c.drawLine(
          Offset(x, r.top),
          Offset(x + math.sin(wx * 57) * 3, r.top - blade),
          Paint()
            ..color = wx * 100 % 3 < 1
                ? const Color(0xFFB5D47B)
                : const Color(0xFF638C42)
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    // Meta: arco de flores.
    final g = toScreen(sim.level.goalX, 0);
    final post = Paint()..color = const Color(0xFF8A5A3B);
    c.drawRect(
      Rect.fromLTWH(g.dx - 4, g.dy - scale * 1.4, 8, scale * 1.4),
      post,
    );
    c.drawRect(
      Rect.fromLTWH(g.dx + scale * 0.9, g.dy - scale * 1.4, 8, scale * 1.4),
      post,
    );
    c.drawRect(
      Rect.fromLTWH(g.dx - 4, g.dy - scale * 1.45, scale * 0.9 + 12, 10),
      post,
    );
    final label = sceneText('META', scale * 0.22, const Color(0xFF5C354E));
    label.paint(
      c,
      Offset(g.dx + scale * 0.45 - label.width / 2, g.dy - scale * 1.75),
    );
    for (final (index, a) in sim.level.apples.indexed) {
      if (sim.collected.contains(a.id)) continue;
      final p = toScreen(a.x, a.y);
      if (p.dx < -30 || p.dx > size.x + 30) continue;
      final r = OrchardSim.appleRadius * scale;
      final bob = reducedMotion ? 0.0 : math.sin(time * 3 + a.x) * 2;
      _fruit(c, p + Offset(0, bob), r, index % 6);
    }
  }

  void _fruit(Canvas c, Offset p, double r, int kind) {
    c.save();
    c.translate(p.dx, p.dy);
    c.scale(r);
    const colors = [
      Color(0xFFD84D47),
      Color(0xFFE4BB52),
      Color(0xFFEF953B),
      Color(0xFFDC526A),
      Color(0xFF7279BD),
      Color(0xFFF3D56B),
    ];
    final fill = Paint()
      ..shader = Gradient.radial(
        const Offset(-0.3, -0.35),
        1.5,
        [
          Color.lerp(colors[kind], const Color(0xFFFFFFFF), 0.35)!,
          colors[kind],
          Color.lerp(colors[kind], const Color(0xFF51374A), 0.3)!,
        ],
        [0, 0.6, 1],
      );
    if (kind == 1) {
      c.drawPath(
        Path()
          ..moveTo(0, -1)
          ..cubicTo(-0.6, -1, -0.45, -0.3, -0.7, 0.05)
          ..cubicTo(-1.1, 1.3, 1.1, 1.3, 0.7, 0.05)
          ..cubicTo(0.45, -0.3, 0.6, -1, 0, -1),
        fill,
      );
    } else if (kind == 3) {
      c.drawPath(
        Path()
          ..moveTo(-0.85, -0.5)
          ..cubicTo(-1.2, 0.05, -0.2, 1.05, 0, 1.1)
          ..cubicTo(0.2, 1.05, 1.2, 0.05, 0.85, -0.5)
          ..quadraticBezierTo(0, -1.1, -0.85, -0.5),
        fill,
      );
      for (var i = 0; i < 7; i++) {
        c.drawOval(
          Rect.fromCenter(
            center: Offset(math.sin(i * 7) * 0.48, -0.35 + i * 0.16),
            width: 0.06,
            height: 0.11,
          ),
          Paint()..color = const Color(0xFFFFDB9A),
        );
      }
    } else if (kind == 4) {
      for (final o in [
        const Offset(-0.45, 0.2),
        const Offset(0.4, 0.2),
        const Offset(0, -0.45),
      ]) {
        c.drawCircle(o, 0.6, fill);
        c.drawCircle(
          o - const Offset(0.1, 0.15),
          0.12,
          Paint()..color = const Color(0xFFBEC3EC),
        );
      }
    } else if (kind == 5) {
      c.drawPath(
        Path()
          ..moveTo(-0.9, -0.75)
          ..quadraticBezierTo(-0.6, 1.5, 1, 0.25)
          ..quadraticBezierTo(0.4, 0.5, -0.9, -0.75),
        fill,
      );
    } else {
      c.drawCircle(Offset.zero, 0.9, fill);
    }
    c.drawLine(
      const Offset(0, -0.65),
      const Offset(0.04, -1.15),
      Paint()
        ..color = const Color(0xFF6B593B)
        ..strokeWidth = 0.1
        ..strokeCap = StrokeCap.round,
    );
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(0.35, -0.92),
        width: 0.65,
        height: 0.25,
      ),
      Paint()..color = const Color(0xFF4E8755),
    );
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(-0.35, -0.35),
        width: 0.16,
        height: 0.27,
      ),
      Paint()..color = const Color(0x77FFFFFF),
    );
    c.restore();
  }

  void _effects(Canvas c) {
    for (final (p, age) in _sparkles) {
      final s = toScreen(p.dx, p.dy);
      final k = age / 0.6;
      final paint = Paint()
        ..color = Color.fromARGB((255 * (1 - k)).round(), 233, 182, 87);
      for (var i = 0; i < 6; i++) {
        final a = i * math.pi / 3;
        c.drawCircle(
          s + Offset(math.cos(a), math.sin(a)) * (10 + 30 * k),
          4 * (1 - k) + 1,
          paint,
        );
      }
      sceneText(
        '+1',
        18,
        Color.fromARGB((255 * (1 - k)).round(), 92, 53, 78),
      ).paint(c, s + Offset(-8, -30 - 20 * k));
    }
    if (sim.respawning) {
      final p = pet.position.toOffset();
      final txt = sceneText('−5 s', 18, const Color(0xFF5C354E));
      txt.paint(c, p + Offset(-txt.width / 2, -pet.petSize * 1.25));
    }
  }
}
