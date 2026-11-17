# Recursos generados con Meshy

Generados el 17 de noviembre de 2026 con la API de Meshy (`POST /openapi/v1/image-to-image`, modelo `nano-banana-pro`, 9 créditos cada uno, 72 en total). Cada imagen parte de una ilustración de referencia del propietario en `docs/arte`, para mantener el estilo. Revisar los términos de uso de Meshy sobre derechos comerciales antes de publicar.

## Salas (`assets/images/rooms/`)

| Archivo | Referencia | Tarea | Edición pedida |
|---|---|---|---|
| `living.jpg` | `escenas.png` (salón) | `01a1e878-7e44-72f5-a8a7-a0c82f01b86d` | Quitar el caniche; alfombra centrada y suelo libre |
| `kitchen.jpg` | `escenas.png` (cocina) | `01a1e878-7e89-743f-a2f6-d832c1c9f3e4` | Quitar caniche y cuenco |
| `bath.jpg` | `escenas.png` (baño) | `01a1e878-7e95-75c0-97ff-97f610881745` | Quitar caniche, bañera, toalla y espuma (la bañera la dibuja el juego) |
| `salon.jpg` | `escenas.png` (peluquería) | `01a1e878-7e3c-70e0-8c4a-b7fecc292821` | Quitar caniche, cepillo, tijeras y espejo (el espejo con reflejo lo dibuja el juego) |
| `wardrobe.jpg` | `escenas.png` (vestidor) | `01a1e878-7e50-7590-b762-464c98c54dd5` | Quitar caniche. Recortado el 22,5 % inferior por una alfombra duplicada |
| `nursery.jpg` | `escenas.png` (cojín) | `01a1e878-7ea0-744c-8c76-eae584ea9c2a` | Quitar caniche y dejar el cojín vacío (Adopción) |

Todas en 3:4 y reducidas a 672 px de ancho. El punto de apoyo del caniche y su altura por sala están en `RoomArt.of` (`lib/game/scenes/room_painter.dart`).

## Piloto del caniche (`docs/arte/meshy/`, aún no usado en el juego)

| Archivo | Referencias | Tarea |
|---|---|---|
| `pet_front.png` | cuadrante del pañuelo de `armario.png` | `01a1e878-d3d6-740c-89e9-4f7c87a7e8ec` |
| `pet_side.png` | ese cuadrante + `caniche.png` (silueta) | `01a1e878-d385-742c-a9ac-f05402bb76de` |

Ambos con `remove_background: true` (PNG con transparencia), albaricoque, rizo natural, sin ropa. La comparación está en [docs/capturas/comparativa-meshy.jpg](../../capturas/comparativa-meshy.jpg).

## Piloto 2 · caniche por capas (17-nov-2026)

8 variantes `image-to-image` (`nano-banana-pro`, `remove_background`, 9 créditos cada una, **72 créditos**; saldo 860 → 788). Cada una parte de `pet_front` o `pet_side` sobre fondo gris y pide cambiar solo una cosa conservando pose, tamaño y encuadre.

| Variante | Tarea | Alineación con la base (IoU de silueta) |
|---|---|---|
| frente, corte pompón | `01a1e88d-b517-7191-8ce4-18e3ee2d5576` | 0,864 (cambia la silueta, esperado) |
| frente, peto verde | `01a1e88d-b56e-7724-8d53-bf268d3bd273` | 0,975 |
| frente, pañuelo coral | `01a1e88d-b579-766d-b575-5ec00eb393a2` | 0,974 |
| frente, ojos cerrados | `01a1e88d-b538-76b6-bd53-261eca961785` | 0,991 |
| frente, boca abierta | `01a1e88d-b57a-76ca-bd7d-58a078475d5b` | 0,991 |
| perfil, corte pompón | `01a1e88d-b51f-722f-a14d-d88f9899020e` | 0,842 (deriva de tono dorado) |
| perfil, peto verde | `01a1e88d-b585-7090-88af-6602536974ed` | 0,978 |
| perfil, salto | `01a1e88d-b52e-7157-989a-a4e7462426f4` | 0,642 (pose nueva, esperado) |

Procesado local (`tool/arte/meshy_layers.py`, sin créditos):

- **Pelaje plata**: matriz de color 4×5 (equivale a `ColorFilter.matrix` de Flutter) sobre la base albaricoque; ojos y nariz siguen oscuros.
- **Prendas como capas**: diferencia máxima por canal entre variante y base, apertura y cierre morfológicos; se quita el pelo anaranjado de la capa para que lo aporte la base teñida.
- **Corrección**: `defringe` elimina el halo del recorte; `match_color` iguala el tono medio del pompón con la base.

Las imágenes originales de los dos pilotos están en `originales/` (WebP). Comprobación visual: [16 combinaciones](../../capturas/meshy-16-combinaciones.jpg), [perfil y salto](../../capturas/meshy-capas-perfil.jpg), [plata por matriz](../../capturas/meshy-plata-matriz.jpg).

Limitaciones: el perfil con pompón conserva algo de deriva dorada; las expresiones son imágenes completas solo para el rizo natural; faltan pañuelo de perfil y las variantes del salto.

## Integración en el juego (17-nov-2026)

4 variantes más (36 créditos; saldo 788 → 752): pañuelo de perfil y salto con pompón, peto y pañuelo.

| Variante | Tarea |
|---|---|
| perfil, pañuelo | `01a1e89d-18e0-7737-94b8-b79fb2b8338f` |
| salto, pompón | `01a1e89d-18db-7060-b233-981131c2c836` |
| salto, peto | `01a1e89d-18dc-7659-adc9-76f43447ea03` |
| salto, pañuelo | `01a1e89d-18de-7243-b6dc-d2a6ef7eb486` |

`python3 tool/arte/build_pet_sprites.py` lee `tool/arte/pet_sprites_spec.json` y las imágenes de `originales/`, y genera `assets/images/pet/*.webp` (14 capas, 460 KB) y `assets/data/pet-sprites-v1.json` (lienzo, ancla y escala por pose, capas y matrices de color).

### Cómo ampliar el armario

| Quiero añadir | Qué hacer | Imágenes Meshy |
|---|---|---|
| Un color de pelo | Añadir su matriz 4×5 en `coats` del spec y el artículo en el balance | 0 (colores muy oscuros pueden necesitar base propia) |
| Un peinado | Generar la base en frente, perfil y salto a partir de las bases actuales y añadirla en `hair` | 3 |
| Una prenda, collar o accesorio | Generar la variante en las 3 poses (pidiendo conservar pose y encuadre) y añadirla en `items` | 3 |
| Otro color de una prenda | Teñir su capa con una matriz (pendiente de exponer en el spec) | 0 |
| Patucos con ropa a la vez | Nueva ranura `paws` en el dominio y el catálogo; capas por pose, y por peinado si chocan con los pompones | 3–6 |
