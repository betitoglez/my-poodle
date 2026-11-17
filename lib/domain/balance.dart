/// Balance v1 tipado. Se construye a partir de `assets/data/balance-v1.json`
/// (copia de `docs/datos/balance-v1.json`). Dart puro: sin Flutter ni Flame.
library;

import 'appearance.dart';

class BalanceFormatException implements Exception {
  BalanceFormatException(this.message);
  final String message;
  @override
  String toString() => 'BalanceFormatException: $message';
}

/// Cuatro medidas en centésimas (0..10000).
enum Need { satiety, hygiene, mood, energy }

class CareRule {
  const CareRule({required this.steps, required this.delta});
  final List<String> steps;

  /// Cambio en puntos enteros (no centésimas) por medida.
  final Map<Need, int> delta;
}

class FruitRule {
  const FruitRule({
    required this.seconds,
    required this.maxScore,
    required this.baseCoins,
    required this.coinsPerPoint,
  });
  final int seconds;
  final int maxScore;
  final int baseCoins;
  final int coinsPerPoint;
}

class FrisbeeRule {
  const FrisbeeRule({
    required this.throws,
    required this.maxScore,
    required this.baseCoins,
    required this.coinsPerPoint,
    required this.flightSeconds,
    required this.catchRadius,
    required this.targetsField,
  });
  final int throws;
  final int maxScore;
  final int baseCoins;
  final int coinsPerPoint;
  final double flightSeconds;
  final double catchRadius;

  /// Pares (x lateral, profundidad) en unidades lógicas de campo.
  final List<(double, double)> targetsField;
}

class StyleItem {
  const StyleItem({
    required this.id,
    required this.slot,
    required this.cost,
    required this.initial,
  });
  final String id;
  final Slot slot;
  final int cost;
  final bool initial;
}

class Balance {
  Balance({
    required this.startCoins,
    required this.tickSeconds,
    required this.maxTicks,
    required this.initial100,
    required this.deltaPerTick100,
    required this.care,
    required this.fruit,
    required this.frisbee,
    required this.gameCompleteDelta,
    required List<StyleItem> styles,
  }) : styles = List.unmodifiable(styles) {
    _validate();
  }

  final int startCoins;
  final int tickSeconds;
  final int maxTicks;
  final Map<Need, int> initial100;
  final Map<Need, int> deltaPerTick100;
  final Map<String, CareRule> care;
  final FruitRule fruit;
  final FrisbeeRule frisbee;
  final Map<Need, int> gameCompleteDelta;
  final List<StyleItem> styles;

