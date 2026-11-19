# Catálogo integrado

Capturas del pintor del juego con el caniche blanco en Rizo natural. Cada lámina muestra todos los artículos de su grupo de frente, de perfil y de espaldas.

- [Petos y jerséis](petos-y-jerseis.png)
- [Impermeables y vestidos](impermeables-y-vestidos.png)
- [Cabeza y gafas](cabeza-y-gafas.png)
- [Collares, pajarita y pañuelos](cuello.png)
- [Calzado](calzado.png)
- [Conjuntos en albaricoque, blanco y negro](conjuntos.png)

Los dibujos de peto, impermeable y vestido reutilizan el mismo tejido por familia. Las variantes se tiñen con los colores del catálogo. El pelo se vuelve a dibujar sobre las aberturas del cuello, los puños y la cola según la vista. El calzado tiene un anclaje por pata y las lentes se alinean a los ojos.

Los tres atlas se generaron con ImageGen integrado. Se empaquetaron en nueve WebP sin pérdida en [assets/images/materials](../../../assets/images/materials/). Las instrucciones de generación están en [prompts.md](prompts.md).

Para repetir las capturas, ejecutar:

```sh
POODLE_REVIEW=1 flutter test --no-pub test/game/integrated_accessories_review_test.dart
```
