/// Las cuatro ranuras independientes del aspecto del caniche.
enum Slot { coat, hair, outfit, neck }

/// Aspecto: un ID de catálogo por ranura. Inmutable.
class Appearance {
  const Appearance({
    required this.coat,
    required this.hair,
    required this.outfit,
    required this.neck,
  });

  final String coat;
  final String hair;
  final String outfit;
  final String neck;

  String of(Slot slot) => switch (slot) {
    Slot.coat => coat,
    Slot.hair => hair,
    Slot.outfit => outfit,
    Slot.neck => neck,
  };

  /// Cambiar una ranura conserva las otras tres.
  Appearance withSlot(Slot slot, String id) => Appearance(
    coat: slot == Slot.coat ? id : coat,
    hair: slot == Slot.hair ? id : hair,
    outfit: slot == Slot.outfit ? id : outfit,
    neck: slot == Slot.neck ? id : neck,
  );

  List<String> get ids => [coat, hair, outfit, neck];

  Map<String, String> toJson() => {
    'coat': coat,
    'hair': hair,
    'outfit': outfit,
    'neck': neck,
  };

  @override
  bool operator ==(Object other) =>
      other is Appearance &&
      other.coat == coat &&
      other.hair == hair &&
      other.outfit == outfit &&
      other.neck == neck;

  @override
  int get hashCode => Object.hash(coat, hair, outfit, neck);

  @override
  String toString() => 'Appearance($coat, $hair, $outfit, $neck)';
}
