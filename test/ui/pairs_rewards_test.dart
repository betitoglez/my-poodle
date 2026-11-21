import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/ui/widgets/common.dart';

import 'app_flow_test.dart' show boot, scrollTo, tapText;
import 'features_test.dart' show backendWith;

void main() {
  setUp(rootBundle.clear);
  testWidgets(
    'Parejas muestra un premio y un icono por línea con texto grande',
    (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await boot(t, backendWith((s) => s), size: const Size(320, 568));
      await tapText(t, 'Juegos');
      await scrollTo(t, find.text('Juego de parejas'));
      await tapText(t, 'Juego de parejas');
      for (final text in [
        '4 parejas: 5 monedas',
        '6 parejas: 15 monedas',
        '8 parejas: 25 monedas',
      ]) {
        final line = find.byWidgetPredicate(
          (w) => w is CoinText && w.source == text,
        );
        await scrollTo(t, line);
        expect(line, findsOneWidget);
        expect(
          find.descendant(of: line, matching: find.byType(CoinIcon)),
          findsOneWidget,
        );
        // Different widgets provide separate rows, rather than wrapping one sentence.
        expect(t.getSize(line).height, greaterThan(0));
      }
      expect(t.takeException(), isNull);
    },
  );
}
