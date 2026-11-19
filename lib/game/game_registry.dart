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

  static List<GameDefinition> all(Balance balance) => [
    fruit(balance.fruit),
    frisbee,
  ];

  static GameDefinition of(GameId id, Balance balance) => switch (id) {
    GameId.fruit => fruit(balance.fruit),
    GameId.frisbee => frisbee,
  };
}
