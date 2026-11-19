import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'feedback.dart';

/// Mantiene un número acotado de canales para impactos y uno por bucle activo.
class AssetEffectPlayback implements EffectPlayback {
  final _voices = List.generate(5, (_) => _EffectVoice());
  final _loops = <Sfx, _EffectVoice>{};
  int _nextVoice = 0;
  bool _disposed = false;

  @override
  void play(Sfx effect) {
    if (_disposed) return;
    _voices[_nextVoice].start(effect);
    _nextVoice = (_nextVoice + 1) % _voices.length;
  }

  @override
  void setLoops(Set<Sfx> effects) {
    if (_disposed) return;
    for (final sfx in _loops.keys.toList()) {
      if (!effects.contains(sfx)) _loops.remove(sfx)!.dispose();
    }
    for (final sfx in effects) {
      _loops.putIfAbsent(sfx, () => _EffectVoice()..start(sfx, loop: true));
    }
  }

  @override
  void stop() {
    setLoops(const {});
    for (final voice in _voices) {
      voice.stop();
    }
  }

  @override
  void dispose() {
    stop();
    _disposed = true;
    for (final voice in _voices) {
      voice.dispose();
    }
  }
}

/// No deja arrancar una muestra si se ha silenciado durante su preparación.
class _EffectVoice {
  AudioPlayer? _player;
  Future<void> _tail = Future.value();
  int _revision = 0;
  static final _context = AudioContext(
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
    android: const AudioContextAndroid(
      usageType: AndroidUsageType.game,
      contentType: AndroidContentType.sonification,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  void _queue(Future<void> Function() action) {
    _tail = _tail.then((_) => action()).catchError((Object error) {
      debugPrint('Audio de efectos no disponible: $error');
    });
  }

  void start(Sfx effect, {bool loop = false}) {
    final revision = ++_revision;
    _queue(() async {
      if (revision != _revision) return;
      final existing = _player;
      final player = existing ?? (_player = AudioPlayer());
      if (existing == null) {
        await player.setAudioContext(_context);
        await player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
      } else {
        await player.stop();
      }
      if (revision != _revision) return;
      await player.setVolume(effect.volume);
      await player.setSource(AssetSource(effect.asset));
      if (revision == _revision) await player.resume();
    });
  }

  void stop() {
    _revision++;
    _queue(() async => _player?.stop());
  }

  void dispose() {
    _revision++;
    _queue(() async {
      await _player?.dispose();
      _player = null;
    });
  }
}
