import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/data/photo_album.dart';
import 'package:my_poodle/data/storage_backend.dart';

class BrokenIndex extends MemoryBackend {
  bool fail = false;
  @override
  Future<void> rename(String from, String to) async {
    if (fail && to == PhotoAlbum.index) throw StateError('disk full');
    await super.rename(from, to);
  }
}

void main() {
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aKRcAAAAASUVORK5CYII=',
  );
  test(
    'photos persist separately from game saves and can be deleted',
    () async {
      final backend = MemoryBackend()..files['save.json'] = 'unchanged';
      final photo = await PhotoAlbum(backend)
          .save(png, now: DateTime.utc(2026, 11, 19));
      final reopened = PhotoAlbum(backend);
      expect((await reopened.load()).single.id, photo.id);
      expect(await reopened.read(photo), png);
      await reopened.remove(photo);
      expect(await reopened.load(), isEmpty);
      expect(backend.files.containsKey('${photo.id}.png.base64'), isFalse);
      expect(backend.files['save.json'], 'unchanged');
    },
  );
  test('failed index replacement preserves previous album', () async {
    final backend = BrokenIndex();
    final album = PhotoAlbum(backend);
    final first = await album.save(png);
    final previous = backend.files[PhotoAlbum.index];
    backend.fail = true;
    await expectLater(album.save(png), throwsStateError);
    expect(backend.files[PhotoAlbum.index], previous);
    expect((await album.load()).single.id, first.id);
    expect(
      backend.files.keys.where((f) => f.endsWith('.png.base64')).length,
      1,
    );
    backend.fail = false;
    await album.save(png);
    expect((await album.load()).length, 2);
  });
  test(
    'concurrent saves respect capacity without deleting previous photos',
    () async {
      final backend = MemoryBackend();
      final album = PhotoAlbum(backend);
      await Future.wait([
        for (var i = 0; i < PhotoAlbum.limit; i++) album.save(png),
      ]);
      expect((await album.load()).length, PhotoAlbum.limit);
      final previous = backend.files[PhotoAlbum.index];
      await expectLater(album.save(png), throwsStateError);
      expect(backend.files[PhotoAlbum.index], previous);
    },
  );
  test(
    'invalid images and corrupted index are preserved for recovery',
    () async {
      final backend = MemoryBackend();
      final album = PhotoAlbum(backend);
      await expectLater(
        album.save(Uint8List.fromList([1, 2, 3])),
        throwsFormatException,
      );
      expect(backend.files, isEmpty);
      backend.files[PhotoAlbum.index] = 'corrupt';
      await expectLater(album.save(png), throwsFormatException);
      expect(backend.files[PhotoAlbum.index], 'corrupt');
    },
  );
}
