import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../app/texts.dart';
import '../../domain/rules.dart';
import '../theme.dart';

/// Fila de iconos de estado, estilo tamagotchi: los cinco siempre visibles;
/// los que no aplican se apagan y los que aplican se encienden, laten y
/// llevan una exclamación (no depende solo del color). Tocar uno encendido
/// lleva a la actividad que lo resuelve.
class StatusBubbles extends StatefulWidget {
  const StatusBubbles({
    super.key,
    required this.active,
    required this.onTap,
    this.reducedMotion = false,
    this.vertical = false,
  });

  final Set<PetCondition> active;
  final void Function(PetCondition) onTap;
  final bool reducedMotion;

  /// En columna junto al borde cuando hay alto de sobra, para no tapar al caniche.
  final bool vertical;

  static const order = [
    PetCondition.sick,
    PetCondition.hungry,
    PetCondition.dirty,
    PetCondition.sad,
    PetCondition.tired,
  ];

  static String assetOf(PetCondition c) => 'assets/images/icons/${c.name}.webp';

  static IconData fallbackIcon(PetCondition c) => switch (c) {
    PetCondition.sick => Icons.sick_rounded,
    PetCondition.hungry => Icons.restaurant_rounded,
    PetCondition.dirty => Icons.bubble_chart_rounded,
    PetCondition.sad => Icons.sentiment_dissatisfied_rounded,
    PetCondition.tired => Icons.bedtime_rounded,
  };

  @override
  State<StatusBubbles> createState() => _StatusBubblesState();
}

class _StatusBubblesState extends State<StatusBubbles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  /// Solo late si hay algún icono encendido; apagados no hay nada que animar.
  bool get _pulsing => !widget.reducedMotion && widget.active.isNotEmpty;

  void _sync() {
    if (!_pulsing) {
      if (_c.isAnimating) _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(StatusBubbles old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(
          widget.vertical ? 22 : AppRadii.pill,
        ),
        boxShadow: const [BoxShadow(color: Color(0x2234283B), blurRadius: 6)],
      ),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Flex(
          direction: widget.vertical ? Axis.vertical : Axis.horizontal,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final cond in StatusBubbles.order)
              _Bubble(
                condition: cond,
                on: widget.active.contains(cond),
                phase: widget.reducedMotion ? 0 : _c.value,
                onTap: () => widget.onTap(cond),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.condition,
    required this.on,
    required this.phase,
    required this.onTap,
  });
  final PetCondition condition;
  final bool on;
  final double phase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = Texts.conditionNames[condition]!;
    final pulse = on ? 1 + 0.08 * math.sin(phase * 2 * math.pi) : 1.0;
    final icon = Image.asset(
      StatusBubbles.assetOf(condition),
      width: 36,
      height: 36,
      errorBuilder: (_, _, _) => Icon(
        StatusBubbles.fallbackIcon(condition),
        size: 30,
        color: AppColors.plum,
      ),
    );
    return Semantics(
      button: true,
      label: on
          ? '$name: encendido, toca para atender'
          : '$name: apagado, toca para atender',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: SizedBox(
          width: AppSizes.touch - 4,
          height: AppSizes.touch - 4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (on)
                Container(
                  width: 42 * pulse,
                  height: 42 * pulse,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.coral, width: 2.5),
                  ),
                ),
              Opacity(
                opacity: on ? 1 : 0.45,
                child: ColorFiltered(
                  colorFilter: on
                      ? const ColorFilter.mode(Color(0x00000000), BlendMode.dst)
                      : const ColorFilter.matrix(<double>[
                          0.33, 0.33, 0.33, 0, 0, //
                          0.33, 0.33, 0.33, 0, 0,
                          0.33, 0.33, 0.33, 0, 0,
                          0, 0, 0, 1, 0,
                        ]),
                  child: icon,
                ),
              ),
              if (on)
                Positioned(
                  right: 1,
                  top: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
