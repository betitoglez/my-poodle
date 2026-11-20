import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/l10n/localized_widgets.dart';

import '../theme.dart';

/// Colores de las fichas «de lujo» (metas de ahorro del armario y del salón).
abstract final class LuxuryColors {
  static const gold = Color(0xFFD9A43A);
  static const goldSoft = Color(0xFFFFF1CC);
}

/// Insignia dorada «Lujo» para la esquina de una miniatura.
class LuxuryBadge extends StatelessWidget {
  const LuxuryBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: LuxuryColors.gold,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      border: Border.all(color: AppColors.coinDeep),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_awesome_rounded, size: 12, color: Colors.white),
        SizedBox(width: 3),
        LText(
          'Lujo',
          maxLines: 1,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}

/// Línea «Te faltan N monedas» bajo el precio cuando no alcanza el saldo.
class MissingCoinsLine extends StatelessWidget {
  const MissingCoinsLine({super.key, required this.missing});
  final int missing;

  @override
  Widget build(BuildContext context) => LText(
    'Te faltan $missing monedas',
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.center,
    style: AppText.small.copyWith(
      color: AppColors.coinDeep,
      fontWeight: FontWeight.w800,
    ),
  );
}

/// Estado accesible de una ficha (cada parte traducida por separado):
/// lujo, estado y lo que falta.
String tileValue(
  BuildContext context,
  String state, {
  bool luxury = false,
  int? missing,
}) => [
  if (luxury) 'Lujo',
  state,
  if (missing != null) 'Te faltan $missing monedas',
].map((part) => localize(context, part)).join('. ');

/// Texto accesible completo de una ficha: nombre y [tileValue].
String tileSemantics(
  BuildContext context,
  String label,
  String state, {
  bool luxury = false,
  int? missing,
}) =>
    '${localize(context, label)}. '
    '${tileValue(context, state, luxury: luxury, missing: missing)}';
