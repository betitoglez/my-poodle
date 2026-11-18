# Prompts y procedencia · piloto integrado

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

