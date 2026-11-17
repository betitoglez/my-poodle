import 'dart:ui';

import '../../domain/appearance.dart';

enum PetPose { front, side, back }

enum HairStyle { natural, pom }

enum OutfitStyle { none, overalls }

enum NeckStyle { none, scarf }

class CoatPalette {
  const CoatPalette(this.base, this.shade, this.light, this.skin);
  final Color base;
  final Color shade;
  final Color light;
  final Color skin;
}

class Garment {
  const Garment(this.color, this.shade, this.trim);
  final Color color;
  final Color shade;
  final Color trim;
}

class PoseMeta {
  const PoseMeta(this.drawOrder, this.anchors);
  final List<String> drawOrder;
  final Map<String, Offset> anchors;
}

/// Aspecto resuelto para dibujar: máscaras de pelaje, corte, prenda y cuello.
/// Los colores fijos (ojos, nariz, lengua) no dependen del pelaje.
class PetLook {
  const PetLook({
    required this.coat,
    required this.hair,
    required this.outfit,
    required this.outfitStyle,
    required this.neck,
    required this.neckStyle,
    this.missing = const [],
    this.ids,
  });

  /// IDs de catálogo resueltos (para elegir capas del atlas de sprites).
  final Appearance? ids;

  final CoatPalette coat;
  final HairStyle hair;
  final OutfitStyle outfitStyle;
  final Garment? outfit;
  final NeckStyle neckStyle;
  final Garment? neck;

  /// IDs sin metadatos visuales: se dibuja el fallback y se informa.
  final List<String> missing;
}

/// Lee assets/data/appearance-v1.json y resuelve aspectos (ApplyAppearance).
class AppearanceCatalog {
  AppearanceCatalog._(
    this._coats,
    this._hair,
    this._outfits,
    this._necks,
    this.poses,
    this.fixed,
    this.labels,
    this._varieties,
    this._varietyOf,
    this._colorLabel,
    this._swatch,
  );

  final Map<String, String> _varieties;
  final Map<String, String> _varietyOf;
  final Map<String, String> _colorLabel;
  final Map<String, Color> _swatch;

  /// Variedad a la que pertenece un artículo (p. ej. «sweater»), si tiene.
  String? varietyOf(String id) => _varietyOf[id];
  String varietyLabel(String variety) => _varieties[variety] ?? variety;

  /// Nombre del color dentro de su variedad («Rojo»), si lo tiene.
  String? colorLabel(String id) => _colorLabel[id];
  Color? swatch(String id) => _swatch[id];

  final Map<String, CoatPalette> _coats;
  final Map<String, HairStyle> _hair;
  final Map<String, (OutfitStyle, Garment?)> _outfits;
  final Map<String, (NeckStyle, Garment?)> _necks;
  final Map<PetPose, PoseMeta> poses;
  final Map<String, Color> fixed;
  final Map<String, String> labels;

  static Color _c(Object? hex) {
    final s = (hex as String).replaceFirst('#', '');
    return Color(int.parse('FF$s', radix: 16));
  }

