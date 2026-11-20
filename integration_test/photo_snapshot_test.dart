import 'dart:convert';

import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_poodle/app/app_root.dart';
import 'package:my_poodle/data/photo_album.dart';
import 'package:my_poodle/data/save_codec.dart';
import 'package:my_poodle/data/save_store.dart';
import 'package:my_poodle/data/storage_backend.dart';
import 'package:my_poodle/domain/appearance.dart';
import 'package:my_poodle/domain/balance.dart';
import 'package:my_poodle/domain/pet_state.dart';
import 'package:my_poodle/store/store_provider.dart';
import 'package:my_poodle/ui/screens/home_screen.dart';
import 'package:my_poodle/ui/screens/photo_screen.dart';
import 'package:my_poodle/ui/widgets/live_poodle_view.dart';

/// Partida y álbum solo en memoria: no compra ni toca la partida personal.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native 3D PNG capture and private photo composition', (t) async {
    expect(
      LivePoodleView.enabled,
      isTrue,
      reason: 'Run with POODLE_LIVE_3D=true on iOS/Android',
    );
    final balance = Balance.fromJson(
      jsonDecode(await rootBundle.loadString('assets/data/balance-v1.json'))
          as Map<String, dynamic>,
    );
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final initial = PetState.adopt(
      validName: 'Photo QA',
      nowUtc: now,
      balance: balance,
    );
    final pet = initial.copyWith(
      owned: {...initial.owned, 'outfit.teal'},
      appearance: initial.appearance.withSlot(Slot.outfit, 'outfit.teal'),
      prefs: initial.prefs.copyWith(
        language: 'en',
        music: false,
        effects: false,
        reducedMotion: true,
      ),
    );
    final backend = MemoryBackend()
      ..files[SaveStore.primary] = SaveCodec(balance).encode(pet);
    Future<void> wait(bool Function() ready, String reason) async {
      final end = DateTime.now().add(const Duration(seconds: 40));
      while (!ready() && DateTime.now().isBefore(end)) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(ready(), isTrue, reason: reason);
    }

    await t.pumpWidget(
      MyPoodleApp(
        backend: backend,
        storeProvider: NoStore(),
        loadSprites: false,
      ),
    );
    await wait(() => find.byType(HomeScreen).evaluate().isNotEmpty, 'home');
    await t.tap(find.byIcon(Icons.camera_alt_rounded));
    await t.pump();
    await wait(
      () => find.byType(PhotoScreen).evaluate().isNotEmpty,
      'photo screen',
    );
    final live = t.widget<LivePoodleView>(
      find.descendant(
        of: find.byType(PhotoScreen),
        matching: find.byType(LivePoodleView),
      ),
    );
    await wait(
      () => live.controller.ready || live.controller.failed,
      'native first frame',
    );
    expect(live.controller.failed, isFalse);
    final native = await live.controller.snapshot();
    expect(native, isNotNull);
    final codec = await ui.instantiateImageCodec(native!);
    final frame = await codec.getNextFrame();
    codec.dispose();
    final rgba = await frame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    var visible = 0;
    for (var i = 3; i < rgba!.lengthInBytes; i += 4) {
      if (rgba.getUint8(i) > 0) visible++;
    }
    expect(
      visible,
      greaterThan(1000),
      reason: 'PNG contains rendered dog pixels',
    );
    final width = frame.image.width, height = frame.image.height;
    frame.image.dispose();
    await t.tap(find.byIcon(Icons.rotate_right_rounded));
    await t.pump(const Duration(milliseconds: 500));
    final rotated = await live.controller.snapshot();
    final rotatedCodec = await ui.instantiateImageCodec(rotated!);
    final rotatedFrame = await rotatedCodec.getNextFrame();
    rotatedCodec.dispose();
    final rotatedRgba = await rotatedFrame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    rotatedFrame.image.dispose();
    expect(rotatedRgba!.lengthInBytes, rgba.lengthInBytes);
    var difference = 0;
    for (var i = 0; i < rgba.lengthInBytes; i++) {
      difference += (rgba.getUint8(i) - rotatedRgba.getUint8(i)).abs();
    }
    expect(
      difference / rgba.lengthInBytes,
      greaterThan(1),
      reason: 'A tap visibly changes the viewing angle',
    );
    await t.tap(find.text('Take photo'));
    await t.pump();
    var photos = <AlbumPhoto>[];
    final end = DateTime.now().add(const Duration(seconds: 20));
    while (photos.isEmpty && DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 100));
      photos = await PhotoAlbum(backend).load();
    }
    expect(photos.length, 1);
    final png = await PhotoAlbum(backend).read(photos.single);
    final compositeCodec = await ui.instantiateImageCodec(png);
    final composite = await compositeCodec.getNextFrame();
    compositeCodec.dispose();
    expect(composite.image.width, greaterThan(100));
    expect(composite.image.height, greaterThan(100));
    composite.image.dispose();
    await t.tap(find.text('Lie down'));
    await t.pump(const Duration(seconds: 2));
    await t.tap(find.text('Take photo'));
    await t.pump();
    final restEnd = DateTime.now().add(const Duration(seconds: 20));
    while (photos.length < 2 && DateTime.now().isBefore(restEnd)) {
      await t.pump(const Duration(milliseconds: 100));
      photos = await PhotoAlbum(backend).load();
    }
    expect(photos.length, 2);
    final restingPng = await PhotoAlbum(backend).read(photos.first);
    final after = SaveCodec(balance).decode(backend.files[SaveStore.primary]!);
    expect(after.coins, pet.coins);
    expect(after.appearance, pet.appearance);
    binding.reportData = {
      'nativePng': base64Encode(native),
      'photoPng': base64Encode(png),
      'restingPhotoPng': base64Encode(restingPng),
      'nativeWidth': width,
      'nativeHeight': height,
      'visibleDogPixels': visible,
      'photoBytes': png.length,
      'albumCount': photos.length,
      'rotationMeanDifference': difference / rgba.lengthInBytes,
    };
    debugPrint(
      'QA_PHOTO visible=$visible rotation=${difference / rgba.lengthInBytes} photoBytes=${png.length}',
    );
    expect(t.takeException(), isNull);
  });
}
