/// Balance v1 tipado. Se construye a partir de `assets/data/balance-v1.json`
/// (copia de `docs/datos/balance-v1.json`). Dart puro: sin Flutter ni Flame.
library;

import 'appearance.dart';
import 'entitlements.dart';

class BalanceFormatException implements Exception {
  BalanceFormatException(this.message);
  final String message;
  @override
  String toString() => 'BalanceFormatException: $message';
}

/// Cuatro medidas en centésimas (0..10000).
enum Need { satiety, hygiene, mood, energy, hydration }

class CareRule {
  const CareRule({
    required this.steps,
    required this.delta,
    this.cures = false,
  });
  final List<String> steps;

  /// Terminar esta actividad cura la enfermedad (veterinario).
  final bool cures;

  /// Cambio en puntos enteros (no centésimas) por medida.
  final Map<Need, int> delta;
}

class FruitRule {
  const FruitRule({
    required this.seconds,
    required this.maxScore,
    required this.baseCoins,
    required this.coinsPerPoint,
    this.tier = Tier.free,
    this.starFruits = const [8, 16],
    this.starGolden = 3,
  });
  final Tier tier;

  /// Frutas para la primera y la segunda estrella.
  final List<int> starFruits;

  /// Frutas doradas que, con la segunda estrella, dan la tercera.
  final int starGolden;
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
    this.tier = Tier.free,
    this.targetPool = const [],
    this.starCatches = const [2, 4, 5],
  });
  final Tier tier;

  /// Reserva de objetivos de la que cada partida toma los lanzamientos
  /// 2.º a último (el primero es siempre `targetsField[0]`). Vacía: fijos.
  final List<(double, double)> targetPool;

  /// Capturas para la primera, segunda y tercera estrella.
  final List<int> starCatches;
  final int throws;
  final int maxScore;
  final int baseCoins;
  final int coinsPerPoint;
  final double flightSeconds;
  final double catchRadius;

  /// Pares (x lateral, profundidad) en unidades lógicas de campo.
  final List<(double, double)> targetsField;
}

/// Salud: la enfermedad es un estado (no una medida) que aparece por
/// descuido o por azar, como máximo una vez por semana, y solo cura el
/// veterinario. Las probabilidades son por bloque de 15 minutos, sobre 10 000.
class HealthRule {
  const HealthRule({
    required this.cooldownSeconds,
    required this.graceSeconds,
    required this.randomChance,
    required this.neglectChance,
    required this.neglectSatietyBelow,
    required this.neglectHygieneBelow,
    required this.neglectEnergyBelow,
    required this.sickMoodPerTick100,
  });
  final int cooldownSeconds;
  final int graceSeconds;
  final int randomChance;
  final int neglectChance;
  final int neglectSatietyBelow;
  final int neglectHygieneBelow;
  final int neglectEnergyBelow;
  final int sickMoodPerTick100;
}

/// Umbrales (en puntos) por debajo de los cuales se enciende cada icono
/// de estado del visor.
class StatusRule {
  const StatusRule({
    required this.hungryBelow,
    required this.dirtyBelow,
    required this.sadBelow,
    required this.tiredBelow,
  });
  final int hungryBelow;
  final int dirtyBelow;
  final int sadBelow;
  final int tiredBelow;
}

class StyleItem {
  const StyleItem({
    required this.id,
    required this.slot,
    required this.cost,
    required this.initial,
    this.tier = Tier.free,
  });
  final String id;
  final Slot slot;
  final int cost;
  final bool initial;

  /// Versión que permite comprarlo (los poseídos siempre se pueden usar).
  final Tier tier;
}

/// Huecos de decoración del salón: independientes del aspecto del caniche.
enum DecorSlot { rug, wall, plant }

class DecorItem {
  const DecorItem({
    required this.id,
    required this.slot,
    required this.cost,
    required this.initial,
    this.tier = Tier.free,
  });
  final String id;
  final DecorSlot slot;
  final int cost;
  final bool initial;
  final Tier tier;
}

/// Tipo de pieza que contiene un pack de fotos.
enum PhotoPackKind { sticker, frame, text }

/// Pack de decoración de fotos: se desbloquea una sola vez con monedas
/// (coste 0: disponible desde el principio). La propiedad se guarda en
/// `PetState.owned` con el propio ID del pack (`photo.<pack>`).
class PhotoPack {
  const PhotoPack({
    required this.id,
    required this.kind,
    required this.cost,
    required this.pieces,
    this.tier = Tier.free,
  });
  final String id;
  final PhotoPackKind kind;
  final int cost;
  final Tier tier;

