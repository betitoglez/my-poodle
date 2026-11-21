# Cuidados, armario y decoración · 20-11-2026

Rama `codex/cuidados-armario-decoracion`, base `3387647` (PR #16 revisada). Flutter 3.50.0 / Dart 3.14.0, sin dependencias nuevas.

- Análisis limpio, **328 pruebas**. Cobertura nueva: plazos de 900 s por opción en ambas versiones, migración de plazos antiguos, cupo de juegos solo gratuito, cuenta atrás activa y oferta, compra de zona sin regalar el pack, descuento de packs, migración de propiedad, colores especiales con incremento global del 20 % y ropa especial por ocho.
- Puente iOS simulado, con `POODLE_LIVE_3D=true`: arrastrar horizontalmente envía rotación; verticalmente no envía giro distinto de cero. La pantalla de decoración usa `LivePoodleView` y oculta el sprite.
- Visor WebGL real en Chrome: **100 miniaturas**, con vigilancia de errores JS/GLSL. Incluye los 24 cortes iniciales/comprables por zona, seis colores especiales y ropa nueva. Ejemplos: [cebra](coat.zebra.webp), [dálmata](coat.dalmatian.webp), [círculos](outfit.overalls_dots.webp), [cabeza moderna](cut.head.modern.webp), [cola concurso](cut.tail.show.webp).
- Validadores correctos: 76 artículos base/packs, 12 de decoración, 11 idiomas × 739 mensajes y parámetros.
- Compilaciones web Release e iOS Profile correctas con 3D activado. Paquete iPhone comprobado: modelo, shaders, nueve imágenes de decoración, dos portadas y 24 miniaturas por zona. Build de comprobación sin firma, sin instalación ni distribución.

## Capturas e inspección

[Portadas](games-covers.png), [cuidado con plazo por ración y saldo](care-options-free.png), [cabeza independiente a 320×568](wardrobe-head-320.png), [alfombra realista](decor-rug.png), [planta realista](decor-plants.png). Las capturas de widgets usan el respaldo 2D para el caniche y fuentes del SDK; algunos textos de botones conservan la fuente de pruebas. La composición y recursos se inspeccionaron; no son capturas de hardware. El 3D se verifica por separado con visor y puente nativo.

## Reproducir

```sh
flutter analyze
dart run tool/validate_content.dart
dart run tool/validate_localizations.dart
flutter test
flutter test test/ui/photo_drag_3d_test.dart --dart-define=POODLE_LIVE_3D=true
flutter test test/ui/catalog_refresh_test.dart --dart-define=REFRESH_CAPTURE=true
node tool/arte/poc_3d/catalog_thumbnails.mjs
flutter build web --release --dart-define=POODLE_LIVE_3D=true
flutter build ios --profile --no-codesign --dart-define=POODLE_LIVE_3D=true
```

Procedencia de arte y prompts: [decor-games-refresh.json](../../arte/decor-games-refresh.json). Los ocho retratos WebP anteriores de los juegos se conservan.

Pendientes: aceptación física de estos cambios en iPhone/Android y revisión lingüística humana. Push está únicamente en TODO: máximo dos avisos/día, separados por ocho horas. No se ha publicado esta rama ni cambiado/fusionado PR #16. La instalación iPhone 0.5.0 (35), de `3387647`, permanece sin modificar.
