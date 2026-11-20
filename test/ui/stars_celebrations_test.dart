import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/app/app_controller.dart';
import 'package:my_poodle/app/app_scope.dart';
import 'package:my_poodle/domain/rules.dart';
import 'package:my_poodle/ui/navigation.dart';
import 'package:my_poodle/ui/screens/main_shell.dart';
import 'package:my_poodle/ui/screens/results_screens.dart';
import 'package:my_poodle/ui/widgets/celebrations.dart';
import 'package:my_poodle/ui/widgets/coin_count.dart';
import 'package:my_poodle/ui/widgets/star_reveal.dart';

import '../support.dart';
import 'app_flow_test.dart'
    show boot, frames, fullStore, idle, scrollTo, tapText;
import 'features_test.dart' show backendWith;

/// Juega una partida por la entrada normal del controlador (sesión abierta,
/// recibo confirmado y guardado) y devuelve el recibo.
Future<Receipt> play(WidgetTester t, GameId game, int score) async {
  final c = AppScope.read(t.element(find.byType(MainShell)));
  late Receipt receipt;
  await t.runAsync(() async {
    final session = await c.beginGame(game);
    expect(session, isNotNull);
    final r = await c.finishGame(session!, game, score);
    receipt = (r as Done<Receipt>).value;
  });
  return receipt;
}

/// Abre el resultado con la misma ruta y transición que la partida (aquí
/// encima de la raíz, para poder volver a las pestañas).
Future<void> showResult(WidgetTester t, GameId game, Receipt receipt) async {
  pushScreen(
    t.element(find.byType(MainShell)),
    GameResultScreen(game: game, receipt: receipt),
  );
  await t.pump();
}

Iterable<int> starRows(WidgetTester t) =>
    t.widgetList<StarRow>(find.byType(StarRow)).map((w) => w.stars);

