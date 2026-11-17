import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Lienzo común de una pose: todas sus capas comparten tamaño y ancla.
class SpritePose {
  const SpritePose(this.size, this.anchor);
  final ui.Size size;

  /// Punto de apoyo (pies) en píxeles del lienzo.
  final ui.Offset anchor;
}

/// Atlas del caniche por capas (assets/data/pet-sprites-v1.json):
/// una base por peinado y pose, capas por artículo y pose, expresiones y
/// matrices de color por pelaje. Añadir un color es añadir una matriz; un
/// peinado o artículo, sus imágenes por pose.
class PetSprites {
  PetSprites._(
    this.unitHeightPx,
    this.poses,
    this._hair,
    this._items,
    this._expressions,
    this._coats,
  );

  final double unitHeightPx;
  final Map<String, SpritePose> poses;
  final Map<String, Map<String, ui.Image>> _hair;
  final Map<String, Map<String, ui.Image>> _items;
  final Map<String, Map<String, ui.Image>> _expressions;
  final Map<String, List<double>?> _coats;

  ui.Image? hair(String id, String pose) => _hair[id]?[pose];
  ui.Image? item(String id, String pose) => _items[id]?[pose];
  ui.Image? expression(String id, String pose) => _expressions[id]?[pose];
  bool hasCoat(String id) => _coats.containsKey(id);
  List<double>? coatMatrix(String id) => _coats[id];

  Iterable<String> get hairIds => _hair.keys;
  Iterable<String> get itemIds => _items.keys;

  static Future<PetSprites> load(
    AssetBundle bundle, {
    String meta = 'assets/data/pet-sprites-v1.json',
    String dir = 'assets/images/pet/',
  }) async {
    final j = jsonDecode(await bundle.loadString(meta)) as Map<String, dynamic>;
    if (j['schemaVersion'] != 1) {
      throw const FormatException('pet-sprites: esquema no soportado');
    }
    final cache = <String, ui.Image>{};
    Future<ui.Image> image(String file) async {
      final cached = cache[file];
      if (cached != null) return cached;
      final data = await bundle.load('$dir$file');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      return cache[file] = frame.image;
    }

    Future<Map<String, Map<String, ui.Image>>> group(String key) async {
      final out = <String, Map<String, ui.Image>>{};
      final m = (j[key] as Map<String, dynamic>?) ?? const {};
      for (final e in m.entries) {
        final byPose = <String, ui.Image>{};
        for (final p in (e.value as Map<String, dynamic>).entries) {
          byPose[p.key] = await image(p.value as String);
        }
        out[e.key] = byPose;
      }
      return out;
    }

    final poses = <String, SpritePose>{};
    (j['poses'] as Map<String, dynamic>).forEach((k, v) {
      final m = v as Map<String, dynamic>;
      final s = (m['size'] as List).cast<num>();
      final a = (m['anchor'] as List).cast<num>();
      poses[k] = SpritePose(
        ui.Size(s[0].toDouble(), s[1].toDouble()),
        ui.Offset(a[0].toDouble(), a[1].toDouble()),
      );
    });
    final coats = <String, List<double>?>{};
    (j['coats'] as Map<String, dynamic>).forEach((k, v) {
      coats[k] = v == null
          ? null
          : [for (final n in v as List) (n as num).toDouble()];
    });
    return PetSprites._(
      (j['unitHeightPx'] as num).toDouble(),
      poses,
      await group('hair'),
      await group('items'),
      await group('expressions'),
      coats,
    );
  }
}
