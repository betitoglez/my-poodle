import 'dart:math' as math;

import 'package:my_poodle/l10n/localized_widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// Confeti breve sobre la pantalla. Con movimiento reducido no se anima:
/// muestra un destello estático y desaparece. Nunca intercepta toques.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    required this.reducedMotion,
    this.onDone,
    this.pieces = 36,
    this.duration = const Duration(milliseconds: 1400),
  });

  final bool reducedMotion;
  final VoidCallback? onDone;
  final int pieces;
  final Duration duration;

  /// Muestra el confeti en la capa superior de [context].
  static void show(BuildContext context, {required bool reducedMotion}) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => ConfettiBurst(
        reducedMotion: reducedMotion,
        onDone: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.reducedMotion
        ? const Duration(milliseconds: 600)
        : widget.duration,
  )..forward().whenComplete(() => widget.onDone?.call());

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(
            _c.value,
            widget.pieces,
            widget.reducedMotion,
          ),
        ),
      ),
    ),
  );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.pieces, this.reduced);
  final double t;
  final int pieces;
  final bool reduced;

  static const _colors = [
    AppColors.coral,
    AppColors.leaf,
    AppColors.plum,
    Color(0xFFE9B23C),
    Color(0xFF6FA8DC),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final fade = (1 - t).clamp(0.0, 1.0);
    if (reduced) {
      final p = Paint()
        ..color = const Color(0xFFE9B23C).withValues(alpha: 0.35 * fade);
      canvas.drawCircle(
        Offset(size.width / 2, size.height * 0.35),
        size.shortestSide * 0.18,
        p,
      );
      return;
    }
    final rng = math.Random(7);
    for (var i = 0; i < pieces; i++) {
      final x0 = size.width * (0.2 + 0.6 * rng.nextDouble());
      final vx = (rng.nextDouble() - 0.5) * size.width * 0.9;
      final vy = -size.height * (0.35 + 0.35 * rng.nextDouble());
      final g = size.height * 1.4;
      final x = x0 + vx * t;
      final y = size.height * 0.45 + vy * t + g * t * t / 2;
      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 8 + i);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 8, height: 5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// Fila de tres estrellas (0..3 encendidas) con etiqueta accesible.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 22});
  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) => LSemantics(
    label: '$stars de 3 estrellas',
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < stars ? const Color(0xFFE9B23C) : AppColors.plumSoft,
          ),
      ],
    ),
  );
}
