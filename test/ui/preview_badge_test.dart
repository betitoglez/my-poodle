import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/ui/widgets/preview_badge.dart';

import 'app_flow_test.dart' show boot, idle, saved, tapText;
import 'features_test.dart' show backendWith;
import 'decor_test.dart' show openDecor;

void main() {
  setUp(rootBundle.clear);
  for (final decor in [false, true]) {
    testWidgets(
      'Probando se pliega al ojo sin aplicar ni descartar, decoración=$decor',
      (t) async {
        final backend = backendWith((s) => s.copyWith(coins: 100));
        await boot(t, backend, size: const Size(320, 568));
        if (decor) {
          await openDecor(t);
          await tapText(t, 'Alfombra redonda');
        } else {
          await tapText(t, 'Armario');
          await tapText(t, 'Gris plata');
        }
        final before = saved(backend);
        expect(find.text('Probando'), findsOneWidget);
        final buttonFinder = find.ancestor(
          of: find.text('Probando'),
          matching: find.byType(FilledButton),
        );
        final button = t.widget<FilledButton>(buttonFinder);
        final theme = Theme.of(t.element(buttonFinder));
        final foreground =
            button.style?.foregroundColor?.resolve({}) ??
            theme.filledButtonTheme.style!.foregroundColor!.resolve({})!;
        final background =
            button.style?.backgroundColor?.resolve({}) ??
            theme.filledButtonTheme.style!.backgroundColor!.resolve({})!;
        final light =
            foreground.computeLuminance() > background.computeLuminance()
            ? foreground
            : background;
        final dark =
            foreground.computeLuminance() > background.computeLuminance()
            ? background
            : foreground;
        expect(
          (light.computeLuminance() + .05) / (dark.computeLuminance() + .05),
          greaterThanOrEqualTo(4.5),
          reason:
              'el texto/ojito deben contrastar con el fondo del botón grande',
        );
        final expanded = t.getSize(find.byType(PreviewBadge));
        await tapText(t, 'Probando');
        expect(find.text('Probando'), findsNothing);
        final eye = find.byTooltip('Mostrar texto de vista previa');
        expect(eye, findsOneWidget);
        final compact = t.getSize(find.byType(PreviewBadge));
        expect(compact.width, lessThan(expanded.width));
        expect(compact.width, lessThanOrEqualTo(56));
        expect(compact.height, lessThanOrEqualTo(56));
        final position = t.widget<Positioned>(
          find
              .ancestor(
                of: find.byType(PreviewBadge),
                matching: find.byType(Positioned),
              )
              .first,
        );
        expect(position.right, lessThanOrEqualTo(12));
        expect(position.top, lessThanOrEqualTo(12));
        expect(
          find.text(decor ? 'Comprar y colocar · 40' : 'Comprar y usar · 30'),
          findsOneWidget,
        );
        expect(saved(backend).coins, before.coins);
        expect(saved(backend).appearance.ids, before.appearance.ids);
        expect(saved(backend).decor, before.decor);
        await t.tap(eye);
        await idle(t);
        expect(find.text('Probando'), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }
}
