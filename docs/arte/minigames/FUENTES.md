# Recursos de Parejas y Memory

Generados el 20-11-2026 con la herramienta integrada `image_gen` (ocho llamadas independientes). Se empaquetan en `assets/images/poodles/` como WebP de 512 px (calidad 85, 228 KB en total; los PNG originales de 1254 px sumaban 18 MB); no se descargan ni generan durante el juego. Inspección visual de los ocho retratos realizada antes de integrarlos.

Prompt común, con sustitución de `{subject}`:

```text
Use case: photorealistic-natural. Asset type: square portrait for a children's poodle matching card game. Subject: {subject}. A single real poodle, head and upper chest centered, looking at camera, friendly and natural. Soft pastel mint studio background, diffuse daylight, detailed realistic curly fur, clean uncluttered composition, recognizable at thumbnail size. No text, no border, no collars, no watermark.
```

Sujetos del conjunto final:

- `white.png`: a snow white toy poodle with a round teddy haircut.
- `black.png`: a jet black toy poodle with a classic curly haircut.
- `apricot.png`: an apricot toy poodle with long fluffy ears.
- `silver.png`: a silver gray miniature poodle with a neat continental haircut.
- `chocolate.png`: a chocolate brown miniature poodle with a puppy haircut.
- `red.png`: a deep red toy poodle with a fluffy round muzzle.
- `parti.png`: a white and black parti poodle with distinct black ears.
- `cream.png`: a cream poodle with a lamb haircut and soft long ears.

Memory reutiliza white, black, apricot y chocolate. Asociación fija para poder aprenderla: rojo/Do (261,63 Hz), azul/Mi (329,63 Hz), verde/Sol (392 Hz), amarillo/Do agudo (523,25 Hz). Audio original sintetizado con `tool/audio/generate_memory_tones.py`; cuatro WAV PCM mono de 0,42 s y 44,1 kHz, con ataque y salida suaves. Se respeta el ajuste Efectos; fotos, formas y resaltado permiten jugar sin sonido.
