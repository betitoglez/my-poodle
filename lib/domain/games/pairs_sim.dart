/// Parejas: cinco errores permitidos; los aciertos no gastan intentos.
class PairsSim {
  PairsSim(List<int> cards) : cards = List.unmodifiable(cards) {
    final counts = <int, int>{};
    for (final card in cards) {
      counts[card] = (counts[card] ?? 0) + 1;
    }
    if (!const [8, 12, 16].contains(cards.length) ||
        counts.values.any((n) => n != 2) ||
        counts.keys.any((n) => n < 0 || n > 7)) {
      throw ArgumentError('Tablero de parejas inválido');
    }
  }

  final List<int> cards;
  final Set<int> matched = {};
  int? first;
  int? second;
  int attempts = 5;
  double remaining = 60;
  double _revealRemaining = 0;
  bool finished = false;
  bool get won => matched.length == cards.length;
  int get pairCount => cards.length ~/ 2;
  int get found => matched.length ~/ 2;
  int get score => won ? pairCount : 0;
  bool visible(int index) =>
      matched.contains(index) || first == index || second == index;

  bool flip(int index) {
    if (finished ||
        index < 0 ||
        index >= cards.length ||
        second != null ||
        visible(index)) {
      return false;
    }
    if (first == null) {
      first = index;
      return true;
    }
    second = index;
    if (cards[first!] == cards[index]) {
      matched.addAll([first!, index]);
      first = second = null;
      if (won) finished = true;
    } else {
      attempts--;
      _revealRemaining = .85;
      if (attempts == 0) finished = true;
    }
    return true;
  }

  void update(double dt) {
    if (finished || dt <= 0 || !dt.isFinite) return;
    remaining = (remaining - dt).clamp(0, 60);
    if (remaining == 0) {
      finished = true;
      return;
    }
    if (second != null) {
      _revealRemaining -= dt;
      if (_revealRemaining <= 0) first = second = null;
    }
  }
}
