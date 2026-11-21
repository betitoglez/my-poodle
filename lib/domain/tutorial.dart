/// Primera partida guiada: lleva al primer objetivo de FUNCIONAL (compartir
/// una comida, completar un juego y estrenar algo). Se deduce del estado
/// confirmado, así que no añade campos al guardado. Dart puro.
library;

import 'balance.dart';
import 'pet_state.dart';

enum TutorialStep { feed, play, dress }

abstract final class Tutorial {
  /// Pista que oculta la guía para siempre («Saltar guía»).
  static const skipHint = 'guide.off';

  /// La guía empieza cuando ya se ha visto la pista de la caricia.
  static const afterHint = 'home.pet';

  static TutorialStep? next(PetState s, Balance balance) {
    if (s.prefs.seenHints.contains(skipHint)) return null;
    if (!s.careCompletedUtc.keys.any(
      (k) => k == 'feed' || k.startsWith('feed.'),
    )) {
      return TutorialStep.feed;
    }
    if (s.bestStars.isEmpty && s.bestFruit == 0 && s.bestFrisbee == 0) {
      return TutorialStep.play;
    }
    final initial = balance.initialAppearance;
    final dressed =
        s.appearance != initial ||
        s.owned.any((id) => !initial.ids.contains(id)) ||
        s.decor.entries.any((e) => balance.decorItem(e.value)?.initial != true);
    return dressed ? null : TutorialStep.dress;
  }
}
