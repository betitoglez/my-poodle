import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/data/entitlement_store.dart';
import 'package:my_poodle/data/save_codec.dart';
import 'package:my_poodle/data/save_store.dart';
import 'package:my_poodle/data/storage_backend.dart';
import 'package:my_poodle/domain/entitlements.dart';
import 'package:my_poodle/domain/pet_state.dart';

import '../support.dart';

void main() {
  const id = 'mypoodle.full_version';
  const full = Entitlement(
    state: EntitlementState.purchased,
    updatedUtc: t0,
    lastEventIds: ['a'],
  );

  test('E14 · ausente o dañado → gratis; válido se relee', () async {
    final b = MemoryBackend();
    final store = EntitlementStore(b, productId: id);
    expect(await store.load(), Entitlement.none);
    await store.write(full);
    expect(await store.load(), full);
    b.files[EntitlementStore.primary] = '{"schemaVersion": 1, "produ';
    // El principal truncado cae a la copia, si existe; si no, gratis.
    expect((await store.load()).full, isFalse);
    await store.write(full);
    await store.write(full.copyWith(updatedUtc: t0 + 1));
    b.files[EntitlementStore.primary] = 'basura';
    expect((await store.load()).full, isTrue, reason: 'usa la copia');
  });

  test('E14 · esquema futuro se conserva sin sobrescribir', () async {
    final b = MemoryBackend();
    const future = '{"schemaVersion": 2, "productId": "$id"}';
    b.files[EntitlementStore.primary] = future;
    final store = EntitlementStore(b, productId: id);
    expect(await store.load(), Entitlement.none);
    expect(store.futureSchema, isTrue);
    expect(() => store.write(full), throwsStateError);
    expect(b.files[EntitlementStore.primary], future);
  });

  test('E14 · documento simulado se ignora en Release', () async {
    final b = MemoryBackend();
    await EntitlementStore(
      b,
      productId: id,
    ).write(full.copyWith(source: EntitlementSource.simulated));
    expect((await EntitlementStore(b, productId: id).load()).full, isTrue);
    final release = EntitlementStore(b, productId: id, acceptSimulated: false);
    expect((await release.load()).full, isFalse);
  });

  test('E14 · reiniciar la partida conserva la versión completa', () async {
    final b = MemoryBackend();
    final balance = loadBalance();
    final save = SaveStore(b, SaveCodec(balance));
    await save.write(
      PetState.adopt(validName: 'Miel', nowUtc: t0, balance: balance),
    );
    final store = EntitlementStore(b, productId: id);
    await store.write(full);
    await save.reset();
    expect(b.files.containsKey(SaveStore.primary), isFalse);
    expect((await store.load()).full, isTrue);
  });
}
