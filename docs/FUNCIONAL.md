# Producto y economía de la primera versión

Juego móvil completamente 2D con Flutter + Flame: caniche, ropa, cortes, escenarios y minijuegos. La apariencia combina piezas reutilizables; el crecimiento del catálogo no requiere imágenes completas por combinación. Guardado, economía y recursos son locales. Sin login, backend, nube ni compras integradas.

## La primera sesión

En una instalación vacía, abrir Adopción y presentar el cachorro con su aspecto gratuito Albaricoque + corte Rizo natural. Tocar el campo «Nombre de tu caniche», abrir teclado, ofrecer «Sugerir nombre» (Nube, Miel, Coco) y confirmar con «Adoptar». Recortar extremos, normalizar Unicode NFC, contar de 1 a 16 grafemas y rechazar controles/saltos de línea. Desactivar formato enriquecido en el nombre mostrado. Conservar tildes y nombres compuestos. Un borrador cancelado nunca crea media mascota. La adopción confirmada crea una única partida con 0 monedas. Un segundo arranque abre Casa directamente.

En casa, tocar al perro hace que mire al jugador. La tarjeta de bienestar sugiere atender la necesidad más baja. El jugador puede elegir otra actividad desde el menú. El primer objetivo es compartir una comida, completar un juego y probar el primer accesorio. Todas las actividades básicas están disponibles desde la adopción.

## Necesidades y paso del tiempo

| Medida | Inicial | Cambio por hora transcurrida | Acción de cuidado |
|---|---:|---:|---|
| Saciedad | 65 | −3 | Una comida completa +20 |
| Higiene | 70 | −2 | Baño +25, cepillado +8 |
| Ánimo | 75 | −2 | Paseo +15, juego terminado +8 |
| Energía | 80 | +4 | Paseo −5, juego terminado −6 |

Propuesta de equilibrio para una mascota tipo Tamagotchi amable. Registrar minutos UTC y aplicar bloques completos de 15 minutos tanto durante la sesión como al volver. Usar valores internos en centésimas para que un cuarto de hora de hambre reste exactamente 0,75. Procesar como máximo 8 horas por ausencia, avanzar el cursor hasta el último cuarto procesable de la hora actual y descartar el exceso. Si el reloj retrocede, aplicar cero y conservar el cursor previo. Limitar todos los valores a 0–100 y redondear solo al presentar. Cerrar y abrir repetidamente dentro de un cuarto no acumula pérdidas. La mascota siempre puede jugar, pasear y recuperarse. El descanso en casa recupera energía según el reloj. Los mensajes sugieren cuidados sin castigar al niño por ausencias. Si hay empate en saciedad/higiene/ánimo, priorizar comida, baño y juego por ese orden. Para energía baja sugerir descansar.

## Estado de salud

La mascota puede ponerse **malita**. Se comprueba por bloque de 15 minutos (en sesión y al volver, con el mismo tope de ausencia) y solo si pasó una semana desde la última vez: máximo **una enfermedad cada 7 días** (604 800 s). La adopción cuenta como «hace 6 días», así que no enferma en el primer día. Probabilidad por bloque, sobre 10 000: azar de fondo 12; +250 si está hambriento (saciedad < 15), sucio (higiene < 15) o agotado (energía < 10). La tirada es determinista (misma partida e instante, mismo resultado, igual en móvil y web). Mientras está malito, el ánimo baja 0,5 por bloque adicional. Solo cura el veterinario con la pastilla; curar no reinicia el plazo de la semana.

**Indicadores del visor (estilo Tamagotchi).** Cinco iconos sobre la escena de Casa: malito, hambriento (saciedad < 30), sucio (higiene < 30), triste (ánimo < 30) y cansado (energía < 25). Los que aplican se encienden, laten y llevan «!»; el resto se apagan. Tocar uno encendido abre la actividad que lo resuelve (veterinario, comer, bañar, jugar, dormir). La sugerencia y el botón de Casa priorizan: malito, hambre, suciedad, tristeza, cansancio. Una barra de salud (Sano / Malito) acompaña a las cuatro necesidades. Un caniche malito se ve pálido y verdoso, tiembla un poco y muestra gotas de sudor.

## Cuidados

