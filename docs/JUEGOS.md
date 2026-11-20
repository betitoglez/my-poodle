# Minijuegos y nuevos juegos

## Acceso y próximos juegos · 19-11-2026

Huerto ofrece una partida gratuita cada 24 h a jugadores sin la compra. Guardar la reserva junto al inicio confirmado; no consumir en instrucciones ni por un fallo de escritura. Abandonar sí consume. Memory de caniches requiere la versión completa sin prueba diaria, por decisión explícita del propietario del 20-11-2026. Parejas y Frisbee son gratuitos. Todos conservan los límites generales de energía y tres inicios por cinco minutos. Laberinto continúa por definir.


## Contrato común

GameDefinition contiene ID estable, título, clave de juego registrada, miniatura, instrucciones, límite de intentos o tiempo, tipo de puntuación, regla de premio y versión (`tier`: `free` o `full`). Frisbee es `free` y Huerto `full`; un juego nuevo es `full` salvo decisión del propietario. Sin la versión completa, su tarjeta aparece con candado y no crea sesión ([reglas](FUNCIONAL.md#versión-gratuita-y-versión-completa)). GamesView construye las tarjetas leyendo GameCatalog. Al tocar una, crear su instancia de FlameGame en GameWidget y el aspecto actual del caniche. Estados: Preparado → Jugando ↔ Pausado → Terminado → Resultado → Casa o Repetir. Salir antes de Terminado cancela la sesión. Repetir crea un identificador nuevo. El minijuego entrega solo métricas enteras validadas, nunca se le confía la escritura del saldo.

Interfaz mínima: startRun(GameContext), setPaused(bool), cancel() y callback completed(GameScore). Suscribirse antes del inicio y desuscribirse al cancelar o al recibir resultado. Al perder foco, vaciar gestos en curso y requerir tocar «Continuar». Dos pantallas de resultado que reciben el mismo evento no deben pagar dos veces.

## Huerto saltarín

**Objetivo.** Llegar a la meta en 60 segundos de juego activo y recoger hasta 24 frutas. El caniche avanza solo. Toca el terreno o el botón Saltar para superar bancales, vallas y setos. El encuadre muestra más terreno a medida que aumenta la velocidad.

**Simulación y visores.** El juego usa un paso fijo de 1/120 s y separa las colisiones del dibujo. Comparte el recorrido entre el visor 3D y la escena 2D. Las coordenadas de la simulación crecen hacia arriba en Y. La cámara lateral sigue al caniche y se abre de forma gradual.

| Parámetro | Valor |
|---|---|
| Recorrido | 116 unidades de principio a fin, 24 frutas de seis tipos |
| Avance | De 3 a 9 unidades/s según el punto más lejano alcanzado |
| Gravedad efectiva | −20 unidades/s² |
| Velocidad vertical inicial | 7 unidades/s |
| Tolerancia del salto | 100 ms después de abandonar el suelo y 120 ms de memoria de un toque |
| Penalización | −5 segundos por choque o caída |
| Premio | 2 monedas más 2 por fruta, hasta 50 monedas |

**Frutas doradas y estrellas** (20-11-2026). Cada partida elige con su semilla (semilla del caniche + identificador de sesión, `runSeed`) tres frutas doradas, una por cada pareja de tramos (t1–t2, t3–t4, t5–t6). Las doradas suman lo mismo que las demás. Estrellas: 1 con 8 frutas, 2 con 16, 3 con 16 y las 3 doradas (`stars`, `starsGolden` del balance). El HUD cuenta «Doradas» y el visor 3D las resalta con un halo.

El tramo final concentra más obstáculos. Cada fruta cuenta una vez, incluso si el caniche reaparece. Al caer, vuelve al último apoyo seguro. La pausa congela cronómetro y física. La partida termina al llegar a la meta o agotar el tiempo y guarda el récord si corresponde.

Ambos juegos consumen 20 de energía y 10 de saciedad al terminar, además de dar +8 de ánimo. Solo admiten tres inicios por ventana móvil de cinco minutos, persistida; con energía cero hay que dormir.

## Frisbee en el prado

**Objetivo.** Lanzar cinco discos para que el perro los atrape en la zona marcada. Cada lanzamiento cuenta una vez, incluidos los fallos. Leer la trayectoria antes de soltar y dejar un botón accesible «Lanzar» que usa dirección y potencia centrales.

**Implementación 2D en Flame.** Fondo de prado ilustrado en vista elevada, sin cámara ni geometría 3D. Usar coordenadas lógicas de campo (x, profundidad): lanzador (0,0), profundidad 2–8 y ancho ±3. Proyectar de forma afín a un rectángulo 2D adaptado al área disponible, con profundidad creciente hacia arriba. Capturar primer pointerId y coordenadas normalizadas; cancelar al salir/perder foco. Arrastre vertical hacia arriba menor de 0,08 de la altura cancela sin gastar intento. Convertir su magnitud en profundidad 2–8 y desplazamiento horizontal en x limitado a ±3. Dibujar con Canvas/Path 16 muestras de la misma función que anima el disco.

Para t en [0,1], punto de campo = lerp(origen, destino, t), elevación visual = 4 × 1,8 × t × (1−t). Proyectar campo a pantalla y restar a Y la elevación multiplicada por la escala de dibujo. La sombra usa el punto sin elevación. Duración 1,1 s activos; objetivos targetsField = [[0,5],[-1.5,6],[1.5,4],[-2,4.5],[2,6.5]]. Son unidades lógicas de campo. Preparar al caniche en el objetivo y animarlo al lanzar; hay captura si la distancia lógica entre destino y centro es ≤1, independientemente de fps, proyección o animación. Aro y marca muestran destino; botón asistido apunta al centro.

Estados Apuntar → Vuelo → Atrapa/Recoge → Devuelve → Apuntar o Terminado. Deshabilitar segundo lanzamiento durante vuelo y devolución. Un fallo muestra cómo acercar el siguiente tiro. Tras cinco intentos, premio = 3 + 3 × aciertos, entre 3 y 18 monedas. Con tres capturas se puede adquirir el pañuelo de 10. Predicción y punto real deben coincidir también a 30 fps.

**Objetivos variables y estrellas** (20-11-2026). El primer objetivo es siempre el de calentamiento (0,5); los otros cuatro salen sin repetir de `targetPool` (diez puntos dentro del campo) según la semilla de la partida, de modo que la misma partida es reproducible y cada partida nueva cambia. El visor 3D recibe los mismos puntos desde Dart. Estrellas: 1 con 2 capturas, 2 con 4 y 3 con 5. Las monedas siguen siendo 3 + 3 × aciertos.

## Añadir un tercer juego

1. Crear una clase FlameGame 2D con puntos iniciales y controlador del contrato común. Construir PetComponent con la apariencia de GameContext.
2. Crear un GameDefinition (con `tier`), miniatura y explicación de un gesto. Registrar una factory por clave en GameRegistry, la definición en el catálogo y sus recursos en pubspec.yaml.
3. Añadir al dominio límites y fórmula de recompensa, un caso mínimo, uno máximo y un evento duplicado. Rechazar métricas inválidas. Definir también los umbrales ascendentes de estrellas en el balance y, si hay variedad, derivarla de `runSeed` para que sea reproducible.
4. Probar cancelación, pausa, modo avión, estilo equipado y resultado tras reinicio. Probar también la tarjeta con candado sin versión completa. La tarjeta debe aparecer sin modificar la pantalla de casa ni la tienda.


## Juego de parejas · 20-11-2026

Gratuito. Antes de iniciar se elige nivel:

| Parejas | Cartas | Premio al completar |
|---|---|---|
| 4 | 8 | 5 monedas |
| 6 | 12 | 15 monedas |
| 8 | 16 | 25 monedas |

60 segundos activos y cinco fallos permitidos. Cada error consume un intento; acertar o tocar de nuevo la misma carta no consume. Solo se descubren dos cartas a la vez. Un fallo deja ver ambas durante 0,85 s antes de ocultarlas, salvo al terminar. El premio exige completar el tablero; al agotar tiempo o intentos se obtiene cero. Las cartas acertadas permanecen visibles.

Los niveles 4 y 6 seleccionan al azar caniches entre ocho retratos distintos. El nivel 8 usa los ocho. Se barajan todas las posiciones y se rechazan tableros ya jugados en ese nivel. El historial se guarda con el inicio confirmado y se mantiene al abandonar o reiniciar. Un fallo de guardado no reserva el tablero. Sin cargo de monedas al iniciar.

## Memory de caniches · 20-11-2026

Solo versión completa, sin prueba de 24 h. Cuatro controles mantienen asociación fija de color, forma, foto y nota para poder aprenderla. El juego reproduce una secuencia aleatoria y el jugador la repite; empieza con tres pasos y añade uno en cada ronda hasta diez. Los valores de la secuencia pueden repetirse (regla de Simón); las pausas separan señales iguales. Los controles no admiten respuestas durante la muestra.

| Pasos completados | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|
| Premio total | 5 | 10 | 15 | 20 | 25 | 30 | 35 | 40 |

El límite es de diez segundos activos **para repetir la secuencia completa del turno**. Un toque correcto no reinicia el contador; la ronda siguiente recibe otros diez segundos. El contador no corre mientras se muestra la secuencia. Un error o tiempo agotado termina y entrega el premio de la última ronda completada; antes de completar tres pasos, cero. No se suman los premios intermedios: se paga una sola vez al acabar. Abandonar cancela sin premio.

Se elige al azar la secuencia completa de diez señales entre 4^10 posibilidades; se rechazan secuencias completas usadas anteriormente en la instalación. Los prefijos cortos pueden coincidir. Se reserva y guarda al iniciar, con la misma atomicidad que Parejas. Fotos, formas y luces permiten jugar con Efectos desactivados.

## Implementación y verificación de tableros

Dominio Dart puro: `PairsSim`, `MemorySim`, `PuzzleDeals` y validación de premios en `Rules`. Flutter representa los tableros, con reloj `PuzzleGame` en Flame y el `ActivityFrame` existente para pausa, segundo plano, continuación y abandono. Las imágenes se precargan antes de iniciar cronómetros. `GameSession` comparte confirmación de premio idempotente y recuperación de errores de guardado con Huerto/Frisbee. Los campos opcionales `bestPairs`, `bestMemory` y `puzzleDeals` conservan el esquema v1 y permiten leer partidas anteriores.

[Recursos y prompts](arte/minigames/FUENTES.md) · [Capturas y comprobaciones](reviews/minigames/README.md). No incluido aún en TestFlight; aceptación física pendiente.


## Integración con estrellas de main

Parejas obtiene 1/2/3 estrellas al completar el tablero de 4/6/8 parejas, y cero al perder. Memory obtiene 1 estrella desde 3 pasos completos, 2 desde 6 y 3 al completar 10. Las estrellas se guardan por juego y no cambian los premios en monedas ni el acceso de cada juego. Huerto y Frisbee mantienen sus reglas, frutas doradas y variedad por sesión de main.
