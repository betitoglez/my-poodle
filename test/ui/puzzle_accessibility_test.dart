import 'dart:ui' show SemanticsAction;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/domain/games/puzzle_deals.dart';
import 'package:my_poodle/store/simulated_store.dart';
import 'package:my_poodle/ui/widgets/activity_frame.dart';

import 'app_flow_test.dart' show boot, frames, idle, saved, scrollTo, tapText;
import 'features_test.dart' show backendWith;
import 'puzzle_games_test.dart' show openPuzzle, ready;

Finder card(int index) =>
    find.bySemanticsLabel(RegExp('^Carta ${index + 1}(?:,|:)'));
const pads = ['Rojo, Do', 'Azul, Mi', 'Verde, Sol', 'Amarillo, Do agudo'];

bool hasTap(WidgetTester t, Finder finder) =>
    t.getSemantics(finder).getSemanticsData().hasAction(SemanticsAction.tap);

Future<void> start(WidgetTester t, String title) async {
  await openPuzzle(t, title);
  await scrollTo(t, find.text('Jugar'));
  await tapText(t, 'Jugar');
  await ready(t);
}

void main() {
  setUp(rootBundle.clear);

  testWidgets('Parejas se completa con acciones del lector de pantalla', (
    t,
  ) async {
    final handle = t.ensureSemantics();
    final backend = backendWith((s) => s);
    await boot(t, backend);
    await start(t, 'Juego de parejas');
    final cards = PuzzleDeals.decode(
      saved(backend).puzzleDeals['pairs-4']!.last,
    );
    expect(hasTap(t, card(0)), isTrue);
    final game = t.widget<ActivityFrame>(find.byType(ActivityFrame)).game;
    final stale = t.getSemantics(card(0));
    game.pauseEngine();
    // Incluso una acción encolada antes de pausar debe volver a comprobarlo.
    stale.owner!.performAction(stale.id, SemanticsAction.tap);
    await t.pump();
    expect(find.bySemanticsLabel('Carta 1, boca abajo'), findsOneWidget);
    game.resumeEngine();
    await frames(t, seconds: .1);

    for (final dog in cards.toSet()) {
      for (var index = 0; index < cards.length; index++) {
        if (cards[index] != dog) continue;
        expect(hasTap(t, card(index)), isTrue);
        t.semantics.tap(
          find.semantics.byLabel(RegExp('^Carta ${index + 1}(?:,|:)')),
        );
        await t.pump(const Duration(milliseconds: 30));
        if (saved(backend).coins == 0) {
          expect(hasTap(t, card(index)), isFalse);
        }
      }
    }
    await idle(t);
    expect(saved(backend).coins, 5);
    expect(find.text('¡Todas las parejas!'), findsOneWidget);
    handle.dispose();
  });

  testWidgets(
    'Memory expone acciones solo durante la respuesta y respeta pausa',
    (t) async {
      final handle = t.ensureSemantics();
      final backend = backendWith((s) => s);
      await boot(
        t,
        backend,
        store: SimulatedStore(owned: true, delay: Duration.zero),
      );
      await start(t, 'Memory de caniches');
      for (final label in pads) {
        expect(hasTap(t, find.bySemanticsLabel(label)), isFalse);
      }
      for (
        var i = 0;
        i < 100 && find.text('Tu turno: 0 / 3').evaluate().isEmpty;
        i++
      ) {
        await t.pump(const Duration(milliseconds: 50));
      }
      final sequence = PuzzleDeals.decode(
        saved(backend).puzzleDeals['memory']!.last,
      );
      final first = find.bySemanticsLabel(pads[sequence.first]);
      expect(hasTap(t, first), isTrue);
      final game = t.widget<ActivityFrame>(find.byType(ActivityFrame)).game;
      final stale = t.getSemantics(first);
      game.pauseEngine();
      stale.owner!.performAction(stale.id, SemanticsAction.tap);
      await t.pump();
      expect(find.text('Tu turno: 0 / 3'), findsOneWidget);
      game.resumeEngine();
      await frames(t, seconds: .1);
      for (final signal in sequence.take(3)) {
        expect(hasTap(t, find.bySemanticsLabel(pads[signal])), isTrue);
        t.semantics.tap(find.semantics.byLabel(pads[signal]));
        await t.pump(const Duration(milliseconds: 40));
      }
      expect(find.text('Premio alcanzado: 5 monedas'), findsOneWidget);
      for (final label in pads) {
        expect(hasTap(t, find.bySemanticsLabel(label)), isFalse);
      }
      await frames(t, seconds: 4.8);
      expect(find.text('Tu turno: 0 / 4'), findsOneWidget);
      for (final label in pads) {
        expect(hasTap(t, find.bySemanticsLabel(label)), isTrue);
      }
      handle.dispose();
    },
  );
}
