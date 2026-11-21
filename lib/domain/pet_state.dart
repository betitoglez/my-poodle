import 'appearance.dart';
import 'balance.dart';

/// Preferencias locales que viajan con la partida (una por instalación).
class Preferences {
  const Preferences({
    this.music = true,
    this.effects = true,
    this.reducedMotion = false,
    this.seenHints = const {},
    this.language,
  });

  final bool music;
  final bool effects;
  final bool reducedMotion;
  final Set<String> seenHints;
  final String? language;

  bool get muted => !music && !effects;

  Preferences copyWith({
    bool? music,
    bool? effects,
    bool? reducedMotion,
    Set<String>? seenHints,
    String? language,
    bool systemLanguage = false,
  }) => Preferences(
    music: music ?? this.music,
    effects: effects ?? this.effects,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    seenHints: seenHints ?? this.seenHints,
    language: systemLanguage ? null : language ?? this.language,
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
    required this.lastSickUtc,
    required this.sickSeed,
    this.bestPairs = 0,
    this.bestMemory = 0,
    this.puzzleDeals = const {},
    this.sickSinceUtc,
    this.careCompletedUtc = const {},
    this.gameStartedUtc = const [],
    this.premiumTrialStartedUtc = const {},
    this.restingSinceUtc,
    this.restEnergyCursorUtc,
    this.bestStars = const {},
    this.decor = const {},
    this.achievements = const {},
    this.albumCollected = const {},
    this.coinsEarnedTotal = 0,
    this.careDayCount = 0,
    this.lastCareDay,
    this.photosTaken = 0,
  });

  static const int schemaVersion = 1;

  /// Mejor número de estrellas (0..3) por juego. Una clave presente indica
  /// que se ha terminado al menos una partida de ese juego.
  final Map<String, int> bestStars;

  /// Decoración colocada en el salón: un ID por hueco ocupado.
  final Map<DecorSlot, String> decor;

  /// Logros conseguidos: ID (`ach.…`) → segundo UTC en que se consiguió.
  /// Nunca se retiran (ver `domain/achievements.dart`).
  final Map<String, int> achievements;

  /// Páginas del álbum cuyo bono ya se recogió (ID de página).
  final Set<String> albumCollected;

  /// Monedas ganadas jugando en total (no cuenta bonos del álbum).
  final int coinsEarnedTotal;

  /// Días UTC distintos con al menos un cuidado y el último de ellos
  /// (`segundos ~/ 86400`).
  final int careDayCount;
  final int? lastCareDay;

  /// Fotos guardadas en el álbum privado desde esta versión.
  final int photosTaken;

  final Map<String, int> careCompletedUtc;
  final List<int> gameStartedUtc;
  final Map<String, int> premiumTrialStartedUtc;
  final int? restingSinceUtc;
  final int? restEnergyCursorUtc;

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
  final int bestPairs;
  final int bestMemory;
  final Map<String, List<String>> puzzleDeals;
  final Preferences prefs;

  /// Salud: segundos UTC en que enfermó (null = sano).
  final int? sickSinceUtc;

  /// Última vez que enfermó, para limitarlo a una por semana.
  final int lastSickUtc;

  /// Semilla propia de la partida para las tiradas deterministas.
  final int sickSeed;

  bool get isSick => sickSinceUtc != null;

  /// Salud para presentar: sana 100, malita 35.
  int get healthPoints => isSick ? 35 : 100;

  int need100(Need n) => needs100[n] ?? (n == Need.hydration ? 9000 : 0);

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
    int? bestPairs,
    int? bestMemory,
    Map<String, List<String>>? puzzleDeals,
    Preferences? prefs,
    int? sickSinceUtc,
    Map<String, int>? careCompletedUtc,
    List<int>? gameStartedUtc,
    Map<String, int>? premiumTrialStartedUtc,
    bool cured = false,
    int? restingSinceUtc,
    int? restEnergyCursorUtc,
    bool wake = false,
    int? lastSickUtc,
    Map<String, int>? bestStars,
    Map<DecorSlot, String>? decor,
    Map<String, int>? achievements,
    Set<String>? albumCollected,
    int? coinsEarnedTotal,
    int? careDayCount,
    int? lastCareDay,
    int? photosTaken,
  }) => PetState(
    achievements: Map.unmodifiable(achievements ?? this.achievements),
    albumCollected: Set.unmodifiable(albumCollected ?? this.albumCollected),
    coinsEarnedTotal: coinsEarnedTotal ?? this.coinsEarnedTotal,
    careDayCount: careDayCount ?? this.careDayCount,
    lastCareDay: lastCareDay ?? this.lastCareDay,
    photosTaken: photosTaken ?? this.photosTaken,
    bestStars: Map.unmodifiable(bestStars ?? this.bestStars),
    decor: Map.unmodifiable(decor ?? this.decor),
    revision: revision ?? this.revision,
    lastCommitId: lastCommitId ?? this.lastCommitId,
    careCompletedUtc: Map.unmodifiable(
      careCompletedUtc ?? this.careCompletedUtc,
    ),
    gameStartedUtc: List.unmodifiable(gameStartedUtc ?? this.gameStartedUtc),
    premiumTrialStartedUtc: Map.unmodifiable(
      premiumTrialStartedUtc ?? this.premiumTrialStartedUtc,
    ),
    restingSinceUtc: wake ? null : restingSinceUtc ?? this.restingSinceUtc,
    restEnergyCursorUtc: wake
        ? null
        : restEnergyCursorUtc ?? this.restEnergyCursorUtc,
    name: name,
    needsCursorUtc: needsCursorUtc ?? this.needsCursorUtc,
    needs100: Map.unmodifiable(needs100 ?? this.needs100),
    coins: coins ?? this.coins,
    owned: Set.unmodifiable(owned ?? this.owned),
    appearance: appearance ?? this.appearance,
    bestFruit: bestFruit ?? this.bestFruit,
    bestFrisbee: bestFrisbee ?? this.bestFrisbee,
    bestPairs: bestPairs ?? this.bestPairs,
    bestMemory: bestMemory ?? this.bestMemory,
    puzzleDeals: Map.unmodifiable({
      for (final entry in (puzzleDeals ?? this.puzzleDeals).entries)
        entry.key: List<String>.unmodifiable(entry.value),
    }),
    prefs: prefs ?? this.prefs,
    sickSinceUtc: cured ? null : (sickSinceUtc ?? this.sickSinceUtc),
    lastSickUtc: lastSickUtc ?? this.lastSickUtc,
    sickSeed: sickSeed,
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
      decor: Map.unmodifiable(balance.initialDecor),
      // El primer día no enferma: el último «enfermó» se fija para que el
      // primer plazo de una semana termine pasado el periodo de gracia.
      lastSickUtc:
          nowUtc - balance.health.cooldownSeconds + balance.health.graceSeconds,
      sickSeed: _seedFrom(nowUtc, validName),
    );
  }

  static int _seedFrom(int nowUtc, String name) {
    var h = nowUtc & 0x7fffffff;
    for (final r in name.runes) {
      h = (h * 31 + r) & 0x7fffffff;
    }
    return h;
  }
}

int clampNeed(int v) => v < 0 ? 0 : (v > 10000 ? 10000 : v);
