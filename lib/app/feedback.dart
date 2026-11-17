import 'package:flutter/services.dart';

import '../domain/pet_state.dart';

enum Sfx {
  tap,
  bite,
  splash,
  bubble,
  brush,
  step,
  sniff,
  jump,
  apple,
  fall,
  throwDisc,
  catchDisc,
  miss,
  coins,
  celebrate,
}

/// Efectos y música. El prototipo no incluye todavía audio producido
/// (Mureka/ElevenLabs): los efectos usan respuesta háptica y el sonido del
/// sistema, y la música queda como punto de integración. Todo feedback
/// esencial también es visual.
class FeedbackService {
  Preferences Function() prefs = () => const Preferences();

  void play(Sfx sfx) {
    if (!prefs().effects) return;
    switch (sfx) {
      case Sfx.coins || Sfx.celebrate || Sfx.catchDisc || Sfx.apple:
        HapticFeedback.mediumImpact();
      case Sfx.fall || Sfx.miss:
        HapticFeedback.lightImpact();
      default:
        HapticFeedback.selectionClick();
    }
  }

  /// Punto de integración de música en bucle (casa/parque).
  void music(String? track) {}
}
