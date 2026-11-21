/// Logros y álbum de pegatinas. Dart puro: sin Flutter ni Flame.
///
/// Cada logro tiene un ID estable (`ach.…`), una página del álbum, una
/// pegatina (clave de dibujo que la UI traduce a icono y color) y una
/// condición evaluada sobre [PetState]. Los logros se guardan en
/// `PetState.achievements` (ID → segundo UTC) y nunca se retiran, aunque
/// cambie el catálogo de artículos. Completar una página permite recoger una
/// sola vez su bono de monedas (`balance.albumPageBonus`).
library;

import 'balance.dart';
import 'entitlements.dart';
import 'haircuts.dart';
import 'pet_state.dart';
import 'rules.dart';

/// Páginas del álbum. `name` es el ID estable guardado en la partida.
enum AlbumPage { care, games, wardrobe, photos, special }

class Achievement {
  const Achievement({
    required this.id,
    required this.page,
    required this.sticker,
    required this.title,
    required this.hint,
    required this.condition,
  });

  /// ID estable guardado en la partida.
  final String id;
  final AlbumPage page;

  /// Clave del dibujo de la pegatina (la UI la convierte en icono y color).
  final String sticker;

  /// Nombre y pista en español: clave de traducción.
  final String title;
  final String hint;
  final bool Function(PetState s, Balance b) condition;
}

/// Segundos de un día UTC: los días de cuidado se cuentan en UTC.
const int secondsPerDay = 86400;

/// Umbrales del catálogo (cambiar junto con las pruebas y la documentación).
const int careDaysFew = 3;
const int careDaysMany = 7;
const int wardrobeMany = 10;
const int photosMany = 10;
const int coinsEarnedGoal = 200;

int _best(PetState s, GameId g) => switch (g) {
  GameId.fruit => s.bestFruit,
  GameId.frisbee => s.bestFrisbee,
  GameId.pairs => s.bestPairs,
  GameId.memory => s.bestMemory,
};

/// Primera partida terminada: `bestStars` tiene la clave desde que existen
/// las estrellas; antes basta con un récord positivo.
bool played(PetState s, GameId g) =>
    s.bestStars.containsKey(g.name) || _best(s, g) > 0;

bool _stars3(PetState s, GameId g) => (s.bestStars[g.name] ?? 0) >= 3;

/// Artículos del armario comprados (no iniciales, solo ranuras de aspecto).
/// Los cortes por zona (`cut.<zona>.<estilo>`) de pago cuentan como compras.
int wardrobeBought(PetState s, Balance b) => s.owned.where((id) {
  if (Haircuts.valid(id)) return Haircuts.cost(id.split('.').last) > 0;
  final item = b.item(id);
  return item != null && !item.initial;
}).length;

/// Con la misma propiedad que la tienda: un peinado completo se tiene si se
/// han comprado sus cortes en todas las zonas.
bool _allFreeWardrobe(PetState s, Balance b) {
  final free = b.styles.where((i) => !i.initial && i.tier == Tier.free);
  return free.isNotEmpty && free.every((i) => Rules.ownsStyleIn(s, i.id));
}

bool _decorPlaced(PetState s, Balance b) =>
    s.decor.values.any((id) => b.decorItem(id)?.initial == false);

bool _care(PetState s, CareKind k) => s.careCompletedUtc.containsKey(k.name);

class Achievements {
  Achievements(this.balance);
  final Balance balance;

