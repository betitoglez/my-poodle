import 'dart:io';

import 'package:flutter/services.dart';

import '../data/storage_backend.dart';

/// Canal pequeño hacia Kotlin/Swift: devuelve un directorio privado excluido
/// de copias de seguridad (Android noBackupFilesDir, iOS Application Support
/// con isExcludedFromBackup). Ver docs/TECNICA.md.
const MethodChannel storageChannel = MethodChannel('my_poodle/storage');

Future<StorageBackend> createPlatformBackend() async {
  String? path;
  if (Platform.isAndroid || Platform.isIOS) {
    path = await storageChannel.invokeMethod<String>('saveDirectory');
  }
  path ??=
      '${Platform.environment['HOME'] ?? Directory.systemTemp.path}/.my_poodle';
  final dir = Directory(path);
  await dir.create(recursive: true);
  return FileBackend(dir);
}

class FileBackend implements StorageBackend {
  FileBackend(this.dir);
  final Directory dir;

  File _f(String name) => File('${dir.path}/$name');

  @override
  Future<String?> read(String name) async {
    final f = _f(name);
    if (!await f.exists()) return null;
    return f.readAsString();
  }

  @override
  Future<void> write(String name, String text) async {
    final raf = await _f(name).open(mode: FileMode.writeOnly);
    try {
      await raf.truncate(0);
      await raf.writeString(text);
      await raf.flush();
    } finally {
      await raf.close();
    }
  }

  @override
  Future<void> rename(String from, String to) async {
    await _f(from).rename(_f(to).path);
  }

  @override
  Future<void> delete(String name) async {
    final f = _f(name);
    if (await f.exists()) await f.delete();
  }

  @override
  Future<bool> exists(String name) => _f(name).exists();

  @override
  String get description => 'archivo local (${dir.path.split('/').last})';
}