  /// IDs de las piezas (`sticker.*`, `frame.*` o `text.*`).
  final List<String> pieces;

  bool get free => cost == 0;
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
    required this.health,
    required this.status,
    required List<StyleItem> styles,
    List<DecorItem> decor = const [],
    List<PhotoPack> photoPacks = const [],
    this.fullVersionProductId = 'mypoodle.full_version',
    Map<String, int> albumPageBonus = const {},
  }) : styles = List.unmodifiable(styles),
       decor = List.unmodifiable(decor),
       photoPacks = List.unmodifiable(photoPacks),
       albumPageBonus = Map.unmodifiable(albumPageBonus) {
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
  final HealthRule health;
  final StatusRule status;
  final List<StyleItem> styles;

  /// Decoración del salón (vacía: sin decoración disponible).
  final List<DecorItem> decor;

  /// Álbum de pegatinas: bono único (monedas) por página completa, por ID
  /// de página (`care`, `games`…). Bloque `album.pageBonus` del JSON.
  final Map<String, int> albumPageBonus;

  DecorItem? decorItem(String id) {
    for (final d in decor) {
      if (d.id == id) return d;
    }
    return null;
  }

  List<DecorItem> decorFor(DecorSlot slot) =>
      decor.where((d) => d.slot == slot).toList(growable: false);

  /// Decoración inicial: el artículo vacío de cada hueco.
  Map<DecorSlot, String> get initialDecor => {
    for (final slot in DecorSlot.values)
      if (decor.any((d) => d.slot == slot && d.initial))
        slot: decor.firstWhere((d) => d.slot == slot && d.initial).id,
  };

  /// Producto de la tienda que desbloquea la versión completa.
  final String fullVersionProductId;

  /// Packs de decoración de fotos (vacío: solo la foto básica).
  final List<PhotoPack> photoPacks;

  PhotoPack? photoPack(String id) {
    for (final p in photoPacks) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Pack al que pertenece una pieza de foto.
  PhotoPack? photoPackOfPiece(String pieceId) {
    for (final p in photoPacks) {
      if (p.pieces.contains(pieceId)) return p;
    }
    return null;
  }

  List<PhotoPack> photoPacksOf(PhotoPackKind kind) =>
      photoPacks.where((p) => p.kind == kind).toList(growable: false);

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

  Appearance get initialAppearance =>
      Appearance({for (final s in Slot.values) s: baseFor(s).id});

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
      if (s.initial && s.tier != Tier.free) {
        throw BalanceFormatException('Inicial de la versión completa: ${s.id}');
      }
    }
    if (fruit.tier != Tier.free && frisbee.tier != Tier.free) {
      throw BalanceFormatException('Hace falta al menos un juego gratuito');
    }
    if (fullVersionProductId.isEmpty) {
      throw BalanceFormatException('fullVersion.productId vacío');
    }
    for (final slot in Slot.values) {
      final base = styles.where((s) => s.slot == slot && s.initial).length;
      if (base != 1) {
        throw BalanceFormatException('Ranura ${slot.name} necesita un inicial');
      }
      final freeBuyable = styles.any(
        (s) => s.slot == slot && !s.initial && s.tier == Tier.free,
      );
      if (!freeBuyable) {
        throw BalanceFormatException(
          'Ranura ${slot.name} sin artículo gratuito comprable',
        );
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
    for (final (x, depth) in [...frisbee.targetsField, ...frisbee.targetPool]) {
      if (x.abs() > 3 || depth < 2 || depth > 8) {
        throw BalanceFormatException('Objetivo de frisbee fuera del campo');
      }
    }
    if (frisbee.targetPool.isNotEmpty &&
        frisbee.targetPool
                .where((p) => p != frisbee.targetsField.first)
                .length <
            frisbee.throws - 1) {
      throw BalanceFormatException('Reserva de objetivos insuficiente');
    }
    bool ascending(List<int> l, int max) {
      for (var i = 0; i < l.length; i++) {
        if (l[i] < 0 || l[i] > max || i > 0 && l[i] < l[i - 1]) return false;
      }
      return true;
    }

    if (fruit.starFruits.length != 2 ||
        !ascending(fruit.starFruits, fruit.maxScore) ||
        fruit.starGolden < 0 ||
        frisbee.starCatches.length != 3 ||
        !ascending(frisbee.starCatches, frisbee.maxScore)) {
      throw BalanceFormatException('Estrellas inválidas');
    }
    for (final e in albumPageBonus.entries) {
      if (e.value < 0 || e.value > 500) {
        throw BalanceFormatException('Bono de álbum inválido: ${e.key}');
      }
    }
    final decorIds = <String>{};
    for (final d in decor) {
      if (!decorIds.add(d.id) || ids.contains(d.id)) {
        throw BalanceFormatException('ID duplicada: ${d.id}');
      }
      if (d.cost < 0) throw BalanceFormatException('Coste negativo: ${d.id}');
      if (!d.id.startsWith('${d.slot.name}.')) {
        throw BalanceFormatException('Ranura incoherente: ${d.id}');
      }
      if (d.initial && (d.cost != 0 || d.tier != Tier.free)) {
        throw BalanceFormatException('Inicial inválido: ${d.id}');
      }
    }
    if (decor.isNotEmpty) {
      for (final slot in DecorSlot.values) {
        if (decor.where((d) => d.slot == slot && d.initial).length != 1) {
          throw BalanceFormatException('Decoración ${slot.name} sin inicial');
        }
        if (!decor.any(
          (d) => d.slot == slot && !d.initial && d.tier == Tier.free,
        )) {
          throw BalanceFormatException(
            'Decoración ${slot.name} sin artículo gratuito comprable',
          );
        }
      }
    }
    _validatePhotoPacks({...ids, ...decorIds});
  }

  /// Packs de fotos: IDs `photo.*` únicos, piezas con el prefijo de su tipo
  /// y sin repetir, coste 0 solo en la versión gratuita, un pack gratuito de
  /// pegatinas y de texto y al menos un pack de pago en la versión gratuita.
  void _validatePhotoPacks(Set<String> otherIds) {
    if (photoPacks.isEmpty) return;
    final packIds = <String>{};
    final pieceIds = <String>{};
    for (final p in photoPacks) {
      if (!p.id.startsWith('photo.') ||
          !packIds.add(p.id) ||
          otherIds.contains(p.id)) {
        throw BalanceFormatException('Pack de fotos inválido: ${p.id}');
      }
      if (p.cost < 0) throw BalanceFormatException('Coste negativo: ${p.id}');
      if (p.free && p.tier != Tier.free) {
        throw BalanceFormatException('Pack gratuito de la versión completa');
      }
      if (p.pieces.isEmpty) {
        throw BalanceFormatException('Pack sin piezas: ${p.id}');
      }
      for (final piece in p.pieces) {
        if (!piece.startsWith('${p.kind.name}.') ||
            !pieceIds.add(piece) ||
            otherIds.contains(piece)) {
          throw BalanceFormatException('Pieza inválida: $piece');
        }
      }
    }
    for (final kind in [PhotoPackKind.sticker, PhotoPackKind.text]) {
      if (!photoPacks.any((p) => p.kind == kind && p.free)) {
        throw BalanceFormatException('Falta un pack gratuito de ${kind.name}');
      }
    }
    if (!photoPacks.any((p) => !p.free && p.tier == Tier.free)) {
      throw BalanceFormatException(
        'Hace falta un pack de fotos de pago en la versión gratuita',
      );
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
        cures: m['cures'] == true,
        steps: List<String>.from(req<List<dynamic>>(m, 'steps')),
        delta: needMap(req<Map<String, dynamic>>(m, 'delta')),
      );
    });
    final games = req<Map<String, dynamic>>(j, 'games');
    final f = req<Map<String, dynamic>>(games, 'fruit');
    final d = req<Map<String, dynamic>>(games, 'frisbee');
    List<(double, double)> points(List<dynamic> raw) => raw.map((p) {
      final l = p as List<dynamic>;
      if (l.length != 2) throw BalanceFormatException('Objetivo inválido');
      return ((l[0] as num).toDouble(), (l[1] as num).toDouble());
    }).toList();
    final targets = points(req<List<dynamic>>(d, 'targetsField'));
    final pool = d['targetPool'] is List
        ? points(d['targetPool'] as List<dynamic>)
        : const <(double, double)>[];
    List<int>? ints(Object? v) =>
        v is List && v.every((e) => e is int) ? v.cast<int>() : null;
    Tier tierOf(Map<String, dynamic> m, String what) {
      final v = req<String>(m, 'tier');
      final t = Tier.values.where((t) => t.name == v).firstOrNull;
      if (t == null) throw BalanceFormatException('tier inválido en $what');
      return t;
    }

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
        tier: tierOf(m, '${m['id']}'),
      );
    }).toList();
    final decor = (j['decor'] is List ? j['decor'] as List<dynamic> : const [])
        .map((e) {
          final m = e as Map<String, dynamic>;
          final slotName = req<String>(m, 'slot');
          final slot = DecorSlot.values
              .where((s) => s.name == slotName)
              .firstOrNull;
          if (slot == null) throw BalanceFormatException('Hueco desconocido');
          return DecorItem(
            id: req<String>(m, 'id'),
            slot: slot,
            cost: req<int>(m, 'cost'),
            initial: req<bool>(m, 'initial'),
            tier: tierOf(m, '${m['id']}'),
          );
        })
        .toList();
    // Partidas y balances anteriores a la decoración de fotos: sin packs.
    final photoPacks =
        (j['photoPacks'] is List ? j['photoPacks'] as List<dynamic> : const [])
            .map((e) {
              final m = e as Map<String, dynamic>;
              final kindName = req<String>(m, 'kind');
              final kind = PhotoPackKind.values
                  .where((k) => k.name == kindName)
                  .firstOrNull;
              if (kind == null) {
                throw BalanceFormatException('Tipo de pack desconocido');
              }
              final pieces = req<List<dynamic>>(m, 'pieces');
              if (pieces.any((e) => e is! String)) {
                throw BalanceFormatException('Piezas inválidas en ${m['id']}');
              }
              return PhotoPack(
                id: req<String>(m, 'id'),
                kind: kind,
                cost: req<int>(m, 'cost'),
                tier: tierOf(m, '${m['id']}'),
                pieces: List.unmodifiable(pieces.cast<String>()),
              );
            })
            .toList();
    final fullVersion = req<Map<String, dynamic>>(j, 'fullVersion');
    final albumJ = j['album'];
    final albumBonus = <String, int>{};
    if (albumJ != null) {
      final pages = albumJ is Map<String, dynamic> ? albumJ['pageBonus'] : null;
      if (pages is! Map<String, dynamic> ||
          pages.values.any((v) => v is! int)) {
        throw BalanceFormatException('album.pageBonus inválido');
      }
      albumBonus.addAll(pages.cast<String, int>());
    }

    final healthJ = req<Map<String, dynamic>>(j, 'health');
    final statusJ = req<Map<String, dynamic>>(j, 'status');
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
        tier: tierOf(f, 'games.fruit'),
        starFruits: ints(f['stars']) ?? const [8, 16],
        starGolden: f['starsGolden'] is int ? f['starsGolden'] as int : 3,
      ),
      frisbee: FrisbeeRule(
        throws: req<int>(d, 'throws'),
        maxScore: req<int>(d, 'maxScore'),
        baseCoins: req<int>(d, 'baseCoins'),
        coinsPerPoint: req<int>(d, 'coinsPerPoint'),
        flightSeconds: req<num>(d, 'flightSeconds').toDouble(),
        catchRadius: req<num>(d, 'catchRadius').toDouble(),
        targetsField: targets,
        targetPool: pool,
        starCatches: ints(d['stars']) ?? const [2, 4, 5],
        tier: tierOf(d, 'games.frisbee'),
      ),
      gameCompleteDelta: needMap(
        req<Map<String, dynamic>>(j, 'gameCompleteDelta'),
      ),
      health: HealthRule(
        cooldownSeconds: req<int>(healthJ, 'cooldownSeconds'),
        graceSeconds: req<int>(healthJ, 'graceSeconds'),
        randomChance: req<int>(healthJ, 'randomChance'),
        neglectChance: req<int>(healthJ, 'neglectChance'),
        neglectSatietyBelow: req<int>(healthJ, 'neglectSatietyBelow'),
        neglectHygieneBelow: req<int>(healthJ, 'neglectHygieneBelow'),
        neglectEnergyBelow: req<int>(healthJ, 'neglectEnergyBelow'),
        sickMoodPerTick100: req<int>(healthJ, 'sickMoodPerTick100'),
      ),
      status: StatusRule(
        hungryBelow: req<int>(statusJ, 'hungryBelow'),
        dirtyBelow: req<int>(statusJ, 'dirtyBelow'),
        sadBelow: req<int>(statusJ, 'sadBelow'),
        tiredBelow: req<int>(statusJ, 'tiredBelow'),
      ),
      styles: styles,
      decor: decor,
      photoPacks: photoPacks,
      fullVersionProductId: req<String>(fullVersion, 'productId'),
      albumPageBonus: albumBonus,
    );
  }
}
