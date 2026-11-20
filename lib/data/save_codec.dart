import 'dart:convert';

import '../domain/appearance.dart';
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

    final appearance = Appearance({
      for (final slot in Slot.values) slot: slotId(slot),
    });
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
    return PetState(
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
}
