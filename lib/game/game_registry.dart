import '../domain/balance.dart';
import '../domain/rules.dart';

/// Definición de un minijuego (contrato común de docs/JUEGOS.md). La pantalla
/// de juegos construye sus tarjetas leyendo [GameCatalog]; cada clave se
/// registra con su fábrica en la pantalla de partida, nunca por ruta tomada
/// de un JSON.
class GameDefinition {
  const GameDefinition({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.tagline,
    required this.objective,
    required this.gesture,
    required this.limitLabel,
    required this.scoreLabel,
    required this.rewardLabel,
  });

  final GameId id;
  final String title;
  final String thumbnail;
  final String tagline;
  final String objective;
  final String gesture;
  final String limitLabel;
  final String scoreLabel;
  final String rewardLabel;
}

abstract final class GameCatalog {
  static GameDefinition fruit(FruitRule rule) => GameDefinition(
    id: GameId.fruit,
    title: 'Huerto saltarín',
    thumbnail: 'assets/images/cards/orchard.jpg',
    tagline: 'Salta los obstáculos y recoge frutas.',
    objective: 'Llega a la meta recogiendo hasta ${rule.maxScore} frutas.',
    gesture: 'Toca la pantalla o el botón Saltar para saltar.',
    limitLabel: '${rule.seconds} segundos',
    scoreLabel: 'frutas',
    rewardLabel: '${rule.baseCoins} monedas + ${rule.coinsPerPoint} por fruta',
  );

  static const frisbee = GameDefinition(
    id: GameId.frisbee,
    title: 'Frisbee en el prado',
    thumbnail: 'assets/images/cards/frisbee.jpg',
    tagline: 'Lanza el disco hacia el aro.',
    objective: 'Que tu caniche atrape el disco dentro del aro.',
    gesture: 'Arrastra hacia arriba y suelta. También puedes usar el lanzamiento asistido.',
    limitLabel: '20 segundos · 5 lanzamientos',
    scoreLabel: 'capturas',
    rewardLabel: '3 monedas + 3 por captura',
  );

  static const pairs = GameDefinition(
    id: GameId.pairs,
    title: 'Juego de parejas',
    thumbnail: 'assets/images/poodles/parti.webp',
    tagline: 'Encuentra los caniches iguales.',
    objective: 'Encuentra todas las parejas antes de agotar el tiempo o los 5 intentos. Solo los fallos gastan intentos.',
    gesture: 'Toca dos cartas para descubrir sus caniches.',
    limitLabel: '60 segundos · 5 intentos',
    scoreLabel: 'parejas',
    rewardLabel: '4 parejas: 5 monedas · 6: 15 · 8: 25',
  );

  static const memory = GameDefinition(
    id: GameId.memory,
    title: 'Memory de caniches',
    thumbnail: 'assets/images/poodles/apricot.webp',
    tagline: 'Recuerda los colores y sus sonidos.',
    objective: 'Repite la secuencia de 3 a 10 pasos. Al fallar o agotar el tiempo cobras el premio de la última ronda completada.',
    gesture: 'Mira y escucha; después toca los caniches en el mismo orden.',
    limitLabel: '10 segundos por turno',
    scoreLabel: 'pasos',
    rewardLabel: 'De 5 a 40 monedas: +5 por ronda completada',
  );

  static List<GameDefinition> all(Balance balance) => [
    fruit(balance.fruit),
    frisbee,
    pairs,
    memory,
  ];

  static GameDefinition of(GameId id, Balance balance) => switch (id) {
    GameId.fruit => fruit(balance.fruit),
    GameId.frisbee => frisbee,
    GameId.pairs => pairs,
    GameId.memory => memory,
  };
}
