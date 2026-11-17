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

## Poses, atrezo y escenas (17-nov-2026)

24 imágenes, **216 créditos** (saldo 752 → 536): 10 en la primera tanda, 13 variantes alineadas y 1 repetición (`eat_pom` salió de pie la primera vez; se repitió solo con la pose de referencia).

| Imagen | Tarea |
|---|---|
| `eat_natural` | `01a1e8b7-bb01-74e1-bb54-199020c3c713` |
| `messy_natural` | `01a1e8b7-bb07-7542-a3f8-f9602fb1cc5e` |
| `messy_pom` | `01a1e8b7-bb00-73b4-8152-0dedf546076a` |
| `prop_bowl_full` | `01a1e8b7-bb01-7077-a556-eb2592d4f3c8` |
| `prop_foam` | `01a1e8b7-bb0a-708e-af20-1e0f07d09248` |
| `prop_tub` | `01a1e8b7-bb05-774e-9a1f-f935470bcb36` |
| `room_salon2` | `01a1e8b7-baff-74f6-a7e9-19f33ee3322b` |
| `run_gather` | `01a1e8b7-bb07-77fd-919f-843b5b549885` |
| `run_reach` | `01a1e8b7-bb03-759e-9e7f-e903ac441bcf` |
| `sleep_natural` | `01a1e8b7-bb12-7460-9c95-e3e445889264` |
| `bowl_empty` | `01a1e8ba-9219-70f8-9677-bb8c35bd2d45` |
| `eat_overalls` | `01a1e8ba-9228-76f7-bd50-508c4c41b3aa` |
| `eat_pom (primera versión, descartada)` | `01a1e8ba-924f-730b-82d1-868925b06e73` |
| `eat_scarf` | `01a1e8ba-921e-703b-9b0a-b39a8fbc5550` |
| `run_gather_overalls` | `01a1e8ba-9231-7509-bad5-98bd99b9eff7` |
| `run_gather_pom` | `01a1e8ba-9232-7725-b19e-d9516bb53e32` |
| `run_gather_scarf` | `01a1e8ba-921b-77be-b87c-9e0ff3450c68` |
| `run_reach_overalls` | `01a1e8ba-9219-7581-9802-eacf5f4624ac` |
| `run_reach_pom` | `01a1e8ba-922a-700b-8b7f-1589a1e35b14` |
| `run_reach_scarf` | `01a1e8ba-9221-7379-85af-3a8b146b43a3` |
| `sleep_overalls` | `01a1e8ba-922f-74fd-ac57-219ebca0da9c` |
| `sleep_pom` | `01a1e8ba-9230-72a6-8720-9908d8a1fec7` |
| `sleep_scarf` | `01a1e8ba-9229-77ee-9d1a-c66441beb967` |
| `eat_pom` (repetida, la que se usa) | `01a1e8c1-be93-725e-bbe0-846e02201115` |

- **Poses nuevas del atlas:** `eat` (cabeza al cuenco), `sleep` (tumbado), `run_a` y `run_b` (zancadas). El galope recorre `run_b → run_a → jump`; el trote del paseo alterna perfil y zancadas.
- **Estado `messy`** (despeinado) por peinado en la pose frontal: el juego lo muestra solo alrededor de cada mechón pendiente y lo desvanece al cepillar.
- **Referencias del cuerpo:** el script calcula por pose ojos, boca, cuello, pecho, costados, hombros, orejas, cabeza y patas, y las guarda en `pet-sprites-v1.json`. Baño, peluquería y frisbee colocan espuma, marcas y disco con ellas, así que se recolocan solas con arte nuevo.
- **Atrezo** (`assets/images/props/`): bañera (se parte en fondo y frente al 17 % de su altura, por el labio), grupo de espuma, cuenco lleno y vacío (la comida se recorta por tercios).
- **Peluquería** (`rooms/salon.jpg`): nueva sala que conserva el espejo; su cristal está anotado en `RoomArt` y el reflejo es el caniche de perfil. Tiene un tono más amarillo que las otras salas.

## Sesión 2026-11-17 · Salud, veterinario, dormir y armario ampliado