  static final List<Achievement> catalog = List.unmodifiable(<Achievement>[
    // ---------------------------------------------------------- Cuidados
    Achievement(
      id: 'ach.care.feed',
      page: AlbumPage.care,
      sticker: 'bowl',
      title: 'Primera comida',
      hint: 'Dale de comer a tu caniche.',
      condition: (s, _) => _care(s, CareKind.feed),
    ),
    Achievement(
      id: 'ach.care.bath',
      page: AlbumPage.care,
      sticker: 'bath',
      title: 'Primer baño',
      hint: 'Baña a tu caniche.',
      condition: (s, _) => _care(s, CareKind.bath),
    ),
    Achievement(
      id: 'ach.care.walk',
      page: AlbumPage.care,
      sticker: 'walk',
      title: 'Primer paseo',
      hint: 'Sal de paseo con tu caniche.',
      condition: (s, _) => _care(s, CareKind.walk),
    ),
    Achievement(
      id: 'ach.care.vet',
      page: AlbumPage.care,
      sticker: 'vet',
      title: 'Visita al veterinario',
      hint: 'Lleva a tu caniche a la consulta.',
      condition: (s, _) => _care(s, CareKind.vet),
    ),
    Achievement(
      id: 'ach.care.sleep',
      page: AlbumPage.care,
      sticker: 'bed',
      title: 'Dulces sueños',
      hint: 'Acuesta a tu caniche en su cama.',
      condition: (s, _) => _care(s, CareKind.sleep),
    ),
    Achievement(
      id: 'ach.care.days3',
      page: AlbumPage.care,
      sticker: 'heart',
      title: 'Buen cuidador',
      hint: 'Cuida a tu caniche $careDaysFew días distintos.',
      condition: (s, _) => s.careDayCount >= careDaysFew,
    ),
    Achievement(
      id: 'ach.care.days7',
      page: AlbumPage.care,
      sticker: 'calendar',
      title: 'Una semana juntos',
      hint: 'Cuida a tu caniche $careDaysMany días distintos.',
      condition: (s, _) => s.careDayCount >= careDaysMany,
    ),
    // ------------------------------------------------------------ Juegos
    Achievement(
      id: 'ach.game.fruit.first',
      page: AlbumPage.games,
      sticker: 'fruit',
      title: 'Primera cosecha',
      hint: 'Termina una partida del Huerto saltarín.',
      condition: (s, _) => played(s, GameId.fruit),
    ),
    Achievement(
      id: 'ach.game.frisbee.first',
      page: AlbumPage.games,
      sticker: 'frisbee',
      title: 'Primer lanzamiento',
      hint: 'Termina una partida de Frisbee en el prado.',
      condition: (s, _) => played(s, GameId.frisbee),
    ),
    Achievement(
      id: 'ach.game.pairs.first',
      page: AlbumPage.games,
      sticker: 'pairs',
      title: 'Primeras parejas',
      hint: 'Termina una partida del Juego de parejas.',
      condition: (s, _) => played(s, GameId.pairs),
    ),
    Achievement(
      id: 'ach.game.fruit.stars3',
      page: AlbumPage.games,
      sticker: 'fruitStar',
      title: 'Huerto de estrellas',
      hint: 'Consigue 3 estrellas en el Huerto saltarín.',
      condition: (s, _) => _stars3(s, GameId.fruit),
    ),
    Achievement(
      id: 'ach.game.frisbee.stars3',
      page: AlbumPage.games,
      sticker: 'frisbeeStar',
      title: 'Frisbee de estrellas',
      hint: 'Consigue 3 estrellas en Frisbee en el prado.',
      condition: (s, _) => _stars3(s, GameId.frisbee),
    ),
    Achievement(
      id: 'ach.game.pairs.stars3',
      page: AlbumPage.games,
      sticker: 'pairsStar',
      title: 'Parejas de estrellas',
      hint: 'Consigue 3 estrellas en el Juego de parejas.',
      condition: (s, _) => _stars3(s, GameId.pairs),
    ),
    // ------------------------------------------------- Armario y salón
    Achievement(
      id: 'ach.wardrobe.first',
      page: AlbumPage.wardrobe,
      sticker: 'hanger',
      title: 'Estreno',
      hint: 'Compra un artículo en el armario.',
      condition: (s, b) => wardrobeBought(s, b) >= 1,
    ),
    Achievement(
      id: 'ach.wardrobe.ten',
      page: AlbumPage.wardrobe,
      sticker: 'closet',
      title: 'Armario lleno',
      hint: 'Compra $wardrobeMany artículos en el armario.',
      condition: (s, b) => wardrobeBought(s, b) >= wardrobeMany,
    ),
    Achievement(
      id: 'ach.wardrobe.allFree',
      page: AlbumPage.wardrobe,
      sticker: 'crown',
      title: 'Coleccionista',
      hint: 'Compra todos los artículos de la versión gratuita del armario.',
      condition: _allFreeWardrobe,
    ),
    Achievement(
      id: 'ach.decor.first',
      page: AlbumPage.wardrobe,
      sticker: 'sofa',
      title: 'Salón decorado',
      hint: 'Coloca una decoración en el salón.',
      condition: _decorPlaced,
    ),
    // ------------------------------------------------------------- Fotos
    Achievement(
      id: 'ach.photo.first',
      page: AlbumPage.photos,
      sticker: 'camera',
      title: 'Primera foto',
      hint: 'Guarda una foto en el modo foto.',
      condition: (s, _) => s.photosTaken >= 1,
    ),
    Achievement(
      id: 'ach.photo.ten',
      page: AlbumPage.photos,
      sticker: 'photos',
      title: 'Fotógrafo',
      hint: 'Guarda $photosMany fotos en el modo foto.',
      condition: (s, _) => s.photosTaken >= photosMany,
    ),
    // --------------------------------------------------------- Especiales
    Achievement(
      id: 'ach.game.memory.first',
      page: AlbumPage.special,
      sticker: 'memory',
      title: 'Buena memoria',
      hint: 'Termina una partida de Memory de caniches.',
      condition: (s, _) => played(s, GameId.memory),
    ),
    Achievement(
      id: 'ach.game.memory.stars3',
      page: AlbumPage.special,
      sticker: 'memoryStar',
      title: 'Memoria de estrellas',
      hint: 'Consigue 3 estrellas en Memory de caniches.',
      condition: (s, _) => _stars3(s, GameId.memory),
    ),
    Achievement(
      id: 'ach.game.allStars',
      page: AlbumPage.special,
      sticker: 'trophy',
      title: 'Campeón',
      hint: 'Consigue 3 estrellas en todos los juegos.',
      condition: (s, _) => GameId.values.every((g) => _stars3(s, g)),
    ),
    Achievement(
      id: 'ach.coins.200',
      page: AlbumPage.special,
      sticker: 'coins',
      title: 'Hucha llena',
      hint: 'Gana $coinsEarnedGoal monedas jugando.',
      condition: (s, _) => s.coinsEarnedTotal >= coinsEarnedGoal,
    ),
  ]);

