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
    final soil = Paint()..color = const Color(0xFF9E7449);
    final grass = Paint()..color = const Color(0xFF6D8B4F);
    final stone = Paint()..color = const Color(0xFFB9A88E);
    for (final p in sim.level.platforms) {
      final a = toScreen(p.x0, p.top), b = toScreen(p.x1, -4);
      if (b.dx < -10 || a.dx > size.x + 10) continue;
      final r = Rect.fromLTRB(a.dx, a.dy, b.dx, size.y + 10);
      c.drawRect(r, p.top > 0 ? stone : soil);
      if (p.top > 0) {
        // Bancal de piedra: juntas.
        final joint = Paint()
          ..color = const Color(0x55000000)
          ..strokeWidth = 1.5;
        for (var y = r.top + scale * 0.18; y < r.bottom; y += scale * 0.22) {
          c.drawLine(Offset(r.left, y), Offset(r.right, y), joint);
        }
      }
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(r.left - 3, r.top - 6, r.width + 6, 12),
          const Radius.circular(6),
        ),
        grass,
      );
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
    // Manzanas pendientes (las recogidas desaparecen).
    for (final a in sim.level.apples) {
      if (sim.collected.contains(a.id)) continue;
      final p = toScreen(a.x, a.y);
      if (p.dx < -30 || p.dx > size.x + 30) continue;
      final r = OrchardSim.appleRadius * scale;
      final bob = reducedMotion ? 0.0 : math.sin(time * 3 + a.x) * 2;
      c.drawCircle(
        p + Offset(0, bob),
        r,
        Paint()..color = const Color(0xFFC0392B),
      );
      c.drawCircle(
        p + Offset(-r * 0.35, -r * 0.35 + bob),
        r * 0.28,
        Paint()..color = const Color(0xFFF48C73),
      );
      c.drawOval(
        Rect.fromCenter(
          center: p + Offset(r * 0.35, -r * 1.05 + bob),
          width: r * 0.7,
          height: r * 0.35,
        ),
        Paint()..color = const Color(0xFF376649),
      );
    }
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
      final txt = sceneText('¡Arriba!', 18, const Color(0xFF5C354E));
      txt.paint(c, p + Offset(-txt.width / 2, -pet.petSize * 1.25));
    }
  }
}
