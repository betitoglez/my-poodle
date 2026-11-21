import 'dart:math';

/// Repartos locales: se reservan con el inicio de sesión y se conservan incluso
/// si se abandona. No se reutiliza ningún tablero/secuencia de la instalación.
abstract final class PuzzleDeals {
  static const poodles = [
    'white',
    'black',
    'apricot',
    'silver',
    'chocolate',
    'red',
    'parti',
    'cream',
  ];
  static String pairsKey(int pairs) => 'pairs-$pairs';

  static String pairs(int count, Iterable<String> used, {Random? random}) {
    if (!const [4, 6, 8].contains(count)) {
      throw ArgumentError.value(count, 'count');
    }
    final rng = random ?? Random.secure();
    final history = used.toSet();
    while (true) {
      final dogs = List.generate(8, (i) => i)..shuffle(rng);
      final selected = dogs.take(count).toList();
      final deck = [...selected, ...selected]..shuffle(rng);
      final signature = deck.join();
      if (!history.contains(signature)) return signature;
    }
  }

  static String memory(Iterable<String> used, {Random? random}) {
    final history = used.toSet();
    // 4^10 secuencias posibles. La comprobación evita un bucle al agotarlas.
    if (history.length >= 1 << 20) throw StateError('No quedan secuencias');
    final rng = random ?? Random.secure();
    while (true) {
      final signature = List.generate(10, (_) => rng.nextInt(4)).join();
      if (!history.contains(signature)) return signature;
    }
  }

  static List<int> decode(String signature) =>
      signature.split('').map(int.parse).toList(growable: false);
}
