import 'dart:math' as math;
import 'dart:ui';

/// Borde visible del cuello medido sobre los sprites, en unidades del perro.
/// El eje va de izquierda a derecha. De perfil coincide con nuca a garganta.
class PetNeck {
  const PetNeck(this.left, this.right);

  final Offset left;
  final Offset right;

  double get width => right.dx - left.dx;

  factory PetNeck.forPose(String pose, String hair) {
    final pom = hair == 'hair.pom';
    return switch (pose) {
      'front' => PetNeck(
        Offset(pom ? -0.198 : -0.159, -0.622),
        Offset(pom ? 0.162 : 0.088, -0.622),
      ),
      'back' => PetNeck(
        Offset(pom ? -0.200 : -0.149, -0.620),
        Offset(pom ? 0.150 : 0.080, -0.620),
      ),
      'run_a' => const PetNeck(Offset(0.035, -0.477), Offset(0.316, -0.407)),
      'run_b' => const PetNeck(Offset(0.067, -0.574), Offset(0.339, -0.546)),
      'jump' => const PetNeck(Offset(0.072, -0.599), Offset(0.354, -0.572)),
      _ => PetNeck(
        Offset(pom ? 0.121 : 0.133, -0.652),
        Offset(pom ? 0.441 : 0.415, -0.636),
      ),
    };
  }

  static Path earMask(String pose, Offset head) {
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

  /// Acentúa la curva de la tela y no deja los extremos como barras rectas.
  Offset at(double t, {double drape = 0.030}) =>
      Offset.lerp(left, right, t)! + Offset(0, math.sin(t * math.pi) * drape);

  Path band(double height) {
    final mid = at(0.5);
    final middle = (left + right) / 2;
    final curve = mid.dy + (mid.dy - middle.dy);
    return Path()
      ..moveTo(left.dx, left.dy - height * 0.18)
      ..quadraticBezierTo(
        mid.dx,
        curve - height / 2,
        right.dx,
        right.dy - height * 0.18,
      )
      ..quadraticBezierTo(
        right.dx + 0.005,
        right.dy + height * 0.26,
        right.dx,
        right.dy + height * 0.46,
      )
      ..quadraticBezierTo(
        mid.dx,
        curve + height / 2,
        left.dx,
        left.dy + height * 0.46,
      )
      ..quadraticBezierTo(
        left.dx - 0.005,
        left.dy + height * 0.26,
        left.dx,
        left.dy - height * 0.18,
      )
      ..close();
  }
}
