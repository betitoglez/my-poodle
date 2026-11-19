import 'package:my_poodle/l10n/localized_widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../game/pet/pet_painter.dart';
import '../theme.dart';

/// Giro para ver al caniche desde los cuatro ángulos.
class TurnControl extends StatelessWidget {
  const TurnControl({
    super.key,
    required this.view,
    required this.onTurn,
    this.compact = false,
  });
  final PetView view;
  final void Function(PetView) onTurn;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: const [BoxShadow(color: Color(0x2234283B), blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: localizeNullable(context, 'Girar a la izquierda'),
            onPressed: () => onTurn(view.previous),
            icon: const Icon(Icons.rotate_left_rounded, color: AppColors.plum),
          ),
          if (!compact)
            LText(
              view.label,
              style: AppText.small.copyWith(color: AppColors.ink),
            ),
          IconButton(
            tooltip: localizeNullable(context, 'Girar a la derecha'),
            onPressed: () => onTurn(view.next),
            icon: const Icon(Icons.rotate_right_rounded, color: AppColors.plum),
          ),
        ],
      ),
    );
  }
}
