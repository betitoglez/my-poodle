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
    'revision': s.revision,
    'lastCommitId': s.lastCommitId,
    'name': s.name,
    'needsCursorUtc': s.needsCursorUtc,
    'satiety100': s.need100(Need.satiety),
    'hygiene100': s.need100(Need.hygiene),
    'mood100': s.need100(Need.mood),
    'energy100': s.need100(Need.energy),
    'coins': s.coins,
    'owned': (s.owned.toList()..sort()),
    'appearance': s.appearance.toJson(),
    'bestFruit': s.bestFruit,
    'bestFrisbee': s.bestFrisbee,
    'muted': s.prefs.muted,
    'music': s.prefs.music,
    'effects': s.prefs.effects,
    'reducedMotion': s.prefs.reducedMotion,
    'seenHints': (s.prefs.seenHints.toList()..sort()),
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
      if (v is! String || !v.startsWith('${slot.name}.')) {
        throw SaveFormatException('appearance.${slot.name} inválido');
      }
      // Un cosmético retirado mantiene su propiedad; el aspecto usa el
      // artículo base de la ranura como fallback visible.
      return balance.item(v) == null ? balance.baseFor(slot).id : v;
    }

    final appearance = Appearance(
      coat: slotId(Slot.coat),
      hair: slotId(Slot.hair),
      outfit: slotId(Slot.outfit),
      neck: slotId(Slot.neck),
    );
    // Los artículos base siempre están en propiedad.
    owned.addAll(balance.initialAppearance.ids);

    bool optBool(String k, bool fallback) {
      final v = j[k];
      return v is bool ? v : fallback;
    }

    final muted = optBool('muted', false);
    final hints = j['seenHints'];
    return PetState(
      revision: revision,
      lastCommitId: req<String>('lastCommitId'),
      name: (nameResult).value,
      needsCursorUtc: req<int>('needsCursorUtc'),
      needs100: {
        Need.satiety: need('satiety100'),
        Need.hygiene: need('hygiene100'),
        Need.mood: need('mood100'),
        Need.energy: need('energy100'),
      },
      coins: coins,
      owned: Set.unmodifiable(owned),
      appearance: appearance,
      bestFruit: (j['bestFruit'] as int?) ?? 0,
      bestFrisbee: (j['bestFrisbee'] as int?) ?? 0,
      prefs: Preferences(
        music: optBool('music', !muted),
        effects: optBool('effects', !muted),
        reducedMotion: optBool('reducedMotion', false),
        seenHints: hints is List ? hints.whereType<String>().toSet() : const {},
      ),
    );
  }
}
