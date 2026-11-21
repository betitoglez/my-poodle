import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/domain/appearance.dart';
import 'package:my_poodle/game/pet/integrated_accessories.dart';

import '../support.dart';

void main() {
  test('estampados fuera de la prenda teñida; colores lisos nuevos dentro', () {
    final outfits = loadBalance()
        .itemsFor(Slot.outfit)
        .map((i) => i.id)
        .where((id) => id != 'outfit.none');
    for (final id in outfits) {
      final pattern = id.split('_').last;
      if (const {'zebra', 'redwhite', 'greenwhite', 'dots'}.contains(pattern)) {
        // El tinte solo cambia el color: el patrón lo dibuja PetAccessories.
        expect(IntegratedAccessories.tailoredFamily(id), isNull, reason: id);
      }
    }
    for (final (id, family) in [
      ('outfit.overalls_denim', 'overalls'),
      ('outfit.overalls_pink', 'overalls'),
      ('outfit.raincoat_red', 'raincoat'),
      ('outfit.raincoat_green', 'raincoat'),
      ('outfit.dress_yellow', 'dress'),
      ('outfit.dress_coral', 'dress'),
    ]) {
      expect(IntegratedAccessories.tailoredFamily(id), family, reason: id);
    }
  });
}
