# Piloto de prendas integradas · 18-11-2026

El piloto integra el gorro de lana, la familia jersey y el pañuelo coral. La revisión del cuello incluye los collares, el pañuelo de punto y la pajarita. Las capturas usan el Rizo natural en albaricoque, blanco y negro.

## Capturas para revisar

- [Comparación antes/después](before-after.png): mismo perro blanco, pose, cámara y tiempo de animación. Tres artículos por separado.
- [Gorro de lana](beanie.png): tres pelajes × frente, perfil, espalda y tres fotogramas de carrera.
- [Jersey](sweater.png): misma matriz; observar cuello, volumen del torso y mangas siguiendo el movimiento.
- [Pañuelo](bandana.png): misma matriz; observar pliegues, nudo y caída sobre el pecho.
- [Los tres artículos juntos](combination.png): orden de capas sobre los tres pelajes, de frente, de perfil, de espaldas y en carrera.
- [Accesorios del cuello](neck-fit.png) muestra pañuelo coral y de punto, pajarita y collares con chapa, cascabel y perlas en tres vistas.

Son renders del pintor real del juego, que se utiliza también en Casa, Armario y minijuegos. No son composiciones de perros vestidos generadas para la presentación. La revisión en dispositivo y la valoración estética del propietario siguen pendientes; no se ha generado un build de distribución.

## Implementación

- Nueve ilustraciones con alfa real de frente, perfil y espalda para las tres prendas, con los pliegues y el volumen del estilo original. Recursos en `assets/images/materials/*-v1.png`, declarados en `pubspec.yaml` y cargados mediante `rootBundle`.
- Una malla de 10 × 10 celdas ajusta torso y manga del jersey a cada fotograma. Los anclajes de cabeza y cuello colocan gorro y pañuelo en la misma transformación que el caniche. Los colores azul y mostaza del jersey reutilizan el recurso rojo mediante las matrices existentes.
- Sombras de contacto recortadas al alfa de la mascota. El pelaje de la imagen base vuelve a dibujarse delante del cuello, puños, flequillo y orejas. Las máscaras de las orejas cambian durante la carrera para evitar borrar el cuello de la prenda.
- Recursos preparados antes de sustituir el aspecto visible; imágenes decodificadas a 512 píxeles de ancho, compartidas entre todos los pelajes. Mallas y shaders se almacenan en caché; no se genera arte durante el juego.
- Piloto visual de frente, de perfil, de espaldas, `run_a`, `run_b` y salto. En la vista posterior, el pañuelo muestra su vuelta y el nudo. El pelaje de la cola pasa por delante del jersey.

Código: `lib/game/pet/integrated_accessories.dart`, composición en `pet_painter.dart` y exclusión de las tres representaciones anteriores en `pet_accessories.dart`.

En la segunda revisión, los contornos del cuello, los puños y el bajo dejan ver el pelaje que sale por cada abertura. La abertura de la manga comparte la deformación y la orientación de la tela en cada fotograma. El pañuelo conserva la curva de su borde frontal. Las láminas del jersey, el pañuelo y el conjunto muestran este ajuste.

El pañuelo ajusta sus dos extremos al contorno compartido del cuello en cada pose. El jersey, los collares, la pajarita y el pañuelo de punto usan la misma referencia. La oreja tapa parte de la vuelta en perfil y carrera.

## Validación

- `flutter analyze --no-pub` sin incidencias.
- `flutter test --no-pub` con **148 pruebas correctas**. Incluye el pelaje que asoma por cuello y puños, la cobertura del pañuelo en las tres vistas y el giro del caniche en Casa.
- El piloto produce 54 capturas individuales, 12 del conjunto y 18 primeros planos de los accesorios de cuello.
- Comprobación visual local de las seis láminas. La prueba de facciones comprueba ojos y hocico con margen de dos niveles de canal para redondeo del raster/alfa.

Regenerar capturas:

```sh
POODLE_REVIEW=1 flutter test --no-pub test/game/integrated_accessories_review_test.dart
```

[Prompts exactos, entradas y salidas de ImageGen](prompts.md). Se utilizó la herramienta integrada en modo edición y transparencia; los PNG finales están guardados en el proyecto, no dependen de rutas externas al ejecutar la app.
