import 'package:my_poodle/l10n/localized_widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/tutorial.dart';
import '../theme.dart';
import 'common.dart';

/// Tarjeta de la primera partida guiada (V05): un paso cada vez, con un
/// botón que lleva a la actividad y otro para saltar la guía para siempre.
class GuideCard extends StatelessWidget {
  const GuideCard({
    super.key,
    required this.step,
    required this.petName,
    required this.onAction,
    required this.onSkip,
  });

  final TutorialStep step;

  /// Nombre elegido por el jugador; no se traduce.
  final String petName;
  final VoidCallback onAction;
  final VoidCallback onSkip;

  static String textOf(TutorialStep step, String name) => switch (step) {
    TutorialStep.feed => 'Primer paso: dale de comer a $name.',
    TutorialStep.play => 'Ahora juega con $name para ganar monedas.',
    TutorialStep.dress =>
      'Estrena algo: un accesorio en el armario o una decoración en el salón.',
  };

  static String actionOf(TutorialStep step) => switch (step) {
    TutorialStep.feed => 'Dar de comer',
    TutorialStep.play => 'A jugar',
    TutorialStep.dress => 'Ir al armario',
  };

  static IconData iconOf(TutorialStep step) => switch (step) {
    TutorialStep.feed => Icons.restaurant_rounded,
    TutorialStep.play => Icons.sports_esports_rounded,
    TutorialStep.dress => Icons.checkroom_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final icon = iconOf(step);
    return LSemantics(
      container: true,
      label: 'Guía de la primera partida',
      child: Material(
        color: AppColors.cream,
        elevation: 3,
        shadowColor: const Color(0x5534283B),
        borderRadius: BorderRadius.circular(AppRadii.m),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.m,
            AppSpace.xs,
            AppSpace.xs,
            AppSpace.s,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.coinDeep),
                  const SizedBox(width: AppSpace.s),
                  Expanded(
                    child: LText(
                      textOf(step, petName),
                      style: AppText.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: localizeNullable(context, 'Saltar guía'),
                    onPressed: onSkip,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.plum,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpace.xs),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    label: actionOf(step),
                    icon: icon,
                    onPressed: onAction,
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
