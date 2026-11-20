import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/data/save_codec.dart';
import 'package:my_poodle/domain/balance.dart';
import 'package:my_poodle/domain/entitlements.dart';
import 'package:my_poodle/domain/pet_name.dart';
import 'package:my_poodle/domain/pet_state.dart';
import 'package:my_poodle/domain/photo_caption.dart';
import 'package:my_poodle/domain/rules.dart';

import '../support.dart';

void main() {
  final balance = loadBalance();
  final rules = Rules(balance);
  final codec = SaveCodec(balance);
  PetState adopt() =>
      PetState.adopt(validName: 'Miel', nowUtc: t0, balance: balance);
  PetState rich(int coins) => adopt().copyWith(coins: coins);
  PurchaseOutcome buy(PetState s, String id, {bool full = false}) =>
      rules.buyPhotoPack(s, id, 'p', t0, fullVersion: full);

  group('catálogo de packs de fotos', () {
    test('packs, precios y versiones del balance', () {
      final packs = {
        for (final p in balance.photoPacks) p.id: (p.cost, p.tier, p.kind),
      };
      expect(packs, {
        'photo.basic': (0, Tier.free, PhotoPackKind.sticker),
        'photo.party': (60, Tier.free, PhotoPackKind.sticker),
        'photo.nature': (60, Tier.full, PhotoPackKind.sticker),
        'photo.bubbles': (80, Tier.full, PhotoPackKind.sticker),
        'photo.frames_basic': (0, Tier.free, PhotoPackKind.frame),
        'photo.frames_color': (50, Tier.free, PhotoPackKind.frame),
        'photo.frames_luxury': (250, Tier.full, PhotoPackKind.frame),
        'photo.text_basic': (0, Tier.free, PhotoPackKind.text),
        'photo.text_styles': (40, Tier.free, PhotoPackKind.text),
      });
      expect(balance.photoPack('photo.basic')!.pieces, hasLength(5));
      expect(balance.photoPackOfPiece('frame.gold')!.id, 'photo.frames_luxury');
      // Comprable con la versión gratuita: fiesta, marcos de colores, estilos.
      expect(
        balance.photoPacks
            .where((p) => !p.free && p.tier == Tier.free)
            .fold(0, (sum, p) => sum + p.cost),
        150,
      );
      expect(
        balance.photoPacks
            .where((p) => p.tier == Tier.full)
            .fold(0, (sum, p) => sum + p.cost),
        390,
      );
    });

    test('las dos copias del balance son idénticas', () {
      expect(
        File('docs/datos/balance-v1.json').readAsStringSync(),
        File('assets/data/balance-v1.json').readAsStringSync(),
      );
    });

    test('la validación rechaza packs incoherentes', () {
      Map<String, dynamic> json() =>
          jsonDecode(File('assets/data/balance-v1.json').readAsStringSync())
              as Map<String, dynamic>;
      void rejects(void Function(List<dynamic> packs) tweak) {
        final j = json();
        tweak(j['photoPacks'] as List<dynamic>);
        expect(
          () => Balance.fromJson(j),
          throwsA(isA<BalanceFormatException>()),
        );
      }

      rejects((p) => (p[1] as Map)['id'] = 'party');
      rejects((p) => (p[1] as Map)['id'] = 'photo.basic');
      rejects((p) => (p[1] as Map)['pieces'] = ['frame.party']);
      rejects((p) => (p[1] as Map)['pieces'] = ['sticker.heart']);
      rejects((p) => (p[1] as Map)['pieces'] = []);
      rejects((p) => (p[1] as Map)['cost'] = -1);
      rejects((p) => (p[0] as Map)['tier'] = 'full');
      rejects((p) => (p[1] as Map)['kind'] = 'sound');
      rejects((p) {
        for (final pack in p) {
          if ((pack as Map)['cost'] != 0) pack['tier'] = 'full';
        }
      });
      // Sin bloque: balance anterior, sin packs.
      final old = json()..remove('photoPacks');
      expect(Balance.fromJson(old).photoPacks, isEmpty);
    });
  });

  group('comprar un pack', () {
    test('saldo exacto: cobra una vez y queda en propiedad', () {
      final r = buy(rich(60), 'photo.party');
      expect(r, isA<Purchased>());
      final p = r as Purchased;
      expect(p.cost, 60);
      expect(p.receipt.after.coins, 0);
      expect(p.receipt.after.owned, contains('photo.party'));
      expect(p.receipt.after.revision, p.receipt.before.revision + 1);
      expect(
        rules.photoPackOwned(
          p.receipt.after,
          balance.photoPack('photo.party')!,
        ),
        isTrue,
      );
    });

    test('saldo insuficiente: indica lo que falta y no cambia nada', () {
      final s = rich(59);
      final r = buy(s, 'photo.party');
      expect(r, isA<InsufficientCoins>());
      expect((r as InsufficientCoins).missing, 1);
      expect(r.cost, 60);
      expect(s.owned, isNot(contains('photo.party')));
    });

    test('versión completa: candado sin derecho, compra con él', () {
      final s = rich(500);
      final locked = buy(s, 'photo.frames_luxury');
      expect(locked, isA<RequiresFull>());
      expect((locked as RequiresFull).itemIds, ['photo.frames_luxury']);
      final bought = buy(s, 'photo.frames_luxury', full: true) as Purchased;
      expect(bought.cost, 250);
      expect(bought.receipt.after.coins, 250);
      // Lo comprado se conserva aunque se pierda la versión completa.
      final again = buy(bought.receipt.after, 'photo.frames_luxury');
      expect(again, isA<Purchased>());
      expect((again as Purchased).cost, 0);
    });

    test('recomprar lo poseído o un pack gratuito cuesta 0', () {
      final first =
          (buy(rich(40), 'photo.text_styles') as Purchased).receipt.after;
      final again = buy(first, 'photo.text_styles') as Purchased;
      expect(again.cost, 0);
      expect(again.receipt.after.coins, 0);
      final basic = buy(adopt(), 'photo.basic') as Purchased;
      expect(basic.cost, 0);
      expect(basic.receipt.after.owned, isNot(contains('photo.basic')));
      expect(
        rules.photoPackOwned(adopt(), balance.photoPack('photo.basic')!),
        isTrue,
      );
    });

    test('pack desconocido: error de regla', () {
      expect(
        () => buy(rich(100), 'photo.retirado'),
        throwsA(isA<RuleException>()),
      );
    });
  });

  group('partidas', () {
    test('una partida anterior carga sin packs comprados', () {
      final j = jsonDecode(codec.encode(rich(70))) as Map<String, dynamic>;
      expect(
        (j['owned'] as List).any((e) => '$e'.startsWith('photo.')),
        isFalse,
      );
      final back = codec.decode(jsonEncode(j));
      expect(back.coins, 70);
      for (final pack in balance.photoPacks) {
        expect(rules.photoPackOwned(back, pack), pack.free);
      }
      expect(buy(back, 'photo.party'), isA<Purchased>());
    });

    test('lo comprado sobrevive a guardar y cargar', () {
      final s = (buy(rich(60), 'photo.party') as Purchased).receipt.after;
      final back = codec.decode(codec.encode(s));
      expect(back.owned, contains('photo.party'));
      expect(back.coins, 0);
    });
  });

  group('texto de la foto', () {
    String? ok(String raw) => switch (PhotoCaption.validate(raw)) {
      ValidName(:final value) => value,
      InvalidName() => null,
    };
    NameError? error(String raw) => switch (PhotoCaption.validate(raw)) {
      InvalidName(:final error) => error,
      ValidName() => null,
    };

    test('recorta, compone NFC y cuenta grafemas', () {
      expect(ok('  ¡Feliz día, Miel!  '), '¡Feliz día, Miel!');
      expect(ok('Café'), 'Café');
      expect(ok('a' * 24), 'a' * 24);
      expect(ok('🐩' * 24), '🐩' * 24);
      expect(PhotoCaption.graphemeCount(' 🐩🐩 '), 2);
    });

    test('rechaza vacío, largo, controles, saltos y marcas de dirección', () {
      expect(error('   '), NameError.empty);
      expect(error('a' * 25), NameError.tooLong);
      expect(error('hola\nadiós'), NameError.invalidCharacters);
      expect(error('ho\u2028la'), NameError.invalidCharacters);
      expect(error('a\u0000b'), NameError.invalidCharacters);
      expect(error('a\u202Eb'), NameError.invalidCharacters);
      expect(error('a\u2066b'), NameError.invalidCharacters);
    });

    test('el texto nunca forma parte de la partida', () {
      final json = codec.encode(adopt());
      expect(json, isNot(contains('caption')));
    });
  });
}
