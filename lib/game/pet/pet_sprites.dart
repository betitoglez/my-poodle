import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart';

import 'coat_recolor.dart';

/// Lienzo común de una pose: todas sus capas comparten tamaño y ancla.
class SpritePose {
  const SpritePose(this.size, this.anchor, [this.landmarks = const {}]);
  final ui.Size size;

  /// Punto de apoyo (pies) en píxeles del lienzo.
  final ui.Offset anchor;

  /// Referencias del cuerpo en unidades (altura 1, origen en el ancla):
  /// ojos, boca, cuello, pecho, costados, patas, cabeza, orejas…
  final Map<String, ui.Offset> landmarks;
}

/// Una capa lista para dibujar: la imagen y su caja en el lienzo de la pose
/// (null = ocupa todo el lienzo).
class SpriteLayer {
  const SpriteLayer(this.image, this.box);
  final ui.Image image;
  final ui.Rect? box;
}

class _Entry {
  const _Entry(this.file, this.box);
  final String file;
  final ui.Rect? box;

  static _Entry? parse(Object? v) {
    if (v == null) return null;
    if (v is String) return _Entry(v, null);
    final m = v as Map<String, dynamic>;
    final b = (m['box'] as List?)?.cast<num>();
    return _Entry(
      m['file'] as String,
      b == null
          ? null
          : ui.Rect.fromLTWH(
              b[0].toDouble(),
              b[1].toDouble(),
              b[2].toDouble(),
              b[3].toDouble(),
            ),
    );
  }
}

/// Variante de color de un artículo: reutiliza la capa de otro y la tiñe.
class ItemVariant {
  const ItemVariant(this.of, this.hue, this.sat, this.light);
  final String of;
  final double hue;
  final double sat;
  final double light;
}

/// Atlas del caniche por capas (assets/data/pet-sprites-v1.json):
/// una base por peinado y pose, capas por artículo y pose, expresiones,
/// variantes de color y matrices por pelaje. Las imágenes se cargan bajo
/// demanda y se conservan; solo se lee el JSON al arrancar.
class PetSprites {
  PetSprites._(
    this._bundle,
    this._dir,
    this.unitHeightPx,
    this.poses,
    this._hair,
    this._items,
    this._expressions,
    this._states,
    this._coats,
    this._variants,
  );

  final AssetBundle _bundle;
  final String _dir;
  final double unitHeightPx;
  final Map<String, SpritePose> poses;
  final Map<String, Map<String, _Entry>> _hair;

  /// artículo → pose → capa (null = «no se ve en esa pose»).
  final Map<String, Map<String, _Entry?>> _items;
  final Map<String, Map<String, _Entry>> _expressions;

  /// Estados alternativos de la base por peinado (p. ej. «messy»).
  final Map<String, Map<String, Map<String, _Entry>>> _states;
  final Map<String, List<double>?> _coats;
  final Map<String, ItemVariant> _variants;

  final Map<String, ui.Image> _cache = {};
  final Map<String, Future<void>> _loading = {};

  /// Se llama (agrupado) cada vez que llega una imagen nueva.
  void Function()? onImageLoaded;

  // Colores preparados bajo demanda, con caché acotada (48 capas).
  final Map<String, ui.Image> _colored = {};
  final Map<String, Future<void>> _colorLoading = {};
  String _colorKey(SpriteLayer layer, String coat) =>
      '${layer.image.hashCode}/$coat';
  SpriteLayer? coatedLayer(SpriteLayer? layer, String coat, List<int> palette) {
    if (layer == null || coat == 'coat.apricot') return layer;
    final key = _colorKey(layer, coat);
    final ready = _colored.remove(key);
    if (ready != null) {
      _colored[key] = ready;
      return SpriteLayer(ready, layer.box);
    }
    prepareCoat(layer, coat, palette);
    return null;
  }

  Future<void> prepareCoat(SpriteLayer layer, String coat, List<int> palette) {
    if (coat == 'coat.apricot') return Future.value();
    final key = _colorKey(layer, coat);
    if (_colored.containsKey(key)) return Future.value();
    return _colorLoading[key] ??= () async {
      try {
        final bytes = await layer.image.toByteData(
          format: ui.ImageByteFormat.rawStraightRgba,
        );
        if (bytes == null) return;
        final pixels = await compute(recolorFur, <String, Object>{
          'pixels': bytes.buffer.asUint8List(),
          'palette': palette,
        });
        final done = Completer<ui.Image>();
        ui.decodeImageFromPixels(
          pixels,
          layer.image.width,
          layer.image.height,
          ui.PixelFormat.rgba8888,
          done.complete,
        );
        _colored[key] = await done.future;
        while (_colored.length > 48) {
          final old = _colored.remove(_colored.keys.first);
          old?.dispose();
        }
      } finally {
        _colorLoading.remove(key);
        onImageLoaded?.call();
      }
    }();
  }

