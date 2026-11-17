# Secuencia de implementación

Ejecutar las fichas en orden. Las rutas parten de la raíz Flutter descrita en TECNICA; las fichas son tareas previstas. Cada fila produce un cambio verificable; en la columna de cierre se indica qué hacer para demostrarlo. Al retomar, contrastar ESTADO.md con el árbol Flutter y ejecutar la prueba del último corte antes de continuar.

## F00 · Preparar el entorno y los dos reproductores

| ID | Implementación y resultado esperado | Prueba de cierre |
|---|---|---|
| 00.1 | Instalar Flutter estable, Android SDK/JDK compatibles y Xcode con componentes de iOS. Ejecutar flutter doctor -v y flutter devices; registrar versiones exactas en ESTADO | Toolchains detectadas; pendientes de firma/hardware identificados |
| 00.2 | Generar app con flutter create --platforms=android,ios en carpeta temporal y llevar lib, android, ios y configuración al clon conservando las guías. Ignorar build, .dart_tool, llaves y logs; versionar pubspec.lock | Clon limpio resuelve paquetes con flutter pub get |
| 00.3 | Añadir Flame compatible, flutter_test e integration_test. Preparar lib/domain, UI y game. Incorporar fuente local con licencia y soporte ñ/acentos; declarar assets en pubspec | flutter analyze y prueba de dominio pasan; dominio sin imports de Flutter/Flame |
| 00.4 | Configurar orientación vertical, AppRoot y pantallas de carga/casa; alojar una escena 2D en GameWidget. Generar APK debug e iOS de humo según ENTREGA | Instalar y arrancar Android e iPhone; registrar build y captura. Sin firma, registrar solo compilación iOS sin firmar |

## F01 · Partida, reloj y cartera

| ID | Implementación | Prueba de cierre |
|---|---|---|
| 01.1 | Crear PetState y DTO v1 según TECNICA. Escribir factory de adopción, normalizador de nombre, validación de cuatro ranuras y límites. Inyectar reloj UTC y directorio temporal de pruebas | Casos vacíos, nombre con tilde, 16/17 grafemas y nombre con salto de línea |
| 01.2 | Codificar NeedsClock con centésimas, cursor en segundos, bloque de 900 s y tope de 32 bloques. Procesar primero tiempo y después acciones sobre una copia | Tras 2 h desde la adopción, saciedad 59. Tras 48 h, saciedad 41. Retroceder el reloj no suma ni resta |
| 01.3 | Crear SaveStore con carga principal/copia, validación, escritura temporal, reemplazo y resultado explícito. Permitir fallos de E/S inyectables en pruebas. Instalar ruta Android y exclusión iOS | Interrumpir en cada frontera descrita en PRUEBAS; se recupera exactamente la revisión anterior o la siguiente |
| 01.4 | Crear StyleCatalog y WalletRules. Registrar IDs, precios, propiedad, ranuras y coste cero de reequipar. Añadir operación Finish con comprobación de sesión e ID | Probar 9, 10 y 12 monedas ante compra de 10; comprobar todas las ranuras tras recargar |

## F02 · Adopción y primer cuidado completo

| ID | Implementación | Prueba de cierre |
|---|---|---|
| 02.1 | Crear AppRoot, AppRouter y vistas Loading/Adoption/Error. Resolver almacenamiento al arrancar. Usar TextField con teclado nativo, nombre como Text y validación del dominio | Cancelar teclado, cerrar antes de adoptar, adoptar/cerrar inmediatamente; reapertura correcta |
| 02.2 | Crear PetComponent 2D con capas provisionales, cuatro ranuras y reloj de animación. Home con nombre, saldo, necesidades y navegación dentro de SafeArea | Cargar a Miel y volver desde cada panel: una raíz, una instancia activa de escena y listeners únicos |
| 02.3 | Crear CareRoom, alimentar en tres pasos. Habilitar siguiente gesto al acabar masticación; presentar progreso y enviar un solo Finish. Conectar sonidos y reducir movimiento | Desde 65 de saciedad completar y reiniciar → 85. Tras dos bocados cancelar → 65; saldo 0 en ambos casos |
| 02.4 | Completar recorrido vertical desde instalación limpia. Crear build de desarrollo por plataforma y ejecutar en modo avión | Criterio del primer corte: adoptar, alimentar, reabrir y ver nombre, saldo y saciedad correctos |

## F03 · Recursos y personalización

| ID | Implementación | Prueba de cierre |
|---|---|---|
| 03.1 | Preparar arte 2D desde las referencias según UI-UX: piezas transparentes, atlas, pivotes y poses. Animar reposo, comida, carrera, salto y captura sin modelos 3D | Reproducir poses frontal/perfil previstas; verificar patas, suelo, anclajes y escala |
| 03.2 | Crear máscaras albaricoque/plata, piezas natural/pompón, peto y pañuelo por pose. Registrar metadatos en appearance-v1.json y resolverlos desde PetComponent | Probar las 16 combinaciones en reposo, salto y carrera; mismo aspecto en casa, cuidados y juegos |
| 03.3 | Construir Boutique con categorías, previsualización aislada, saldo, coste, confirmación y cancelación. Llamar a BuyAndEquip. Volver a casa reconstruye Appearance desde el estado confirmado | Completar compra con saldo exacto y cerrar durante confirmación. Probar restauración y compra repetida |
| 03.4 | Crear clips musicales cortos de Mureka, efectos en ElevenLabs y canales de audio Music, Pet, UI. Configurar bucle, prioridades y silenciamiento persistente. Registrar origen/licencia por archivo | En modo avión se oye cada acción. Con silencio, las señales visuales permiten completarla |

