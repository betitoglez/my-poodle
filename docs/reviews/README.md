# Revisión de cuidados, balance y arte · 17-11-2026

Implementación en `feat/interactive-care`, basada en `fb4a500`. Identificador Android/iOS: `com.betitoglez.mypoodle`. No se ha generado un build de distribución ni probado esta revisión en móvil. El clon original tiene cambios sin commit en main: integrar primero esos cambios y rebasear esta rama antes del build.

## Cambios comprobados

- Paneles e iconos de estado pulsables, incluso con necesidades altas. Energía abre Dormir; ánimo abre Juegos. Energía cero bloquea los demás cuidados y los juegos.
- Cada cuidado se completa una vez por 300 segundos; todas las comidas comparten plazo. Tres inicios de minijuego en ventana móvil de 300 segundos, compartidos entre juegos. Abandonar consume una partida, sin premio. Ambos límites sobreviven al reinicio; partidas antiguas cargan con los campos nuevos vacíos.
- Menú con seis raciones. Pienso gratis (+20 saciedad), premium 10 monedas (+40 saciedad); salmón 30 (+60 saciedad/+5 energía/+20 ánimo), vegana 15 provisional (+10 saciedad/+20 energía/+5 ánimo), tarta 25 (+5 saciedad/+10 energía/+60 ánimo), hueso 5 (+5 saciedad/+30 ánimo). Las cuatro últimas requieren versión completa. Cobro y efectos en una escritura al terminar los bocados. **El encargo no especifica precio de la vegana: 15 es una decisión provisional**, centralizada en `lib/domain/food.dart`.
- Baño: ducha mantenida cinco segundos, esponja en cabeza/lomo/pecho/patas, aclarado cinco segundos y secador cinco segundos. Soltar la herramienta detiene el avance. Marcas y espuma por zona.
- Peluquería: peine, tijeras y secador, cada uno en flequillo, orejas y lomo. Herramienta visible siguiendo al dedo y alternativas accesibles por zona.
- Veterinario: 30 monedas al completar. Fonendo en el pecho tres segundos, lupa en las patas tres segundos y arrastrar pastilla a la boca si está enfermo. Una revisión sana no necesita pastilla.
- Dormir +60 energía/+10 ánimo. Cuerpo reducido sobre el cojín, borde de cama por delante; manta de punto recortada con el alfa del cuerpo, con la cara fuera de la zona cubierta.
- Jugar −20 energía/−10 saciedad. Frisbee con cinco lanzamientos. Huerto con seis frutas, césped, raíces, tierra estratificada y bancales; cada caída descuenta cinco segundos adicionales una sola vez.
- Recoloreado del pelaje en isolate, preparado bajo demanda y con caché de 48 capas; conserva detalles oscuros, microtextura y bordes premultiplicados. Paletas con sombras y luces. Accesorios escalables por anclajes que sustituyen los recortes con fragmentos de pelo. Ropa/accesorios ya no fuerzan perfil estático al correr. Los cortes sin galope propio articulan las patas; los que no tienen pose de comida combinan cuerpo inclinado y cabeza propia.
- Cinco fases visuales de suciedad y desaliño: higiene 64–52, 51–39, 38–26, 25–13, 12–0. Limpio desde 65.

## Evidencias

- Suite completa: **143 pruebas correctas** (`flutter test --no-pub`). Comprobación posterior de pintor, catálogo y composiciones: **10 pruebas correctas**. Comprobación posterior de textura de manta: tres pruebas de composición.
- `flutter analyze --no-pub`: sin incidencias.
- `dart run tool/validate_content.dart`: contenido válido; `git diff --check`: sin errores.
- [Catálogo, colores, cortes, accesorios, fases y carrera](catalogue.png).
- [Comida: hocico y borde delantero del recipiente](feed.png).
- [Sueño: cuerpo, manta y cama](sleep.png).
- [Huerto: suelo, caniche y frutas](orchard.png).

Para regenerar los PNG desde el pintor real: `POODLE_REVIEW=1 flutter test --no-pub test/game/appearance_review_test.dart test/ui/care_composition_review_test.dart`. Las capturas del motor son evidencia visual local; no sustituyen la prueba de fluidez y gestos en dispositivo.
