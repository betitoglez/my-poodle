import 'appearance.dart';
import 'balance.dart';

/// Preferencias locales que viajan con la partida (una por instalación).
class Preferences {
  const Preferences({
    this.music = true,
    this.effects = true,
    this.reducedMotion = false,
    this.seenHints = const {},
  });

  final bool music;
  final bool effects;
  final bool reducedMotion;
  final Set<String> seenHints;

  bool get muted => !music && !effects;

  Preferences copyWith({
    bool? music,
    bool? effects,
    bool? reducedMotion,
    Set<String>? seenHints,
  }) => Preferences(
    music: music ?? this.music,
    effects: effects ?? this.effects,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    seenHints: seenHints ?? this.seenHints,
  );
}

/// Estado confirmado de la partida. Inmutable: cada operación devuelve una
/// copia. Las necesidades se guardan en centésimas (0..10000).
class PetState {
  const PetState({
    required this.revision,
    required this.lastCommitId,
    required this.name,
    required this.needsCursorUtc,
    required this.needs100,
    required this.coins,
    required this.owned,
    required this.appearance,
    required this.bestFruit,
    required this.bestFrisbee,
    required this.prefs,
  });

  static const int schemaVersion = 1;

  final int revision;
  final String lastCommitId;
  final String name;

  /// Segundos UTC del último bloque de 15 minutos procesado.
  final int needsCursorUtc;
  final Map<Need, int> needs100;
  final int coins;
  final Set<String> owned;
  final Appearance appearance;
  final int bestFruit;
  final int bestFrisbee;
  final Preferences prefs;

  int need100(Need n) => needs100[n] ?? 0;

  /// Valor redondeado para presentar (0..100).
  int needPoints(Need n) => (need100(n) / 100).round();

  PetState copyWith({
    int? revision,
    String? lastCommitId,
    int? needsCursorUtc,
    Map<Need, int>? needs100,
    int? coins,
    Set<String>? owned,
    Appearance? appearance,
    int? bestFruit,
    int? bestFrisbee,
    Preferences? prefs,
  }) => PetState(
    revision: revision ?? this.revision,
    lastCommitId: lastCommitId ?? this.lastCommitId,
    name: name,
    needsCursorUtc: needsCursorUtc ?? this.needsCursorUtc,
    needs100: Map.unmodifiable(needs100 ?? this.needs100),
    coins: coins ?? this.coins,
    owned: Set.unmodifiable(owned ?? this.owned),
    appearance: appearance ?? this.appearance,
    bestFruit: bestFruit ?? this.bestFruit,
    bestFrisbee: bestFrisbee ?? this.bestFrisbee,
    prefs: prefs ?? this.prefs,
  );

  /// Adopción: única forma de crear una partida. Revisión 1, saldo inicial,
  /// cuatro artículos base y necesidades iniciales.
  static PetState adopt({
    required String validName,
    required int nowUtc,
    required Balance balance,
  }) {
    final base = balance.initialAppearance;
    return PetState(
      revision: 1,
      lastCommitId: 'adopcion-1',
      name: validName,
      needsCursorUtc: nowUtc,
      needs100: Map.unmodifiable(Map.of(balance.initial100)),
      coins: balance.startCoins,
      owned: Set.unmodifiable(base.ids.toSet()),
      appearance: base,
      bestFruit: 0,
      bestFrisbee: 0,
      prefs: const Preferences(),
    );
  }
}

int clampNeed(int v) => v < 0 ? 0 : (v > 10000 ? 10000 : v);
