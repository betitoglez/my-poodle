# Parejas y Memory · verificación del 20-11-2026

Rama `codex/minijuegos-parejas-memory`, base `0baabdd`, Flutter 3.50.0 / Dart 3.14.0. [Resultados](results.json).

- Análisis sin incidencias; **249 pruebas correctas** (22 nuevas de reglas, simulación y recorridos de los tableros).
- Contenido y catálogos completos: 11 idiomas × 605 mensajes; ocho retratos nuevos y cuatro notas locales.
- Compilación web Release correcta con `POODLE_LIVE_3D=true`; sin nuevas dependencias.
- Comprobados premios exactos, rangos de puntuación, pago idempotente, guardados antiguos, historial tras reinicio/abandono, descarte de colisiones, inicio fallido/concurrente, acceso gratuito/completo, pausa/segundo plano, límite de diez segundos por turno completo y juego sin sonido.
- Capturas de widget con Roboto y MaterialIcons del SDK: [6 parejas](pairs-6.png), [8 parejas a 320×568](pairs-8-320.png), [8 parejas a 844×390](pairs-8-844.png) y [Memory](memory.png). Inspección visual realizada; imágenes precargadas antes del cronómetro.

## Reproducir

```sh
flutter analyze
dart run tool/validate_content.dart
dart run tool/validate_localizations.dart
flutter test
flutter build web --release --dart-define=POODLE_LIVE_3D=true
```

Para regenerar capturas, ejecutar `flutter test test/ui/puzzle_games_test.dart --dart-define=PUZZLE_CAPTURE=true`; requiere `FLUTTER_ROOT` o la ruta del SDK usada en esta máquina. Sin ese flag las pruebas usan el entorno habitual. [Prompts de imágenes y generador de notas](../../arte/minigames/FUENTES.md).

Aceptación física de los dos juegos y nueva distribución TestFlight pendientes. Esta implementación no forma parte de la IPA (34) ya instalada. Las pruebas automáticas no acreditan sonido, accesibilidad o interrupciones reales en iPhone/Android.
