# Prueba de vestuario 3D

La escena usa una malla de Meshy 7.1 y un esqueleto cuadrúpedo creado en Blender 5.3. Los tres conjuntos comparten el cuerpo y la animación. El corte pompón es una deformación del copete y las orejas del mismo caniche. Bajo el gorro se aplica el 10 % de esa deformación.

- [Vistas desde cinco ángulos · osito](angulos-osito.png) y [pompón](angulos-pompon.png)
- [Ajuste de la montura](gafas-ajuste.png) y [GLB original de las gafas](montura-meshy.glb)
- [Vista de cerca de los tejidos y accesorios](detalles-de-ropa.png)
- [Comparación con el peto 2D](comparativa-2d-3d.png)
- [Tres conjuntos con corte osito](osito.png) y [con corte pompón](pompon.png)
- [Bucle de carrera con peto](carrera-peto.gif)
- [Escena editable con materiales y texturas](My-Poodle-vestuario.blend)
- [GLB original de Meshy](caniche-meshy.glb) y [recuento de triángulos](triangulos.json)

## Inspeccionar en Blender

La escena abre el peto en perfil. En el panel de colecciones se puede alternar entre **Peto**, **Vestido** e **Impermeable**. **Botas** es una colección independiente compartida por peto y vestido. La clave de forma **Corte pompón** está en los datos de malla de **Caniche · malla Meshy**. Usar valor 1 para pompón y 0 para osito. Con el gorro equipado, el valor de las capturas es 0,1. Las botas tienen una clave de forma **Caña bajo la pernera**. Las capturas usan valor 1 con el peto y 0 con el vestido.

El fotograma 0 corresponde a la pose de pie. El 7 corresponde a extensión y el 17 a recogida. El ciclo va del 1 al 24 a 24 FPS. La cámara usa proyección ortográfica. Las láminas de carrera comparan frente, perfil y espalda en reposo y los dos extremos de perfil. Las láminas de ángulos usan cámaras independientes para frente, perfil izquierdo, perfil derecho, cenital y espalda.

## Geometría y ajuste

El GLB de partida contiene 734.406 triángulos. Blender conserva sus UV, une vértices duplicados en las costuras y reduce el cuerpo a 109.999 triángulos. La ropa parte de una copia suavizada de su superficie, con recortes para cuello, cola y patas. El cuerpo y los conjuntos usan los mismos pesos en las articulaciones. Las botas se ajustan a cada pata por altura, con suela rígida y caña que sigue la pierna.

El informe cuenta las mallas con los modificadores evaluados y con un único conjunto visible. Las seis configuraciones caben en 200.000 triángulos. Es una medición geométrica de Blender. La prueba visual usa imágenes prerenderizadas.

La pana tiene canales y variación de tinte. El peto incorpora bolsillos y tirantes pespunteados. El pañuelo rodea la nuca y cae sobre el pecho con pliegues de algodón. El vestido tiene dos volantes de popelina y un lazo de cinta plegada. El impermeable lleva una trama de lona encerada y una solapa con automáticos. El gorro combina una copa de punto y una vuelta de canalé. Las botas tienen suela y caña de caucho diferenciadas. La montura de las gafas se generó en Meshy 7.1 a partir de dos referencias de la pieza aislada. Blender reduce la geometría y ajusta la curva de los aros al hocico, abre las patillas alrededor del pelo y coloca dos lentes de reflejo suave en las aberturas.

En la recogida se separaron las patas delanteras y traseras. Los volantes mantienen su forma base al seguir el tronco. El detalle de la trama se aprecia mejor en la lámina de cerca.

## Reproducir

Se usaron las vistas `teddy_front.webp`, `teddy_side.webp` y `teddy_back.webp` de `docs/arte/meshy/originales`. La sesión privada de Meshy usó Ultra 2K, textura 2K y la mejora de imagen desactivada. Blender trabaja con los dos GLB guardados en esta carpeta. El argumento opcional `--glasses` permite proporcionar otra ruta para la montura.

Desde la raíz del checkout, con Blender y Pillow instalados:

```sh
blender -b --factory-startup --python-exit-code 1 --python tool/arte/poc_3d/build.py -- \
  docs/reviews/wardrobe-3d/caniche-meshy.glb /tmp/mypoodle-3d-renders
python3 tool/arte/poc_3d/review.py /tmp/mypoodle-3d-renders /tmp/mypoodle-3d-revision
```

Para recrear la comparativa, añadir la ruta a `cinco-poses.png` del piloto articulado 2D como tercer argumento de `review.py`.

## 3D en tiempo real en Casa y Armario

