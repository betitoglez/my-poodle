# Correcciones de Codex en PR #17 · 21-11-2026

Base revisada `7d468b7`, rama `codex/cuidados-armario-decoracion`. Dos P2 corregidos:

- [Corte moderno en el respaldo 2D](https://github.com/betitoglez/my-poodle/pull/17#discussion_r4648629871). El alias comparte únicamente la textura natural; `ModernHairMesh` dibuja una silueta distinta mediante vértices/UV, sin generar imágenes durante la partida. Cresta, botas, lomo y pluma se deforman de forma independiente. Los cortes mixtos usan una única base deformada, con regiones de cabeza/cola según la pose; se precargan todas las texturas y colores necesarios. También se diferencia el respaldo vectorial sin atlas. No cambian precios ni propiedad.
- [Percepción accesible de Memory](https://github.com/betitoglez/my-poodle/pull/17#discussion_r4648629879). La región viva del estado comunica color, nota y número de paso, incluso cuando se repite el mismo color. Conserva el mensaje durante el intervalo apagado. Con lector de pantalla activo, cada señal dura 2,6 s y su intervalo 0,4 s. La respuesta sigue disponiendo de diez segundos por turno; sonidos y controles mantienen su comportamiento.

## Pruebas

**334 pruebas correctas**, análisis limpio, catálogos válidos y 11 × 740 mensajes con parámetros verificados. Sin dependencias ni recursos raster nuevos para la app. Compilaciones web Release e iOS Profile sin firma correctas con `POODLE_LIVE_3D=true`; modelo e idiomas del paquete comprobados.

Seis regresiones nuevas cubren compra/recarga del pack y cada zona, render con atlas y vectorial, frente/perfil/espalda y animaciones de correr/saltar/comer/dormir, señales iguales consecutivas, pausas durante demostración/respuesta, efectos apagados y diez segundos de respuesta. El recorrido accesible recoge únicamente las señales del árbol semántico y responde mediante sus botones; no lee `puzzleDeals` ni la secuencia guardada.

Se reejecutaron las pruebas sobre el render y la pantalla anteriores a la corrección: cuatro fallan por las incidencias originales. El widget nuevo de región viva, aún desconectado en esa reproducción, pasa. Restaurado el código corregido, pasan las pruebas dirigidas y la batería completa.

[Comparativa 2D](modern-2d.png): columnas natural, pack moderno, solo cabeza, solo patas, solo lomo y solo cola; filas frente, perfil y espalda. Los cambios de la cola se aprecian en las poses en las que se ve. Inspeccionada la silueta y la continuidad de las zonas.

```sh
flutter analyze
flutter test
flutter test test/game/modern_hair_render_test.dart test/ui/memory_signal_accessibility_test.dart test/game/puzzle_sim_test.dart --dart-define=REVIEW_CAPTURE=true
dart run tool/validate_content.dart
dart run tool/validate_localizations.dart
flutter build web --release --dart-define=POODLE_LIVE_3D=true
flutter build ios --profile --no-codesign --dart-define=POODLE_LIVE_3D=true
```

La aceptación física con VoiceOver/TalkBack sigue pendiente. Estas pruebas acreditan el contenido y las transiciones del árbol semántico, no la salida hablada real del sistema. No se instala ni distribuye una nueva versión.
