import 'dart:convert';

import '../domain/achievements.dart' show secondsPerDay;
import '../domain/appearance.dart';
import '../domain/haircuts.dart';
import '../domain/balance.dart';
import '../domain/pet_name.dart';
import '../domain/pet_state.dart';

class SaveFormatException implements Exception {
  SaveFormatException(this.message);
  final String message;
  @override
  String toString() => 'SaveFormatException: $message';
}

class FutureSchemaException implements Exception {
  FutureSchemaException(this.version);
  final int version;
}

/// Documento persistente v1 (ver docs/TECNICA.md). Validación explícita.
class SaveCodec {
  const SaveCodec(this.balance);
  final Balance balance;

  String encode(PetState s) => jsonEncode({
    'schemaVersion': PetState.schemaVersion,
    'careCompletedUtc': s.careCompletedUtc,
    'gameStartedUtc': s.gameStartedUtc,
    'premiumTrialStartedUtc': s.premiumTrialStartedUtc,
    'revision': s.revision,
    'lastCommitId': s.lastCommitId,
    'name': s.name,
    'needsCursorUtc': s.needsCursorUtc,
    'satiety100': s.need100(Need.satiety),
    'hygiene100': s.need100(Need.hygiene),
    'mood100': s.need100(Need.mood),
    'energy100': s.need100(Need.energy),
    'hydration100': s.need100(Need.hydration),
    'restingSinceUtc': s.restingSinceUtc,
    'restEnergyCursorUtc': s.restEnergyCursorUtc,
    'coins': s.coins,
    'owned': (s.owned.toList()..sort()),
    'appearance': s.appearance.toJson(),
    'bestFruit': s.bestFruit,
    'bestFrisbee': s.bestFrisbee,
    'bestPairs': s.bestPairs,
    'bestMemory': s.bestMemory,
    'puzzleDeals': s.puzzleDeals,
    'bestStars': s.bestStars,
    'decor': {for (final e in s.decor.entries) e.key.name: e.value},
    'muted': s.prefs.muted,
    'music': s.prefs.music,
    'effects': s.prefs.effects,
    'reducedMotion': s.prefs.reducedMotion,
    'seenHints': (s.prefs.seenHints.toList()..sort()),
    'language': s.prefs.language,
    'sickSinceUtc': s.sickSinceUtc,
    'lastSickUtc': s.lastSickUtc,
    'sickSeed': s.sickSeed,
    // Logros y álbum (opcionales al leer).
    'achievements': s.achievements,
    'albumCollected': (s.albumCollected.toList()..sort()),
    'coinsEarnedTotal': s.coinsEarnedTotal,
    'careDayCount': s.careDayCount,
    'lastCareDay': s.lastCareDay,
    'photosTaken': s.photosTaken,
  });

