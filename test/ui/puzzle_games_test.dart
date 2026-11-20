import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/app/app_controller.dart';
import 'package:my_poodle/app/app_scope.dart';
import 'package:my_poodle/app/feedback.dart';
import 'package:my_poodle/domain/games/puzzle_deals.dart';
import 'package:my_poodle/domain/rules.dart';
import 'package:my_poodle/store/simulated_store.dart';
import 'package:my_poodle/ui/screens/puzzle_screens.dart';
import 'package:my_poodle/ui/widgets/activity_frame.dart';
import 'package:my_poodle/ui/widgets/common.dart';
import 'package:my_poodle/ui/widgets/status_bubbles.dart';

import 'app_flow_test.dart'
    show boot, frames, idle, saved, reopen, scrollTo, tapText;
import 'features_test.dart' show backendWith;
import 'premium_trial_test.dart' show FailTrialWrite;

class _Sound implements EffectPlayback {
  final notes = <Sfx>[];
  @override
  void play(Sfx effect) {
    if (effect.file.startsWith('memory_')) notes.add(effect);
  }

  @override
  void setLoops(Set<Sfx> effects) {}
  @override
  void stop() {}
  @override
  void dispose() {}
}

Future<void> openPuzzle(WidgetTester t, String title) async {
  await tapText(t, 'Juegos');
  await scrollTo(t, find.text(title));
  await tapText(t, title);
}

Future<void> ready(WidgetTester t) async {
  for (
    var i = 0;
    i < 60 && find.byType(ActivityFrame).evaluate().isEmpty;
    i++
  ) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await t.pump(const Duration(milliseconds: 16));
  }
  expect(find.byType(ActivityFrame), findsOneWidget);
}

