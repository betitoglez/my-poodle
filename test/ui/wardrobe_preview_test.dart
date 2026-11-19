import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/main_wardrobe_preview.dart' as preview;

void main() {
  testWidgets('El visor cambia de conjunto, peinado, ángulo y movimiento', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(preview.main);
    await tester.pumpAndSettle();

    void shows(String frame) {
      final expected = 'assets/images/wardrobe_preview/$frame.webp';
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == expected,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }

    Future<void> choose(String text) async {
      final chip = find.widgetWithText(ChoiceChip, text);
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pump();
    }

    shows('osito-impermeable-frente');
    await choose('Peto');
    await choose('Pompón');
    await choose('Arriba');
    await tester.ensureVisible(find.byType(Image));
    shows('pompon-peto-arriba');

    await choose('Carrera');
    await tester.ensureVisible(find.byType(Image));
    shows('pompon-peto-carrera');

    await choose('Recogida');
    await tester.ensureVisible(find.byType(Image));
    shows('pompon-peto-recogida');
  });
}
