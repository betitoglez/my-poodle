import 'package:flutter_test/flutter_test.dart';
import 'package:my_poodle/data/save_codec.dart';
import 'package:my_poodle/domain/appearance.dart';
import 'package:my_poodle/domain/entitlements.dart';
import 'package:my_poodle/domain/pet_state.dart';
import 'package:my_poodle/domain/rules.dart';
import 'package:my_poodle/ui/widgets/live_poodle_view.dart';

import '../support.dart';

void main() {
  final balance = loadBalance(), rules = Rules(loadBalance());
  PetState pet() => PetState.adopt(
    validName: 'Rizo',
    nowUtc: t0,
    balance: balance,
  ).copyWith(coins: 5000);
  const elf = 'outfit.sweater_elf';

  test('elfo: versión completa, compra única y guardado compatible', () {
    final before = pet();
    final target = before.appearance.withSlot(Slot.outfit, elf);
    expect(balance.item(elf)!.tier, Tier.full);
    expect(LivePoodleView.supports(target), isTrue);
    expect(rules.lookCost(before, target), 320);
    expect(
      rules.applyLook(before, target, 'free', t0, fullVersion: false),
      isA<RequiresFull>(),
    );
    expect(before.coins, 5000);
    final purchase = rules.applyLook(
      before,
      target,
      'buy',
      t0,
      fullVersion: true,
    ) as Purchased;
    expect(purchase.cost, 320);
    final codec = SaveCodec(balance);
    final after = codec.decode(codec.encode(purchase.receipt.after));
    expect(after.appearance.outfit, elf);
    expect(after.owned, contains(elf));
    expect(after.coins, 4680);
    expect(rules.styleCost(after, elf), 0);
    final reequipped = rules.applyLook(
      after,
      target,
      'again',
      t0,
      fullVersion: true,
    ) as Purchased;
    expect(reequipped.cost, 0);
    expect(reequipped.receipt.after.coins, 4680);
  });

  test('elfo comparte solo el aumento de los jerséis especiales', () {
    PetState buy(PetState s, String id) => (rules.applyLook(
      s,
      s.appearance.withSlot(balance.item(id)!.slot, id),
      id,
      t0,
      fullVersion: true,
    ) as Purchased).receipt.after;
    var s = buy(pet(), 'outfit.sweater_blue');
    s = buy(s, 'outfit.dress_zebra');
    expect(rules.styleCost(s, elf), 320);
    s = buy(s, 'outfit.sweater_zebra');
    expect(rules.styleCost(s, elf), 390);
    s = buy(s, elf);
    expect(rules.styleCost(s, 'outfit.sweater_dots'), 470);
    expect(rules.styleCost(s, 'outfit.dress_dots'), 680);
    expect(rules.styleCost(s, 'outfit.overalls_dots'), 160);
    expect(rules.styleCost(s, 'outfit.sweater_blue'), 0);
  });
}