  PetState decode(String text) {
    final Object? raw;
    try {
      raw = jsonDecode(text);
    } on FormatException catch (e) {
      throw SaveFormatException('JSON inválido: ${e.message}');
    }
    if (raw is! Map<String, dynamic>) throw SaveFormatException('No es objeto');
    final j = raw;
    final schema = j['schemaVersion'];
    if (schema is! int) throw SaveFormatException('Sin schemaVersion');
    if (schema > PetState.schemaVersion) throw FutureSchemaException(schema);
    if (schema < 1) throw SaveFormatException('Esquema desconocido');

    T req<T>(String k) {
      final v = j[k];
      if (v is! T) throw SaveFormatException('Campo $k inválido');
      return v;
    }

    int need(String k) {
      final v = req<int>(k);
      if (v < 0 || v > 10000) throw SaveFormatException('$k fuera de rango');
      return v;
    }

    final nameResult = PetName.validate(req<String>('name'));
    if (nameResult is! ValidName) throw SaveFormatException('Nombre inválido');
    final coins = req<int>('coins');
    if (coins < 0) throw SaveFormatException('Saldo negativo');
    final revision = req<int>('revision');
    if (revision < 1) throw SaveFormatException('Revisión inválida');

    final owned = req<List<dynamic>>('owned').map((e) {
      if (e is! String) throw SaveFormatException('owned inválido');
      return e;
    }).toSet();
    final ap = req<Map<String, dynamic>>('appearance');
    String slotId(Slot slot) {
      final v = ap[slot.name];
      // Partidas anteriores a una ranura nueva (cabeza, ojos, collar,
      // patucos…) no la traen: se usa el artículo base.
      if (v == null) return balance.baseFor(slot).id;
      if (v is! String || !v.startsWith('${slot.name}.')) {
        throw SaveFormatException('appearance.${slot.name} inválido');
      }
      // Un cosmético retirado mantiene su propiedad; el aspecto usa el
      // artículo base de la ranura como fallback visible.
      return balance.item(v) == null ? balance.baseFor(slot).id : v;
    }

    final legacyHair = slotId(Slot.hair);
    final appearance = Appearance(
      {for (final slot in Slot.values) slot: slotId(slot)},
      cuts: {
        for (final z in HairZone.values)
          z:
              ap['cut_${z.name}'] is String &&
                  Haircuts.supports(z, ap['cut_${z.name}'] as String)
              ? ap['cut_${z.name}'] as String
              : Haircuts.styleOf(legacyHair),
      },
    );
    // Los packs antiguos se conservan como sus cuatro cortes ya adquiridos.
    for (final pack in owned.where((id) => id.startsWith('hair.')).toList()) {
      for (final zone in HairZone.values) {
        owned.add(Haircuts.id(zone, Haircuts.styleOf(pack)));
      }
    }
    // Los artículos base siempre están en propiedad.
    owned.addAll(balance.initialAppearance.ids);

    bool optBool(String k, bool fallback) {
      final v = j[k];
      return v is bool ? v : fallback;
    }

    final muted = optBool('muted', false);
    final cursor = req<int>('needsCursorUtc');
    final sickSince = j['sickSinceUtc'];
    final lastSick = j['lastSickUtc'];
    final seed = j['sickSeed'];
    final hints = j['seenHints'];
    final careTimes = j['careCompletedUtc'] ?? <String, dynamic>{};
    final gameTimes = j['gameStartedUtc'] ?? <dynamic>[];
    final trialTimes = j['premiumTrialStartedUtc'] ?? <String, dynamic>{};
    if (trialTimes is! Map<String, dynamic> ||
        trialTimes.values.any((v) => v is! int || v < 0)) {
      throw SaveFormatException('Pruebas premium inválidas');
    }
    final deals = j['puzzleDeals'] ?? <String, dynamic>{};
    if (deals is! Map<String, dynamic> ||
        deals.values.any((v) => v is! List || v.any((e) => e is! String))) {
      throw SaveFormatException('Repartos inválidos');
    }
    final starsRaw = j['bestStars'] ?? <String, dynamic>{};
    if (starsRaw is! Map<String, dynamic> ||
        starsRaw.values.any((v) => v is! int || v < 0 || v > 3)) {
      throw SaveFormatException('Estrellas inválidas');
    }
    // Partidas anteriores a la decoración: salón vacío. Un artículo retirado
    // o sin propiedad vuelve al hueco vacío, conservando lo comprado.
    final decorRaw = j['decor'];
    final decor = Map<DecorSlot, String>.of(balance.initialDecor);
    if (decorRaw is Map<String, dynamic>) {
      for (final slot in DecorSlot.values) {
        final v = decorRaw[slot.name];
        final item = v is String ? balance.decorItem(v) : null;
        if (item != null &&
            item.slot == slot &&
            (item.initial || owned.contains(item.id))) {
          decor[slot] = item.id;
        }
      }
    } else if (decorRaw != null) {
      throw SaveFormatException('Decoración inválida');
    }
    final restStart = j['restingSinceUtc'];
    final restCursor = j['restEnergyCursorUtc'];
    if (careTimes is! Map<String, dynamic> ||
        careTimes.values.any((v) => v is! int || v < 0) ||
        gameTimes is! List ||
        gameTimes.any((v) => v is! int || v < 0)) {
      throw SaveFormatException('Límites de actividad inválidos');
    }
    final album = _decodeAlbum(j, coins: coins, owned: owned, care: careTimes);
    return PetState(
      achievements: album.achievements,
      albumCollected: album.collected,
      coinsEarnedTotal: album.coinsEarned,
      careDayCount: album.careDays,
      lastCareDay: album.lastCareDay,
      photosTaken: album.photos,
      restingSinceUtc: restStart is int && restStart >= 0 ? restStart : null,
      restEnergyCursorUtc: restCursor is int && restCursor >= 0
          ? restCursor
          : null,
      careCompletedUtc: careTimes.cast<String, int>(),
      gameStartedUtc: gameTimes.cast<int>(),
      premiumTrialStartedUtc: Map.unmodifiable(trialTimes.cast<String, int>()),
      revision: revision,
      lastCommitId: req<String>('lastCommitId'),
      name: (nameResult).value,
      needsCursorUtc: cursor,
      needs100: {
        Need.satiety: need('satiety100'),
        Need.hygiene: need('hygiene100'),
        Need.mood: need('mood100'),
        Need.energy: need('energy100'),
        Need.hydration: j.containsKey('hydration100')
            ? need('hydration100')
            : balance.initial100[Need.hydration]!,
      },
      coins: coins,
      owned: Set.unmodifiable(owned),
      appearance: appearance,
      bestFruit: (j['bestFruit'] as int?) ?? 0,
      bestFrisbee: (j['bestFrisbee'] as int?) ?? 0,
      bestPairs: (j['bestPairs'] as int?) ?? 0,
      bestMemory: (j['bestMemory'] as int?) ?? 0,
      puzzleDeals: Map.unmodifiable({
        for (final e in deals.entries)
          e.key: List<String>.unmodifiable((e.value as List).cast<String>()),
      }),
      bestStars: Map.unmodifiable(starsRaw.cast<String, int>()),
      decor: Map.unmodifiable(decor),
      prefs: Preferences(
        language: j['language'] is String ? j['language'] as String : null,
        music: optBool('music', !muted),
        effects: optBool('effects', !muted),
        reducedMotion: optBool('reducedMotion', false),
        seenHints: hints is List ? hints.whereType<String>().toSet() : const {},
      ),
      sickSinceUtc: sickSince is int ? sickSince : null,
      // Partidas anteriores a la salud: sin enfermedad y con el plazo de
      // una semana medido desde el último cursor menos un día de gracia.
      lastSickUtc: lastSick is int
          ? lastSick
          : cursor -
                balance.health.cooldownSeconds +
                balance.health.graceSeconds,
      sickSeed: seed is int ? seed : (cursor & 0x7fffffff),
    );
  }

