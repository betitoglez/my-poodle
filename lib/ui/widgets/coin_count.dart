import 'package:my_poodle/l10n/localized_widgets.dart';
import 'package:material_ui/material_ui.dart';

/// Número que cuenta de [from] a [to] (solo representación: el valor real ya
/// está confirmado en el recibo). Con movimiento reducido, o si no hay
/// diferencia, muestra el valor final desde el primer fotograma. La semántica
/// anuncia siempre el valor final, nunca los intermedios.
class CountUpText extends StatefulWidget {
  const CountUpText({
    super.key,
    required this.from,
    required this.to,
    required this.format,
    required this.reducedMotion,
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  final int from;
  final int to;

  /// Texto fuente en español para un valor (se localiza al pintar).
  final String Function(int value) format;
  final bool reducedMotion;
  final TextStyle? style;
  final Duration duration;

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;
  bool _done = false;

  bool get _animate => !widget.reducedMotion && widget.from != widget.to;

  @override
  void initState() {
    super.initState();
    if (_animate) {
      _c = AnimationController(vsync: this, duration: widget.duration)
        ..forward();
    }
  }

  @override
  void didUpdateWidget(CountUpText old) {
    super.didUpdateWidget(old);
    // Activar el movimiento reducido a mitad de cuenta la completa al momento.
    if (!_animate) _done = true;
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  int _valueAt(double t) {
    if (t >= 1) return widget.to;
    final v =
        widget.from +
        (widget.to - widget.from) * Curves.easeOutCubic.transform(t);
    // Redondeo hacia el destino: el último paso no se queda a medias.
    return widget.to >= widget.from ? v.ceil() : v.floor();
  }

  @override
  Widget build(BuildContext context) {
    final c = _done ? null : _c;
    return LSemantics(
      label: widget.format(widget.to),
      excludeSemantics: true,
      child: c == null
          ? LText(widget.format(widget.to), style: widget.style)
          : AnimatedBuilder(
              animation: c,
              builder: (context, _) =>
                  LText(widget.format(_valueAt(c.value)), style: widget.style),
            ),
    );
  }
}