La variante Android de My Poodle carga el modelo glTF local en Casa y Armario. Arrastra sobre el caniche para girarlo, tócalo para mover la cola y usa **Tumbarse** y **Levantarse** para probar el esqueleto. En Armario, **Looks 3D** abre la vista previa del peto con pañuelo, el vestido con lazo y el conjunto de impermeable, botas, gorro y gafas. La vista previa se puede descartar y las compras siguen el flujo habitual del armario.

El piloto incluye el corte osito como modelo base y los cortes pompón y cachorro como deformaciones. Los minijuegos conservan sus sprites 2D.

Desde la versión 0.2.1, el peto, el vestido y el impermeable usan mapas de color y normales horneados de los materiales procedurales de Blender. El exportador incluye la pana del peto y sus bolsillos, la popelina del cuerpo y los dos volantes y la lona encerada del impermeable. El GLB conserva la rugosidad y el brillo de los tejidos. El visor calcula la iluminación en tiempo real y las texturas siguen la malla al doblar las patas.

La versión 0.2.2 aplica el acabado a todas las piezas disponibles en 3D. El exportador agrupa remates, puntadas, algodón del pañuelo, tela del lazo, lana del gorro, caucho de las botas y acetato de las gafas en atlas por artículo. El punto mantiene las UV originales del patrón al hornearse. La montura tiene vetas de carey y las lentes usan un reflejo suave con transparencia. El exportador ajusta la caída del pañuelo, el anclaje del lazo y cómo la ropa y las botas siguen las articulaciones al tumbarse. La holgura de los cuerpos de las tres prendas aumenta con la flexión y vuelve a su valor inicial al levantarse.

La versión 0.2.3 usa una pose específica cuando el impermeable y las botas están equipados juntos. Al tumbarse, el perro apoya las patas delanteras más adelantadas y recoge las cañas de forma progresiva. La misma transición se reproduce a la inversa al levantarse. Se verificó la separación de las mallas del impermeable y de las cuatro botas en 49 muestras de la transición.

La versión 0.3.0 incluye las 27 prendas y accesorios del armario. El módulo `catalog.py` amplía la escena con los modelos pendientes y el exportador hornea los materiales de Blender. Ocho variantes de color comparten malla y mapas de relieve. La pajarita y la bufanda rodean el cuello, y los colgantes quedan debajo de la prenda de cuello al combinar ambos accesorios. Los dobladillos del peto y los volantes del vestido dejan holgura para el calzado durante la flexión. Las botas de lluvia con peto conservan la caña por dentro de la pernera. Se añadieron tres combinaciones a **Looks 3D** para probar las piezas nuevas.

La versión 0.3.1 captura las 42 fichas del armario desde el propio visor WebGL. Cada ficha muestra el artículo por separado y el visor superior muestra el conjunto elegido. Las imágenes WebP reutilizan los materiales y la iluminación del visor. Tras modificar el GLB o la paleta, regenerar las fichas con Node.js 22 y Chrome.

La versión 0.3.2 añade la cocina 3D. La animación **Comer** flexiona las patas delanteras, baja el hocico dentro del cuenco y lo levanta después de masticar. El cuenco tiene volumen y su borde oculta parte del hocico durante el bocado. La animación toma el progreso y el nivel de comida de la actividad existente. Los tres bocados se pueden dar con el botón o tocando el cuenco. Huerto Saltarín y Frisbee siguen usando sus escenas 2D.

La versión 0.3.3 eleva el ángulo de cámara de la cocina y reduce la altura y la extensión del montón de pienso con cada bocado. Así se ven dos tercios y un tercio antes de vaciar el cuenco. El cuenco comparte el espacio 3D con el hocico y lo tapa parcialmente mientras el caniche mastica.

La versión 0.3.4 añade el baño 3D. La ducha, el aclarado y el secador progresan durante cinco segundos de uso en cada fase. Al frotar el lomo, las patas, el pecho y la cabeza, la espuma se acumula en cada zona del modelo y se retira durante el aclarado. El pelaje se oscurece al mojarse y recupera su acabado al secarse.

La versión 0.3.5 añade la consulta 3D. El fonendoscopio y la lupa responden al mantener el contacto tres segundos sobre el pecho y las patas. En una consulta por enfermedad, la pastilla sigue el gesto hasta el hocico y el caniche reacciona al tomarla. La consulta de un caniche sano conserva los dos pasos de revisión. El coste sigue siendo de 30 monedas al completar la visita.

La versión 0.3.6 añade la peluquería 3D. El peine alisa el pelo, las tijeras aplican el corte elegido y el secador devuelve volumen. Cada herramienta progresa por separado en el flequillo, las orejas y el lomo. Se puede elegir un corte durante el peinado, incluidos los del catálogo como vista previa. Al terminar, el corte se guarda junto con el cuidado si ya está adquirido.

