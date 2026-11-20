import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/app/feedback.dart';

import 'app_flow_test.dart' show boot, frames, idle, saved, tapIcon, tapText;
import 'features_test.dart' show backendWith;

class _RecordingPlayback implements EffectPlayback {
  final played = <Sfx>[];
  Set<Sfx> loops = {};
  int stops = 0;

  @override
  void play(Sfx effect) => played.add(effect);
  @override
  void setLoops(Set<Sfx> effects) => loops = {...effects};
  @override
  void stop() {
    stops++;
    loops.clear();
  }

  @override
  void dispose() {}
}

void main() {
  setUp(rootBundle.clear);

  testWidgets('los 37 efectos activos tienen un MP3 único en el paquete', (
    _,
  ) async {
    final assets = {for (final effect in Sfx.values) effect.asset};
    expect(assets, hasLength(37));
    expect(assets, isNot(contains('audio/sfx/step_grass.mp3')));
    expect(assets, isNot(contains('audio/sfx/step_indoor.mp3')));
    for (final asset in assets) {
      expect(
        (await rootBundle.load('assets/$asset')).lengthInBytes,
        greaterThan(1000),
        reason: asset,
      );
    }
  });

  testWidgets('el ajuste Efectos silencia y vuelve a activar el bocado', (
    t,
  ) async {
    final backend = backendWith((s) => s);
    final sound = _RecordingPlayback();
    await boot(t, backend, effectPlayback: sound);

    Future<void> setEffects(bool enabled) async {
      await tapIcon(t, Icons.settings_rounded);
      await tapText(t, 'Efectos');
      expect(saved(backend).prefs.effects, enabled);
      Navigator.of(t.element(find.text('Efectos'))).pop();
      await idle(t);
    }

    Future<void> feed() async {
      await tapText(t, 'Cuidados');
      await tapText(t, 'Comer');
      await tapText(t, 'Pienso diario · Gratis');
      await tapText(t, 'Dar un bocado');
    }

    await setEffects(false);
    expect(sound.stops, 1);
    sound.played.clear();
    await feed();
    expect(sound.played, isEmpty);
    await tapIcon(t, Icons.close_rounded);
    await tapText(t, 'Salir');
    await tapText(t, 'Casa');
    await setEffects(true);
    await feed();
    expect(sound.played.where((event) => event == Sfx.bite), hasLength(1));
  });

  testWidgets('la ducha suena durante la pulsación y para en segundo plano', (
    t,
  ) async {
    final sound = _RecordingPlayback();
    await boot(t, backendWith((s) => s), effectPlayback: sound);
    await tapText(t, 'Cuidados');
    await tapText(t, 'Bañar');
    await tapText(t, 'Baño estándar · Gratis');
    await tapText(t, 'Empezar el baño');

    final shower = find.text('Mantén: ducha');
    final first = await t.startGesture(t.getCenter(shower));
    await frames(t, seconds: .4);
    expect(sound.loops, {Sfx.shower});
    expect(sound.played, contains(Sfx.splash));
    await first.up();
    await t.pump();
    expect(sound.loops, isEmpty);

    final second = await t.startGesture(t.getCenter(shower));
    await frames(t, seconds: .4);
    expect(sound.loops, {Sfx.shower});
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump();
    expect(sound.loops, isEmpty);
    await second.up();
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    expect(sound.loops, isEmpty);
    await tapText(t, 'Continuar');
    expect(sound.loops, isEmpty);
  });
}
