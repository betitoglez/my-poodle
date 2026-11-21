import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/app/feedback.dart';
import 'package:my_poodle/domain/games/memory_sim.dart';
import 'package:my_poodle/ui/screens/puzzle_screens.dart';
import 'package:my_poodle/ui/widgets/activity_frame.dart';

import 'app_flow_test.dart'
    show boot, frames, fullStore, idle, scrollTo, tapText;
import 'features_test.dart' show backendWith;
import 'puzzle_accessibility_test.dart' show pads;
import 'puzzle_games_test.dart' show ready;

class _SilentPlayback implements EffectPlayback {
  final played = <Sfx>[];
  @override
  void play(Sfx effect) => played.add(effect);
  @override
  void setLoops(Set<Sfx> effects) {}
  @override
  void stop() {}
  @override
  void dispose() {}
}

void main() {
  setUp(rootBundle.clear);
  testWidgets(
    'la región viva distingue colores consecutivos y no se borra durante la pausa',
    (t) async {
      final handle = t.ensureSemantics();
      final sim = MemorySim([0, 0, 1, 2, 3, 0, 1, 2, 3, 0]);
      Future<String> label() async {
        await t.pumpWidget(MaterialApp(home: MemorySignalStatus(sim: sim)));
        final data = t
            .getSemantics(find.byKey(const ValueKey('memory-signal')))
            .getSemanticsData();
        expect(data.flagsCollection.isLiveRegion, isTrue);
        return data.label;
      }

      sim.update(.55);
      expect(await label(), 'Rojo, Do. Paso 1 de 3.');
      sim.update(.6);
      expect(sim.lit, isNull);
      expect(await label(), 'Rojo, Do. Paso 1 de 3.');
      sim.update(.25);
      expect(await label(), 'Rojo, Do. Paso 2 de 3.');
      sim.update(.85);
      expect(await label(), 'Azul, Mi. Paso 3 de 3.');
      handle.dispose();
    },
  );

  testWidgets(
    'Memory sin efectos: se escucha la secuencia por semántica y se responde sin leer el guardado',
    (t) async {
      final handle = t.ensureSemantics();
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final playback = _SilentPlayback();
      await boot(
        t,
        backendWith((s) => s.copyWith(prefs: s.prefs.copyWith(effects: false))),
        store: fullStore(),
        effectPlayback: playback,
      );
      await tapText(t, 'Juegos');
      await scrollTo(t, find.text('Memory de caniches'));
      await tapText(t, 'Memory de caniches');
      await scrollTo(t, find.text('Jugar'));
      await tapText(t, 'Jugar');
      await ready(t);
      final heard = <String>[];
      var pausedDuringDemo = false;
      final game = t.widget<ActivityFrame>(find.byType(ActivityFrame)).game;
      final cue = find.byKey(const ValueKey('memory-signal'));
      final pattern = RegExp(r'^(.*)\. Paso (\d+) de 3\.$');
      for (
        var i = 0;
        i < 300 && find.text('Tu turno: 0 / 3').evaluate().isEmpty;
        i++
      ) {
        final data = t.getSemantics(cue).getSemanticsData();
        final match = pattern.firstMatch(data.label);
        if (match != null && int.parse(match[2]!) == heard.length + 1) {
          expect(data.flagsCollection.isLiveRegion, isTrue);
          heard.add(match[1]!);
          if (!pausedDuringDemo) {
            pausedDuringDemo = true;
            game.pauseEngine();
            await t.pump(const Duration(seconds: 3));
            expect(t.getSemantics(cue).getSemanticsData().label, data.label);
            game.resumeEngine();
            await frames(t, seconds: .1);
          }
        }
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(heard, hasLength(3));
      game.pauseEngine();
      final paused = t.getSemantics(cue).getSemanticsData().label;
      await t.pump(const Duration(seconds: 3));
      expect(t.getSemantics(cue).getSemanticsData().label, paused);
      game.resumeEngine();
      await frames(t, seconds: .1);
      for (final signal in heard) {
        expect(pads, contains(signal));
        t.semantics.tap(find.semantics.byLabel(signal));
        await t.pump(const Duration(milliseconds: 30));
      }
      expect(find.text('¡Muy bien! Siguiente ronda…'), findsOneWidget);
      expect(
        playback.played.where((s) => s.file.startsWith('memory_')),
        isEmpty,
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await idle(t);
      handle.dispose();
    },
  );
}