  static Achievement? byId(String id) =>
      catalog.where((a) => a.id == id).firstOrNull;

  static List<Achievement> onPage(AlbumPage page) =>
      catalog.where((a) => a.page == page).toList(growable: false);

  bool isMet(Achievement a, PetState s) => a.condition(s, balance);

  /// Logros que se cumplen en [after] y no estaban guardados ni en [before]
  /// ni en [after]. Función pura e idempotente: aplicar el resultado y
  /// volver a evaluar devuelve una lista vacía.
  List<String> newlyUnlocked(PetState before, PetState after) => [
    for (final a in catalog)
      if (!before.achievements.containsKey(a.id) &&
          !after.achievements.containsKey(a.id) &&
          isMet(a, after))
        a.id,
  ];

  /// Guarda [ids] con el segundo [nowUtc].
  PetState record(PetState s, List<String> ids, int nowUtc) => ids.isEmpty
      ? s
      : s.copyWith(
          achievements: {...s.achievements, for (final id in ids) id: nowUtc},
        );

  int pageBonus(AlbumPage page) => balance.albumPageBonus[page.name] ?? 0;

  int unlockedOn(PetState s, AlbumPage page) =>
      onPage(page).where((a) => s.achievements.containsKey(a.id)).length;

  bool pageComplete(PetState s, AlbumPage page) =>
      onPage(page).every((a) => s.achievements.containsKey(a.id));

  bool collected(PetState s, AlbumPage page) =>
      s.albumCollected.contains(page.name);

  /// Se puede pulsar «Recoger»: página completa, bono positivo, sin cobrar.
  bool canCollect(PetState s, AlbumPage page) =>
      pageComplete(s, page) && !collected(s, page) && pageBonus(page) > 0;

  /// Bonos pendientes de recoger (para avisar en la cabecera).
  int pendingPages(PetState s) =>
      AlbumPage.values.where((p) => canCollect(s, p)).length;
}