  // ------------------------------------------------------------ consultas

  bool hasPose(String pose) => poses.containsKey(pose);
  bool hasCoat(String id) => _coats.containsKey(id);
  List<double>? coatMatrix(String id) => _coats[id];
  bool hasHair(String id, String pose) => _hair[id]?.containsKey(pose) ?? false;

  Iterable<String> get hairIds => _hair.keys;
  Iterable<String> get itemIds => [..._items.keys, ..._variants.keys];

  String _layerId(String id) => _variants[id]?.of ?? id;

  /// ¿Se conoce el artículo en el atlas (directo o como variante)?
  bool knowsItem(String id) => _items.containsKey(_layerId(id));

  /// ¿Declara el artículo algo para esta pose (una capa o «no se ve»)?
  bool supportsItem(String id, String pose) =>
      _items[_layerId(id)]?.containsKey(pose) ?? false;

  /// ¿Tiene capa visible en esta pose?
  bool itemVisible(String id, String pose) =>
      _items[_layerId(id)]?[pose] != null;

  ItemVariant? variant(String id) => _variants[id];

  /// Matriz de color de un artículo (null si no es una variante).
  List<double>? itemMatrix(String id) {
    final v = _variants[id];
    return v == null ? null : hueMatrix(v.hue, sat: v.sat, light: v.light);
  }

  // ------------------------------------------------------------ capas

  SpriteLayer? hairLayer(String id, String pose) => _layer(
    _hair[id]?[pose] ?? (pose == 'eat' ? _hair['hair.natural']!['eat'] : null),
  );

  SpriteLayer? itemLayer(String id, String pose) =>
      _layer(_items[_layerId(id)]?[pose]);

  SpriteLayer? expressionLayer(String id, String pose) =>
      _layer(_expressions[id]?[pose]);

  SpriteLayer? stateLayer(String state, String hair, String pose) =>
      _layer(_states[state]?[hair]?[pose]);

  SpriteLayer? _layer(_Entry? e) {
    if (e == null) return null;
    final img = _cache[e.file];
    if (img == null) {
      _request(e.file);
      return null;
    }
    return SpriteLayer(img, e.box);
  }

  bool _notifyScheduled = false;

  Future<void> _request(String file) {
    if (_cache.containsKey(file)) return Future.value();
    return _loading[file] ??= () async {
      try {
        final data = await _bundle.load('$_dir$file');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        _cache[file] = (await codec.getNextFrame()).image;
      } catch (_) {
        // Una capa que falta simplemente no se dibuja.
      } finally {
        _loading.remove(file);
      }
      if (!_notifyScheduled) {
        _notifyScheduled = true;
        Future.microtask(() {
          _notifyScheduled = false;
          onImageLoaded?.call();
        });
      }
    }();
  }

  /// Carga a la vez todo lo necesario para dibujar un aspecto en estas
  /// poses (evita parpadeos al cambiar de peinado, prenda o pose).
  Future<void> preload({
    required String hair,
    Iterable<String> items = const [],
    required Iterable<String> poseNames,
    Iterable<String> extras = const ['blink', 'happy'],
  }) async {
    final files = <String>{};
    for (final p in poseNames) {
      final h =
          _hair[hair]?[p] ??
          (p == 'eat' ? _hair['hair.natural']!['eat'] : null);
      if (p == 'eat' && !hasHair(hair, p)) {
        final head = _hair[hair]?['front'];
        if (head != null) files.add(head.file);
      }
      if (h != null) files.add(h.file);
      for (final i in items) {
        final e = _items[_layerId(i)]?[p];
        if (e != null) files.add(e.file);
      }
      for (final x in extras) {
        final e = _expressions[x]?[p];
        if (e != null) files.add(e.file);
      }
      final m = _states['messy']?[hair]?[p];
      if (m != null) files.add(m.file);
    }
    await Future.wait([for (final f in files) _request(f)]);
  }

  // ------------------------------------------------------------ carga

