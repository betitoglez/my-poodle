import 'balance.dart';
import 'entitlements.dart';

/// Una ración por cuidado, con cobro y efectos en la misma escritura.
enum Food {
  basic('Pienso diario', 0, Tier.free, {Need.satiety: 20}),
  premium('Comida premium', 10, Tier.free, {Need.satiety: 40}),
  salmon('Comida de salmón', 30, Tier.full, {
    Need.satiety: 60,
    Need.energy: 5,
    Need.mood: 20,
  }),
  vegan('Comida vegana', 15, Tier.full, {
    Need.satiety: 10,
    Need.energy: 20,
    Need.mood: 5,
  }),
  cake('Tarta perruna', 25, Tier.full, {
    Need.satiety: 5,
    Need.mood: 60,
    Need.energy: 10,
  }),
  bone('Hueso', 5, Tier.full, {Need.satiety: 5, Need.mood: 30});

  const Food(this.label, this.cost, this.tier, this.delta);
  final String label;
  final int cost;
  final Tier tier;
  final Map<Need, int> delta;
}
