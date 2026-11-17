import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/ui/parental_gate.dart';

void main() {
  tearDown(ParentalGate.reset);

  test('números en letras del 21 al 99', () {
    expect(ParentalGate.words(21), 'veintiuno');
    expect(ParentalGate.words(26), 'veintiséis');
    expect(ParentalGate.words(30), 'treinta');
    expect(ParentalGate.words(47), 'cuarenta y siete');
    expect(ParentalGate.words(99), 'noventa y nueve');
    for (var i = 0; i < 200; i++) {
      final n = ParentalGate.nextNumber();
      expect(n, inInclusiveRange(21, 99));
    }
  });

  Future<int> pumpGate(WidgetTester t) async {
    var unlocked = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [AdultGateButton(onUnlocked: () => unlocked++)],
          ),
        ),
      ),
    );
    return unlocked;
  }

  testWidgets('acertar en cifras abre; cancelar no', (t) async {
    var unlocked = 0;
    ParentalGate.nextNumber = () => 47;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AdultGateButton(onUnlocked: () => unlocked++)),
      ),
    );
    await t.tap(find.byType(AdultGateButton));
    await t.pumpAndSettle();
    expect(find.text('Escribe en cifras: cuarenta y siete'), findsOneWidget);
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(unlocked, 0);
    await t.tap(find.byType(AdultGateButton));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('parental-gate-field')), '47');
    await t.tap(find.text('Continuar'));
    await t.pumpAndSettle();
    expect(unlocked, 1);
  });

  testWidgets('un fallo cambia el número; tres fallos esperan 30 s', (t) async {
    var n = 30;
    ParentalGate.nextNumber = () => ++n;
    var now = DateTime(2026, 11, 17, 12);
    ParentalGate.now = () => now;
    expect(await pumpGate(t), 0);
    await t.tap(find.byType(AdultGateButton));
    await t.pumpAndSettle();
    expect(find.text('Escribe en cifras: treinta y uno'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await t.enterText(find.byKey(const Key('parental-gate-field')), '20');
      await t.tap(find.text('Continuar'));
      await t.pump();
      if (i == 0) {
        expect(find.text('Escribe en cifras: treinta y dos'), findsOneWidget);
        expect(find.textContaining('No es correcto'), findsOneWidget);
      }
    }
    expect(find.textContaining('Espera 30 s'), findsOneWidget);
    // Cerrar y reabrir no se salta la espera.
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    await t.tap(find.byType(AdultGateButton));
    await t.pump();
    expect(find.textContaining('Demasiados intentos'), findsOneWidget);
    now = now.add(const Duration(seconds: 31));
    await t.pump(const Duration(seconds: 2));
    expect(find.byKey(const Key('parental-gate-field')), findsOneWidget);
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
  });
}
