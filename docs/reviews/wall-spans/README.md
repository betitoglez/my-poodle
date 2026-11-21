# Pared adaptable y vista previa · 21-11-2026

La guirnalda anterior se ajustaba deformando su ancho y las estrellas se centraban sin cubrir toda la pared. Se sustituyen ambos recursos por imágenes nuevas generadas con la herramienta integrada `image_gen.imagegen`, transparencia real y materiales realistas. [Prompts completos, exportación y rutas finales](../../arte/wall-spans.json).

- [Guirnalda nueva](../../../assets/images/decor/wall.garland.webp): seis banderines de lino con costuras, pliegues y cordón continuo.
- [Estrellas nuevas](../../../assets/images/decor/wall.stars.webp): seis estrellas de latón con contorno LED y halo cálido incluidos en el propio recurso.
- El montaje repite tramos manteniendo una única escala para ambos ejes. En pantallas más anchas aparecen más adornos; el último tramo continúa fuera del visor. No se estiran las imágenes para rellenar el ancho. El cordón llega a ambos bordes y las estrellas conservan su forma.
- Miniaturas, Casa y Decoración comparten el mismo dibujo. El brillo permanece con movimiento reducido.
- «Probando» se pliega al tocarlo en Armario y Decoración: queda solo el ojo arriba a la derecha, con área táctil accesible y acción para recuperar el texto. No aplica, compra ni descarta la prueba pendiente.

## Cinco anchos

Las capturas transparentes son la salida real de `DecorPainter`, con el mismo tamaño de perro y altura de pared. La prueba compara los primeros adornos entre anchos para detectar cualquier estiramiento y comprueba los píxeles de los dos bordes.

| Ancho | Guirnalda | Estrellas |
|---:|---|---|
| 320 | [Ver](garland-320.png) | [Ver](stars-320.png) |
| 390 | [Ver](garland-390.png) | [Ver](stars-390.png) |
| 600 | [Ver](garland-600.png) | [Ver](stars-600.png) |
| 844 | [Ver](garland-844.png) | [Ver](stars-844.png) |
| 1024 | [Ver](garland-1024.png) | [Ver](stars-1024.png) |

## Revisión adicional de Codex

Hallazgo P2 de PR #17 sobre `6925ca4`: el material integrado del jersey aceptaba todos los IDs, pero solo teñía rojo, azul y mostaza. Se limita esa ruta a los tres colores que representa; blanco, negro y cuatro estampados usan el dibujante existente que sí los representa. Una regresión de píxeles con atlas y materiales cargados reproduce el fallo anterior (blanco = rojo, cero píxeles distintos) y comprueba después todas las variantes entre sí en frente, perfil y espalda. Se conservan precios, propiedad e IDs.

```sh
flutter analyze
flutter test
flutter test test/game/wall_decor_render_test.dart --dart-define=WALL_CAPTURE=true
flutter test test/ui/preview_badge_test.dart test/game/sweater_variants_render_test.dart
dart run tool/validate_content.dart
dart run tool/validate_localizations.dart
flutter build web --release --dart-define=POODLE_LIVE_3D=true
flutter build ios --profile --build-name 0.5.0 --build-number 38 --dart-define=POODLE_LIVE_3D=true
```

Validación final en [ESTADO](../../ESTADO.md). Aceptación visual manual en dispositivos pendiente.
