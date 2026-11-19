import 'dart:async';

import 'package:my_poodle/app/background_music.dart';

class FakeMusicPlayer implements MusicPlayer {
  final calls = <String>[];
  final tracks = <MusicTrack>[];
  bool failNextResume = false;
  Completer<void>? pendingResume;
  Completer<void>? pendingSelection;

  @override
  Future<void> selectTrack(MusicTrack track) async {
    tracks.add(track);
    await pendingSelection?.future;
  }

  @override
  Future<void> resume() async {
    calls.add('resume');
    await pendingResume?.future;
    if (failNextResume) {
      failNextResume = false;
      throw StateError('Autoplay bloqueado');
    }
  }

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> dispose() async => calls.add('dispose');
}