Todas con `image-to-image` y el modelo `nano-banana-2-lite` (3 créditos por imagen), que alineó igual de bien que `nano-banana-pro` en las pruebas (IoU 0,97–0,99). Resumen: pruebas de modelo 6 tareas (27 créditos), lote principal 66 tareas (198), correcciones de manta y consulta del veterinario 4 tareas (12). Total **237 créditos** (saldo 536 → 299). Referencias sobre fondo gris; las capas de cada artículo se extraen por diferencia con la variante.

**Cómo añadir un artículo:** generar el caniche con la pieza puesta en cada pose, guardar el original en `docs/arte/meshy/originales/`, añadirlo a `tool/arte/pet_sprites_spec.json`, ejecutar `python3 tool/arte/build_pet_sprites.py` (unos 3 min), dar de alta el artículo en `docs/datos/balance-v1.json` y `assets/data/balance-v1.json` (idénticos), en `assets/data/appearance-v1.json` y ejecutar `dart run tool/validate_content.dart`. Los colores de una misma prenda no se generan: son variantes de tono (`variants` del atlas) de una sola capa.

| Pieza | Tarea |
|---|---|
| `t_ov_21` | `01a1e928-2cc8-77e0-8290-a5afdb397022` |
| `t_gl_21` | `01a1e928-2f86-755c-9a79-a3eec31e7f49` |
| `t_back_21` | `01a1e928-325a-71bc-8be6-e1285abbf1fc` |
| `t_ov_lite` | `01a1e928-2da4-7377-a354-85193aaed68f` |
| `t_gl_lite` | `01a1e928-30c7-75f3-b4ce-3f12d83dea45` |
| `t_back_pro` | `01a1e928-33f4-777a-af69-344ae7efbfa2` |
| `puppy_back` | `01a1e929-c643-7271-a7b4-d0958192b8ee` |
| `puppy_front` | `01a1e929-c2b6-75e0-b4f5-788d0f745740` |
| `sweater_back` | `01a1e929-cc76-73c5-95c6-4195a87cb80d` |
| `teddy_side` | `01a1e929-be59-710d-acda-9ba13aef2f5e` |
| `teddy_sleep` | `01a1e929-c117-7297-8e4e-7456619b8527` |
| `puppy_sleep` | `01a1e929-c7e4-76fb-b443-e4cde7f6d71b` |
| `sweater_side` | `01a1e929-cafa-73c0-993f-383b8ded056b` |
| `back_pom` | `01a1e929-bb66-73c6-8712-c5f10c8cd48c` |
| `teddy_back` | `01a1e929-bfa0-7587-8598-e30fb422d681` |
| `puppy_side` | `01a1e929-c4a8-7593-b437-5e836336f672` |
| `teddy_front` | `01a1e929-bcba-7367-971b-12dfff4958d0` |
| `raincoat_front` | `01a1e92a-1a51-7674-bc82-e1d7892b118d` |
| `raincoat_back` | `01a1e92a-1e27-71fa-a2e1-f87cfe4cb352` |
| `dress_back` | `01a1e92a-2a2c-737c-896b-f36b0a2b17ee` |
| `overalls_back` | `01a1e92a-3247-75a8-b6b7-2de6affb3c3e` |
| `head_bow_side` | `01a1e92a-39c2-770c-8081-0f39516d46ba` |
| `head_bow_back` | `01a1e92a-441c-74fa-a5d4-dfb752f504a5` |
| `raincoat_side` | `01a1e92a-1d49-73fd-a5f8-690709071301` |
| `head_beanie_front` | `01a1e92a-4bab-7112-914a-91559bafec7b` |
| `head_bow_front` | `01a1e92a-3531-7183-9d89-d9bb6e128fa0` |
| `dress_front` | `01a1e92a-202d-77d3-bbcd-646dc835f3b3` |
| `dress_side` | `01a1e92a-27bd-77a7-933b-6c76e1ce7dc8` |
| `sweater_front` | `01a1e929-c911-74ff-a9c3-105ac81e033b` |
| `head_crown_side` | `01a1e92a-7e5e-725c-9656-0fbe9bf8f839` |
| `head_beanie_back` | `01a1e92a-6af5-715f-a2f1-4353e448f424` |
| `head_crown_back` | `01a1e92a-8600-732c-8cd5-37e377c7a905` |
| `eyes_sun_front` | `01a1e92a-959f-703e-8ce5-63235955f91f` |
| `eyes_heart_front` | `01a1e92a-97e4-7098-a43c-7c6cf1d8e2c5` |
| `eyes_sun_side` | `01a1e92a-976d-72a2-b839-28f92cee4de5` |
| `eyes_heart_side` | `01a1e92a-98a7-7112-a59c-536c4558e37d` |
| `head_crown_front` | `01a1e92a-7c37-772b-83cd-69b04ec32db5` |
| `eyes_round_side` | `01a1e92a-9394-7085-a6c1-5fd381cbbafc` |
| `head_beanie_side` | `01a1e92a-67cb-74e4-a47a-acfd00d7ea05` |
| `collar_tag_front` | `01a1e92a-a9f3-7673-b87b-c4bf6276a3ec` |
| `collar_tag_back` | `01a1e92a-c9f9-7277-980d-fec325825fca` |
| `collar_bell_front` | `01a1e92a-ce3f-760a-9c02-9ba5d37341d4` |
| `collar_bell_side` | `01a1e92a-d5de-7705-906e-87bd3b057284` |
| `collar_bell_back` | `01a1e92a-e7f5-73a3-926f-a36ffd7b2bff` |
| `collar_pearls_side` | `01a1e92a-e95e-7279-b646-cf9f95b33510` |
| `collar_pearls_back` | `01a1e92a-e967-708e-a1e5-e4a06c9ef9e4` |
| `collar_pearls_front` | `01a1e92a-e95b-717c-9497-d0441022e938` |
| `neck_bowtie_front` | `01a1e92a-f489-77f6-bb79-008ceb5b8ad1` |
| `collar_tag_side` | `01a1e92a-c760-7047-b927-ea4c9d66613c` |
| `neck_knit_back` | `01a1e92b-1b2d-71c4-bd8a-9e9a4d1c153a` |
| `neck_bowtie_side` | `01a1e92a-f590-7622-a056-7e9da8fa7325` |
| `neck_bowtie_back` | `01a1e92a-f614-714c-b8ff-046bae8165bb` |
| `neck_knit_side` | `01a1e92b-1aad-716f-be4f-69d2a559a1d4` |
| `paws_booties_front` | `01a1e92b-3816-755a-a4cd-a32a1cf1535e` |
| `neck_knit_front` | `01a1e92b-0c52-7439-99de-c1a22da15b62` |
| `paws_sneakers_side` | `01a1e92b-45b7-7281-910b-9f2a84411de0` |
| `paws_sneakers_back` | `01a1e92b-4750-726b-acc1-7bfc1808c604` |
| `neck_coral_back` | `01a1e92b-215b-7775-8870-77c13cd85f11` |
| `paws_booties_side` | `01a1e92b-3b98-75ad-87cf-4f9c90f22fd9` |
| `paws_booties_back` | `01a1e92b-3cc9-7699-9dc8-57911c568974` |
| `paws_rain_back` | `01a1e92b-72d2-70f5-90c8-920ab3372115` |
| `paws_rain_side` | `01a1e92b-72ce-7636-b6fa-3ecb2796f7e2` |
| `prop_bed` | `01a1e92b-80a3-740b-9784-368247995932` |
| `prop_blanket` | `01a1e92b-841b-7463-9a1f-5621f38cdbea` |
| `room_vet` | `01a1e92b-8ef5-7053-ba16-f4258324ed2c` |
| `icon_hungry` | `01a1e92b-9314-73bf-8e35-37c49e96877e` |
| `icon_dirty` | `01a1e92b-92d9-7460-8f67-487ed60db079` |
| `paws_sneakers_front` | `01a1e92b-3deb-731c-ae88-3c898e442496` |
| `icon_sad` | `01a1e92b-997a-710b-a85e-70a887bdecdf` |
| `icon_sick` | `01a1e92b-b400-7212-863d-6152b2b98f8d` |
| `paws_rain_front` | `01a1e92b-6abf-70d1-bca3-f2465e588ea8` |
| `icon_tired` | `01a1e92b-b48c-75da-a918-58fd41c251a6` |
| `prop_blanket_v1` | `01a1e92d-b7a4-759f-a989-f60c6646d141` |
| `prop_blanket_v2` | `01a1e92d-ba88-72ce-aab5-5ade1c650fc1` |
| `room_vet_v2` | `01a1e92d-bbcc-71ff-ba68-04303e1ca4ea` |
| `room_vet_v1` | `01a1e92d-b8fd-7320-b145-7fb35bec55cd` |