  static Future<PetSprites> load(
    AssetBundle bundle, {
    String meta = 'assets/data/pet-sprites-v1.json',
    String dir = 'assets/images/pet/',
  }) async {
    final j = jsonDecode(await bundle.loadString(meta)) as Map<String, dynamic>;
    if (j['schemaVersion'] != 1) {
      throw const FormatException('pet-sprites: esquema no soportado');
    }
    Map<String, Map<String, _Entry?>> group(String key) {
      final out = <String, Map<String, _Entry?>>{};
      ((j[key] as Map<String, dynamic>?) ?? const {}).forEach((id, v) {
        out[id] = {
          for (final p in (v as Map<String, dynamic>).entries)
            p.key: _Entry.parse(p.value),
        };
      });
      return out;
    }

    Map<String, Map<String, _Entry>> nonNull(String key) => {
      for (final e in group(key).entries)
        e.key: {
          for (final p in e.value.entries)
            if (p.value != null) p.key: p.value!,
        },
    };

    final poses = <String, SpritePose>{};
    (j['poses'] as Map<String, dynamic>).forEach((k, v) {
      final m = v as Map<String, dynamic>;
      final s = (m['size'] as List).cast<num>();
      final a = (m['anchor'] as List).cast<num>();
      final lm = <String, ui.Offset>{};
      ((m['landmarks'] as Map<String, dynamic>?) ?? const {}).forEach((n, p) {
        final l = (p as List).cast<num>();
        lm[n] = ui.Offset(l[0].toDouble(), l[1].toDouble());
      });
      poses[k] = SpritePose(
        ui.Size(s[0].toDouble(), s[1].toDouble()),
        ui.Offset(a[0].toDouble(), a[1].toDouble()),
        lm,
      );
    });
    final coats = <String, List<double>?>{};
    (j['coats'] as Map<String, dynamic>).forEach((k, v) {
      coats[k] = v == null
          ? null
          : [for (final n in v as List) (n as num).toDouble()];
    });
    final variants = <String, ItemVariant>{};
    ((j['variants'] as Map<String, dynamic>?) ?? const {}).forEach((k, v) {
      final m = v as Map<String, dynamic>;
      variants[k] = ItemVariant(
        m['of'] as String,
        ((m['hue'] as num?) ?? 0).toDouble(),
        ((m['sat'] as num?) ?? 1).toDouble(),
        ((m['light'] as num?) ?? 1).toDouble(),
      );
    });
    final states = <String, Map<String, Map<String, _Entry>>>{};
    ((j['states'] as Map<String, dynamic>?) ?? const {}).forEach((st, v) {
      states[st] = {
        for (final h in (v as Map<String, dynamic>).entries)
          h.key: {
            for (final p in (h.value as Map<String, dynamic>).entries)
              p.key: _Entry.parse(p.value)!,
          },
      };
    });
    return PetSprites._(
      bundle,
      dir,
      (j['unitHeightPx'] as num).toDouble(),
      poses,
      nonNull('hair'),
      group('items'),
      nonNull('expressions'),
      states,
      coats,
      variants,
    );
  }

  // ------------------------------------------------------------ color

  /// Matriz 4×5 (estilo ColorFilter.matrix) que gira el tono [deg] grados,
  /// con saturación y luminosidad opcionales. Conserva el blanco y el gris.
  static List<double> hueMatrix(
    double deg, {
    double sat = 1,
    double light = 1,
  }) {
    final h = deg * math.pi / 180, c = math.cos(h), s = math.sin(h);
    final hue = <double>[
      0.213 + c * 0.787 - s * 0.213,
      0.715 - c * 0.715 - s * 0.715,
      0.072 - c * 0.072 + s * 0.928,
      0.213 - c * 0.213 + s * 0.143,
      0.715 + c * 0.285 + s * 0.140,
      0.072 - c * 0.072 - s * 0.283,
      0.213 - c * 0.213 - s * 0.787,
      0.715 - c * 0.715 + s * 0.715,
      0.072 + c * 0.928 + s * 0.072,
    ];
    final sm = <double>[
      0.213 * (1 - sat) + sat,
      0.715 * (1 - sat),
      0.072 * (1 - sat),
      0.213 * (1 - sat),
      0.715 * (1 - sat) + sat,
      0.072 * (1 - sat),
      0.213 * (1 - sat),
      0.715 * (1 - sat),
      0.072 * (1 - sat) + sat,
    ];
    final out = List<double>.filled(20, 0);
    for (var r = 0; r < 3; r++) {
      for (var c2 = 0; c2 < 3; c2++) {
        var v = 0.0;
        for (var k = 0; k < 3; k++) {
          v += sm[r * 3 + k] * hue[k * 3 + c2];
        }
        out[r * 5 + c2] = v * light;
      }
    }
    out[18] = 1;
    return out;
  }

  /// Compone dos matrices 4×5: primero [a], luego [b].
  static List<double> chain(List<double>? a, List<double>? b) {
    if (a == null) return b ?? identity;
    if (b == null) return a;
    final out = List<double>.filled(20, 0);
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        var v = 0.0;
        for (var k = 0; k < 4; k++) {
          v += b[r * 5 + k] * a[k * 5 + c];
        }
        out[r * 5 + c] = v;
      }
      var off = b[r * 5 + 4];
      for (var k = 0; k < 4; k++) {
        off += b[r * 5 + k] * a[k * 5 + 4];
      }
      out[r * 5 + 4] = off;
    }
    return out;
  }

  static const List<double> identity = [
    1, 0, 0, 0, 0, //
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];
}
