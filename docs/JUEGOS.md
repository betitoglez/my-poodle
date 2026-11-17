# Minijuegos y nuevos juegos

## Contrato común

GameDefinition contiene ID estable, título, clave de juego registrada, miniatura, instrucciones, límite de intentos o tiempo, tipo de puntuación, regla de premio y versión (`tier`: `free` o `full`). Frisbee es `free` y Huerto `full`; un juego nuevo es `full` salvo decisión del propietario. Sin la versión completa, su tarjeta aparece con candado y no crea sesión ([reglas](FUNCIONAL.md#versión-gratuita-y-versión-completa)). GamesView construye las tarjetas leyendo GameCatalog. Al tocar una, crear su instancia de FlameGame en GameWidget y el aspecto actual del caniche. Estados: Preparado → Jugando ↔ Pausado → Terminado → Resultado → Casa o Repetir. Salir antes de Terminado cancela la sesión. Repetir crea un identificador nuevo. El minijuego entrega solo métricas enteras validadas, nunca se le confía la escritura del saldo.

Interfaz mínima: startRun(GameContext), setPaused(bool), cancel() y callback completed(GameScore). Suscribirse antes del inicio y desuscribirse al cancelar o al recibir resultado. Al perder foco, vaciar gestos en curso y requerir tocar «Continuar». Dos pantallas de resultado que reciben el mismo evento no deben pagar dos veces.

## Huerto saltarín

**Objetivo.** Atravesar una pista lateral en 30 segundos de juego activo y recoger hasta 12 manzanas. El caniche avanza solo. Un toque en el terreno o el botón Saltar produce un salto. El jugador ve la siguiente plataforma antes del punto de despegue. Una caída devuelve al último punto seguro, con las frutas recogidas aún retiradas y el tiempo en marcha.

**Construcción.** OrchardGame de Flame completamente 2D, con sprites y cámara lateral. Movimiento cinemático sencillo sin motor de física adicional: paso fijo de 1/120 s con acumulador; usar barrido de hitbox contra plataformas para no atravesarlas. La colisión y el reloj de sesión usan el mismo tiempo simulado. Limitar el retraso acumulado y entrar en pausa ante una interrupción larga. Coordenadas de simulación X derecha/Y arriba; convertir a dibujo Flame (Y hacia abajo) con escala inicial 100 unidades lógicas de dibujo por unidad de juego. Separar hitbox del personaje y animación visual. Comprobar solapamientos con frutas una vez por ID. CameraComponent sigue X con suavidad y altura fija. Toque o botón Jump encolan una intención consumida en el siguiente paso.

| Parámetro | Valor inicial de trabajo |
|---|---|
| Avance | 3 unidades/s |
| Gravedad efectiva | −20 unidades/s² |
| Velocidad vertical inicial | 7 unidades/s |
| Altura y alcance ideal a igual cota | 1,23 unidades y 2,1 unidades |
| Tolerancias | 100 ms después de abandonar suelo; 120 ms de memoria de un toque justo antes de aterrizar |
| Hueco inicial | 0,6–1,1 unidades entre bordes. Aumentos de altura hasta 0,35 unidades |
| Premio | Al agotar tiempo o llegar a meta, 2 + frutas únicas, máximo 14 monedas |

Preparar tres tramos manuales de 20 unidades, cuatro frutas por tramo. Primero salto en suelo continuo, después dos bancales, finalmente plataformas y meta. Colocar frutas sobre la curva de salto, incluyendo algunas recogibles sin saltar. Identificar cada fruta por tramo/índice. Al detectar solapamiento añadir a conjunto de recogidas y ocultar su objeto. Una segunda detección no suma. Registrar el punto seguro solo al apoyar ambas patas sobre un bancal. Al caer por debajo de y = −3, anular velocidad, recolocar en punto seguro y dar medio segundo para leer la escena. HUD muestra tiempo y frutas. Pausa y reanudación congelan cronómetro, movimiento y física. Límite de sesión o meta gana la primera transición a Terminado. Con 7 frutas debe acreditar 9 monedas y actualizar el récord si corresponde.

## Frisbee en el prado

**Objetivo.** Lanzar tres discos para que el perro los atrape en la zona marcada. Cada lanzamiento cuenta una vez, incluidos los fallos. Leer la trayectoria antes de soltar y dejar un botón accesible «Lanzar» que usa dirección y potencia centrales.

**Implementación 2D en Flame.** Fondo de prado ilustrado en vista elevada, sin cámara ni geometría 3D. Usar coordenadas lógicas de campo (x, profundidad): lanzador (0,0), profundidad 2–8 y ancho ±3. Proyectar de forma afín a un rectángulo 2D adaptado al área disponible, con profundidad creciente hacia arriba. Capturar primer pointerId y coordenadas normalizadas; cancelar al salir/perder foco. Arrastre vertical hacia arriba menor de 0,08 de la altura cancela sin gastar intento. Convertir su magnitud en profundidad 2–8 y desplazamiento horizontal en x limitado a ±3. Dibujar con Canvas/Path 16 muestras de la misma función que anima el disco.

Para t en [0,1], punto de campo = lerp(origen, destino, t), elevación visual = 4 × 1,8 × t × (1−t). Proyectar campo a pantalla y restar a Y la elevación multiplicada por la escala de dibujo. La sombra usa el punto sin elevación. Duración 1,1 s activos; objetivos targetsField = [[0,5],[-1.5,6],[1.5,4]]. Son unidades lógicas de campo. Preparar al caniche en el objetivo y animarlo al lanzar; hay captura si la distancia lógica entre destino y centro es ≤1, independientemente de fps, proyección o animación. Aro y marca muestran destino; botón asistido apunta al centro.

Estados Apuntar → Vuelo → Atrapa/Recoge → Devuelve → Apuntar o Terminado. Deshabilitar segundo lanzamiento durante vuelo y devolución. Un fallo muestra cómo acercar el siguiente tiro. Tras tres intentos, premio = 3 + 3 × aciertos, entre 3 y 12 monedas. Con tres capturas se puede adquirir el pañuelo de 10. Predicción y punto real deben coincidir también a 30 fps.

## Añadir un tercer juego

1. Crear una clase FlameGame 2D con puntos iniciales y controlador del contrato común. Construir PetComponent con la apariencia de GameContext.
2. Crear un GameDefinition (con `tier`), miniatura y explicación de un gesto. Registrar una factory por clave en GameRegistry, la definición en el catálogo y sus recursos en pubspec.yaml.
3. Añadir al dominio límites y fórmula de recompensa, un caso mínimo, uno máximo y un evento duplicado. Rechazar métricas inválidas.
4. Probar cancelación, pausa, modo avión, estilo equipado y resultado tras reinicio. Probar también la tarjeta con candado sin versión completa. La tarjeta debe aparecer sin modificar la pantalla de casa ni la tienda.
