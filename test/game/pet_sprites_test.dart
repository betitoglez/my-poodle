import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/domain/appearance.dart';
import 'package:my_poodle/domain/balance.dart';
import 'package:my_poodle/game/pet/appearance_catalog.dart';
import 'package:my_poodle/game/pet/pet_painter.dart';
import 'package:my_poodle/game/pet/pet_sprites.dart';

import '../support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Balance balance;
  late AppearanceCatalog looks;

  setUpAll(() {
    balance = loadBalance();
    looks = AppearanceCatalog.fromJson(
      jsonDecode(File('assets/data/appearance-v1.json').readAsStringSync())
          as Map<String, dynamic>,
    );
  });

  Future<PetPainter> painterWith(WidgetTester t) async {
    final sprites = await t.runAsync(() => PetSprites.load(rootBundle));
    return PetPainter(looks)..sprites = sprites;
  }

  void paintAll(PetPainter painter, Appearance a) {
    for (final pose in PetPose.values) {
      for (final anim in PetAnim.values) {
        final rec = ui.PictureRecorder();
        painter.paint(
          ui.Canvas(rec),
          looks.resolve(a),
          pose: pose,
          anim: anim,
          t: 1.3,
          size: 200,
          fx: const PetFx(
            wet: true,
            foam: [1, 1, 1],
            messy: [1, 0.5, 1],
            sick: true,
          ),
        );
        rec.endRecording().dispose();
      }
    }
  }

  testWidgets('el catálogo completo tiene sprite en frente, perfil y espalda', (
    t,
  ) async {
    final painter = await painterWith(t);
    final sp = painter.sprites!;
    final base = balance.initialAppearance;
    for (final item in balance.styles) {
      if (item.slot == Slot.coat) {
        expect(sp.hasCoat(item.id), isTrue, reason: item.id);
        continue;
      }
      if (item.slot == Slot.hair) {
        for (final pose in ['front', 'side', 'back']) {
          expect(sp.hasHair(item.id, pose), isTrue, reason: '${item.id} $pose');
        }
        continue;
      }
      if (item.initial) continue;
      expect(sp.knowsItem(item.id), isTrue, reason: item.id);
      for (final pose in ['front', 'side', 'back']) {
        expect(
          sp.supportsItem(item.id, pose),
          isTrue,
          reason: '${item.id} $pose',
        );
      }
      // Pintar un aspecto con el artículo no lanza en ninguna pose ni reacción.
      final a = base.withSlot(item.slot, item.id);
      await t.runAsync(() => painter.warm(a));
      paintAll(painter, a);
    }
  });

  testWidgets('pose pedida, pose dibujada y artículos visibles', (t) async {
    final painter = await painterWith(t);
    final base = balance.initialAppearance;
    // Peto y pañuelo originales tienen todas las poses.
    final old = base
        .withSlot(Slot.outfit, 'outfit.teal')
        .withSlot(Slot.neck, 'neck.coral');
    for (final pose in [
      'front',
      'side',
      'jump',
      'eat',
      'sleep',
      'run_a',
      'run_b',
      'back',
    ]) {
      expect(painter.resolve(pose, old)?.pose, pose, reason: pose);
    }
    // Un artículo sin pose de salto obliga a usar el perfil…
    final glasses = base.withSlot(Slot.eyes, 'eyes.sun');
    expect(painter.resolve('jump', glasses)?.pose, 'jump');
    expect(painter.resolve('run_a', glasses)?.pose, 'run_a');
    // …pero al comer o dormir simplemente no se dibuja.
    final eat = painter.resolve('eat', glasses)!;
    expect([eat.pose, eat.items], ['eat', isEmpty]);
    expect(painter.resolve('sleep', glasses)!.pose, 'sleep');
    // Los peinados nuevos no tienen salto: perfil; sí tienen dormir.
    final teddy = base.withSlot(Slot.hair, 'hair.teddy');
    expect(painter.resolve('jump', teddy)?.pose, 'side');
    expect(painter.resolve('sleep', teddy)?.pose, 'sleep');
    expect(painter.resolve('eat', teddy)?.pose, 'eat');
    // Las gafas no se ven desde atrás; el sombrero sí.
    final back = painter.resolve(
      'back',
      base.withSlot(Slot.eyes, 'eyes.sun').withSlot(Slot.head, 'head.bow'),
    )!;
    expect(back.pose, 'back');
    expect(back.items, ['head.bow']);
  });

  testWidgets('cuatro ángulos y selección de fotograma', (t) async {
    final painter = await painterWith(t);
    expect(PetView.front.next, PetView.right);
    expect(PetView.right.next.next, PetView.left);
    expect(PetView.left.next, PetView.front);
    expect(PetView.front.previous, PetView.left);
    expect(
      [for (final v in PetView.values) v.pose],
      [PetPose.front, PetPose.side, PetPose.back, PetPose.side],
    );
    expect(PetView.left.facingLeft, isTrue);
    expect(PetView.right.facingLeft, isFalse);
    expect(painter.spritePoseName(PetPose.back, PetAnim.idle, 0), 'back');
    expect(painter.spritePoseName(PetPose.front, PetAnim.eat, 0), 'eat');
    expect(painter.spritePoseName(PetPose.front, PetAnim.sleep, 0), 'sleep');
    expect(
      {
        for (var i = 0; i < 9; i++)
          painter.spritePoseName(PetPose.side, PetAnim.run, i / 9),
      },
      {'run_a', 'run_b', 'jump'},
    );
    expect(
      painter.spritePoseName(
        PetPose.side,
        PetAnim.run,
        0.2,
        reducedMotion: true,
      ),
      'side',
    );
  });

  testWidgets('variantes de color: matriz de tono y composición', (t) async {
    final painter = await painterWith(t);
    final sp = painter.sprites!;
    final red = sp.variant('outfit.overalls_red')!;
    expect(red.of, 'outfit.teal');
    expect(sp.itemMatrix('outfit.teal'), isNull);
    expect(sp.itemMatrix('outfit.overalls_red'), hasLength(20));
    // Giro de 0° y 360° es la identidad.
    final id0 = PetSprites.hueMatrix(0);
    for (var i = 0; i < 20; i++) {
      expect(id0[i], closeTo(PetSprites.identity[i], 1e-9), reason: '$i');
    }
    expect(PetSprites.hueMatrix(360)[0], closeTo(1, 1e-9));
    // El gris se conserva al girar el tono.
    final m = PetSprites.hueMatrix(137);
    expect(m[0] + m[1] + m[2], closeTo(1, 1e-6));
    expect(PetSprites.chain(null, null), PetSprites.identity);
    final twice = PetSprites.chain(
      PetSprites.hueMatrix(90),
      PetSprites.hueMatrix(90),
    );
    final once = PetSprites.hueMatrix(180);
    for (var i = 0; i < 20; i++) {
      expect(
        twice[i],
        closeTo(once[i], 2e-3),
      ); // constantes del estándar redondeadas
    }
    // Todos los colores comparten capa con su variedad.
    for (final id in [
      'outfit.sweater_blue',
      'outfit.raincoat_pink',
      'outfit.dress_lilac',
    ]) {
      expect(sp.knowsItem(id), isTrue);
      expect(sp.supportsItem(id, 'front'), isTrue);
    }
  });

  testWidgets('las referencias del cuerpo existen en cada pose', (t) async {
    final sp = (await painterWith(t)).sprites!;
    for (final name in [
      'eyes',
      'mouth',
      'chest',
      'flankLeft',
      'flankRight',
      'paws',
      'headTop',
      'earLeft',
      'earRight',
    ]) {
      expect(sp.poses['front']!.landmarks[name], isNotNull, reason: name);
    }
    expect(sp.poses['jump']!.landmarks['mouth']!.dx, greaterThan(0.2));
    for (final p in ['back', 'sleep', 'eat']) {
      expect(sp.poses[p]!.landmarks['paws'], isNotNull, reason: p);
    }
  });

  testWidgets('despeinado y todas las combinaciones de pelaje y peinado', (
    t,
  ) async {
    final painter = await painterWith(t);
    final base = balance.initialAppearance;
    var painted = 0;
    for (final coat in balance.itemsFor(Slot.coat)) {
      for (final hair in balance.itemsFor(Slot.hair)) {
        final a = base
            .withSlot(Slot.coat, coat.id)
            .withSlot(Slot.hair, hair.id);
        await t.runAsync(() => painter.warm(a));
        paintAll(painter, a);
        painted++;
      }
    }
    expect(painted, 5 * 5);
    expect(
      painter.sprites!.stateLayer('messy', 'hair.pom', 'front'),
      isNotNull,
    );
  });
}