| Pantalla | Secuencia válida | Feedback y resultado |
|---|---|---|
| Dar de comer | Elegir el cuenco gratuito, ofrecer tres bocados con toques sucesivos. Un toque mientras mastica no cuenta | El cuenco se vacía por tercios, el perro mastica y al tercer bocado gana saciedad |
| Bañar | Mojar, enjabonar tres zonas distintas (lomo, patas, pecho), aclarar. Se puede tocar cada zona o pasar la esponja sobre ella | Desplegar marcas de espuma por zona. Aclarar limpia la máscara y confirma higiene |
| Pasear | Seguir el sendero de tres paradas. Tocar las huellas o el destino, esperar la llegada y olfatear antes de habilitar la siguiente parada | Cámara acompaña al caniche y muestra 1/3, 2/3, 3/3. El último punto mejora ánimo y consume energía |
| Peluquería | Cepillar tres mechones, previsualizar el corte en espejo. El cepillado gratuito se confirma al terminar. Los cortes permanentes se adquieren o equipan aparte | Un mechón resuelto no vuelve a contar. Previsualizar nunca cambia inventario. Un corte nuevo usa el flujo de compra del armario |
| Dormir | Llevarlo a su cama (se acurruca), arroparlo con la manta y apagar la luz. Duerme unos segundos y despierta | Energía +45, ánimo +3. La luz solo se apaga con la manta puesta. Salir a medias no aplica nada |
| Veterinario | Escuchar el corazón, revisar las patas y, si está malito, darle la pastilla. Cada paso exige el instrumento y la zona indicados | Sano: dos pasos, +5 de ánimo. Malito: tres pasos, recupera la salud y +5 de ánimo |

Los cuidados no otorgan monedas. Antes de confirmar se puede salir sin modificar atributos. Si el proceso se cierra después de confirmar, la próxima sesión muestra el efecto ya aplicado. Un indicador al máximo no impide disfrutar de la animación.

## Monedas y vestuario

Las monedas se ganan completando los dos minijuegos. La función de recompensa está en [Minijuegos](JUEGOS.md). El cuenco, el baño, el parque, la consulta y los juegos son gratuitos. Saldo inicial 0. El primer premio perfecto de frisbee permite comprar el pañuelo de coral.

| ID inmutable | Categoría / ranura | Coste | Representación |
|---|---|---:|---|
| coat.apricot | Color | 0 inicial | Pelaje albaricoque |
| coat.silver | Color | 24 | Pelaje gris plata |
| hair.natural | Peinado | 0 inicial | Rizo natural |
| hair.pom | Peinado | 30 | Corte pompón con tobillos y corona |
| outfit.none | Ropa | 0 inicial | Sin prenda |
| outfit.teal | Ropa | 18 | Peto verde de pana |
| neck.none | Artículo de cuello | 0 inicial | Cuello libre |
| neck.coral | Artículo de cuello | 10 | Pañuelo coral |

**Ampliación del catálogo** (42 artículos, ocho ranuras; los ID y precios originales no cambian, y una partida anterior sigue cargando con las ranuras nuevas vacías). El precio sube de un artículo al siguiente dentro de cada categoría. Categorías del armario: **Colores** (albaricoque, plata, gris claro, blanco, negro), **Peinados** (rizo natural, pompón, osito, cachorro), **Ropa** (peto, jersey, impermeable, vestido; **todos los colores de una misma prenda cuestan lo mismo**, el precio lo marca el tipo de prenda: peto 18, jersey 32, impermeable 46, vestido 64) y **Accesorios** con submenús **Cabeza**, **Ojos**, **Collares**, **Cuello** y **Patucos**. El caniche se puede girar con el control «De frente / Lado derecho / De espaldas / Lado izquierdo» en Casa y en el armario. Los precios exactos son los de `docs/datos/balance-v1.json`.

El armario empieza con los artículos iniciales en propiedad. Elegir una categoría y una ficha actualiza la previsualización en una copia del aspecto. «Comprar y usar» muestra coste y saldo restante. Confirmar valida saldo, propiedad y ranura y guarda en una operación. «Usar» sobre un artículo en propiedad cuesta cero. Volver o cancelar restaura el aspecto anterior. Se pueden combinar todas las ranuras. Reemplazar una ranura conserva las demás. Si faltan monedas, mostrar la diferencia exacta y un acceso a Juegos. Reabrir el armario conserva la propiedad de artículos desequipados.

**Ejemplo reproducible.** Adoptar a Miel, terminar un frisbee con tres aciertos (12 monedas), comprar el pañuelo (quedan 2), equipar cuello libre y volver a equipar el pañuelo (siguen quedando 2). Un nuevo dispositivo comienza por Adopción.
