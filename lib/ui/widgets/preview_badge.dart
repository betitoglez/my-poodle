import 'package:material_ui/material_ui.dart';

import '../../l10n/localized_widgets.dart';
import '../theme.dart';

/// Aviso de una prueba pendiente que puede plegarse sin aplicarla ni descartarla.
class PreviewBadge extends StatefulWidget {
  const PreviewBadge({super.key});

  @override
  State<PreviewBadge> createState() => _PreviewBadgeState();
}

class _PreviewBadgeState extends State<PreviewBadge> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    if (_collapsed) {
      return IconButton.filledTonal(
        tooltip: localize(context, 'Mostrar texto de vista previa'),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.cream,
          foregroundColor: AppColors.plum,
        ),
        onPressed: () => setState(() => _collapsed = false),
        icon: const Icon(Icons.visibility_rounded, size: 20),
      );
    }
    return Tooltip(
      message: localize(context, 'Ocultar texto de vista previa'),
      child: FilledButton.tonalIcon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.cream,
          foregroundColor: AppColors.plum,
        ),
        onPressed: () => setState(() => _collapsed = true),
        icon: const Icon(Icons.visibility_rounded, size: 18),
        label: const LText('Probando'),
      ),
    );
  }
}
