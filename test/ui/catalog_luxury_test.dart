import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/game/scenes/decor_painter.dart';
import 'package:my_poodle/ui/widgets/luxury_badge.dart';

import '../support.dart';
import 'app_flow_test.dart' show boot, fullStore, scrollTo, tapText;
import 'decor_test.dart' show openDecor;
import 'features_test.dart' show backendWith;

const _newDecor = [
  'rug.checks',
  'rug.cloud',
  'rug.persian',
  'wall.rainbow',
  'wall.clock',
  'wall.goldframe',
  'plant.sunflower',
  'plant.bonsai',
  'plant.lights',
];

/// Píxeles opacos de un dibujo de [size].
Future<int> _inkOf(void Function(Canvas) draw, Size size) async {
  final rec = ui.PictureRecorder();
  draw(Canvas(rec));
  final image = await rec.endRecording().toImage(
    size.width.toInt(),
    size.height.toInt(),
  );
  final bytes = (await image.toByteData())!;
  var ink = 0;
  for (var i = 3; i < bytes.lengthInBytes; i += 4) {
    if (bytes.getUint8(i) > 0) ink++;
  }
  return ink;
}

void main() {
  setUp(rootBundle.clear);

  group('decoración nueva', () {
    final balance = loadBalance();

    test('cada artículo nuevo dibuja su miniatura y en la sala', () async {
      const room = Size(390, 600);
      final scene = DecorScene(
        art: Offset.zero & room,
        view: Offset.zero & room,
        feet: const Offset(195, 470),
        petSize: 220,
      );
      for (final id in _newDecor) {
        final item = balance.decorItem(id)!;
        expect(DecorPainter.paints(id), isTrue, reason: id);
        final thumb = await _inkOf(
          (c) => DecorPainter.paintThumb(c, const Size(96, 72), id),
          const Size(96, 72),
        );
        expect(thumb, greaterThan(400), reason: 'miniatura $id');
        for (final reduced in [true, false]) {
          final ink = await _inkOf(
            (c) => DecorPainter.paint(
              c,
              item.slot,
              id,
              scene,
              t: 1.7,
              reducedMotion: reduced,
            ),
            room,
          );
          expect(ink, greaterThan(400), reason: 'sala $id');
        }
        final box = DecorPainter.boxIn(item.slot, id, scene);
        expect((Offset.zero & room).contains(box.center), isTrue, reason: id);
      }
    });
  });

  group('fichas de lujo', () {
    testWidgets('armario: insignia «Lujo» y «Te faltan N monedas»', (t) async {
      final semantics = t.ensureSemantics();
      final backend = backendWith((s) => s.copyWith(coins: 120));
      await boot(t, backend, store: fullStore());
      await tapText(t, 'Armario');
      await tapText(t, 'Colores');
      await scrollTo(t, find.text('Pelaje dorado'));
      final tile = find
          .ancestor(
            of: find.text('Pelaje dorado'),
            matching: find.byType(InkWell),
          )
          .first;
      expect(
        find.descendant(of: tile, matching: find.byType(LuxuryBadge)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tile, matching: find.text('Te faltan 380 monedas')),
        findsOneWidget,
      );
      // Un pelaje asequible (110) no lleva ni insignia ni aviso.
      final latte = find
          .ancestor(
            of: find.text('Café con leche'),
            matching: find.byType(InkWell),
          )
          .first;
      expect(
        find.descendant(of: latte, matching: find.byType(LuxuryBadge)),
        findsNothing,
      );
      expect(
        find.descendant(of: latte, matching: find.textContaining('Te faltan')),
        findsNothing,
      );
      // El lector de pantalla oye nombre, lujo, precio y lo que falta, y
      // puede activar la ficha.
      final node = t.getSemantics(
        find.bySemanticsLabel(RegExp('^Pelaje dorado')).first,
      );
      final text = '${node.label} ${node.value}';
      expect(text, contains('Lujo'));
      expect(text, contains('500 monedas'));
      expect(text, contains('Te faltan 380 monedas'));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      semantics.dispose();
    });

    testWidgets('salón: la alfombra persa es lujo del modo gratuito', (
      t,
    ) async {
      final backend = backendWith((s) => s.copyWith(coins: 100));
      await boot(t, backend);
      await openDecor(t);
      await scrollTo(t, find.text('Alfombra persa'));
      final tile = find
          .ancestor(
            of: find.text('Alfombra persa'),
            matching: find.byType(InkWell),
          )
          .first;
      expect(
        find.descendant(of: tile, matching: find.byType(LuxuryBadge)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tile, matching: find.text('380 monedas')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tile, matching: find.text('Te faltan 280 monedas')),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    });
  });

  group('320×568 con texto ×1,6', () {
    testWidgets('armario: pelajes y collares de lujo sin desbordes', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final backend = backendWith((s) => s.copyWith(coins: 40));
      await boot(t, backend, size: const Size(320, 568), store: fullStore());
      await tapText(t, 'Armario');
      await tapText(t, 'Colores');
      await scrollTo(t, find.text('Pelaje dorado'));
      expect(t.takeException(), isNull);
      await tapText(t, 'Pelaje dorado');
      expect(t.takeException(), isNull);
      await tapText(t, 'Accesorios');
      await tapText(t, 'Cuello');
      await scrollTo(t, find.text('Collar de perlas doradas'));
      expect(t.takeException(), isNull);
    });

    testWidgets('salón: metas de lujo de cada hueco sin desbordes', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final backend = backendWith((s) => s.copyWith(coins: 30));
      await boot(t, backend, size: const Size(320, 568), store: fullStore());
      await openDecor(t);
      for (final (slot, item) in const [
        ('Alfombra', 'Alfombra persa'),
        ('Pared', 'Retrato con marco dorado'),
        ('Planta', 'Árbol con luces'),
      ]) {
        await tapText(t, slot);
        await scrollTo(t, find.text(item));
        await tapText(t, item);
        expect(t.takeException(), isNull, reason: '$slot · $item');
      }
      expect(find.text('Probando'), findsOneWidget);
    });
  });
}
