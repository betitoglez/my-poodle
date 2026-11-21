import 'dart:ui';

import 'package:flame/game.dart';

/// Reloj Flame común para los tableros Flutter. ActivityFrame controla pausa,
/// segundo plano y abandono igual que en los demás minijuegos.
class PuzzleGame extends FlameGame {
  PuzzleGame({required this.tick, required this.onChanged});
  final void Function(double dt) tick;
  final void Function() onChanged;
  @override
  Color backgroundColor() => const Color(0xFFF8F3E8);
  @override
  void update(double dt) {
    super.update(dt);
    tick(dt);
    onChanged();
  }
}