## F04 · Rutinas de cuidado

| ID | Implementación | Prueba de cierre |
|---|---|---|
| 04.1 | Crear BathController Wet/Soap/Rinse con tres zonas 2D y máscaras de espuma. Convertir coordenadas de toque/arrastre al espacio del personaje; excluir UI | Repetir pata solo marca una zona; aclarar tras tres zonas concede +25 una vez |
| 04.2 | Crear GroomController, tres mechones y espejo. Tras +8 de higiene ofrecer elegir corte. Delegar precio y propiedad al armario; al cancelar corte se conserva cepillado ya confirmado | Cepillar, probar pompón, cancelar, salir y volver. Higiene nueva y corte anterior |
| 04.3 | Montar Park con recorrido fijo de tres waypoints y animación Trot/Sniff. Aceptar toque al destino activo, interpolar movimiento y habilitar siguiente solo tras llegar | Tocar un punto fuera de orden no avanza. Última parada concede +15 ánimo y −5 energía |
| 04.4 | Añadir consulta con dos instrumentos, estados y reacción tranquila. Enlazar desde lista de cuidados | Volver tras un paso deja ánimo intacto; terminar dos pasos añade +5 |
| 04.5 | Probar gestos con segundo dedo, mano izquierda, sistema en pausa y movimiento reducido. Transferir la entrada a un solo pointerId y limpiar al cancelar | Una secuencia de pulsaciones simultáneas nunca salta dos fases |

## F05 · Plataformas con frutas

| ID | Implementación | Prueba de cierre |
|---|---|---|
| 05.1 | Crear OrchardGame, tres tramos, suelo, frutas y meta según JUEGOS. Añadir overlay de depuración 2D del salto/viewport y validar IDs únicos con tool/validate_content.dart | Recorrer saltos en 320×568 y 430×932; próximo apoyo visible |
| 05.2 | Implementar movimiento cinemático 2D a paso fijo, barrido de colisión y apoyo. Aplicar tolerancia y buffer de Jump; hitbox independiente de las capas visuales | A 30 y 60 fps alcanza el mismo bancal; mantener pulsado no repite salto |
| 05.3 | Implementar fruta de un solo uso, checkpoint, recuperación tras caída, temporizador y meta. Mantener conjunto de recogidas al reaparecer | Caer sobre una fruta recogida no vuelve a sumarla; pausar durante 10 s conserva el tiempo restante |
| 05.4 | Conectar Completed al resumen común, recompensas y récord. Probar tiempo agotado en el mismo frame que la meta | Una partida con 7 frutas concede 9 monedas. Reiniciar la aplicación tras el resultado conserva 9 |

## F06 · Frisbee y ampliación del catálogo

| ID | Implementación | Prueba de cierre |
|---|---|---|
| 06.1 | Crear FrisbeeGame, fondo 2D, objetivos, aro y disco. Dibujar guía con Canvas/Path usando la misma función de proyección y arco que el vuelo | Soltar izquierda/centro/derecha coincide con marca; gesto corto conserva intento |
| 06.2 | Implementar vuelo, captura, recogida y devolución con tiempo activo. Callback visual nunca concede puntos. Botón asistido apunta al centro | Segundo toque en vuelo no duplica intento; tres fallos/aciertos dan 3/12 monedas |
| 06.3 | Crear una definición por juego. Conectar selector, repetir y volver. Aplicar aspecto equipado al comenzar ambos juegos | Cambiar color y peto, iniciar ambos juegos y revisar que se conservan; cargar definición de ensayo para probar extensión |
| 06.4 | Encadenar adopción, frisbee, pañuelo, huerto y nuevo arranque. Verificar cartera usando la fórmula independiente | Con frisbee perfecto y 7 frutas, después de comprar pañuelo quedan 11 monedas |

## F07 · Monetización y aceptación móvil

| ID | Implementación | Prueba de cierre |
|---|---|---|
| 07.1 | Implementar NoAds y SimulatedAds con disponible, no-fill, fallo, demora y cierre. Crear AdsPolicy local con pantallas y umbral. Ocultar banner al salir de casa | Un callback que llega en baño nunca inserta banner. Tras resultado sin red se puede seguir |
| 07.2 | Evaluar audiencia, datos y proveedor por plataforma según ENTREGA. Configurar SDK autorizado en variante separada. Inicializar tras aplicar controles infantiles, usar inventario de prueba | Evidencia de configuración, versión y tráfico observado en build. Probar reanudación del audio e input tras cerrar |
| 07.3 | Ejecutar dominio, widgets, componentes e integration_test; restauración, transferencia y matriz visual. Medir 60 s por escena con DevTools en profile en hardware | Corregir PRUEBAS y repetir en ambos sistemas; identificar dispositivo que limita rendimiento |

## F08 · Candidatas y distribución

| ID | Implementación | Prueba de cierre |
|---|---|---|
| 08.1 | Preparar comandos y validación de ENTREGA. Fijar versión, número de build, recursos, configuración publicitaria y firma local. Generar APK, AAB y archivo/IPA | Comandos fallan ante error; clon limpio contiene mismos catálogos, rutas y recursos |
| 08.2 | Preparar AAB firmado y archivo Xcode Release. Ejecutar betas internas. Instalar desde TestFlight y Play Internal, también como actualización sobre build anterior | Los dos canales conservan partida y catálogo; registrar identificadores de build y dispositivos |
| 08.3 | Completar fichas, privacidad, licencias, clasificación y capturas reales; registrar resultado de revisión y habilitar lanzamiento según decisión del propietario | Build pública identificable por versión y revisión de Git. Si hay incidencia aplicar el procedimiento de recuperación de ENTREGA |
