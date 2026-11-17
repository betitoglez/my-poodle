import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/data/save_codec.dart';
import 'package:my_poodle/data/save_store.dart';
import 'package:my_poodle/data/storage_backend.dart';
import 'package:my_poodle/domain/appearance.dart';
import 'package:my_poodle/domain/pet_state.dart';
import 'package:my_poodle/domain/rules.dart';
import 'package:my_poodle/platform/platform_backend_io.dart';

import '../support.dart';

/// Backend que falla en la operación número [failAt] (write/rename).
class FaultyBackend extends MemoryBackend {
  int ops = 0;
  int failAt = -1;
  void _maybeFail() {
    if (ops++ == failAt) throw const FileSystemException('fallo inyectado');
  }

  @override
  Future<void> write(String name, String text) async {
    _maybeFail();
    await super.write(name, text);
  }

  @override
  Future<void> rename(String from, String to) async {
    _maybeFail();
    await super.rename(from, to);
  }
}

void main() {
  final balance = loadBalance();
  final codec = SaveCodec(balance);
  final rules = Rules(balance);
  final adopted = PetState.adopt(
    validName: 'María José',
    nowUtc: t0,
    balance: balance,
  );

  test('codifica y decodifica sin pérdida', () {
    final s = (rules.applyLook(
      adopted.copyWith(coins: 40),
      adopted.appearance
          .withSlot(Slot.neck, 'neck.coral')
          .withSlot(Slot.coat, 'coat.silver'),
      'op',
      t0,
      fullVersion: true,
    ) as Purchased).receipt.after;
    final back = codec.decode(codec.encode(s));
    expect(back.name, 'María José');
    expect(back.coins, s.coins);
    expect(back.owned, s.owned);
    expect(back.appearance, s.appearance);
    expect(back.revision, 2);
  });

  test('vacío → Adopción', () async {
    expect(await SaveStore(MemoryBackend(), codec).load(), isA<LoadEmpty>());
  });

  group('E06 lectura', () {
    test('principal truncado con copia válida → recupera copia', () async {
      final b = MemoryBackend();
      final store = SaveStore(b, codec);
      await store.write(adopted);
      await store.write(
        adopted.copyWith(revision: 2, lastCommitId: 'r2', coins: 5),
      );
      b.files[SaveStore.primary] = b.files[SaveStore.primary]!.substring(0, 20);
      final r = await store.load() as LoadOk;
      expect(r.recoveredFromBackup, isTrue);
      expect(r.state.revision, 1);
      expect((await store.load() as LoadOk).recoveredFromBackup, isFalse);
    });
    test('principal ausente con copia', () async {
      final b = MemoryBackend();
      final store = SaveStore(b, codec);
      await store.write(adopted);
      await store.write(adopted.copyWith(revision: 2, lastCommitId: 'r2'));
      await b.delete(SaveStore.primary);
      expect((await store.load() as LoadOk).state.revision, 1);
    });
    test('esquema futuro se preserva', () async {
      final b = MemoryBackend();
      b.files[SaveStore.primary] = '{"schemaVersion": 7}';
      expect(await SaveStore(b, codec).load(), isA<LoadFutureSchema>());
      expect(b.files[SaveStore.primary], '{"schemaVersion": 7}');
    });
    test('ambos dañados → corrupto, archivos preservados', () async {
      final b = MemoryBackend()
        ..files[SaveStore.primary] = '{'
        ..files[SaveStore.backup] = 'x';
      expect(await SaveStore(b, codec).load(), isA<LoadCorrupted>());
      expect(b.files.length, 2);
    });
    test('cosmético retirado: mantiene propiedad y usa fallback visible', () {
      final text = codec
          .encode(adopted)
          .replaceAll('"neck":"neck.none"', '"neck":"neck.retirado"')
          .replaceAll('"owned":[', '"owned":["neck.retirado",');
      final s = codec.decode(text);
      expect(s.appearance.neck, 'neck.none');
      expect(s.owned.contains('neck.retirado'), isTrue);
    });
    test('temporal huérfano nunca se confirma', () async {
      final b = MemoryBackend();
      final store = SaveStore(b, codec);
      await store.write(adopted);
      b.files[SaveStore.temp] = codec.encode(
        adopted.copyWith(revision: 9, lastCommitId: 'x', coins: 999),
      );
      expect((await store.load() as LoadOk).state.coins, 0);
    });
  });

  test('E07 fallo en cada frontera: se lee la revisión anterior o la siguiente', () async {
    final next = rules
        .finishGame(adopted, GameId.frisbee, 3, 'game-1', t0)
        .after;
    for (var failAt = 0; failAt < 4; failAt++) {
      final b = FaultyBackend();
      final store = SaveStore(b, codec);
      await store.write(adopted);
      b.ops = 0;
      b.failAt = failAt;
      Object? error;
      try {
        await store.write(next);
      } catch (e) {
        error = e;
      }
      final loaded = (await store.load() as LoadOk).state;
      expect([1, 2], contains(loaded.revision), reason: 'failAt=$failAt');
      if (error != null) {
        expect(error, isA<SaveException>());
        expect(loaded.revision, 1);
        // Resultado incierto: releer antes de reintentar evita pagar dos veces.
        expect(await store.committedId(), isNot('game-1'));
        b.failAt = -1;
        await store.write(next);
      }
      final final_ = (await store.load() as LoadOk).state;
      expect([final_.revision, final_.coins], [2, 12]);
    }
  });

  test('reinicio borra principal, copia y temporales', () async {
    final b = MemoryBackend();
    final store = SaveStore(b, codec);
    await store.write(adopted);
    await store.write(adopted.copyWith(revision: 2, lastCommitId: 'r2'));
    await store.reset();
    expect(b.files, isEmpty);
    expect(await store.load(), isA<LoadEmpty>());
  });

  test(
    'marcador de reinicio pendiente termina el borrado al arrancar',
    () async {
      final b = MemoryBackend();
      final store = SaveStore(b, codec);
      await store.write(adopted);
      b.files[SaveStore.resetMarker] = '1';
      expect(await store.load(), isA<LoadEmpty>());
      expect(b.files, isEmpty);
    },
  );

  test('FileBackend real en directorio temporal', () async {
    final dir = await Directory.systemTemp.createTemp('poodle');
    addTearDown(() => dir.delete(recursive: true));
    final store = SaveStore(FileBackend(dir), codec);
    await store.write(adopted);
    await store.write(
      adopted.copyWith(revision: 2, lastCommitId: 'r2', coins: 3),
    );
    expect((await store.load() as LoadOk).state.coins, 3);
    expect(File('${dir.path}/${SaveStore.backup}').existsSync(), isTrue);
    expect(File('${dir.path}/${SaveStore.temp}').existsSync(), isFalse);
  });
}
