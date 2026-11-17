import '../domain/pet_state.dart';
import 'save_codec.dart';
import 'storage_backend.dart';

sealed class LoadResult {
  const LoadResult();
}

class LoadEmpty extends LoadResult {
  const LoadEmpty();
}

class LoadOk extends LoadResult {
  const LoadOk(this.state, {this.recoveredFromBackup = false});
  final PetState state;
  final bool recoveredFromBackup;
}

/// Ambos archivos dañados: se preservan y se ofrece reinicio adulto.
class LoadCorrupted extends LoadResult {
  const LoadCorrupted(this.detail);
  final String detail;
}

/// Partida de una versión posterior: mantener archivos y pedir actualizar.
class LoadFutureSchema extends LoadResult {
  const LoadFutureSchema(this.version);
  final int version;
}

/// Fallo de E/S al leer (por ejemplo, almacenamiento no disponible).
class LoadIoError extends LoadResult {
  const LoadIoError(this.detail);
  final String detail;
}

class SaveException implements Exception {
  SaveException(this.stage, this.cause);
  final String stage;
  final Object cause;
  @override
  String toString() => 'SaveException($stage): $cause';
}

/// Guardado con principal, copia y temporal. Nunca borra el principal antes
/// de promover el temporal validado; nunca confirma desde un temporal huérfano.
class SaveStore {
  SaveStore(this.backend, this.codec);

  final StorageBackend backend;
  final SaveCodec codec;

  static const primary = 'save.json';
  static const backup = 'save.bak';
  static const temp = 'save.tmp';
  static const backupTemp = 'save.bak.tmp';
  static const resetMarker = 'reset.marker';

  Future<PetState?> _tryRead(String name, List<String> errors) async {
    final text = await backend.read(name);
    if (text == null) return null;
    try {
      return codec.decode(text);
    } on FutureSchemaException {
      rethrow;
    } catch (e) {
      errors.add('$name: $e');
      return null;
    }
  }

  Future<LoadResult> load() async {
    try {
      if (await backend.exists(resetMarker)) {
        await _deleteAll();
        return const LoadEmpty();
      }
      final errors = <String>[];
      try {
        final main = await _tryRead(primary, errors);
        if (main != null) return LoadOk(main);
      } on FutureSchemaException catch (e) {
        return LoadFutureSchema(e.version);
      }
      try {
        final copy = await _tryRead(backup, errors);
        if (copy != null) {
          // Promover la copia con seguridad: temporal → principal.
          final text = (await backend.read(backup))!;
          await backend.write(temp, text);
          await backend.rename(temp, primary);
          return LoadOk(copy, recoveredFromBackup: true);
        }
      } on FutureSchemaException catch (e) {
        return LoadFutureSchema(e.version);
      }
      if (errors.isNotEmpty) return LoadCorrupted(errors.join('; '));
      return const LoadEmpty();
    } catch (e) {
      return LoadIoError('$e');
    }
  }

  /// Escribe una revisión. Lanza [SaveException] indicando la frontera que
  /// falló; el principal anterior sigue siendo válido hasta el reemplazo.
  Future<void> write(PetState s) async {
    final text = codec.encode(s);
    var stage = 'temporal';
    try {
      await backend.write(temp, text);
      stage = 'verificar';
      final reread = await backend.read(temp);
      if (reread == null) throw StateError('Temporal ausente');
      final check = codec.decode(reread);
      if (check.revision != s.revision ||
          check.lastCommitId != s.lastCommitId) {
        throw StateError('Temporal no coincide');
      }
      stage = 'copia';
      final current = await backend.read(primary);
      if (current != null) {
        try {
          codec.decode(current);
          await backend.write(backupTemp, current);
          await backend.rename(backupTemp, backup);
        } on SaveFormatException {
          // Principal dañado: no se copia sobre una copia válida.
        }
      }
      stage = 'reemplazo';
      await backend.rename(temp, primary);
    } catch (e) {
      throw SaveException(stage, e);
    }
  }

  /// Último ID confirmado en disco, para decidir ante un resultado incierto.
  Future<String?> committedId() async {
    final text = await backend.read(primary);
    if (text == null) return null;
    try {
      return codec.decode(text).lastCommitId;
    } catch (_) {
      return null;
    }
  }

  /// Reinicio adulto: marcador local para terminar el borrado tras un cierre.
  Future<void> reset() async {
    await backend.write(resetMarker, '1');
    await _deleteAll();
  }

  Future<void> _deleteAll() async {
    for (final f in [primary, backup, temp, backupTemp]) {
      await backend.delete(f);
    }
    await backend.delete(resetMarker);
  }
}
