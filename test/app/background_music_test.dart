import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/app/background_music.dart';

import '../music_player_fake.dart';

void main() {
  final interruptions = <String, void Function(BackgroundMusic)>{
    'silenciar': (music) => music.setEnabled(false),
    'pausar actividad': (music) => music.setActivityPaused(true),
    'segundo plano': (music) => music.setForeground(false),
  };
  for (final interruption in interruptions.entries) {
    test(
      '${interruption.key} durante la preparación impide arrancar',
      () async {
        final pending = Completer<void>();
        final player = FakeMusicPlayer()..pendingSelection = pending;
        final music = BackgroundMusic(player: player);
        music.setEnabled(true);
        await Future<void>.delayed(Duration.zero);
        expect(player.tracks, [MusicTrack.home]);
        interruption.value(music);
        pending.complete();
        await music.settled;
        expect(
          player.calls,
          isEmpty,
          reason: 'No debe iniciar audio tras pedir silencio',
        );
        music.setEnabled(true);
        music.setActivityPaused(false);
        music.setForeground(true);
        await music.settled;
        expect(player.calls, ['resume']);
        expect(player.tracks, [MusicTrack.home]);
        await music.dispose();
      },
    );
  }

  test('destruir durante la preparación libera sin arrancar', () async {
    final pending = Completer<void>();
    final player = FakeMusicPlayer()..pendingSelection = pending;
    final music = BackgroundMusic(player: player);
    music.setEnabled(true);
    await Future<void>.delayed(Duration.zero);
    expect(player.tracks, [MusicTrack.home]);
    final disposed = music.dispose();
    pending.complete();
    await disposed;
    expect(player.calls, ['dispose']);
  });

  test(
    'cambiar de pista durante la preparación no arranca la anterior',
    () async {
      final pending = Completer<void>();
      final player = FakeMusicPlayer()..pendingSelection = pending;
      final music = BackgroundMusic(player: player);
      music.setEnabled(true);
      await Future<void>.delayed(Duration.zero);
      music.setTrack(MusicTrack.games);
      pending.complete();
      await music.settled;
      expect(player.tracks, [MusicTrack.home, MusicTrack.games]);
      expect(player.calls, ['resume']);
      await music.dispose();
    },
  );

  test(
    'cambia de pista sin duplicarla y respeta el silencio al cambiar',
    () async {
      final player = FakeMusicPlayer();
      final music = BackgroundMusic(player: player);
      music.setEnabled(true);
      await music.settled;
      music.setTrack(MusicTrack.games);
      await music.settled;
      music.setTrack(MusicTrack.games);
      music.retry();
      await music.settled;
      expect(player.tracks, [MusicTrack.home, MusicTrack.games]);
      music.setEnabled(false);
      await music.settled;
      music.setTrack(MusicTrack.activities);
      await music.settled;
      expect(player.tracks, [MusicTrack.home, MusicTrack.games]);
      expect(player.calls.last, 'pause');
      music.setEnabled(true);
      await music.settled;
      expect(player.tracks.last, MusicTrack.activities);
      music.setActivityPaused(true);
      await music.settled;
      music.setTrack(MusicTrack.home);
      await music.settled;
      expect(player.tracks.last, MusicTrack.activities);
      music.setActivityPaused(false);
      await music.settled;
      expect(player.tracks.last, MusicTrack.home);
      await music.dispose();
    },
  );

  test('en web espera al primer gesto antes de reproducir', () async {
    final player = FakeMusicPlayer();
    final music = BackgroundMusic(player: player, requireUserGesture: true);
    music.setEnabled(true);
    await music.settled;
    expect(player.calls, isEmpty);
    music.onUserInteraction();
    await music.settled;
    expect(player.calls, ['resume']);
    await music.dispose();
  });

  test('preferencias y pausas conservan un solo reproductor', () async {
    final player = FakeMusicPlayer();
    final music = BackgroundMusic(player: player);
    music.setEnabled(true);
    await music.settled;
    music.setEnabled(true);
    music.retry();
    await music.settled;
    expect(player.calls, ['resume']);
    music.setActivityPaused(true);
    await music.settled;
    music.setForeground(false);
    music.setActivityPaused(false);
    await music.settled;
    expect(player.calls, ['resume', 'pause']);
    music.setForeground(true);
    await music.settled;
    music.setEnabled(false);
    await music.settled;
    music.setForeground(false);
    music.setForeground(true);
    await music.settled;
    expect(player.calls, ['resume', 'pause', 'resume', 'pause']);
    await music.dispose();
    expect(player.calls.last, 'dispose');
  });

  test('reintenta tras fallo de autoplay sin bloquear el juego', () async {
    final player = FakeMusicPlayer()..failNextResume = true;
    final music = BackgroundMusic(player: player);
    music.setEnabled(true);
    await music.settled;
    music.retry();
    await music.settled;
    expect(player.calls, ['resume', 'resume']);
    await music.dispose();
  });

  test('silenciar durante el arranque no deja la música sonando', () async {
    final pending = Completer<void>();
    final player = FakeMusicPlayer()..pendingResume = pending;
    final music = BackgroundMusic(player: player);
    music.setEnabled(true);
    await Future<void>.delayed(Duration.zero);
    music.setEnabled(false);
    pending.complete();
    await music.settled;
    expect(player.calls, ['resume', 'pause']);
    await music.dispose();
    music.retry();
    await music.settled;
    expect(player.calls.last, 'dispose');
  });
}
