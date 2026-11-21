import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_flow_test.dart' show boot, fullStore, tapText, saved, reopen;
import 'features_test.dart' show backendWith;

void main() {
  setUp(rootBundle.clear);
  for (final full in [false, true]) {
    testWidgets('Navidad: probar sin pagar, compra y recarga; completa=$full', (
      t,
    ) async {
      final backend = backendWith((s) => s.copyWith(coins: 1000));
      await boot(
        t,
        backend,
        store: full ? fullStore() : null,
        size: const Size(320, 568),
      );
      await tapText(t, 'Armario');
      await tapText(t, 'Ropa');
      expect(find.text('Jersey de elfo'), findsNothing);
      await tapText(t, 'Navidad');
      expect(find.text('Jersey de elfo'), findsOneWidget);
      await tapText(t, 'Jersey de elfo');
      expect(saved(backend).appearance.outfit, 'outfit.none');
      expect(saved(backend).coins, 1000);
      if (full) {
        await tapText(t, 'Comprar y usar · 320');
        expect(saved(backend).coins, 1000);
        await tapText(t, 'Confirmar');
        expect(saved(backend).appearance.outfit, 'outfit.sweater_elf');
        expect(saved(backend).coins, 680);
        await tapText(t, 'Ropa');
        expect(find.text('Jersey de elfo'), findsNothing);
        await tapText(t, 'Navidad');
        expect(find.text('Jersey de elfo'), findsOneWidget);
        await reopen(t, backend);
        expect(saved(backend).appearance.outfit, 'outfit.sweater_elf');
        expect(saved(backend).coins, 680);
      } else {
        expect(find.text('Versión completa'), findsWidgets);
        expect(find.textContaining('Comprar y usar'), findsNothing);
        await tapText(t, 'Descartar');
        expect(saved(backend).coins, 1000);
      }
      expect(t.takeException(), isNull);
    });
  }
}