  factory AppearanceCatalog.fromJson(Map<String, dynamic> j) {
    final labels = <String, String>{};
    final coats = <String, CoatPalette>{};
    (j['coats'] as Map<String, dynamic>).forEach((k, v) {
      final m = v as Map<String, dynamic>;
      labels[k] = m['label'] as String;
      coats[k] = CoatPalette(
        _c(m['base']),
        _c(m['shade']),
        _c(m['light']),
        _c(m['skin']),
      );
    });
    final hair = <String, HairStyle>{};
    (j['hair'] as Map<String, dynamic>).forEach((k, v) {
      final m = v as Map<String, dynamic>;
      labels[k] = m['label'] as String;
      hair[k] = HairStyle.values.byName(m['style'] as String);
    });
    Garment? garment(Map<String, dynamic> m) => m['color'] == null
        ? null
        : Garment(
            _c(m['color']),
            _c(m['shade']),
            m['trim'] == null ? _c(m['color']) : _c(m['trim']),
          );
    final outfits = <String, (OutfitStyle, Garment?)>{};
    (j['outfits'] as Map<String, dynamic>).forEach((k, v) {
      final m = v as Map<String, dynamic>;
      labels[k] = m['label'] as String;
      outfits[k] = (
        OutfitStyle.values.byName(m['style'] as String),
        garment(m),
      );
    });
    final necks = <String, (NeckStyle, Garment?)>{};
    (j['necks'] as Map<String, dynamic>).forEach((k, v) {
      final m = v as Map<String, dynamic>;
      labels[k] = m['label'] as String;
      necks[k] = (NeckStyle.values.byName(m['style'] as String), garment(m));
    });
    final fixed = <String, Color>{};
    (j['fixed'] as Map<String, dynamic>).forEach((k, v) => fixed[k] = _c(v));
    final poses = <PetPose, PoseMeta>{};
    (j['poses'] as Map<String, dynamic>).forEach((k, v) {
      final m = v as Map<String, dynamic>;
      final anchors = <String, Offset>{};
      (m['anchors'] as Map<String, dynamic>).forEach((a, p) {
        final l = p as List<dynamic>;
        anchors[a] = Offset((l[0] as num).toDouble(), (l[1] as num).toDouble());
      });
      poses[PetPose.values.byName(k)] = PoseMeta(
        List<String>.from(m['drawOrder'] as List),
        anchors,
      );
    });
    // Accesorios sin dibujo vectorial: solo etiquetas.
    final varietyOf = <String, String>{};
    final colorLabel = <String, String>{};
    final swatch = <String, Color>{};
    for (final section in const [
      'coats',
      'hair',
      'outfits',
      'necks',
      'heads',
      'eyes',
      'collars',
      'paws',
    ]) {
      ((j[section] as Map<String, dynamic>?) ?? const {}).forEach((k, v) {
        final m = v as Map<String, dynamic>;
        labels[k] = m['label'] as String;
        if (m['variety'] != null) varietyOf[k] = m['variety'] as String;
        if (m['colorLabel'] != null) colorLabel[k] = m['colorLabel'] as String;
        if (m['swatch'] != null) swatch[k] = _c(m['swatch']);
      });
    }
    final varieties = {
      for (final e
          in ((j['varieties'] as Map<String, dynamic>?) ?? const {}).entries)
        e.key: e.value as String,
    };
    return AppearanceCatalog._(
      coats,
      hair,
      outfits,
      necks,
      poses,
      fixed,
      labels,
      varieties,
      varietyOf,
      colorLabel,
      swatch,
    );
  }

  /// IDs de catálogo que no tienen representación visual.
  List<String> missingFor(Iterable<String> ids) => ids
      .where(
        (id) =>
            !_coats.containsKey(id) &&
            !_hair.containsKey(id) &&
            !_outfits.containsKey(id) &&
            !_necks.containsKey(id) &&
            !labels.containsKey(id),
      )
      .toList();

  String label(String id) => labels[id] ?? id;

  PetLook resolve(Appearance a) {
    final missing = <String>[];
    T pick<T>(Map<String, T> m, String id, String fallback) {
      final v = m[id];
      if (v != null) return v;
      missing.add(id);
      return m[fallback] as T;
    }

    final coat = pick(_coats, a.coat, 'coat.apricot');
    final hair = pick(_hair, a.hair, 'hair.natural');
    final outfit = pick(_outfits, a.outfit, 'outfit.none');
    final neck = pick(_necks, a.neck, 'neck.none');
    return PetLook(
      coat: coat,
      hair: hair,
      outfitStyle: outfit.$1,
      outfit: outfit.$2,
      neckStyle: neck.$1,
      neck: neck.$2,
      missing: missing,
      ids: a,
    );
  }
}