  /// Campos de logros y álbum. Opcionales: una partida anterior los deduce
  /// de lo guardado (días de cuidado por `careCompletedUtc`, monedas ganadas
  /// como cota inferior: saldo + artículos comprados − saldo inicial; fotos
  /// desde cero). Un campo presente con forma inválida rechaza la partida.
  _AlbumFields _decodeAlbum(
    Map<String, dynamic> j, {
    required int coins,
    required Set<String> owned,
    required Map<String, dynamic> care,
  }) {
    int? optCount(String k) {
      final v = j[k];
      if (v == null) return null;
      if (v is! int || v < 0) throw SaveFormatException('$k inválido');
      return v;
    }

    final achRaw = j['achievements'] ?? <String, dynamic>{};
    if (achRaw is! Map<String, dynamic> ||
        achRaw.values.any((v) => v is! int || v < 0)) {
      throw SaveFormatException('Logros inválidos');
    }
    final collectedRaw = j['albumCollected'] ?? <dynamic>[];
    if (collectedRaw is! List || collectedRaw.any((v) => v is! String)) {
      throw SaveFormatException('Álbum inválido');
    }
    var careDays = optCount('careDayCount');
    var lastDay = optCount('lastCareDay');
    if (careDays == null) {
      final days = {
        for (final e in care.entries)
          if (e.key != 'greeting') (e.value as int) ~/ secondsPerDay,
      };
      careDays = days.length;
      lastDay = days.isEmpty ? null : days.reduce((a, b) => a > b ? a : b);
    }
    var earned = optCount('coinsEarnedTotal');
    if (earned == null) {
      // Cortes por zona a su precio; el peinado completo `hair.<estilo>` solo
      // cuenta si no hay cortes por zona de ese estilo (sería un alias).
      var spent = 0;
      final cutStyles = <String>{};
      for (final id in owned) {
        if (!Haircuts.valid(id)) continue;
        final style = id.split('.').last;
        spent += Haircuts.cost(style);
        cutStyles.add(style);
      }
      for (final id in owned) {
        final style = balance.item(id);
        final decor = balance.decorItem(id);
        if (style != null && !style.initial) {
          final alias =
              style.slot == Slot.hair && cutStyles.contains(id.split('.').last);
          if (!alias) spent += style.cost;
        }
        if (decor != null && !decor.initial) spent += decor.cost;
      }
      earned = coins + spent - balance.startCoins;
      if (earned < 0) earned = 0;
    }
    return _AlbumFields(
      achievements: Map.unmodifiable(achRaw.cast<String, int>()),
      collected: Set.unmodifiable(collectedRaw.cast<String>()),
      coinsEarned: earned,
      careDays: careDays,
      lastCareDay: lastDay,
      photos: optCount('photosTaken') ?? 0,
    );
  }
}

class _AlbumFields {
  const _AlbumFields({
    required this.achievements,
    required this.collected,
    required this.coinsEarned,
    required this.careDays,
    required this.lastCareDay,
    required this.photos,
  });
  final Map<String, int> achievements;
  final Set<String> collected;
  final int coinsEarned;
  final int careDays;
  final int? lastCareDay;
  final int photos;
}
