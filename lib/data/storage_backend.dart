/// Acceso mínimo a archivos de partida. Implementaciones: disco (móvil),
/// localStorage (vista previa web) y memoria (pruebas y modo demostración).
abstract class StorageBackend {
  Future<String?> read(String name);

  /// Escribe completo y vacía a disco antes de volver.
  Future<void> write(String name, String text);

  /// Reemplazo atómico en el mismo volumen cuando la plataforma lo permite.
  Future<void> rename(String from, String to);
  Future<void> delete(String name);
  Future<bool> exists(String name);
  String get description;
}

class MemoryBackend implements StorageBackend {
  final Map<String, String> files = {};

  @override
  Future<String?> read(String name) async => files[name];
  @override
  Future<void> write(String name, String text) async => files[name] = text;
  @override
  Future<void> rename(String from, String to) async {
    final v = files.remove(from);
    if (v == null) throw StateError('No existe $from');
    files[to] = v;
  }

  @override
  Future<void> delete(String name) async => files.remove(name);
  @override
  Future<bool> exists(String name) async => files.containsKey(name);
  @override
  String get description => 'memoria';
}
