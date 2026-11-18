# Piloto de prendas integradas · 18-11-2026

Revisión limitada al gorro de lana (`head.beanie`), familia jersey (`outfit.sweater_*`) y pañuelo coral (`neck.coral`). Las capturas usan el Rizo natural en albaricoque, blanco y negro. No se amplía el sistema al resto del catálogo hasta la revisión del propietario.

## Capturas para revisar

- [Comparación antes/después](before-after.png): mismo perro blanco, pose, cámara y tiempo de animación. Tres artículos por separado.
- [Gorro de lana](beanie.png): tres pelajes × frente, perfil y tres fotogramas de carrera.
- [Jersey](sweater.png): misma matriz; observar cuello, volumen del torso y mangas siguiendo el movimiento.
- [Pañuelo](bandana.png): misma matriz; observar pliegues, nudo y caída sobre el pecho.
- [Los tres artículos juntos](combination.png): orden de capas sobre los tres pelajes, de frente y corriendo.

Son renders del pintor real del juego, que se utiliza también en Casa, Armario y minijuegos. No son composiciones de perros vestidos generadas para la presentación. La revisión en dispositivo y la valoración estética del propietario siguen pendientes; no se ha generado un build de distribución.

## Implementación

- Seis ilustraciones con alfa real: frente y perfil de cada prenda, con los pliegues y el volumen del estilo original. Recursos en `assets/images/materials/*-v1.png`, declarados en `pubspec.yaml` y cargados mediante `rootBundle`.
- Una malla de 10 × 10 celdas ajusta torso y manga del jersey a cada fotograma. Los anclajes de cabeza y cuello colocan gorro y pañuelo en la misma transformación que el caniche. Los colores azul y mostaza del jersey reutilizan el recurso rojo mediante las matrices existentes.
- Sombras de contacto recortadas al alfa de la mascota. El pelaje de la imagen base vuelve a dibujarse delante del cuello, puños, flequillo y orejas. Las máscaras de las orejas cambian durante la carrera para evitar borrar el cuello de la prenda.
- Recursos preparados antes de sustituir el aspecto visible; imágenes decodificadas a 512 píxeles de ancho, compartidas entre todos los pelajes. Mallas y shaders se almacenan en caché; no se genera arte durante el juego.
- Piloto visual en frente, perfil, `run_a`, `run_b` y salto. Espalda, comer y dormir conservan el render anterior para esta revisión. El resto del catálogo conserva exactamente su representación anterior; una prueba compara sus píxeles.

Código: `lib/game/pet/integrated_accessories.dart`, composición en `pet_painter.dart` y exclusión de las tres representaciones anteriores en `pet_accessories.dart`.

En la segunda revisión, los contornos del cuello, los puños y el bajo dejan ver el pelaje que sale por cada abertura. La abertura de la manga comparte la deformación y la orientación de la tela en cada fotograma. El pañuelo conserva la curva de su borde frontal. Las láminas del jersey, el pañuelo y el conjunto muestran este ajuste.

## Validación

- `flutter analyze --no-pub` sin incidencias.
- `flutter test --no-pub` con **147 pruebas correctas** tras el ajuste de los contornos. Incluye comprobar que el pelaje del caniche blanco se ve en el cuello y ambos puños de frente, y en el cuello, el puño y el bajo de perfil.
- `flutter test --no-pub test/game/pet_sprites_test.dart test/game/integrated_accessories_review_test.dart test/ui/features_test.dart test/ui/app_flow_test.dart`: **36 pruebas correctas**.
- El piloto produce las 45 combinaciones individuales (3 prendas × 3 pelajes × 5 vistas/fotogramas), la comparativa y seis combinaciones de las tres prendas juntas.
- Comprobación visual local de las cinco láminas. La prueba de facciones comprueba ojos y hocico con margen de dos niveles de canal para redondeo del raster/alfa.

Regenerar capturas:

```sh
POODLE_REVIEW=1 flutter test --no-pub test/game/integrated_accessories_review_test.dart
```

[Prompts exactos, entradas y salidas de ImageGen](prompts.md). Se utilizó la herramienta integrada en modo edición y transparencia; los PNG finales están guardados en el proyecto, no dependen de rutas externas al ejecutar la app.
