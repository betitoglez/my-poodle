import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../domain/pet_state.dart';
import 'background_music.dart';

enum Sfx {
  tap('tap', .52),
  bite('bite', .9),
  splash('splash', .83),
  bubble('bubble', .66),
  brush('brush', 1),
  sniff('sniff', .88),
  jump('jump', .48),
  apple('apple', .48),
  fall('fall', .35),
  throwDisc('throw_disc', .65),
  catchDisc('catch_disc', .43),
  miss('miss', .65),
  coins('coins', .53),
  celebrate('celebrate', .42),
  lap('lap', 1),
  pourBowl('pour_bowl', .88),
  shower('shower', 1),
  dryer('dryer', 1),
  countdown('countdown', .32),
  blocked('blocked', .5),
  hitFence('hit_fence', .49),
  hitHedge('hit_hedge', .49),
  land('land', .72),
  nailClip('nail_clip', .88),
  scissors('scissors', .68),
  fabric('fabric', .83),
  bark('bark', .45),
  heartbeat('heartbeat', .29),
  gulp('gulp', 1),
  curler('curler', .85),
  salts('salts', .83),
  massage('massage', .45),
  lightSwitch('light_switch', .67),
  sleepBreath('sleep_breath', .8),
  pant('pant', .85),
  parkAmbience('park_ambience', .64),
  fountain('fountain', .85),
  memoryRed('memory_red', .8, 'wav'),
  memoryBlue('memory_blue', .8, 'wav'),
  memoryGreen('memory_green', .8, 'wav'),
  memoryYellow('memory_yellow', .8, 'wav');

  const Sfx(this.file, this.volume, [this.extension = 'mp3']);
  final String file;
  final double volume;
  final String extension;
  String get asset => 'audio/sfx/$file.$extension';
}

abstract interface class EffectPlayback {
  void play(Sfx effect);
  void setLoops(Set<Sfx> effects);
  void stop();
  void dispose();
}

/// Mantiene juntas la preferencia de efectos, la háptica y el audio.
class FeedbackService {
  FeedbackService({this._playback, BackgroundMusic? music})
    : music = music ?? BackgroundMusic();

  final BackgroundMusic music;

  final EffectPlayback? _playback;
  final routes = RouteObserver<ModalRoute<dynamic>>();
  Preferences Function() prefs = () => const Preferences();
  final _sceneLoops = <Object, Set<Sfx>>{};
  Set<Sfx> _playingLoops = const {};
  bool _foreground = true;
  bool _stopped = false;
  bool get _audible => _foreground && prefs().effects;

  void play(Sfx sfx, {bool haptic = true}) {
    if (!_audible) return;
    _playback?.play(sfx);
    if (!haptic) return;
    switch (sfx) {
      case Sfx.coins || Sfx.celebrate || Sfx.catchDisc || Sfx.apple:
        HapticFeedback.mediumImpact();
      case Sfx.fall || Sfx.miss || Sfx.hitFence || Sfx.hitHedge:
        HapticFeedback.lightImpact();
      default:
        HapticFeedback.selectionClick();
    }
  }

  void setLoops(Object scene, Set<Sfx> effects) {
    final previous = _sceneLoops[scene];
    if (effects.isEmpty) {
      if (previous == null) return;
      _sceneLoops.remove(scene);
    } else {
      if (previous != null &&
          previous.length == effects.length &&
          previous.containsAll(effects)) {
        return;
      }
      _sceneLoops[scene] = effects;
    }
    sync();
  }

  void setForeground(bool foreground) {
    _foreground = foreground;
    sync();
  }

  void sync() {
    if (!_audible) {
      if (!_stopped) _playback?.stop();
      _stopped = true;
      _playingLoops = const {};
      return;
    }
    _stopped = false;
    final next = {for (final effects in _sceneLoops.values) ...effects};
    if (next.length == _playingLoops.length &&
        _playingLoops.containsAll(next)) {
      return;
    }
    _playingLoops = next;
    _playback?.setLoops(next);
  }

  void dispose() => _playback?.dispose();
}
