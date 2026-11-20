import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'storage_backend.dart';

class AlbumPhoto {
  const AlbumPhoto(this.id, this.createdUtc);
  final String id;
  final int createdUtc;
  Map<String, Object> toJson() => {'id': id, 'createdUtc': createdUtc};
}

/// Álbum privado separado de la partida y de los derechos de compra.
class PhotoAlbum {
  PhotoAlbum(this.backend);
  final StorageBackend backend;
  static const index = 'photos-v1.json';
  static const limit = 24;
  static int _sequence = 0;
  static final _writeQueues = Expando<_AlbumWriteQueue>('private photo album');

  _AlbumWriteQueue get _queue => _writeQueues[backend] ??= _AlbumWriteQueue();

  Future<List<AlbumPhoto>> load() async {
    final raw = await backend.read(index);
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! Map ||
        decoded['version'] != 1 ||
        decoded['photos'] is! List) {
      throw const FormatException('Álbum inválido');
    }
    final photos = <AlbumPhoto>[];
    for (final entry in decoded['photos'] as List) {
      if (entry is! Map ||
          entry['id'] is! String ||
          !RegExp(r'^photo-[0-9]+-[0-9]+$').hasMatch(entry['id'] as String) ||
          entry['createdUtc'] is! int) {
        throw const FormatException('Foto inválida');
      }
      photos.add(AlbumPhoto(entry['id'] as String, entry['createdUtc'] as int));
    }
    if (photos.length > limit ||
        photos.map((p) => p.id).toSet().length != photos.length) {
      throw const FormatException('Índice de fotos inválido');
    }
    return photos;
  }

  Future<T> _serial<T>(Future<T> Function() action) {
    final queue = _queue;
    final next = queue.tail.then((_) => action());
    queue.tail = next.then((_) {}, onError: (_) {});
    return next;
  }

  Future<void> _writeIndex(List<AlbumPhoto> photos) async {
    await backend.write(
      '$index.tmp',
      jsonEncode({
        'version': 1,
        'photos': photos.map((p) => p.toJson()).toList(),
      }),
    );
    await backend.rename('$index.tmp', index);
  }

  Future<AlbumPhoto> save(Uint8List png, {DateTime? now}) => _serial(() async {
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    if (png.length < signature.length ||
        List.generate(
          signature.length,
          (i) => png[i] == signature[i],
        ).contains(false)) {
      throw const FormatException('Imagen PNG inválida');
    }
    if (png.length > 8 * 1024 * 1024) throw StateError('Foto demasiado grande');
    final photos = await load();
    if (photos.length >= limit) throw StateError('Álbum lleno');
    final time = (now ?? DateTime.now()).toUtc();
    final photo = AlbumPhoto(
      'photo-${time.microsecondsSinceEpoch}-${_sequence++}',
      time.millisecondsSinceEpoch ~/ 1000,
    );
    final file = '${photo.id}.png.base64';
    await backend.write('$file.tmp', base64Encode(png));
    await backend.rename('$file.tmp', file);
    try {
      await _writeIndex([photo, ...photos]);
    } catch (_) {
      try {
        await backend.delete(file);
      } catch (_) {
        /* Recurso huérfano; no aparece en el índice. */
      }
      rethrow;
    }
    return photo;
  });

  Future<Uint8List> read(AlbumPhoto photo) async {
    if (!(await load()).any((p) => p.id == photo.id)) {
      throw StateError('Foto no encontrada');
    }
    final data = await backend.read('${photo.id}.png.base64');
    if (data == null) throw StateError('Foto no encontrada');
    return base64Decode(data);
  }

  Future<void> remove(AlbumPhoto photo) => _serial(() async {
    final photos = await load();
    await _writeIndex(photos.where((p) => p.id != photo.id).toList());
    await backend.delete('${photo.id}.png.base64');
  });
}

class _AlbumWriteQueue {
  Future<void> tail = Future.value();
}
