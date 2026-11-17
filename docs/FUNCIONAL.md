# Producto y economía de la primera versión

Juego móvil completamente 2D con Flutter + Flame: caniche, ropa, cortes, escenarios y minijuegos. La apariencia combina piezas reutilizables; el crecimiento del catálogo no requiere imágenes completas por combinación. Guardado, economía y recursos son locales. Sin login, backend, nube ni publicidad. La descarga es gratuita y una única compra integrada desbloquea la versión completa (ver [Versión gratuita y versión completa](#versión-gratuita-y-versión-completa)).

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

## Versión gratuita y versión completa

Decisión del propietario del 17 de noviembre de 2026. Descarga gratuita con lo básico jugable para siempre. Una compra única, **«Versión completa»**, desbloquea el resto del contenido y las novedades futuras. Sin publicidad, suscripciones, venta de monedas, consumibles, cajas sorpresa, ofertas por tiempo ni temporizadores que se aceleren pagando.

| Gratis para siempre | Versión completa |
|---|---|
| Adopción, Casa, los cuatro ángulos del caniche y los seis cuidados (comer, bañar, pasear, peluquería, dormir y veterinario) | Todo lo gratuito |
| Salud, iconos de estado y sugerencias | **Huerto saltarín** (`fruit`) y los minijuegos que se añadan |
| **Frisbee en el prado** (`frisbee`) y sus monedas | 24 artículos más del armario (lista abajo) |
| 18 artículos del armario: los 8 iniciales y 10 que se compran con monedas | Novedades de catálogo, escenarios y actividades futuras, sin volver a pagar |

**Artículos por versión** (los ID y los precios en monedas no cambian; la versión solo decide si se pueden comprar):

| Ranura | Gratis | Versión completa |
|---|---|---|
| Color | coat.apricot, coat.silver | coat.lightgray, coat.white, coat.black |
| Peinado | hair.natural, hair.pom | hair.teddy, hair.puppy |
| Ropa | outfit.none y el peto en sus tres colores (outfit.teal, outfit.overalls_red, outfit.overalls_yellow) | Jersey, impermeable y vestido en todos sus colores |
| Cabeza | head.none, head.bow | head.beanie, head.crown |
| Ojos | eyes.none, eyes.round | eyes.sun, eyes.heart |
| Collares | collar.none, collar.tag | collar.bell, collar.pearls |
| Cuello | neck.none, neck.coral | neck.bowtie, neck.knit |
| Patucos | paws.none, paws.booties | paws.sneakers, paws.rain |

Con la versión gratuita hay 190 monedas de artículos por conseguir, con algo comprable en cada pestaña del armario.

**Reglas**

1. **Los cuidados y la salud nunca se bloquean.** Ninguna parte de la versión completa afecta a necesidades, salud ni a la velocidad del reloj. Un caniche nunca sufre por no pagar.
2. **Las monedas solo se ganan jugando.** La compra no da ni vende monedas, y los precios en monedas son iguales en las dos versiones.
3. **Contenido bloqueado visible y sin presión.** Los artículos y juegos de la versión completa aparecen con un candado y la etiqueta «Versión completa». En el armario se pueden probar en la vista previa sin coste, pero no comprarlos con monedas. La tarjeta del Huerto muestra el candado y no abre el juego.
4. **El adulto es quien compra.** Tocar un candado abre «Pide ayuda a un adulto». Desde ahí, la [puerta adulta](UI-UX.md#puerta-adulta) lleva a la pantalla Versión completa, que muestra lo que incluye, el precio que da la tienda, «Desbloquear» y «Restaurar compras». La pantalla también está en Ajustes → Zona adulta.
5. **Nunca se ofrece sin pedirlo.** Ni al arrancar, ni sobre un resultado o un premio, ni durante un cuidado o un juego, ni con avisos repetidos. La única puerta de entrada es que el jugador toque un candado o el adulto abra la pantalla.
6. **La compra es de la cuenta de la tienda, no de la partida.** Reiniciar la partida conserva la versión completa. En una reinstalación o en otro dispositivo, Android la recupera al arrancar con conexión e iOS con «Restaurar compras». En iOS se activa Compartir en familia.
7. **Sin conexión** se usa el último estado conocido. La versión gratuita funciona siempre offline. Comprar o restaurar necesita conexión. Si la tienda no responde, el botón dice «No disponible ahora. Inténtalo con conexión» y el juego sigue igual.
8. **Compra pendiente** (aprobación familiar de iOS o pago pendiente en Play): se muestra «Esperando la aprobación» y no se desbloquea nada hasta que la tienda confirme el pago.
9. **Reembolso o revocación confirmados por la tienda:** vuelve a bloquear el Huerto y la compra de artículos de la versión completa. Los artículos ya comprados con monedas se conservan y se pueden seguir usando: nunca se le quita nada al caniche.
10. **Contenido nuevo.** Por defecto entra en la versión completa. También se puede añadir contenido gratuito a criterio del propietario, siguiendo estas mismas reglas.

**Precio.** Pago único de **1,99 €** en la zona euro y **1,99 US$** en Estados Unidos, impuestos incluidos. En las demás divisas se usa el equivalente de 1,99 € del día de configuración, redondeado al punto de precio más cercano que termine en **,49 o ,99**; si dos quedan a la misma distancia, se elige el más bajo. En divisas sin decimales (JPY, KRW, CLP, COP, HUF…) la terminación es 49 o 99 en la última cifra que admita la tienda (por ejemplo, 249 o 299). Si la tienda no ofrece ninguno, se usa el punto más cercano y se registra la excepción. La app muestra siempre el precio localizado que entrega la tienda, nunca un importe escrito en el código. Configuración y tabla aplicada en [ENTREGA](ENTREGA.md#compra-integrada-precios-y-fichas).

## Monedas y vestuario

Las monedas se ganan completando los minijuegos (con la versión gratuita, el frisbee). La función de recompensa está en [Minijuegos](JUEGOS.md). El cuenco, el baño, el parque, la consulta, la cama y el frisbee son gratuitos; el Huerto es de la versión completa. Saldo inicial 0. El primer premio perfecto de frisbee permite comprar el pañuelo de coral.

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

El armario empieza con los artículos iniciales en propiedad. Elegir una categoría y una ficha actualiza la previsualización en una copia del aspecto. «Comprar y usar» muestra coste y saldo restante. Confirmar valida saldo, propiedad y ranura y guarda en una operación. «Usar» sobre un artículo en propiedad cuesta cero. Volver o cancelar restaura el aspecto anterior. Se pueden combinar todas las ranuras. Reemplazar una ranura conserva las demás. Si faltan monedas, mostrar la diferencia exacta y un acceso a Juegos. Un artículo de la versión completa sin la compra se puede probar en la vista previa, pero muestra el candado en lugar de «Comprar y usar». Reabrir el armario conserva la propiedad de artículos desequipados.

**Ejemplo reproducible.** Adoptar a Miel, terminar un frisbee con tres aciertos (12 monedas), comprar el pañuelo (quedan 2), equipar cuello libre y volver a equipar el pañuelo (siguen quedando 2). Un nuevo dispositivo comienza por Adopción.
