import 'dart:convert';

import '../domain/entitlements.dart';
import 'storage_backend.dart';

/// Documento local del derecho a la versión completa (docs/TECNICA.md). Vive
/// junto a la partida, pero no forma parte de ella: reiniciar la partida no
/// lo borra. Mismo patrón de escritura: temporal verificado, copia y
/// reemplazo. Nunca guarda recibos, IDs de transacción en claro ni datos de
/// la cuenta de la tienda.
class EntitlementStore {
  EntitlementStore(
    this.backend, {
    required this.productId,
    this.acceptSimulated = true,
  });

  final StorageBackend backend;
  final String productId;

  /// En Release se ignora un documento creado por la tienda simulada.
  final bool acceptSimulated;

  static const schemaVersion = 1;
  static const primary = 'entitlement.json';
  static const backup = 'entitlement.bak';
  static const temp = 'entitlement.tmp';
  static const backupTemp = 'entitlement.bak.tmp';

  /// El documento es de una versión posterior: se conserva sin escribir.
  bool futureSchema = false;

  String encode(Entitlement e) => jsonEncode({
    'schemaVersion': schemaVersion,
    'productId': productId,
    'full': e.full,
    'state': e.state.name,
    'source': e.source.name,
    'updatedUtc': e.updatedUtc,
    'lastEventIds': e.lastEventIds,
  });

  /// Lanza [FormatException] si el texto no es un documento válido.
  Entitlement decode(String text) {
    final j = jsonDecode(text);
    if (j is! Map<String, dynamic>) throw const FormatException('No es objeto');
    final v = j['schemaVersion'];
    if (v is! int) throw const FormatException('Sin versión');
    if (v > schemaVersion) throw _FutureSchema();
    if (j['productId'] != productId) {
      throw const FormatException('Otro producto');
    }
    T pick<T>(List<T> values, Object? name) => values.firstWhere(
      (x) => (x as Enum).name == name,
      orElse: () => throw const FormatException('Valor desconocido'),
    );
    final state = pick(EntitlementState.values, j['state']);
    final source = pick(EntitlementSource.values, j['source']);
    final updated = j['updatedUtc'];
    final ids = j['lastEventIds'];
    if (updated is! int || ids is! List || ids.any((x) => x is! String)) {
      throw const FormatException('Campos inválidos');
    }
    if (j['full'] != (state == EntitlementState.purchased)) {
      throw const FormatException('full no coincide con state');
    }
    return Entitlement(
      state: state,
      source: source,
      updatedUtc: updated,
      lastEventIds: List<String>.from(ids),
    );
  }

  Future<Entitlement?> _try(String name) async {
    final text = await backend.read(name);
    if (text == null) return null;
    try {
      return decode(text);
    } on _FutureSchema {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  /// Ausente o dañado → sin versión completa (la tienda puede restaurarla).
  Future<Entitlement> load() async {
    futureSchema = false;
    try {
      final e = await _try(primary) ?? await _try(backup);
      if (e == null) return Entitlement.none;
      if (e.source == EntitlementSource.simulated && !acceptSimulated) {
        return Entitlement.none;
      }
      return e;
    } on _FutureSchema {
      futureSchema = true;
      return Entitlement.none;
    } catch (_) {
      return Entitlement.none;
    }
  }

  Future<void> write(Entitlement e) async {
    if (futureSchema) {
      throw StateError('Documento de una versión posterior: no se sobrescribe');
    }
    final text = encode(e);
    await backend.write(temp, text);
    final reread = await backend.read(temp);
    if (reread == null || decode(reread) != e) {
      throw StateError('Temporal del derecho no coincide');
    }
    final current = await backend.read(primary);
    if (current != null) {
      try {
        decode(current);
        await backend.write(backupTemp, current);
        await backend.rename(backupTemp, backup);
      } catch (_) {
        // Principal dañado: no se copia sobre una copia válida.
      }
    }
    await backend.rename(temp, primary);
  }
}

class _FutureSchema implements Exception {}
