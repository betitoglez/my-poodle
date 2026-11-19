# Prompts y procedencia · piloto integrado

La revisión de espalda añade tres piezas. Los originales generados conservan el formato PNG y su transparencia.

## beanie-back

Entrada de silueta `assets/images/pet/back__head_beanie.webp` y referencia de estilo `assets/images/materials/beanie-front-v1.png`.
Recurso del juego `assets/images/materials/beanie-back-v1.png`.

Use case: precise-object-edit. Asset type: isolated rear-view transparent garment sprite for a 2D toy poodle game. Image 1 is the damaged REAR view, a silhouette and direction reference. Image 2 is the already approved FRONT view, used only for yarn, construction, lighting, textile color and continuity of identity. Back view of the same mustard yellow cable-knit puppy beanie. Rounded wool pompom, rounded cap, thick continuous curved ribbed hem wrapping around the lower back of head. Keep the proportions, golden color and tactile yarn of the reference. Rear hem should form a low gently curved cuff designed for the nape, without a forehead opening. Soft upper-left light and tactile illustrated realism. Keep only the isolated clothing, no mannequin, no dog, no fur, no paws, no head, no eyes, no background floor, no shadow outside the asset, no checkerboard or text. Clean genuine RGBA transparency all around, and generous transparent padding so no edge is cropped. Remove all fragments of the puppy and correct the holes left by the damaged extraction.

## sweater-back

Entrada de silueta `assets/images/pet/back__outfit_sweater_red.webp` y referencia de estilo `assets/images/materials/sweater-front-v1.png`.
Recurso del juego `assets/images/materials/sweater-back-v1.png`.

Use case: precise-object-edit. Asset type: isolated rear-view transparent garment sprite for a 2D toy poodle game. Image 1 is the damaged REAR view, a silhouette and direction reference. Image 2 is the already approved FRONT view, used only for yarn, construction, lighting, textile color and continuity of identity. Straight orthographic rear view of a tiny dog's red knitted sweater. Match the rear silhouette of the first reference: high ribbed neck at top, broad knitted back panel from neck down to the rump, two short side tubes for limbs, symmetrical cream double zigzag across lower body, matching red ribbed hems. Same warm red yarn, wool loops, highlights, thickness and stripes as second style reference. Make the entire body panel continuous knitted fabric with no circular hole in it; the game will draw the furry tail over the panel separately. Soft upper-left light and tactile illustrated realism. Keep only the isolated clothing, no mannequin, no dog, no fur, no paws, no head, no eyes, no background floor, no shadow outside the asset, no checkerboard or text. Clean genuine RGBA transparency all around, and generous transparent padding so no edge is cropped. Remove all fragments of the puppy and correct the holes left by the damaged extraction.

## bandana-back

Entrada de silueta `assets/images/pet/back__neck_coral.webp` y referencia de estilo `assets/images/materials/bandana-front-v1.png`.
Recurso del juego `assets/images/materials/bandana-back-v1.png`.

Use case: precise-object-edit. Asset type: isolated rear-view transparent garment sprite for a 2D toy poodle game. Image 1 is the damaged REAR view, a silhouette and direction reference. Image 2 is the already approved FRONT view, used only for yarn, construction, lighting, textile color and continuity of identity. Rear view of same tied coral-cotton dog bandana. Show a low horizontal curved strip of soft coral fabric wrapping across the back of the neck, a small knot just left of center, and two short fabric tails drooping diagonally to either side. Overall horizontal shape about three times as wide as high. The large triangular bib is around the front of the puppy and is not visible. Match the fabric folds, fine texture and coral of the second reference. Keep the continuous wrap visible from left to right, including under the knot. Soft upper-left light and tactile illustrated realism. Keep only the isolated clothing, no mannequin, no dog, no fur, no paws, no head, no eyes, no background floor, no shadow outside the asset, no checkerboard or text. Clean genuine RGBA transparency all around, and generous transparent padding so no edge is cropped. Remove all fragments of the puppy and correct the holes left by the damaged extraction.