Future<void> capture(WidgetTester t, String name) async {
  if (!const bool.fromEnvironment('PUZZLE_CAPTURE')) return;
  await t.pump();
  final boundary = t.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  await t.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('docs/reviews/minigames/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUp(rootBundle.clear);
  setUpAll(() async {
    if (!const bool.fromEnvironment('PUZZLE_CAPTURE')) return;
    final flutterRoot =
        Platform.environment['FLUTTER_ROOT'] ?? '/opt/homebrew/share/flutter';
    for (final entry in {
      'Roboto': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf',
    }.entries) {
      final font = File(
        '$flutterRoot/bin/cache/artifacts/material_fonts/${entry.value}',
      );
      final loader = FontLoader(entry.key)
        ..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())));
      await loader.load();
    }
  });

  testWidgets(
    'Parejas: selector 6, partida completa, pago único y récord tras reinicio',
    (t) async {
      final backend = backendWith((s) => s);
      await boot(t, backend);
      await openPuzzle(t, 'Juego de parejas');
      await tapText(t, '6 parejas');
      await scrollTo(t, find.text('Jugar'));
      await tapText(t, 'Jugar');
      await ready(t);
      expect(find.byType(PairsScreen), findsOneWidget);
      final screen = t.widget<PairsScreen>(find.byType(PairsScreen));
      expect(screen.pairs, 6);
      final state = saved(backend);
      final cards = PuzzleDeals.decode(state.puzzleDeals['pairs-6']!.last);
      final c = AppScope.read(t.element(find.byType(PairsScreen)));
      final session = c.sessions;
      // La cartera solo se confirma al terminar, con el ID de la sesión real.
      expect(state.coins, 0);
      await capture(t, 'pairs-6');
      for (final dog in cards.toSet()) {
        for (var index = 0; index < cards.length; index++) {
          if (cards[index] != dog) continue;
          await t.tap(find.byKey(ValueKey('pair-card-$index')));
          await t.pump(const Duration(milliseconds: 30));
        }
      }
      await idle(t);
      expect(find.text('+15 monedas'), findsOneWidget);
      expect(saved(backend).coins, 15);
      expect(saved(backend).bestPairs, 6);
      final opId = saved(backend).lastCommitId;
      expect(session.isOpen(opId), isFalse);
      final again = await c.finishGame(opId, GameId.pairs, 6);
      expect(again, isA<Done>());
      expect(saved(backend).coins, 15);
      await reopen(t, backend);
      expect(saved(backend).bestPairs, 6);
      expect(
        saved(backend).puzzleDeals['pairs-6'],
        state.puzzleDeals['pairs-6'],
      );
    },
  );

  testWidgets(
    'Parejas: pausa en segundo plano congela el contador y salir no paga',
    (t) async {
      final backend = backendWith((s) => s);
      await boot(t, backend);
      await openPuzzle(t, 'Juego de parejas');
      await scrollTo(t, find.text('Jugar'));
      await tapText(t, 'Jugar');
      await ready(t);
      final game = t.widget<ActivityFrame>(find.byType(ActivityFrame)).game;
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await t.pump();
      final timer = find.text('60 s');
      expect(timer, findsOneWidget);
      await frames(t, seconds: 4);
      expect(timer, findsOneWidget);
      expect(game.paused, isTrue);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      expect(game.paused, isTrue);
      await tapText(t, 'Continuar');
      await frames(t, seconds: 1.2);
      expect(find.text('60 s'), findsNothing);
      await t.tap(find.byIcon(Icons.close_rounded));
      await idle(t);
      await tapText(t, 'Salir');
      expect(find.byType(PairsScreen), findsNothing);
      expect(saved(backend).coins, 0);
      expect(saved(backend).puzzleDeals['pairs-4'], hasLength(1));
    },
  );

  testWidgets('Memory: gratuita bloqueada y acceso directo sin sesión', (
    t,
  ) async {
    final backend = backendWith((s) => s);
    await boot(t, backend);
    final c = AppScope.read(t.element(find.byType(StatusBubbles)));
    expect(c.canPlay(GameId.memory), isFalse);
    expect(c.isGameTrial(GameId.memory), isFalse);
    expect(await c.beginGame(GameId.memory), isNull);
    expect(saved(backend).puzzleDeals, isEmpty);
    await openPuzzle(t, 'Memory de caniches');
    expect(find.byType(MemoryScreen), findsNothing);
    expect(
      find.text('Esto es de la versión completa. Pide ayuda a un adulto'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Memory: colores emiten notas, primer premio y tiempo máximo por respuesta',
    (t) async {
      final backend = backendWith((s) => s);
      final sound = _Sound();
      await boot(
        t,
        backend,
        store: SimulatedStore(owned: true, delay: Duration.zero),
        effectPlayback: sound,
      );
      await openPuzzle(t, 'Memory de caniches');
      await scrollTo(t, find.text('Jugar'));
      await tapText(t, 'Jugar');
      await ready(t);
      final sequence = PuzzleDeals.decode(
        saved(backend).puzzleDeals['memory']!.last,
      );
      for (
        var i = 0;
        i < 100 && find.text('Tu turno: 0 / 3').evaluate().isEmpty;
        i++
      ) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Tu turno: 0 / 3'), findsOneWidget);
      const sounds = [
        Sfx.memoryRed,
        Sfx.memoryBlue,
        Sfx.memoryGreen,
        Sfx.memoryYellow,
      ];
      expect(sound.notes.take(3), sequence.take(3).map((n) => sounds[n]));
      await capture(t, 'memory');
      final controller = AppScope.read(t.element(find.byType(MemoryScreen)));
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await t.pump();
      await frames(t, seconds: 12);
      expect(find.text('10 s'), findsOneWidget);
      expect(sound.notes, hasLength(3));
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      await tapText(t, 'Continuar');
      await controller.updatePrefs(controller.prefs.copyWith(effects: false));
      for (final signal in sequence.take(3)) {
        await t.tap(find.byKey(ValueKey('memory-pad-$signal')));
        await t.pump(const Duration(milliseconds: 40));
      }
      expect(
        find.byWidgetPredicate(
          (w) => w is CoinText && w.source == 'Premio alcanzado: 5 monedas',
        ),
        findsOneWidget,
      );
      expect(saved(backend).coins, 0);
      for (
        var i = 0;
        i < 140 && find.text('Tu turno: 0 / 4').evaluate().isEmpty;
        i++
      ) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Tu turno: 0 / 4'), findsOneWidget);
      expect(
        sound.notes,
        hasLength(3),
        reason: 'se puede jugar con efectos silenciados',
      );
      await frames(t, seconds: 10.2);
      await idle(t);
      expect(find.text('Se acabó el tiempo'), findsOneWidget);
      expect(saved(backend).coins, 5);
      expect(saved(backend).bestMemory, 3);
    },
  );

  testWidgets(
    'inicio fallido no reserva reparto; inicios concurrentes siempre distintos',
    (t) async {
      final backend = FailTrialWrite()
        ..files.addAll(backendWith((s) => s).files);
      await boot(t, backend);
      final c = AppScope.read(t.element(find.byType(StatusBubbles)));
      backend.fail = true;
      expect(await c.beginGame(GameId.pairs), isNull);
      expect(saved(backend).puzzleDeals, isEmpty);
      backend.fail = false;
      final ids = await Future.wait([
        c.beginGame(GameId.pairs),
        c.beginGame(GameId.pairs),
      ]);
      expect(ids.whereType<String>(), hasLength(2));
      final deals = saved(backend).puzzleDeals['pairs-4']!;
      expect(deals, hasLength(2));
      expect(deals.toSet(), hasLength(2));
      for (final id in ids.whereType<String>()) {
        c.cancelActivity(id);
      }
    },
  );

  for (final size in [const Size(320, 568), const Size(844, 390)]) {
    testWidgets('tableros completos sin overflow a $size', (t) async {
      final backend = backendWith((s) => s);
      await boot(
        t,
        backend,
        size: size,
        store: SimulatedStore(owned: true, delay: Duration.zero),
      );
      await openPuzzle(t, 'Juego de parejas');
      await scrollTo(t, find.text('8 parejas'));
      await tapText(t, '8 parejas');
      await scrollTo(t, find.text('Jugar'));
      await scrollTo(t, find.text('Jugar'));
      await tapText(t, 'Jugar');
      await ready(t);
      for (var i = 0; i < 16; i++) {
        expect(
          find.byKey(ValueKey('pair-card-$i')).hitTestable(),
          findsOneWidget,
        );
      }
      await capture(t, 'pairs-8-${size.width.toInt()}');
      expect(t.takeException(), isNull);
    });
  }
}
