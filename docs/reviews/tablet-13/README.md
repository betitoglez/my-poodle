# Revisión en tablet · 21-11-2026

15 capturas nativas del mismo **iPad Pro de 13 pulgadas (M5), iOS 26.5**, con **1032×1376 puntos / 2064×2752 píxeles** y DPR 2. Orientación vertical admitida por la app; no se cambia el tamaño entre pantallas. [Galería](index.html) · [Metadatos](manifest.json).

La toma usa `simctl io screenshot`, incluyendo las vistas WebGL nativas del caniche. El recorrido espera el primer frame 3D y falla si el visor falla o Flutter comunica excepciones/desbordes. Partida, nombre de muestra e inventario solo en memoria; compras simuladas sin tocar la tienda Apple ni el guardado del iPhone. PNG originales sin editar entregados en la carpeta externa de revisión; copias WebP de igual resolución en este directorio.

El botón grande «Probando» heredaba texto crema sobre fondo crema. Primer plano ciruela explícito para texto e icono; prueba de contraste mínimo 4,5:1 y capturas con el aviso expandido y plegado en Decoración y Armario.

| Nº | Pantalla |
|---:|---|
| 1 | [Casa · guirnaldas](01-casa-guirnalda.webp) |
| 2 | [Casa · estrellas](02-casa-estrellas.webp) |
| 3 | [Decorar · Probando visible](03-decoracion-probando-visible.webp) |
| 4 | [Decorar · estrellas colocadas](04-decoracion-estrellas-colocadas.webp) |
| 5 | [Armario · cola de perfil](05-armario-cola-probando.webp) |
| 6 | [Armario · aviso plegado](06-armario-cola-ojo.webp) |
| 7 | [Cuidados](07-cuidados.webp) |
| 8 | [Comer](08-comer.webp) |
| 9 | [Modo foto · 3D](09-modo-foto.webp) |
| 10 | [Catálogo de juegos](10-catalogo-juegos.webp) |
| 11 | [Parejas · instrucciones](11-instrucciones-parejas.webp) |
| 12 | [Parejas · 8 parejas](12-juego-parejas-8.webp) |
| 13 | [Memory](13-juego-memory.webp) |
| 14 | [Huerto saltarín](14-juego-huerto.webp) |
| 15 | [Frisbee en el prado](15-juego-frisbee.webp) |

```sh
TABLET_OUTPUT=/ruta/de/salida flutter drive --driver=test_driver/tablet_screenshots.dart --target=integration_test/tablet_screenshots_test.dart --device-id=9495CF14-6CFE-4489-8D61-5A80673C803F --dart-define=POODLE_LIVE_3D=true
flutter test test/ui/preview_badge_test.dart
```

Recorrido nativo y quince capturas completados sin incidencias; análisis y prueba de contraste correctos. Estas capturas acreditan las pantallas observadas en el simulador, no una aceptación completa en tablet física.
