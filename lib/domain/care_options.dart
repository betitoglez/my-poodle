import 'balance.dart';
import 'entitlements.dart';

abstract interface class CareOption {
  String get label;
  int get cost;
  Tier get tier;
  Map<Need, int> get delta;
}

enum BathPlan implements CareOption {
  standard('Baño estándar', 0, Tier.free, {Need.hygiene: 30}),
  premium('Baño Premium', 30, Tier.free, {Need.hygiene: 60}),
  massage('Baño con Masaje', 30, Tier.full, {Need.hygiene: 50, Need.mood: 25});

  const BathPlan(this.label, this.cost, this.tier, this.delta);
  @override
  final String label;
  @override
  final int cost;
  @override
  final Tier tier;
  @override
  final Map<Need, int> delta;
}

enum Drink implements CareOption {
  water('Agua', 0, {Need.hydration: 60}),
  bottled('Agua embotellada', 5, {Need.hydration: 90}),
  vitamins('Agua con vitaminas', 15, {
    Need.hydration: 90,
    Need.energy: 30,
    Need.mood: 10,
  }),
  juice('Zumo para perros', 20, {
    Need.hydration: 60,
    Need.energy: 50,
    Need.mood: 25,
  });

  const Drink(this.label, this.cost, this.delta);
  @override
  final String label;
  @override
  final int cost;
  @override
  final Map<Need, int> delta;
  @override
  Tier get tier => Tier.free;
}