  StyleItem? item(String id) {
    for (final s in styles) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<StyleItem> itemsFor(Slot slot) =>
      styles.where((s) => s.slot == slot).toList(growable: false);

  StyleItem baseFor(Slot slot) =>
      styles.firstWhere((s) => s.slot == slot && s.initial);

  Appearance get initialAppearance => Appearance(
    coat: baseFor(Slot.coat).id,
    hair: baseFor(Slot.hair).id,
    outfit: baseFor(Slot.outfit).id,
    neck: baseFor(Slot.neck).id,
  );

  void _validate() {
    final ids = <String>{};
    for (final s in styles) {
      if (!ids.add(s.id)) throw BalanceFormatException('ID duplicada: ${s.id}');
      if (s.cost < 0) throw BalanceFormatException('Coste negativo: ${s.id}');
      if (!s.id.startsWith('${s.slot.name}.')) {
        throw BalanceFormatException('Ranura incoherente: ${s.id}');
      }
      if (s.initial && s.cost != 0) {
        throw BalanceFormatException('Inicial con coste: ${s.id}');
      }
    }
    for (final slot in Slot.values) {
      final base = styles.where((s) => s.slot == slot && s.initial).length;
      if (base != 1) {
        throw BalanceFormatException('Ranura ${slot.name} necesita un inicial');
      }
    }
    for (final need in Need.values) {
      final v = initial100[need];
      if (v == null || v < 0 || v > 10000) {
        throw BalanceFormatException('Valor inicial inválido: ${need.name}');
      }
    }
    if (tickSeconds <= 0 || maxTicks <= 0) {
      throw BalanceFormatException('Reloj inválido');
    }
    if (fruit.maxScore < 0 || frisbee.maxScore < 0 || frisbee.throws <= 0) {
      throw BalanceFormatException('Juego inválido');
    }
    if (frisbee.targetsField.length != frisbee.throws) {
      throw BalanceFormatException('Objetivos de frisbee incompletos');
    }
  }

  /// Construye desde el mapa decodificado del JSON (jsonDecode).
  factory Balance.fromJson(Map<String, dynamic> j) {
    T req<T>(Map<String, dynamic> m, String k) {
      final v = m[k];
      if (v is! T) throw BalanceFormatException('Campo $k ausente o inválido');
      return v;
    }

    if (j['schemaVersion'] != 1) {
      throw BalanceFormatException('schemaVersion no soportada');
    }
    final needs = req<Map<String, dynamic>>(j, 'needs');
    final unitsPerPoint = req<int>(needs, 'unitsPerPoint');
    if (unitsPerPoint != 100) {
      throw BalanceFormatException('unitsPerPoint debe ser 100');
    }
    Map<Need, int> needMap(Map<String, dynamic> m, {int factor = 1}) {
      final out = <Need, int>{};
      m.forEach((k, v) {
        final need = Need.values.where((n) => n.name == k).firstOrNull;
        if (need == null || v is! int) {
          throw BalanceFormatException('Medida desconocida: $k');
        }
        out[need] = v * factor;
      });
      return out;
    }

    final careJ = req<Map<String, dynamic>>(j, 'care');
    final care = <String, CareRule>{};
    careJ.forEach((k, v) {
      final m = v as Map<String, dynamic>;
      care[k] = CareRule(
        steps: List<String>.from(req<List<dynamic>>(m, 'steps')),
        delta: needMap(req<Map<String, dynamic>>(m, 'delta')),
      );
    });
    final games = req<Map<String, dynamic>>(j, 'games');
    final f = req<Map<String, dynamic>>(games, 'fruit');
    final d = req<Map<String, dynamic>>(games, 'frisbee');
    final targets = req<List<dynamic>>(d, 'targetsField').map((p) {
      final l = p as List<dynamic>;
      if (l.length != 2) throw BalanceFormatException('Objetivo inválido');
      return ((l[0] as num).toDouble(), (l[1] as num).toDouble());
    }).toList();
    final styles = req<List<dynamic>>(j, 'styles').map((e) {
      final m = e as Map<String, dynamic>;
      final slotName = req<String>(m, 'slot');
      final slot = Slot.values.where((s) => s.name == slotName).firstOrNull;
      if (slot == null) throw BalanceFormatException('Ranura desconocida');
      return StyleItem(
        id: req<String>(m, 'id'),
        slot: slot,
        cost: req<int>(m, 'cost'),
        initial: req<bool>(m, 'initial'),
      );
    }).toList();

    return Balance(
      startCoins: req<int>(j, 'startCoins'),
      tickSeconds: req<int>(needs, 'tickSeconds'),
      maxTicks: req<int>(needs, 'maxTicks'),
      initial100: needMap(
        req<Map<String, dynamic>>(needs, 'initial'),
        factor: unitsPerPoint,
      ),
      deltaPerTick100: needMap(
        req<Map<String, dynamic>>(needs, 'deltaPerTick100'),
      ),
      care: care,
      fruit: FruitRule(
        seconds: req<int>(f, 'seconds'),
        maxScore: req<int>(f, 'maxScore'),
        baseCoins: req<int>(f, 'baseCoins'),
        coinsPerPoint: req<int>(f, 'coinsPerPoint'),
      ),
      frisbee: FrisbeeRule(
        throws: req<int>(d, 'throws'),
        maxScore: req<int>(d, 'maxScore'),
        baseCoins: req<int>(d, 'baseCoins'),
        coinsPerPoint: req<int>(d, 'coinsPerPoint'),
        flightSeconds: req<num>(d, 'flightSeconds').toDouble(),
        catchRadius: req<num>(d, 'catchRadius').toDouble(),
        targetsField: targets,
      ),
      gameCompleteDelta: needMap(
        req<Map<String, dynamic>>(j, 'gameCompleteDelta'),
      ),
      styles: styles,
    );
  }
}
