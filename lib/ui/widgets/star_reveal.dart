import 'package:my_poodle/l10n/localized_widgets.dart';
import 'package:material_ui/material_ui.dart';

import 'celebrations.dart';

/// [StarRow] con aparición escalonada de las estrellas ganadas: cada una
/// crece con un pequeño rebote sobre su contorno. Con movimiento reducido
/// (o sin estrellas) es la fila estática. La semántica es la de [StarRow]
/// («N de 3 estrellas»), sin anunciar pasos intermedios.
class StarReveal extends StatefulWidget {
  const StarReveal({
    super.key,
    required this.stars,
    required this.reducedMotion,
    this.size = 34,
    this.delay = const Duration(milliseconds: 250),
    this.step = const Duration(milliseconds: 220),
    this.pop = const Duration(milliseconds: 420),
  });

  final int stars;
  final bool reducedMotion;
  final double size;

  /// Espera inicial (deja terminar la transición de entrada).
  final Duration delay;

  /// Separación entre estrellas y duración del rebote de cada una.
  final Duration step;
  final Duration pop;

  /// Duración total de la animación para [stars] estrellas.
  Duration totalFor(int stars) =>
      stars <= 0 ? Duration.zero : delay + step * (stars - 1) + pop;

  @override
  State<StarReveal> createState() => _StarRevealState();
}

class _StarRevealState extends State<StarReveal>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;
  bool _done = false;

  bool get _animate => !widget.reducedMotion && widget.stars > 0;

  @override
  void initState() {
    super.initState();
    if (_animate) {
      _c =
          AnimationController(
              vsync: this,
              duration: widget.totalFor(widget.stars.clamp(0, 3)),
            )
            ..addStatusListener((status) {
              // Al terminar queda la fila estática (sin ticker ni capas extra).
              if (status == AnimationStatus.completed && mounted) {
                setState(() => _done = true);
              }
            })
            ..forward();
    }
  }

  @override
  void didUpdateWidget(StarReveal old) {
    super.didUpdateWidget(old);
    if (!_animate) _done = true;
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  /// Escala (0..~1.15..1) de la estrella [i] en el instante [t] de 0 a 1.
  double _scale(int i, double t) {
    final total = widget.totalFor(widget.stars.clamp(0, 3)).inMicroseconds;
    if (total == 0) return 1;
    final start = (widget.delay + widget.step * i).inMicroseconds / total;
    final end = start + widget.pop.inMicroseconds / total;
    if (t <= start) return 0;
    if (t >= end) return 1;
    return Curves.easeOutBack.transform((t - start) / (end - start));
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null || _done) {
      return StarRow(stars: widget.stars, size: widget.size);
    }
    final lit = widget.stars.clamp(0, 3);
    return LSemantics(
      label: '${widget.stars} de 3 estrellas',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: c,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            // Contornos estáticos: la fila no cambia de tamaño al aparecer.
            StarRow(stars: 0, size: widget.size),
            ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    Transform.scale(
                      scale: i < lit ? _scale(i, c.value) : 0,
                      child: Icon(
                        Icons.star_rounded,
                        size: widget.size,
                        color: const Color(0xFFE9B23C),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
