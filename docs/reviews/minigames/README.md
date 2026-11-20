# Parejas y Memory · verificación del 20-11-2026

Rama `codex/minijuegos-parejas-memory`, base inicial `0baabdd`, main integrado `ed77192`, Flutter 3.50.0 / Dart 3.14.0. [Resultados](results.json).

- Análisis sin incidencias; **312 pruebas correctas** (26 nuevas de reglas, simulación y recorridos de los tableros).
- Contenido y catálogos completos: 11 idiomas × 671 mensajes; ocho retratos nuevos y cuatro notas locales.
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

## Actualización con main

Merge de `ed77192` (PR #14 y #15), conservando el commit original de los minijuegos `f3b87c7`. Se combinan traducciones, guardados, semilla por sesión y frutas doradas; la nueva decoración y las estrellas conviven con el historial de Parejas/Memory. Retos de estrellas de Parejas: 4/6/8 parejas; de Memory: 3/6/10 pasos. Dos regresiones adicionales verifican estrellas/premios y guardado simultáneo de decoración, estrellas e historial. La prueba de tarjetas recorre los cuatro juegos mediante desplazamiento.

## Corrección de accesibilidad · PR #16

Codex detectó que `excludeSemantics` ocultaba la acción del `InkWell` en cartas y pulsadores. Los dos controles comparten ahora una acción guardada entre la semántica y el toque, exponen su estado habilitado y vuelven a comprobar pausa/finalización al ejecutar una acción encolada. Dos pruebas reproducían el fallo antes del cambio y verifican Parejas hasta su premio y una ronda de Memory mediante acciones del lector de pantalla, con bloqueo durante pausa/muestra. Análisis limpio, 312 pruebas, validadores y web Release correctos. El resultado de la revisión remota se registra en [PR #16](https://github.com/betitoglez/my-poodle/pull/16).

El recorrido accesible también cubre la tarjeta del catálogo y Jugar, antes de llegar al tablero. Se conserva el commit remoto `76712ee` que sustituye los ocho retratos PNG por WebP de 512 px; referencias y validación usan los WebP.
