import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/domain/balance.dart';
import 'package:my_poodle/domain/pet_state.dart';
import 'package:my_poodle/domain/tutorial.dart';
import 'package:my_poodle/game/pet/pet_painter.dart';
import 'package:my_poodle/game/scenes/stage_game.dart';
import 'package:my_poodle/ui/navigation.dart';
import 'package:my_poodle/ui/screens/care_activity_screens.dart';
import 'package:my_poodle/ui/screens/decor_screen.dart';
import 'package:my_poodle/ui/screens/home_screen.dart';
import 'package:my_poodle/ui/widgets/dialogs.dart';
import 'package:my_poodle/ui/widgets/guide_card.dart';
import 'package:my_poodle/ui/widgets/pet_hearts.dart';
import 'package:my_poodle/ui/widgets/scene_view.dart';

import '../support.dart';
import 'app_flow_test.dart' show boot, frames, idle, saved;
import 'features_test.dart' show backendWith;

PetState seen(PetState s, Set<String> hints, {bool reducedMotion = false}) =>
    s.copyWith(
      prefs: s.prefs.copyWith(
        seenHints: {...s.prefs.seenHints, ...hints},
        reducedMotion: reducedMotion,
      ),
    );

/// Toca el pecho del caniche de Casa (sprite 2D).
Future<void> petThePoodle(WidgetTester t) async {
  final scene = find.byType(SceneView);
  final game = t.widget<SceneView>(scene).game as HomeGame;
  await t.tapAt(t.getTopLeft(scene) + game.pet.landmarkScene('chest'));
  await t.pump();
}

Finder get hearts => find.descendant(
  of: find.byType(PetHearts),
  matching: find.byIcon(Icons.favorite_rounded),
);

