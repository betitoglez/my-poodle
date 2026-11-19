import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum MusicTrack {
  home('audio/background.mp3'),
  games('audio/games.mp3'),
  activities('audio/activities.mp3');

  const MusicTrack(this.asset);
  final String asset;
}

/// Un único reproductor local, independiente de escenas y reconstrucciones.
abstract interface class MusicPlayer {
  Future<void> selectTrack(MusicTrack track);
  Future<void> resume();
  Future<void> pause();
  Future<void> dispose();
}

class _AssetMusicPlayer implements MusicPlayer {
  final _player = AudioPlayer();
  bool _configured = false;
  static final _context = AudioContext(
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
    android: const AudioContextAndroid(
      usageType: AndroidUsageType.game,
      contentType: AndroidContentType.music,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  @override
  Future<void> selectTrack(MusicTrack track) async {
    await _player.pause();
    if (!_configured) {
      await _player.setAudioContext(_context);
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(0.35);
      _configured = true;
    }
    await _player.setSource(AssetSource(track.asset));
    await _player.seek(Duration.zero);
  }

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> dispose() => _player.dispose();
}

class BackgroundMusic {
  BackgroundMusic({MusicPlayer? player, bool requireUserGesture = kIsWeb})
    : // Mantener público el nombre del parámetro de inyección.
      // ignore: prefer_initializing_formals
      _player = player,
      _gestureReceived = !requireUserGesture;

  MusicPlayer? _player;
  bool _gestureReceived;
  bool _enabled = false;
  bool _foreground = true;
  bool _activityPaused = false;
  bool _playing = false;
  bool _disposed = false;
  MusicTrack _track = MusicTrack.home;
  MusicTrack? _loadedTrack;
  Future<void> _tail = Future.value();

  void setTrack(MusicTrack track) {
    if (_track == track) return;
    _track = track;
    retry();
  }

  void setEnabled(bool enabled) {
    if (_enabled == enabled) return;
    _enabled = enabled;
    retry();
  }

  void setForeground(bool foreground) {
    _foreground = foreground;
    retry();
  }

  void setActivityPaused(bool paused) {
    _activityPaused = paused;
    retry();
  }

  void onUserInteraction() {
    _gestureReceived = true;
    retry();
  }

  /// Reintenta tras un gesto si el navegador bloqueó el inicio automático.
  void retry() {
    if (_disposed) return;
    _tail = _tail.then((_) async {
      if (_disposed) return;
      final shouldPlay =
          _enabled && _foreground && !_activityPaused && _gestureReceived;
      if (_playing == shouldPlay && (!shouldPlay || _loadedTrack == _track)) {
        return;
      }
      try {
        if (shouldPlay) {
          final player = _player ??= _AssetMusicPlayer();
          final track = _track;
          if (_loadedTrack != track) {
            _playing = false;
            await player.selectTrack(track);
            _loadedTrack = track;
          }
          await player.resume();
        } else {
          await _player?.pause();
        }
        _playing = shouldPlay;
      } catch (e) {
        // Un fallo de audio nunca bloquea el juego ni cambia las preferencias.
        debugPrint('Música no disponible: $e');
      }
    });
  }

  @visibleForTesting
  Future<void> get settled => _tail;

  Future<void> dispose() async {
    _disposed = true;
    await _tail;
    try {
      await _player?.dispose();
    } catch (e) {
      debugPrint('No se pudo liberar la música: $e');
    }
  }
}
