import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/app/background_music.dart';

import '../music_player_fake.dart';
import 'app_flow_test.dart' show boot, saved, tapIcon, tapText, idle, frames;
import 'features_test.dart' show backendWith;

void main() {
  setUp(rootBundle.clear);

  testWidgets('menús, juego, pausa y resultado eligen su pista', (t) async {
    final player = FakeMusicPlayer();
    final music = BackgroundMusic(player: player);
    await boot(t, backendWith((s) => s), music: music);
    await tapText(t, 'Juegos');
    await t.ensureVisible(find.text('Frisbee en el prado'));
    await tapText(t, 'Frisbee en el prado');
    expect(player.tracks, [MusicTrack.home]);
    await tapText(t, 'Jugar');
    expect(player.tracks, [MusicTrack.home, MusicTrack.games]);
    await tapIcon(t, Icons.pause_circle_rounded);
    expect(player.calls.last, 'pause');
    await tapText(t, 'Continuar');
    expect(player.calls, ['resume', 'resume', 'pause', 'resume']);
    expect(player.tracks, [MusicTrack.home, MusicTrack.games]);
    for (var i = 0; i < 5; i++) {
      await tapText(t, 'Lanzar al aro');
      await frames(t, seconds: 2.8);
    }
    await idle(t);
    expect(player.tracks, [MusicTrack.home, MusicTrack.games, MusicTrack.home]);
    await tapText(t, 'Casa');
    expect(player.tracks.length, 3);
  });

  testWidgets('cuidados cambian de pista y el resultado vuelve a Casa', (
    t,
  ) async {
    final player = FakeMusicPlayer();
    final music = BackgroundMusic(player: player);
    await boot(t, backendWith((s) => s), music: music);
    await tapText(t, 'Cuidados');
    expect(player.tracks, [MusicTrack.home]);
    await tapText(t, 'Comer');
    expect(player.tracks.last, MusicTrack.activities);
    await tapText(t, 'Pienso diario · Gratis');
    for (var i = 0; i < 3; i++) {
      await tapText(t, 'Dar un bocado');
      await frames(t, seconds: 1.5);
    }
    await idle(t);
    expect(player.tracks, [
      MusicTrack.home,
      MusicTrack.activities,
      MusicTrack.home,
    ]);
  });

  testWidgets('menú dentro de peluquería restaura la pista al volver', (
    t,
  ) async {
    final player = FakeMusicPlayer();
    await boot(
      t,
      backendWith((s) => s),
      music: BackgroundMusic(player: player),
    );
    await tapText(t, 'Cuidados');
    await tapText(t, 'Peluquería');
    expect(player.tracks.last, MusicTrack.activities);
    await tapText(t, 'Probar cortes');
    expect(player.tracks.last, MusicTrack.home);
    await t.tap(find.byType(BackButton));
    await idle(t);
    expect(player.tracks.last, MusicTrack.activities);
    await tapIcon(t, Icons.close_rounded);
    expect(player.tracks.last, MusicTrack.home);
  });

  testWidgets('música respeta ajustes guardados y segundo plano', (t) async {
    final backend = backendWith(
      (s) => s.copyWith(prefs: s.prefs.copyWith(music: false)),
    );
    final player = FakeMusicPlayer();
    final music = BackgroundMusic(player: player);
    await boot(t, backend, music: music);
    expect(player.calls, isEmpty);
    await tapIcon(t, Icons.settings_rounded);
    await tapText(t, 'Música');
    await music.settled;
    expect(saved(backend).prefs.music, isTrue);
    expect(player.calls, ['resume']);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump();
    await music.settled;
    expect(player.calls.last, 'pause');
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    await music.settled;
    expect(player.calls.last, 'resume');
    await tapText(t, 'Música');
    expect(saved(backend).prefs.music, isFalse);
    expect(player.calls.last, 'pause');
    await t.pumpWidget(const SizedBox());
    await idle(t);
    expect(player.calls.last, 'dispose');
    final reopened = FakeMusicPlayer();
    await boot(t, backend, music: BackgroundMusic(player: reopened));
    expect(reopened.calls, isEmpty);
  });
}
