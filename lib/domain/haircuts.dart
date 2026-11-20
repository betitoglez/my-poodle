import 'entitlements.dart';

enum HairZone { head, legs, back, tail }

extension HairZoneName on HairZone {
  String get label => switch (this) {
    HairZone.head => 'Cabeza',
    HairZone.legs => 'Patas',
    HairZone.back => 'Lomo',
    HairZone.tail => 'Cola',
  };
}

abstract final class Haircuts {
  static const styles = ['natural', 'teddy', 'pom', 'puppy', 'show', 'modern'];
  static const labels = {
    'natural': 'Rizo natural',
    'teddy': 'Corte osito',
    'pom': 'Corte pompón',
    'puppy': 'Corte cachorro',
    'show': 'Corte de concurso',
    'modern': 'Corte moderno',
  };
  static String id(HairZone zone, String style) => 'cut.${zone.name}.$style';
  static String styleOf(String legacy) =>
      styles.contains(legacy.split('.').last)
      ? legacy.split('.').last
      : 'natural';
  static bool valid(String id) {
    final bits = id.split('.');
    return bits.length == 3 &&
        bits.first == 'cut' &&
        HairZone.values.any((z) => z.name == bits[1]) &&
        styles.contains(bits[2]);
  }

  static int cost(String style) => style == 'natural'
      ? 0
      : style == 'show'
      ? 100
      : 50;
  static Tier tier(String style) =>
      const {'teddy', 'puppy', 'modern'}.contains(style)
      ? Tier.full
      : Tier.free;
  static String label(String id) =>
      '${labels[id.split('.').last]} · ${HairZone.values.byName(id.split('.')[1]).label}';
}