La versión 0.3.7 añade el descanso 3D. Al tocar la cama, el caniche se acomoda dentro del cojín. Un segundo toque despliega la manta sobre el cuerpo y deja la cabeza al descubierto. El interruptor atenúa el salón y la luz del modelo. El tiempo de descanso y su recompensa siguen las reglas del cuidado Dormir.

La versión 0.3.8 añade el paseo 3D. La cámara acompaña al caniche por el sendero de piedra y la pisada se articula por pata. En las flores, el banco y la fuente, el caniche espera a que el jugador toque la huella o el botón **Olfatear**, baja el hocico y habilita la siguiente parada cuando termina. Los minijuegos conservan sus escenas 2D.

La versión 0.3.9 añade Huerto Saltarín 3D. El visor lee la posición, los bancales, el estado del salto y las frutas recogidas de la simulación de paso fijo. El caniche reproduce el galope del rig y recoge seis tipos de fruta. El botón **Empezar** aparece al cargar la escena. Cada caída descuenta cinco segundos y conserva la fruta recogida. Frisbee sigue en 2D.

La versión 0.4.0 añade Frisbee 3D con 20 segundos de juego activo y hasta cinco lanzamientos. Casa, Armario, Adopción, Cuidados y las pantallas de resultados muestran un indicador mientras carga el visor. El pelaje mantiene un tinte uniforme incluso en las sombras y refleja la higiene por niveles. El caniche mueve la cabeza y la cola, jadea a intervalos y muestra gotas y una postura decaída según su estado. La cama tiene un borde más bajo y se reutiliza en el descanso de Casa. Cuello reúne pañuelos, lazos y los collares reajustados. El corte Osito tiene la coronilla más baja y las orejas más redondeadas. El corte de concurso se inspira en el Continental.

Las herramientas de cuidados se generaron con ImageGen integrado. El atlas final en `assets/images/props/care_tools.webp` usa ocho recortes con transparencia.

> Single transparent PNG sprite atlas for a polished cozy 3D poodle care game. Exactly nine separate everyday objects arranged as a rigid 3 by 3 grid with equal square cell sizes. Center each complete object inside its cell, generous empty transparent gutters of 15 percent, no overlaps, no shadow outside silhouettes. Row 1 (left to right): chrome handheld shower head with short downward handle, yellow rectangular bath sponge, plum and cream hair dryer with nozzle pointing left. Row 2: honey brown wide toothed grooming comb with teeth down, open stainless grooming scissors with plum handles and blades pointing left, silver and burgundy stethoscope composed into a loose upright oval with chestpiece at the bottom. Row 3: handheld walnut and brass magnifying glass with clear lens, single white and coral oval capsule, small sage green soft grooming brush. Style: hand-painted realistic game item artwork with physically convincing polished steel, translucent glass, warm highlights, visible material detail, high-contrast silhouettes appropriate at 48 px, consistent soft upper-left studio lighting and orthographic three-quarter view. No words, borders, numerals, decorations or people. Each cell has genuine transparent background.

```sh
blender -b docs/reviews/wardrobe-3d/My-Poodle-vestuario.blend --python-exit-code 1 \
  --python tool/arte/poc_3d/export_live.py -- assets/wardrobe_live/caniche.glb
node tool/arte/poc_3d/catalog_thumbnails.mjs
MY_POODLE_WARDROBE_PREVIEW=1 flutter build apk --release \
  --dart-define=POODLE_LIVE_3D=true --target-platform android-arm64 \
  --build-name 0.4.0 --build-number 18
```

Esta compilación usa el nombre **Vestuario 3D** y el identificador `com.betitoglez.mypoodle.wardrobepreview`. La partida de prueba queda en ese paquete, separado de la instalación habitual de My Poodle.

## Visor de imágenes prerenderizadas en Android

En esta compilación, **Vestuario 3D** abre directamente un visor local con los tres conjuntos, los dos peinados y las capturas de Blender. Además de las cinco vistas en reposo, se pueden probar los seis bucles de carrera o detenerse en sus poses de extensión y recogida.

```sh
blender -b docs/reviews/wardrobe-3d/My-Poodle-vestuario.blend --python-exit-code 1 \
  --python tool/arte/poc_3d/device_preview.py -- /tmp/mypoodle-device-renders
python3 tool/arte/poc_3d/pack_device_preview.py /tmp/mypoodle-device-renders assets/images/wardrobe_preview
MY_POODLE_WARDROBE_PREVIEW=1 flutter build apk --release \
  --target lib/main_wardrobe_preview.dart --target-platform android-arm64
```

La compilación de prueba usa `com.betitoglez.mypoodle.wardrobepreview` y arranca sin servicios de partida o compras. Puede convivir con la instalación de My Poodle.
