import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/domain/balance.dart';
import 'package:my_poodle/game/scenes/stage_game.dart';
import 'package:my_poodle/ui/ask_adult_view.dart';
import 'package:my_poodle/ui/navigation.dart';
import 'package:my_poodle/ui/screens/decor_screen.dart';
import 'package:my_poodle/ui/widgets/common.dart';
import 'package:my_poodle/ui/widgets/scene_view.dart';
import 'package:my_poodle/ui/widgets/status_bubbles.dart';

import 'app_flow_test.dart' show boot, idle, reopen, saved, tapText;
import 'features_test.dart' show backendWith;

/// Abre «Decorar el salón» desde Casa (el botón de Casa es de otra pantalla).
Future<void> openDecor(WidgetTester t) async {
  pushScreen<void>(t.element(find.byType(StatusBubbles)), const DecorScreen());
  await idle(t);
  expect(find.byType(DecorScreen), findsOneWidget);
}

HomeGame previewGame(WidgetTester t) =>
    t
            .widget<SceneView>(
              find.descendant(
                of: find.byType(DecorScreen),
                matching: find.byType(SceneView),
              ),
            )
            .game
        as HomeGame;

Finder tileState(String label, String state) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first,
  matching: find.text(state),
);

void main() {
  setUp(rootBundle.clear);

  testWidgets('abre la decoración con saldo, huecos y artículos', (t) async {
    final backend = backendWith((s) => s.copyWith(coins: 100));
    await boot(t, backend);
    await openDecor(t);
    expect(find.text('Decorar el salón'), findsOneWidget);
    for (final slot in ['Alfombra', 'Pared', 'Planta']) {
      expect(find.text(slot), findsOneWidget, reason: slot);
    }
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(CoinBalance),
      ),
      findsOneWidget,
    );
    expect(find.text('Sin alfombra'), findsOneWidget);
    expect(find.text('Alfombra redonda'), findsOneWidget);
    expect(tileState('Sin alfombra', 'Puesto'), findsOneWidget);
    expect(tileState('Alfombra redonda', '40 monedas'), findsOneWidget);
    // Los de la versión completa llevan candado.
    expect(find.byType(LockBadge), findsNWidgets(2));
    expect(find.widgetWithText(AppButton, 'Puesto'), findsOneWidget);
    expect(previewGame(t).decor, {
      DecorSlot.rug: 'rug.none',
      DecorSlot.wall: 'wall.none',
      DecorSlot.plant: 'plant.none',
    });
    await tapText(t, 'Pared');
    expect(find.text('Cuadro de huella'), findsOneWidget);
    expect(find.text('Guirnalda de banderines'), findsOneWidget);
    expect(find.text('Estrellas luminosas'), findsOneWidget);
    await tapText(t, 'Planta');
    for (final name in ['Helecho', 'Maceta de flores', 'Cactus sonriente']) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('tocar una ficha solo previsualiza, sin gastar', (t) async {
    final backend = backendWith((s) => s.copyWith(coins: 100));
    await boot(t, backend);
    final before = saved(backend);
    await openDecor(t);
    await tapText(t, 'Alfombra redonda');
    expect(find.text('Probando'), findsOneWidget);
    expect(previewGame(t).decor[DecorSlot.rug], 'rug.round');
    expect(
      find.widgetWithText(AppButton, 'Comprar y colocar · 40'),
      findsOneWidget,
    );
    expect(saved(backend).coins, before.coins);
    expect(saved(backend).revision, before.revision);
    // Cambiar de hueco descarta la prueba anterior; Descartar vuelve atrás.
    await tapText(t, 'Pared');
    expect(previewGame(t).decor[DecorSlot.rug], 'rug.none');
    await tapText(t, 'Cuadro de huella');
    expect(previewGame(t).decor[DecorSlot.wall], 'wall.frame');
    await tapText(t, 'Descartar');
    expect(previewGame(t).decor[DecorSlot.wall], 'wall.none');
    expect(find.text('Probando'), findsNothing);
    expect(saved(backend).coins, 100);
    expect(saved(backend).decor[DecorSlot.wall], 'wall.none');
  });

  testWidgets('comprar la alfombra redonda con 40 monedas exactas', (t) async {
    final backend = backendWith((s) => s.copyWith(coins: 40));
    await boot(t, backend);
    await openDecor(t);
    await tapText(t, 'Alfombra redonda');
    await tapText(t, 'Comprar y colocar · 40');
    expect(find.text('Saldo restante'), findsOneWidget);
    await tapText(t, 'Confirmar');
    final s = saved(backend);
    expect(s.coins, 0);
    expect(s.decor[DecorSlot.rug], 'rug.round');
    expect(s.owned, contains('rug.round'));
    expect(find.widgetWithText(AppButton, 'Puesto'), findsOneWidget);
    expect(tileState('Alfombra redonda', 'Puesto'), findsOneWidget);
    expect(t.takeException(), isNull);

    // Tras cerrar y abrir, la alfombra sigue puesta.
    await reopen(t, backend);
    await openDecor(t);
    expect(previewGame(t).decor[DecorSlot.rug], 'rug.round');
    expect(tileState('Alfombra redonda', 'Puesto'), findsOneWidget);
    expect(tileState('Sin alfombra', 'Gratis'), findsOneWidget);
    // Quitarla es gratis y la alfombra se conserva en propiedad.
    await tapText(t, 'Sin alfombra');
    await tapText(t, 'Colocar');
    expect(saved(backend).decor[DecorSlot.rug], 'rug.none');
    expect(saved(backend).coins, 0);
    expect(tileState('Alfombra redonda', 'En propiedad'), findsOneWidget);
  });

  testWidgets('candado: pide ayuda a un adulto sin gastar', (t) async {
    final backend = backendWith((s) => s.copyWith(coins: 500));
    await boot(t, backend);
    final before = saved(backend);
    await openDecor(t);
    await tapText(t, 'Alfombra de rayas');
    expect(tileState('Alfombra de rayas', 'Versión completa'), findsOneWidget);
    // La vista previa sí se permite.
    expect(previewGame(t).decor[DecorSlot.rug], 'rug.stripes');
    await t.tap(find.widgetWithText(AppButton, 'Versión completa'));
    await idle(t);
    expect(find.byType(AskAdultScreen), findsOneWidget);
    expect(
      find.text('Esto es de la versión completa. Pide ayuda a un adulto'),
      findsOneWidget,
    );
    expect(saved(backend).coins, before.coins);
    expect(saved(backend).revision, before.revision);
    await tapText(t, 'Volver');
    expect(find.byType(DecorScreen), findsOneWidget);
  });

  testWidgets('saldo insuficiente: muestra lo que falta y lleva a Juegos', (
    t,
  ) async {
    final backend = backendWith((s) => s.copyWith(coins: 10));
    await boot(t, backend);
    await openDecor(t);
    await tapText(t, 'Alfombra redonda');
    await tapText(t, 'Faltan 30 · Jugar');
    expect(find.text('Faltan 30 monedas'), findsOneWidget);
    await tapText(t, 'Ir a Juegos');
    expect(find.byType(DecorScreen), findsNothing);
    expect(find.text('A jugar'), findsOneWidget);
    expect(saved(backend).coins, 10);
    expect(saved(backend).decor[DecorSlot.rug], 'rug.none');
  });

  for (final scale in const [1.0, 1.3]) {
    testWidgets('320×568 con texto ×$scale sin desbordes', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final backend = backendWith((s) => s.copyWith(coins: 30));
      await boot(t, backend, size: const Size(320, 568));
      await openDecor(t);
      expect(t.takeException(), isNull);
      for (final (slot, item) in const [
        ('Alfombra', 'Alfombra redonda'),
        ('Pared', 'Guirnalda de banderines'),
        ('Planta', 'Cactus sonriente'),
      ]) {
        await tapText(t, slot);
        await tapText(t, item);
        expect(t.takeException(), isNull, reason: '$slot · $item');
      }
      expect(find.text('Probando'), findsOneWidget);
    });
  }
}
