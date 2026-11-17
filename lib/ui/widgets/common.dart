import 'package:material_ui/material_ui.dart';

import '../../domain/balance.dart';
import '../theme.dart';

/// Botón principal con icono y texto (≥ 48×48).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.secondary = false,
    this.big = false,
    this.expand = false,
    this.semanticsHint,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool secondary;
  final bool big;
  final bool expand;
  final String? semanticsHint;

  @override
  Widget build(BuildContext context) {
    final size = Size(
      expand ? double.infinity : AppSizes.touch,
      big ? AppSizes.bigButton : AppSizes.touch,
    );
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: big ? 28 : 22),
        const SizedBox(width: AppSpace.s),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
    final button = secondary
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(minimumSize: size),
            child: child,
          )
        : FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(minimumSize: size),
            child: child,
          );
    return Semantics(hint: semanticsHint, child: button);
  }
}

/// Saldo de monedas: disco dorado y número.
class CoinBalance extends StatelessWidget {
  const CoinBalance({super.key, required this.coins, this.large = false});
  final int coins;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$coins monedas',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: large ? 14 : 10,
          vertical: large ? 8 : 5,
        ),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: AppColors.coin, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CoinIcon(size: large ? 24 : 20),
            const SizedBox(width: 6),
            Text(
              '$coins',
              style: AppText.number.copyWith(fontSize: large ? 20 : 17),
            ),
          ],
        ),
      ),
    );
  }
}

class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 20});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.coin,
      border: Border.all(color: AppColors.coinDeep, width: size * 0.12),
    ),
    alignment: Alignment.center,
    child: Text(
      'm',
      style: TextStyle(
        fontSize: size * 0.5,
        fontWeight: FontWeight.w900,
        color: AppColors.coinDeep,
        height: 1,
      ),
    ),
  );
}

extension NeedVisuals on Need {
  IconData get icon => switch (this) {
    Need.satiety => Icons.restaurant_rounded,
    Need.hygiene => Icons.bubble_chart_rounded,
    Need.mood => Icons.favorite_rounded,
    Need.energy => Icons.bolt_rounded,
  };
  Color get color => switch (this) {
    Need.satiety => AppColors.satiety,
    Need.hygiene => AppColors.hygiene,
    Need.mood => AppColors.mood,
    Need.energy => AppColors.energy,
  };
}

/// Indicador de necesidad: icono, nombre, valor en texto y barra.
class NeedMeter extends StatelessWidget {
  const NeedMeter({
    super.key,
    required this.need,
    required this.label,
    required this.value,
    this.highlight = false,
  });
  final Need need;
  final String label;
  final int value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final low = value < 30;
    return Semantics(
      label: '$label: $value de 100${low ? ', bajo' : ''}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(AppRadii.s),
          border: Border.all(
            color: highlight ? need.color : const Color(0x22000000),
            width: highlight ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(need.icon, size: 18, color: need.color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: AppText.small.copyWith(color: AppColors.ink),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (low)
                  const Icon(
                    Icons.priority_high_rounded,
                    size: 16,
                    color: AppColors.coral,
                  ),
                Text('$value', style: AppText.number.copyWith(fontSize: 15)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 8,
                color: need.color,
                backgroundColor: need.color.withValues(alpha: 0.18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Panel crema de esquinas suaves sobre la escena.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;
  @override
  Widget build(BuildContext context) {
    final l = Layout.of(context);
    return Container(
      width: double.infinity,
      padding:
          padding ??
          EdgeInsets.fromLTRB(l.gutter, AppSpace.m, l.gutter, AppSpace.m),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.l)),
        boxShadow: [
          BoxShadow(
            color: Color(0x2234283B),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: l.maxContentWidth),
          child: child,
        ),
      ),
    );
  }
}

/// Marcas de progreso (●●○) con texto «1 de 3» para no depender del color.
class StepMarks extends StatelessWidget {
  const StepMarks({
    super.key,
    required this.done,
    required this.total,
    this.labels,
  });
  final int done;
  final int total;
  final List<String>? labels;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Progreso $done de $total',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < done ? AppColors.leaf : Colors.white,
                  border: Border.all(color: AppColors.leaf, width: 2),
                ),
                child: i < done
                    ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          const SizedBox(width: 8),
          Text('$done / $total', style: AppText.number.copyWith(fontSize: 15)),
        ],
      ),
    );
  }
}

/// Banda reservada para un banner (solo en Casa, modo demostración).
class BannerSlot extends StatelessWidget {
  const BannerSlot({super.key});
  @override
  Widget build(BuildContext context) => Container(
    height: 50,
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFEDE7DA),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFB7AB97)),
    ),
    alignment: Alignment.center,
    child: const Text(
      'Espacio reservado para publicidad (simulado)',
      style: AppText.small,
    ),
  );
}

/// Etiqueta de modo demostración, visible mientras está activo.
class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.coral,
      borderRadius: BorderRadius.circular(AppRadii.pill),
    ),
    child: const Text(
      'DEMO',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 12,
        letterSpacing: 1,
      ),
    ),
  );
}