Herramienta: `image_gen` integrada, modo edición con `transparent_background=true`. Se conservaron los originales generados y se copiaron los seis PNG finales al proyecto. Las imágenes de entrada son los recortes existentes de las prendas, usados como referencia de identidad y perspectiva.

La composición final, las sombras, la deformación por pose y la oclusión de pelaje se ejecutan en Flutter. Las capturas de esta carpeta proceden de ese pintor, no de imágenes generadas de perros vestidos.

## sweater-front

Entrada: `assets/images/pet/front__outfit_sweater_red.webp`.
Salida: `assets/images/materials/sweater-front-v1.png`.

Use case: background-extraction / precise-object-edit. Edit target: the supplied damaged transparent accessory cutout. Produce a clean production-ready 2D game accessory sprite. FRONT view of the red knitted puppy sweater with a rolled rib collar, two short front-leg sleeves and cream zigzag rows. Preserve the tactile wool stitches, subtle wrinkles, lighting and original three-dimensional tailoring. Remove EVERY trace of the orange puppy, fur, hair, skin, face, eyes, ears, body, legs or paws. Keep ONLY the garment itself on genuine transparent alpha. Fill the accidental holes and missing fabric in the reference naturally with matching stitches/cloth; preserve intentional collar and sleeve openings as transparent. Make clean soft natural textile edges with a few fine wool/cotton fibers, no outlines or sticker border. Same soft upper-left lighting and realistic softly illustrated style as the source. Keep its silhouette and proportions and viewing direction. Center the whole isolated garment with a little transparent padding, never crop any part of the garment or pompom/tails. No mannequin, no dog, no person, no text, no checkered background, no ground, no cast shadow outside the garment.

## sweater-side

Entrada: `assets/images/pet/side__outfit_sweater_red.webp`.
Salida: `assets/images/materials/sweater-side-v1.png`.

Use case: background-extraction / precise-object-edit. Edit target: the supplied damaged transparent accessory cutout. Produce a clean production-ready 2D game accessory sprite. RIGHT-FACING PROFILE view of the red knitted puppy sweater with a rolled rib collar, short front-leg sleeve, open rear and cream zigzag rows. Preserve the tactile wool stitches, subtle wrinkles, lighting and original three-dimensional tailoring. Remove EVERY trace of the orange puppy, fur, hair, skin, face, eyes, ears, body, legs or paws. Keep ONLY the garment itself on genuine transparent alpha. Fill the accidental holes and missing fabric in the reference naturally with matching stitches/cloth; preserve intentional collar and sleeve openings as transparent. Make clean soft natural textile edges with a few fine wool/cotton fibers, no outlines or sticker border. Same soft upper-left lighting and realistic softly illustrated style as the source. Keep its silhouette and proportions and viewing direction. Center the whole isolated garment with a little transparent padding, never crop any part of the garment or pompom/tails. No mannequin, no dog, no person, no text, no checkered background, no ground, no cast shadow outside the garment.

## beanie-front

Entrada: `assets/images/pet/front__head_beanie.webp`.
Salida: `assets/images/materials/beanie-front-v1.png`.

Use case: background-extraction / precise-object-edit. Edit target: the supplied damaged transparent accessory cutout. Produce a clean production-ready 2D game accessory sprite. FRONT view of the mustard yellow knitted beanie ONLY, including its soft round wool pompom and curved turned rib brim. The brim should curve up above the center forehead and down at the temples. Preserve wool loops, folds and rounded volume. Remove EVERY trace of the orange puppy, fur, hair, skin, face, eyes, ears, body, legs or paws. Keep ONLY the garment itself on genuine transparent alpha. Fill the accidental holes and missing fabric in the reference naturally with matching stitches/cloth; preserve intentional collar and sleeve openings as transparent. Make clean soft natural textile edges with a few fine wool/cotton fibers, no outlines or sticker border. Same soft upper-left lighting and realistic softly illustrated style as the source. Keep its silhouette and proportions and viewing direction. Center the whole isolated garment with a little transparent padding, never crop any part of the garment or pompom/tails. No mannequin, no dog, no person, no text, no checkered background, no ground, no cast shadow outside the garment.