void main() {
  setUp(rootBundle.clear);

  group('corazones al acariciar', () {
    testWidgets('salen del punto tocado y se desvanecen en ~1 s', (t) async {
      await boot(t, backendWith((s) => seen(s, {'home.pet'})));
      expect(hearts, findsNothing);
      await petThePoodle(t);
      await frames(t, seconds: 0.3);
      final n = hearts.evaluate().length;
      expect(n, inInclusiveRange(3, 5));
      // Decoración pura: no se anuncia ni intercepta toques.
      expect(
        find.ancestor(
          of: find.byType(PetHearts),
          matching: find.byType(SceneView),
        ),
        findsOneWidget,
      );
      await frames(t, seconds: 1);
      expect(hearts, findsNothing);
      await idle(t);
    });

    testWidgets('con movimiento reducido sale un solo corazón', (t) async {
      await boot(
        t,
        backendWith((s) => seen(s, {'home.pet'}, reducedMotion: true)),
      );
      await petThePoodle(t);
      await frames(t, seconds: 0.3);
      expect(hearts, findsOneWidget);
      await frames(t, seconds: 1);
      expect(hearts, findsNothing);
      await idle(t);
    });
  });

  group('reposos variados en 2D', () {
    Future<Set<PetAnim>> watch(WidgetTester t, {double seconds = 14}) async {
      final game = t.widget<SceneView>(find.byType(SceneView)).game as HomeGame;
      final seenAnims = <PetAnim>{};
      for (var i = 0; i < seconds * 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
        seenAnims.add(game.pet.anim);
      }
      return seenAnims;
    }

    testWidgets('mira hacia arriba al rato, sin tocarlo', (t) async {
      await boot(t, backendWith((s) => seen(s, {'home.pet'})));
      expect(await watch(t), containsAll({PetAnim.idle, PetAnim.lookUp}));
    });

    testWidgets('con movimiento reducido se queda quieto', (t) async {
      await boot(
        t,
        backendWith((s) => seen(s, {'home.pet'}, reducedMotion: true)),
      );
      expect(await watch(t), {PetAnim.idle});
    });
  });

  group('guía de la primera partida', () {
    testWidgets(
      'aparece tras la pista de la caricia, lleva a comer y se puede saltar',
      (t) async {
        final backend = backendWith(
          (s) => s.copyWith(needs100: {...s.needs100, Need.satiety: 3000}),
        );
        await boot(t, backend);
        // Primero, la pista de la caricia; la guía espera.
        expect(find.byType(HintBubble), findsOneWidget);
        expect(find.byType(GuideCard), findsNothing);
        await petThePoodle(t);
        await idle(t);
        expect(find.byType(HintBubble), findsNothing);
        expect(find.text('Primer paso: dale de comer a Miel.'), findsOneWidget);
        // El botón lleva a la misma actividad que «comer» en Casa.
        await t.tap(find.text('Dar de comer').hitTestable());
        await idle(t);
        expect(find.byType(FeedScreen), findsOneWidget);
        Navigator.of(t.element(find.byType(FeedScreen))).pop();
        await idle(t);
        expect(find.byType(GuideCard), findsOneWidget);
        // «Saltar guía» la oculta y queda guardado.
        await t.tap(find.byTooltip('Saltar guía'));
        await idle(t);
        expect(find.byType(GuideCard), findsNothing);
        expect(saved(backend).prefs.seenHints, contains(Tutorial.skipHint));
      },
    );

    testWidgets('el paso de jugar abre la pestaña de juegos', (t) async {
      await boot(
        t,
        backendWith(
          (s) => seen(s, {'home.pet'}).copyWith(careCompletedUtc: {'feed': t0}),
        ),
      );
      final shell = ShellScope.maybeOf(t.element(find.byType(HomeScreen)))!;
      expect(
        find.text('Ahora juega con Miel para ganar monedas.'),
        findsOneWidget,
      );
      await t.tap(find.text('A jugar').hitTestable());
      await idle(t);
      expect(shell.tab, ShellTab.games);
    });

    testWidgets('con la guía completada no aparece', (t) async {
      await boot(
        t,
        backendWith(
          (s) => seen(s, {'home.pet'}).copyWith(
            careCompletedUtc: {'feed': t0},
            bestStars: {'fruit': 0},
            owned: {...s.owned, 'neck.coral'},
          ),
        ),
      );
      expect(find.byType(GuideCard), findsNothing);
      expect(find.byType(HintBubble), findsNothing);
    });
  });

  testWidgets('iconos de estado: anuncian su estado y qué hacen', (t) async {
    final handle = t.ensureSemantics();
    await boot(
      t,
      backendWith(
        (s) => seen(s, {
          'home.pet',
          Tutorial.skipHint,
        }).copyWith(needs100: {...s.needs100, Need.satiety: 1500}),
      ),
    );
    expect(
      t.getSemantics(
        find.bySemanticsLabel('Hambriento: activo. Toca para darle de comer.'),
      ),
      isSemantics(isButton: true, hasTapAction: true),
    );
    expect(
      t.getSemantics(find.bySemanticsLabel('Sucio: bien.')),
      isSemantics(isButton: false, hasTapAction: false),
    );
    expect(find.bySemanticsLabel('Malito: bien.'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('encendido|apagado')), findsNothing);
    handle.dispose();
  });

  testWidgets('la cabecera de Casa abre la decoración del salón', (t) async {
    await boot(t, backendWith((s) => seen(s, {'home.pet'})));
    await t.tap(find.byTooltip('Decorar el salón'));
    await idle(t);
    expect(find.byType(DecorScreen), findsOneWidget);
  });

  for (final step in TutorialStep.values) {
    testWidgets('guía «${step.name}» sin desbordes a 320×568 y texto 1,6', (
      t,
    ) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await boot(
        t,
        backendWith((s) {
          final base = seen(s, {'home.pet'});
          return switch (step) {
            TutorialStep.feed => base,
            TutorialStep.play => base.copyWith(careCompletedUtc: {'feed': t0}),
            TutorialStep.dress => base.copyWith(
              careCompletedUtc: {'feed': t0},
              bestStars: {'fruit': 0},
            ),
          };
        }),
        size: const Size(320, 568),
      );
      expect(find.byType(GuideCard), findsOneWidget);
      expect(find.byTooltip('Saltar guía'), findsOneWidget);
      expect(t.takeException(), isNull);
      await petThePoodle(t);
      await frames(t, seconds: 1.2);
      expect(t.takeException(), isNull);
    });
  }
}
