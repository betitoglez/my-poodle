# Producto y economía de la primera versión

## Alcance MVP vigente · 19-11-2026

Primera beta TestFlight con es/en/fr/de/pt-BR/it/ru/ko/ja/zh-Hans/zh-Hant, selector persistente y nombre localizado (Mi Caniche en español; My Poodle en inglés/respaldo). Modo foto con captura 3D y álbum privado local; una persona adulta puede copiar cada foto al carrete del móvil. Cada juego premium permite una partida gratuita cada 24 h por juego sin compra; el cupo se confirma al iniciar, se conserva al cerrar y no se consume si falla el guardado. La compra elimina el cupo de prueba; se mantienen energía y límites generales. Parejas, Simón de perritos y laberinto son propuestas por definir. Estas decisiones prevalecen sobre referencias históricas contradictorias.


Juego móvil con Flutter + Flame, caniche y vestuario 3D locales en iOS/Android, escenarios 2D y respaldo ilustrado. La apariencia combina piezas reutilizables; el crecimiento del catálogo no requiere imágenes completas por combinación. Guardado, economía y recursos son locales. Sin login, backend, nube ni publicidad. La descarga es gratuita y una única compra integrada desbloquea la versión completa (ver [Versión gratuita y versión completa](#versión-gratuita-y-versión-completa)).

## La primera sesión

En una instalación vacía, abrir Adopción y presentar el cachorro con su aspecto gratuito Albaricoque + corte Rizo natural. Tocar el campo «Nombre de tu caniche», abrir teclado, ofrecer «Sugerir nombre» (Nube, Miel, Coco) y confirmar con «Adoptar». Recortar extremos, normalizar Unicode NFC, contar de 1 a 16 grafemas y rechazar controles/saltos de línea. Desactivar formato enriquecido en el nombre mostrado. Conservar tildes y nombres compuestos. Un borrador cancelado nunca crea media mascota. La adopción confirmada crea una única partida con 0 monedas. Un segundo arranque abre Casa directamente.

En casa, tocar al perro hace que mire al jugador. Al poner el dedo en el salón, el caniche lo mira (en 3D gira la cabeza; en 2D se inclina hacia él) y vuelve al frente poco después de soltar. La tarjeta de bienestar sugiere atender la necesidad más baja. El jugador puede elegir otra actividad desde el menú. El primer objetivo es compartir una comida, completar un juego y probar el primer accesorio. Todas las actividades básicas están disponibles desde la adopción.

**Guía de la primera partida** (20-11-2026). Tras la pista de la caricia, Casa muestra una tarjeta con el siguiente paso: dar de comer, jugar y estrenar algo (un accesorio o una decoración). Cada paso se deduce del estado confirmado (comida registrada, primera partida terminada, artículo o decoración no inicial), así que no añade campos a la partida. «Saltar guía» la oculta para siempre (pista `guide.off`). Nunca bloquea ninguna actividad.

## Necesidades y paso del tiempo

| Medida | Inicial | Cambio por hora transcurrida | Acción de cuidado |
|---|---:|---:|---|
| Saciedad | 65 | −3 | Pienso +20; otras raciones, ver menú |
| Higiene | 70 | −2 | Baño +25, cepillado +8 |
| Ánimo | 75 | −2 | Paseo +15, juego terminado +8 |
| Energía | 80 | +4 | Paseo −5, juego −20; dormir +60 |

Propuesta de equilibrio para una mascota tipo Tamagotchi amable. Registrar minutos UTC y aplicar bloques completos de 15 minutos tanto durante la sesión como al volver. Usar valores internos en centésimas para que un cuarto de hora de hambre reste exactamente 0,75. Procesar como máximo 8 horas por ausencia, avanzar el cursor hasta el último cuarto procesable de la hora actual y descartar el exceso. Si el reloj retrocede, aplicar cero y conservar el cursor previo. Limitar todos los valores a 0–100 y redondear solo al presentar. Cerrar y abrir repetidamente dentro de un cuarto no acumula pérdidas. Con energía a cero solo puede dormir; los demás cuidados y juegos se bloquean hasta recuperar energía. El descanso en casa recupera energía según el reloj. Los mensajes sugieren cuidados sin castigar al niño por ausencias. Si hay empate en saciedad/higiene/ánimo, priorizar comida, baño y juego por ese orden. Para energía baja sugerir descansar.

## Estado de salud

La mascota puede ponerse **malita**. Se comprueba por bloque de 15 minutos (en sesión y al volver, con el mismo tope de ausencia) y solo si pasó una semana desde la última vez: máximo **una enfermedad cada 7 días** (604 800 s). La adopción cuenta como «hace 6 días», así que no enferma en el primer día. Probabilidad por bloque, sobre 10 000: azar de fondo 12; +250 si está hambriento (saciedad < 15), sucio (higiene < 15) o agotado (energía < 10). La tirada es determinista (misma partida e instante, mismo resultado, igual en móvil y web). Mientras está malito, el ánimo baja 0,5 por bloque adicional. Solo cura el veterinario con la pastilla; curar no reinicia el plazo de la semana.

**Indicadores del visor (estilo Tamagotchi).** Cinco iconos sobre la escena de Casa: malito, hambriento (saciedad < 30), sucio (higiene < 30), triste (ánimo < 30) y cansado (energía < 25). Los que aplican se encienden, laten y llevan «!»; el resto se apagan. Tocar cualquier icono, encendido o apagado, abre la actividad que lo resuelve (veterinario, comer, bañar, jugar, dormir). La sugerencia y el botón de Casa priorizan: malito, hambre, suciedad, tristeza, cansancio. Una barra de salud (Sano / Malito) acompaña a las cuatro necesidades. Los cinco paneles también son pulsables: saciedad → comida, higiene → baño, ánimo → juegos, energía → dormir y salud → veterinario. Un caniche malito se ve pálido y verdoso, tiembla un poco y muestra gotas de sudor.

## Cuidados

| Pantalla | Secuencia válida | Feedback y resultado |
|---|---|---|
| Dar de comer | Elegir una ración del menú, ofrecer tres bocados con toques sucesivos. Un toque mientras mastica no cuenta | El cuenco se vacía por tercios, el perro mastica y al tercer bocado gana saciedad |
| Bañar | Mantener ducha 5 s, frotar cabeza, lomo, patas y pecho, aclarar con ducha 5 s y secar con secador 5 s. Soltar detiene el tiempo de herramienta | Desplegar marcas de espuma por zona. Aclarar limpia la máscara y confirma higiene |
| Pasear | Seguir el sendero de tres paradas. Tocar las huellas o el destino, esperar la llegada y olfatear antes de habilitar la siguiente parada | Cámara acompaña al caniche y muestra 1/3, 2/3, 3/3. El último punto mejora ánimo y consume energía |
| Peluquería | Pasar peine, tijeras y secador por flequillo, orejas y lomo (nueve pasos); previsualizar el corte en espejo. El cuidado se confirma al terminar. Los cortes permanentes se adquieren o equipan aparte | Un mechón resuelto no vuelve a contar. Previsualizar nunca cambia inventario. Un corte nuevo usa el flujo de compra del armario |
| Dormir | Llevarlo a su cama (se acurruca), arroparlo con la manta y apagar la luz. Duerme unos segundos y despierta | Energía +60, ánimo +10. La luz solo se apaga con la manta puesta. Salir a medias no aplica nada |
| Veterinario | Escuchar el corazón, revisar las patas y, si está malito, darle la pastilla. Cada paso exige el instrumento y la zona indicados | Cuesta 30 monedas al completar. Seleccionar fonendo y mantenerlo en pecho 3 s; lupa sobre patas 3 s; si está enfermo, arrastrar pastilla a la boca. Sano: +5 de ánimo; malito: también cura |

Cada opción concreta de cuidado se puede completar una vez cada **15 minutos (900 s)** en ambas versiones. Cada ración, bebida o plan de baño tiene su propio plazo: pienso diario en espera no impide comida premium. Los cuidados sin opciones tienen un plazo por actividad. Se inicia al confirmar y se conserva al reiniciar. Los selectores muestran cuenta atrás al agotarse los usos disponibles. Los juegos gratuitos admiten tres inicios globales en una ventana móvil de 300 s; abandonar consume un inicio sin premio. La versión completa no tiene este cupo. Al alcanzarlo, la gratuita muestra el contador y ofrece comprar la completa mediante la puerta adulta.

Los cuidados no otorgan monedas. Antes de confirmar se puede salir sin modificar atributos. Si el proceso se cierra después de confirmar, la próxima sesión muestra el efecto ya aplicado. Un indicador al máximo no impide disfrutar de la animación.

## Menú de comidas

El coste y los efectos se guardan juntos al completar los tres bocados; salir antes no cobra ni mejora. Sin monedas o sin el derecho requerido, la ración queda bloqueada. El pienso sigue siendo gratuito. Fuente única de las raciones: `lib/domain/food.dart`.

| Ración | Monedas | Saciedad | Energía | Ánimo | Versión |
|---|---:|---:|---:|---:|---|
| Pienso diario | 0 | +20 | 0 | 0 | Gratuita |
| Comida premium | 10 | +40 | 0 | 0 | Gratuita |
| Salmón | 30 | +60 | +5 | +20 | Completa |
| Vegana | 15* | +10 | +20 | +5 | Completa |
| Tarta perruna | 25 | +5 | +10 | +60 | Completa |
| Hueso | 5 | +5 | 0 | +30 | Completa |

*Precio provisional de la vegana: el encargo no especifica precio. Ajustable en `Food.vegan` sin duplicar reglas en la interfaz. Todos los efectos se limitan a 100.

La higiene tiene cinco fases visuales: 64–52, 51–39, 38–26, 25–13 y 12–0. A 65 o más el pelaje se ve limpio. Cada fase añade manchas y mechones levantados. El recoloreado conserva facciones oscuras y el relieve del pelo; las piezas del armario se dibujan por anclajes, sin fragmentos del pelaje fuente.

## Versión gratuita y versión completa

Decisión del propietario del 17 de noviembre de 2026. Descarga gratuita con lo básico jugable para siempre. Una compra única, **«Versión completa»**, desbloquea el resto del contenido y las novedades futuras. Sin publicidad, suscripciones, venta de monedas, consumibles, cajas sorpresa, ofertas por tiempo ni temporizadores que se aceleren pagando.

| Gratis para siempre | Versión completa |
|---|---|
| Adopción, Casa, los cuatro ángulos del caniche y los seis cuidados (comer, bañar, pasear, peluquería, dormir y veterinario) | Todo lo gratuito |
| Salud, iconos de estado y sugerencias | **Huerto saltarín** (`fruit`) y los minijuegos que se añadan |
| **Frisbee en el prado** (`frisbee`) y sus monedas | Más colores, cortes por zonas, ropa y accesorios (catálogo empaquetado) |
| 23 artículos base o de catálogo gratuito, más los cortes por zonas correspondientes | Novedades de catálogo, escenarios y actividades futuras, sin volver a pagar |

**Artículos por versión** (IDs anteriores conservados; precios redondeados hacia arriba a múltiplos de 10):

| Ranura | Gratis | Versión completa |
|---|---|---|
| Color | coat.apricot, coat.silver, coat.zebra | coat.lightgray, coat.white, coat.black y los otros cinco colores especiales |
| Peinado | Natural, pompón y concurso por zona o pack | Osito, cachorro y moderno por zona o pack |
| Ropa | outfit.none y el peto en colores normales, incluidos azul, blanco y negro | Jersey, impermeable y vestido; los cuatro estampados especiales en todas las prendas |
| Cabeza | head.none, head.bow | head.beanie, head.crown |
| Ojos | eyes.none, eyes.round | eyes.sun, eyes.heart |
| Collares | collar.none, collar.tag | collar.bell, collar.pearls |
| Cuello | neck.none, neck.coral | neck.bowtie, neck.knit |
| Patucos | paws.none, paws.booties | paws.sneakers, paws.rain |

Los costes vigentes y derechos se validan contra `assets/data/balance-v1.json`; los cortes individuales se definen en `Haircuts`. Las compras anteriores siguen en propiedad, incluso al perder el derecho de versión completa.

**Reglas**

1. **Los cuidados y la salud nunca se bloquean.** Ninguna parte de la versión completa afecta a necesidades, salud ni a la velocidad del reloj. Un caniche nunca sufre por no pagar.
2. **Las monedas solo se ganan jugando.** La compra no da ni vende monedas, y los precios en monedas son iguales en las dos versiones.
3. **Contenido bloqueado visible y sin presión.** Los artículos y juegos de la versión completa aparecen con un candado y la etiqueta «Versión completa». En el armario se pueden probar en la vista previa sin coste, pero no comprarlos con monedas. La tarjeta del Huerto muestra el candado y no abre el juego.
4. **El adulto es quien compra.** Tocar un candado abre «Pide ayuda a un adulto». Desde ahí, la [puerta adulta](UI-UX.md#puerta-adulta) lleva a la pantalla Versión completa, que muestra lo que incluye, el precio que da la tienda, «Desbloquear» y «Restaurar compras». La pantalla también está en Ajustes → Zona adulta.
5. **Nunca se ofrece sin pedirlo.** Ni al arrancar, ni sobre un resultado o un premio, ni durante un cuidado o un juego, ni con avisos repetidos. La única puerta de entrada es que el jugador toque un candado o el adulto abra la pantalla.
6. **La compra es de la cuenta de la tienda, no de la partida.** Reiniciar la partida conserva la versión completa. En una reinstalación o en otro dispositivo, Android la recupera al arrancar con conexión e iOS con «Restaurar compras». En iOS se activa Compartir en familia.
7. **Sin conexión** se usa el último estado conocido. La versión gratuita funciona siempre offline. Comprar o restaurar necesita conexión. Si la tienda no responde, el botón dice «No disponible ahora. Inténtalo con conexión» y el juego sigue igual.
8. **Compra pendiente:** no se desbloquea nada hasta que la tienda confirme el pago. Android muestra «Esperando la aprobación» y reconcilia su estado. En iOS se permite enviar otra solicitud: StoreKit no notifica el rechazo de Ask to Buy, por lo que no se bloquea el botón esperando ese evento. La demostración conserva su estado de espera simulado.
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


## Parejas y Memory · ampliación del 20-11-2026

Parejas es gratuito, con tres niveles de 4/6/8 parejas, 60 segundos y cinco fallos permitidos; completar da 5/15/25 monedas. Memory requiere versión completa y no ofrece prueba diaria: cuatro colores/fotos/notas, secuencia inicial de tres pasos y máximo de diez, diez segundos para repetir la secuencia completa del turno y premio total de 5 a 40 (+5 por ronda completada). Al equivocarse o agotar tiempo se recibe el premio de la última ronda completada. Abandonar no paga. Los dos juegos reservan repartos aleatorios sin repetirlos tras reiniciar y conservan los límites generales de energía y descanso. [Reglas completas](JUEGOS.md#juego-de-parejas--20-11-2026).

## Decoración del salón · 20-11-2026

Segundo uso de las monedas, para cuando el armario ya está completo. Tres huecos en el salón de Casa: **Alfombra** (bajo el caniche), **Pared** y **Planta**. Cada hueco empieza vacío (artículo inicial gratuito) y tiene un artículo comprable de la versión gratuita; el resto son de la versión completa y se muestran con candado (tocar abre «Pide ayuda a un adulto»). Comprar sigue las reglas del armario: tocar una ficha solo previsualiza, «Comprar y colocar» cobra una vez y coloca, «Colocar» sobre algo en propiedad cuesta cero, si faltan monedas se muestra la diferencia y un acceso a Juegos. Una partida anterior carga con los tres huecos vacíos; un artículo desconocido o retirado vuelve al hueco vacío sin perder la partida.

| ID inmutable | Hueco | Coste | Versión |
|---|---|---:|---|
| rug.none / wall.none / plant.none | — | 0 inicial | gratuita |
| plant.fern | Planta | 35 | gratuita |
| rug.round | Alfombra | 40 | gratuita |
| wall.frame | Pared | 50 | gratuita |
| rug.stripes | Alfombra | 60 | completa |
| wall.garland | Pared | 70 | completa |
| plant.flowers | Planta | 80 | completa |
| rug.bone | Alfombra | 90 | completa |
| plant.cactus | Planta | 100 | completa |
| wall.stars | Pared | 110 | completa |

Totales: 125 monedas en la versión gratuita y 510 en la completa. Precios en `docs/datos/balance-v1.json` (bloque `decor`). En 3D la decoración se dibuja en la escena 2D, bajo el visor transparente del caniche.

**Ejemplo reproducible.** Con 40 monedas, «Comprar y colocar» la alfombra redonda deja 0 y la muestra tras reiniciar; volver a «Sin alfombra» y recolocarla cuesta 0. Con 39 monedas se indica que falta 1.

## Estrellas por partida · 20-11-2026

Cada partida terminada da de 0 a 3 estrellas además de las monedas, que no cambian. La tarjeta de cada juego muestra la mejor marca guardada (`bestStars`), y el resultado anuncia «¡Nueva mejor marca de estrellas!» cuando la supera. Umbrales en [Minijuegos](JUEGOS.md). Las estrellas solo son reto: no desbloquean nada ni cambian la economía.


## Ampliación de armario y presentación · 20-11-2026

- Peinados: submenús **Cabeza, Patas, Lomo, Cola y Packs**. Cada zona conserva su corte independiente. Cinco estilos comprables por zona (osito, pompón, cachorro, concurso y moderno), además del natural inicial. Cola incluye también **Corte estándar** uniforme sin pompón, gratuito en ambas versiones. Lomo y Cola se previsualizan de perfil. Cada pieza cuesta **50**, excepto concurso **100**. El pack cuesta la suma de sus cuatro piezas todavía no poseídas: 200/400 de base. Los packs antiguos conceden sus cuatro piezas al migrar.
- Colores de pelaje normales: coste redondeado hacia arriba a múltiplo de 10. Especiales **Cebra, Azul, Verde, Rojiblanco, Dálmata, Tigre**: primer especial 1000; cada especial adquirido aumenta un 20 % el precio del siguiente, redondeado hacia arriba a 10 (1000, 1200, 1440, 1730, 2080, 2490). Cebra se compra en gratuita; los otros cinco requieren completa. Reequipar algo adquirido es gratuito.
- Misma ropa por familias; colores normales azul, blanco y negro. Especiales **Cebra, Rojiblanco, Verdiblanco y Círculos de colores** (rojo, amarillo, verde y azul), exclusivos completos a **8 × coste normal de la familia** como precio base. Comprar un especial aumenta un 20 % los especiales restantes de esa misma familia y categoría, redondeados hacia arriba al múltiplo de 10: vestido, jersey, impermeable, peto y pelaje se cuentan por separado. Las compras normales no cuentan; las ya adquiridas se usan gratis. Accesorios redondeados hacia arriba a múltiplos de 10.
- El aviso «Probando» del Armario y Decoración se pliega al tocarlo: queda solo el ojo arriba a la derecha. Tocar el ojo recupera el texto sin cambiar la prueba pendiente.
- La peluquería cuida el peinado equipado y abre Armario para cambiarlo; desaparece Elegir corte. Los cuidados sin ropa conservan las cuatro zonas de pelo.
- Decoración: nueve ilustraciones realistas 2D con transparencia. El caniche de la pantalla de decoración usa el mismo visor 3D nativo que Casa. La guirnalda y las estrellas abarcan de extremo a extremo el ancho visible mediante nuevos tramos repetibles que mantienen su proporción: un ancho mayor añade adornos, sin estirarlos. Las estrellas tienen contorno LED luminoso en el recurso, también con movimiento reducido.
- Foto: arrastre horizontal del visor para girar sobre el eje vertical; el arrastre vertical no inclina. Se conservan las flechas. Acción **Álbum** con texto e icono arriba a la derecha.
- Parejas y Memory tienen portadas explicativas de sus mecánicas. Las descripciones y premios usan el icono de moneda; Parejas presenta una línea por nivel (4, 6 y 8 parejas) con icono en cada premio; la lectura accesible conserva la unidad escrita. Los submenús de cuidado muestran saldo arriba a la derecha.
- Ayuda y créditos comienza con «Juego desarrollado por Alberto González Cuenca». Idiomas muestran la bandera correspondiente.
- **Pendiente, solo TODO**: push con mal estado del perro, máximo dos al día y al menos ocho horas entre envíos.