## beanie-side

Entrada: `assets/images/pet/side__head_beanie.webp`.
Salida: `assets/images/materials/beanie-side-v1.png`.

Use case: background-extraction / precise-object-edit. Edit target: the supplied damaged transparent accessory cutout. Produce a clean production-ready 2D game accessory sprite. RIGHT-FACING PROFILE view of the mustard yellow knitted beanie ONLY, including its soft wool pompom and curved turned rib brim. Preserve the existing camera angle, wool loops, folds and rounded volume. Remove EVERY trace of the orange puppy, fur, hair, skin, face, eyes, ears, body, legs or paws. Keep ONLY the garment itself on genuine transparent alpha. Fill the accidental holes and missing fabric in the reference naturally with matching stitches/cloth; preserve intentional collar and sleeve openings as transparent. Make clean soft natural textile edges with a few fine wool/cotton fibers, no outlines or sticker border. Same soft upper-left lighting and realistic softly illustrated style as the source. Keep its silhouette and proportions and viewing direction. Center the whole isolated garment with a little transparent padding, never crop any part of the garment or pompom/tails. No mannequin, no dog, no person, no text, no checkered background, no ground, no cast shadow outside the garment.

## bandana-front

Entrada: `assets/images/pet/front__neck_coral.webp`.
Salida: `assets/images/materials/bandana-front-v1.png`.

Use case: background-extraction / precise-object-edit. Edit target: the supplied damaged transparent accessory cutout. Produce a clean production-ready 2D game accessory sprite. FRONT view of the coral peach puppy neckerchief ONLY, a softly draped triangular bandana with realistic curved cloth folds and small tied knot and tails at the right. Preserve the original folds, highlights and soft shadowed textile volume. Remove EVERY trace of the orange puppy, fur, hair, skin, face, eyes, ears, body, legs or paws. Keep ONLY the garment itself on genuine transparent alpha. Fill the accidental holes and missing fabric in the reference naturally with matching stitches/cloth; preserve intentional collar and sleeve openings as transparent. Make clean soft natural textile edges with a few fine wool/cotton fibers, no outlines or sticker border. Same soft upper-left lighting and realistic softly illustrated style as the source. Keep its silhouette and proportions and viewing direction. Center the whole isolated garment with a little transparent padding, never crop any part of the garment or pompom/tails. No mannequin, no dog, no person, no text, no checkered background, no ground, no cast shadow outside the garment.

## bandana-side

Entrada: `assets/images/pet/side__neck_coral.webp`.
Salida: `assets/images/materials/bandana-side-v1.png`.

Use case: background-extraction / precise-object-edit. Edit target: the supplied damaged transparent accessory cutout. Produce a clean production-ready 2D game accessory sprite. RIGHT-FACING PROFILE view of the coral peach puppy neckerchief ONLY, with its tied knot and tails toward the rear left, and its triangular point hanging down toward the front right. Preserve the original folds, highlights and soft shadowed textile volume. Remove EVERY trace of the orange puppy, fur, hair, skin, face, eyes, ears, body, legs or paws. Keep ONLY the garment itself on genuine transparent alpha. Fill the accidental holes and missing fabric in the reference naturally with matching stitches/cloth; preserve intentional collar and sleeve openings as transparent. Make clean soft natural textile edges with a few fine wool/cotton fibers, no outlines or sticker border. Same soft upper-left lighting and realistic softly illustrated style as the source. Keep its silhouette and proportions and viewing direction. Center the whole isolated garment with a little transparent padding, never crop any part of the garment or pompom/tails. No mannequin, no dog, no person, no text, no checkered background, no ground, no cast shadow outside the garment.
