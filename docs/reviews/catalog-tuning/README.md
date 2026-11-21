# Ajustes de catálogo y decoración · 21-11-2026

Desde `bed4bee`, sin dependencias nuevas, Flutter 3.50.0 / Dart 3.14.0.

- La marca morada era una «z» del efecto de sueño con visibilidad indefinida. Se fuerza un booleano en el efecto y su activación. Las 101 miniaturas se recapturan con el visor WebGL local; una regresión ejecuta el efecto real con flags ausentes/falsos y comprueba que dormir sigue mostrando las tres letras. [Manifiesto](frames.json), [comprobación de píxeles](pixel-check.json).
- Cola estándar uniforme sin pompón: gratuita para ambas versiones, también con saldo cero; guardado compatible, modelo 3D e imagen 2D propios. Solo pertenece a Cola, sin introducir un pack estándar. [Comparación 2D: natural / estándar](tail-2d.png).
- Lomo y Cola se abren de perfil tanto en el visor como en las miniaturas y el respaldo 2D. [Cola estándar](../../../assets/images/wardrobe_thumbs/cut.tail.standard.webp), [lomo moderno](../../../assets/images/wardrobe_thumbs/cut.back.modern.webp).
- El aumento del 20 % cuenta únicamente especiales ya comprados de la misma categoría y familia. Vestido, jersey, impermeable, peto y pelaje tienen contadores independientes. Una compra normal no cuenta, volver a equipar no cobra y las compras antiguas conservan su propiedad. Precio = base × 1,2^comprados, redondeado hacia arriba al múltiplo de diez; por ejemplo vestido 560 → 680 → 810. La recarga conserva los importes.
- La guirnalda ocupa el ancho visible completo: sin márgenes de escena ni píxeles transparentes del recurso en los extremos. Se comprueban los píxeles de ambos bordes a 320 y 600 px.
- Las estrellas ilustradas tienen halo dorado en el contorno, incluso con movimiento reducido; se comprueban píxeles luminosos fuera de la silueta original. [Bordes luminosos](stars-glow.png).
- Los premios de Parejas se muestran en tres filas: 4 parejas / 5, 6 / 15 y 8 / 25, cada una con su icono de moneda y semántica. Comprobado a 320×568 con texto ×1,3.
- El pelo se ajusta bajo gorro y corona después de aplicar el corte. Se oculta solo la superficie cubierta por la ropa y el calzado, usando sus planos de abertura en coordenadas del modelo; se conservan las partes expuestas. Combinaciones de seis peinados con las cuatro familias de ropa, gorro y botas en frente/perfil/espalda: 72 capturas sin errores JS/GLSL. [Manifiesto](fitting-frames.json).

| Comparación | Antes | Después |
|---|---|---|
| Peto, botas y gorro con concurso | [Antes](peto-before.webp) | [Después](peto-after.webp) |
| Jersey, botas y gorro con moderno | [Antes](jersey-before.webp) | [Después](jersey-after.webp) |

[Frente del gorro con pompón](gorro-front.webp) y [corona con concurso](corona-front.webp). Dos capturas adicionales con corona, [manifiesto](crown-frames.json). Las capturas proceden del visor empaquetado, sin editar el modelo de origen ni generar arte durante la partida.

## Reproducción

```sh
flutter analyze
flutter test
flutter test test/game/modern_hair_render_test.dart test/game/wall_decor_render_test.dart --dart-define=CATALOG_CAPTURE=true
node --test tool/arte/poc_3d/catalog_frames.test.mjs
node tool/arte/poc_3d/catalog_thumbnails.mjs
node tool/arte/poc_3d/catalog_thumbnails.mjs --fitting
dart run tool/validate_content.dart
dart run tool/validate_localizations.dart
flutter build web --release --dart-define=POODLE_LIVE_3D=true
flutter build ios --profile --build-name 0.5.0 --build-number 37 --dart-define=POODLE_LIVE_3D=true
```

Validación final y aceptación física registradas en [ESTADO](../../ESTADO.md). La instalación no sustituye la aceptación manual de cada combinación o la revisión humana de traducciones.
