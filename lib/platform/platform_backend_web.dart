import 'package:web/web.dart' as web;

import '../data/storage_backend.dart';

/// Vista previa web: localStorage del navegador, solo en este dispositivo.
Future<StorageBackend> createPlatformBackend() async => LocalStorageBackend();

class LocalStorageBackend implements StorageBackend {
  static const _prefix = 'my_poodle/';
  web.Storage get _s => web.window.localStorage;

  @override
  Future<String?> read(String name) async => _s.getItem('$_prefix$name');
  @override
  Future<void> write(String name, String text) async =>
      _s.setItem('$_prefix$name', text);
  @override
  Future<void> rename(String from, String to) async {
    final v = _s.getItem('$_prefix$from');
    if (v == null) throw StateError('No existe $from');
    _s.setItem('$_prefix$to', v);
    _s.removeItem('$_prefix$from');
  }

  @override
  Future<void> delete(String name) async => _s.removeItem('$_prefix$name');
  @override
  Future<bool> exists(String name) async => _s.getItem('$_prefix$name') != null;
  @override
  String get description => 'almacenamiento del navegador';
}
