import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/ui/widgets/dialogs.dart';

void main() {
  testWidgets('pulsación mantenida de 2 s desbloquea; soltar antes no', (
    t,
  ) async {
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
    final short = await t.startGesture(
      t.getCenter(find.byType(AdultGateButton)),
    );
    for (var i = 0; i < 30; i++) {
      await t.pump(const Duration(milliseconds: 33));
    }
    await short.up();
    await t.pump(const Duration(seconds: 3));
    expect(unlocked, 0);
    final g = await t.startGesture(t.getCenter(find.byType(AdultGateButton)));
    for (var i = 0; i < 70; i++) {
      await t.pump(const Duration(milliseconds: 33));
    }
    await g.up();
    await t.pump();
    expect(unlocked, 1);
  });
}