void main() {
  setUp(rootBundle.clear);

  testWidgets('frisbee con 5 aciertos: 3 estrellas y nueva mejor marca', (
    t,
  ) async {
    await boot(t, backendWith((s) => s), store: fullStore());
    final receipt = await play(t, GameId.frisbee, 5);
    expect(receipt.stars, 3);
    expect(receipt.newBestStars, isTrue);
    await showResult(t, GameId.frisbee, receipt);
    await frames(t, seconds: 2);
    expect(find.byType(StarReveal), findsOneWidget);
    expect(starRows(t), contains(3));
    expect(find.text('¡Nueva mejor marca de estrellas!'), findsOneWidget);
    expect(find.text('5 de 5 capturas · ¡nuevo récord!'), findsOneWidget);
    expect(t.takeException(), isNull);

    // Segunda partida peor: no hay línea de mejor marca y se conserva la guardada.
    await tapText(t, 'Casa');
    final worse = await play(t, GameId.frisbee, 2);
    expect(worse.stars, 1);
    expect(worse.newBestStars, isFalse);
    expect(worse.after.bestStars['frisbee'], 3);
    await showResult(t, GameId.frisbee, worse);
    await frames(t, seconds: 2);
    expect(starRows(t), contains(1));
    expect(find.text('¡Nueva mejor marca de estrellas!'), findsNothing);
  });

  testWidgets(
    'las monedas cuentan hasta el valor final y la semántica lo anuncia',
    (t) async {
      await boot(
        t,
        backendWith((s) => s.copyWith(coins: 7)),
        store: fullStore(),
      );
      final handle = t.ensureSemantics();
      final receipt = await play(t, GameId.frisbee, 5);
      final earned = receipt.coinsEarned;
      final total = receipt.after.coins;
      expect(total, 7 + earned);
      await showResult(t, GameId.frisbee, receipt);
      await t.pump(const Duration(milliseconds: 120));
      // A mitad de cuenta el texto aún no es el final, pero el lector sí oye
      // el valor final y nunca los intermedios.
      expect(find.text('+$earned monedas'), findsNothing);
      expect(find.text('Saldo $total'), findsNothing);
      expect(find.bySemanticsLabel('+$earned monedas'), findsOneWidget);
      expect(find.bySemanticsLabel('Saldo $total'), findsOneWidget);
      await frames(t, seconds: 1.2);
      expect(find.text('+$earned monedas'), findsOneWidget);
      expect(find.text('Saldo $total'), findsOneWidget);
      expect(find.bySemanticsLabel('3 de 3 estrellas'), findsWidgets);
      handle.dispose();
    },
  );

  testWidgets('la tarjeta de cada juego muestra la mejor marca guardada', (
    t,
  ) async {
    final handle = t.ensureSemantics();
    await boot(
      t,
      backendWith((s) => s.copyWith(bestStars: {'fruit': 1, 'frisbee': 2})),
      store: fullStore(),
    );
    await tapText(t, 'Juegos');
    await t.ensureVisible(find.text('Frisbee en el prado'));
    await idle(t);
    expect(starRows(t), containsAll([1, 2]));
    expect(
      find.bySemanticsLabel(RegExp(r'Mejor marca: 2 de 3 estrellas\.$')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'Mejor marca: 1 de 3 estrellas\.$')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('las instrucciones listan los retos con números del balance', (
    t,
  ) async {
    final b = loadBalance();
    await boot(t, backendWith((s) => s), store: fullStore());
    await tapText(t, 'Juegos');
    await t.ensureVisible(find.text('Frisbee en el prado'));
    await idle(t);
    await tapText(t, 'Frisbee en el prado');
    expect(find.text('Retos de estrellas'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      final line = 'Estrella ${i + 1}: ${b.frisbee.starCatches[i]} capturas';
      await scrollTo(t, find.text(line));
      expect(find.text(line), findsOneWidget);
    }
    expect(find.text('Los objetivos cambian en cada partida.'), findsOneWidget);
    await tapText(t, 'Volver');

    await t.ensureVisible(find.text('Huerto saltarín'));
    await idle(t);
    await tapText(t, 'Huerto saltarín');
    final fruit = [
      'Estrella 1: ${b.fruit.starFruits[0]} frutas',
      'Estrella 2: ${b.fruit.starFruits[1]} frutas',
      'Estrella 3: ${b.fruit.starFruits[1]} frutas y las ${b.fruit.starGolden} doradas',
      'Cada partida esconde ${b.fruit.starGolden} frutas doradas.',
    ];
    for (final line in fruit) {
      await scrollTo(t, find.text(line));
      expect(find.text(line), findsOneWidget);
    }
    // Las cifras son las del balance actual (16 frutas y 3 doradas).
    expect(fruit[2], 'Estrella 3: 16 frutas y las 3 doradas');
  });

  testWidgets('con movimiento reducido no queda ninguna animación pendiente', (
    t,
  ) async {
    await boot(
      t,
      backendWith(
        (s) =>
            s.copyWith(coins: 4, prefs: s.prefs.copyWith(reducedMotion: true)),
      ),
      store: fullStore(),
    );
    final receipt = await play(t, GameId.frisbee, 5);
    await showResult(t, GameId.frisbee, receipt);
    // Un único fotograma: ruta sin transición, estrellas y monedas finales.
    final route = ModalRoute.of(t.element(find.byType(GameResultScreen)))!;
    expect(route.animation!.status, AnimationStatus.completed);
    expect(starRows(t), contains(3));
    expect(
      find.descendant(
        of: find.byType(StarReveal),
        matching: find.byType(AnimatedBuilder),
      ),
      findsNothing,
    );
    expect(find.text('+${receipt.coinsEarned} monedas'), findsOneWidget);
    expect(find.text('Saldo ${receipt.after.coins}'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CountUpText),
        matching: find.byType(AnimatedBuilder),
      ),
      findsNothing,
    );
    // El cambio de pestaña tampoco se anima.
    await tapText(t, 'Casa');
    await t.tap(find.text('Juegos').hitTestable().first);
    await t.pump();
    final fade = t.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('A jugar'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, 1);
    await idle(t);
    expect(t.takeException(), isNull);
  });

  testWidgets('sin movimiento reducido las transiciones se animan y terminan', (
    t,
  ) async {
    await boot(t, backendWith((s) => s), store: fullStore());
    await t.tap(find.text('Juegos').hitTestable().first);
    await t.pump();
    await t.pump(const Duration(milliseconds: 60));
    final fade = t.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('A jugar'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, inExclusiveRange(0, 1));
    await idle(t);
    final ctx = t.element(find.byType(MainShell));
    expect(navigationReducedMotion(ctx), isFalse);
    pushScreen(ctx, const Scaffold(body: Text('Destino')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    final route = ModalRoute.of(t.element(find.text('Destino')))!;
    expect(route, isA<SoftPageRoute<dynamic>>());
    expect(route.animation!.value, inExclusiveRange(0, 1));
    await t.pump(SoftPageRoute.duration);
    expect(route.animation!.status, AnimationStatus.completed);
  });

  for (final screen in ['Juegos', 'Instrucciones', 'Resultado']) {
    testWidgets('$screen sin desbordes a 320×568 con texto ×1,6', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await boot(
        t,
        backendWith((s) => s.copyWith(bestStars: {'fruit': 2, 'frisbee': 1})),
        size: const Size(320, 568),
        store: fullStore(),
      );
      switch (screen) {
        case 'Juegos':
          await tapText(t, 'Juegos');
          await scrollTo(t, find.text('Frisbee en el prado'));
          await scrollTo(t, find.text('Jugar').last);
          await idle(t);
        case 'Instrucciones':
          await tapText(t, 'Juegos');
          await tapText(t, 'Huerto saltarín');
          await scrollTo(t, find.text('Retos de estrellas'));
          await scrollTo(
            t,
            find.text('Cada partida esconde 3 frutas doradas.'),
          );
          await idle(t);
        case 'Resultado':
          final receipt = await play(t, GameId.frisbee, 5);
          await showResult(t, GameId.frisbee, receipt);
          await frames(t, seconds: 2);
          expect(find.text('¡Nueva mejor marca de estrellas!'), findsOneWidget);
          await t.drag(find.byType(Scrollable).last, const Offset(0, -2000));
          await idle(t);
          expect(find.text('Casa').hitTestable(), findsWidgets);
      }
      expect(t.takeException(), isNull, reason: screen);
    });
  }
}
