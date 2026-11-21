import 'haircuts.dart';

/// Ranuras independientes del aspecto del caniche. Una por categoría del
/// armario; cada una admite «sin artículo» salvo color y peinado.
enum Slot { coat, hair, outfit, head, eyes, collar, neck, paws }

/// Aspecto: un ID de catálogo por ranura. Inmutable.
class Appearance {
  Appearance(Map<Slot, String> ids, {Map<HairZone, String>? cuts})
    : _ids = Map.unmodifiable(ids),
      cuts = Map.unmodifiable({
        for (final z in HairZone.values)
          z: cuts?[z] ?? Haircuts.styleOf(ids[Slot.hair] ?? 'hair.natural'),
      }) {
    for (final s in Slot.values) {
      if (!_ids.containsKey(s)) {
        throw ArgumentError('Falta la ranura ${s.name}');
      }
    }
  }

  final Map<Slot, String> _ids;
  final Map<HairZone, String> cuts;
  String cutId(HairZone zone) => Haircuts.id(zone, cuts[zone] ?? 'natural');
  bool get uniformHair =>
      HairZone.values.every((z) => cuts[z] == Haircuts.styleOf(hair));
  Appearance withCut(HairZone zone, String style) => Appearance(
    {..._ids, if (zone == HairZone.head) Slot.hair: 'hair.$style'},
    cuts: {...cuts, zone: style},
  );

  String of(Slot slot) => _ids[slot]!;

  String get coat => of(Slot.coat);
  String get hair => of(Slot.hair);
  String get outfit => of(Slot.outfit);
  String get head => of(Slot.head);
  String get eyes => of(Slot.eyes);
  String get collar => of(Slot.collar);
  String get neck => of(Slot.neck);
  String get paws => of(Slot.paws);

  /// Cambiar una ranura conserva las demás.
  Appearance withSlot(Slot slot, String id) =>
      Appearance({..._ids, slot: id}, cuts: slot == Slot.hair ? null : cuts);

  /// IDs en el orden de [Slot.values].
  List<String> get ids => [
    for (final s in Slot.values)
      if (s != Slot.hair || uniformHair) _ids[s]!,
    for (final z in HairZone.values) cutId(z),
  ];

  Map<String, String> toJson() => {
    for (final s in Slot.values) s.name: _ids[s]!,
    for (final z in HairZone.values) 'cut_${z.name}': cuts[z] ?? 'natural',
  };

  @override
  bool operator ==(Object other) {
    if (other is! Appearance) return false;
    for (final s in Slot.values) {
      if (other._ids[s] != _ids[s]) return false;
    }
    return HairZone.values.every((z) => cuts[z] == other.cuts[z]);
  }

  @override
  int get hashCode => Object.hashAll(ids);

  @override
  String toString() => 'Appearance(${ids.join(', ')})';
}
