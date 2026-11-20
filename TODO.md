# TODO · My Poodle / Mi Caniche

Actualizado el 20-11-2026. Este documento recoge el alcance confirmado; [FASES](docs/FASES.md) ordena las entregas y [ESTADO](docs/ESTADO.md) contiene la evidencia. Una tarea implementada no equivale a una prueba física pasada.

## Puerta de salida: primera beta funcional de TestFlight

- [x] Integrar en main las correcciones de compras (PR #5, `f08fb2d`; 193 pruebas y Codex sin incidencias): restauración siempre visible, cancelación Android sin producto, pendientes nativas y reconciliación al reanudar. Mantener partida y monedas.
- [x] Implementar los catálogos locales (11 × 559 mensajes) y selector persistente; 221 pruebas correctas. Localizar toda la app en **11 variantes**: español (es), inglés (en, respaldo), francés (fr), alemán (de), portugués de Brasil (pt-BR), italiano (it), ruso (ru), coreano de Corea del Sur (ko), japonés (ja), chino simplificado (zh-Hans) y chino tradicional (zh-Hant). Selección persistente y detección del sistema; revisar textos largos y accesibilidad.
- [x] Localizar el nombre bajo el icono y en la app: **Mi Caniche** en español, **My Poodle** en inglés/respaldo, y nombre equivalente en cada idioma. No cambiar Bundle ID ni producto de compra.
- [x] **Modo foto del MVP implementado** (pendiente aceptación física de la captura 3D en la beta): posar/girar al caniche con su aspecto actual, capturar el render 3D y conservar fotos en un álbum privado dentro de la app. No exige compartir ni acceso a las fotos personales del dispositivo.
- [x] **Prueba premium gratuita implementada y probada**: una partida por cada minijuego de la versión completa cada 24 horas, guardada al comenzar. Reiniciar el proceso no renueva el cupo; abandono consume el intento; guardar fallido no lo consume. Se mantienen las reglas generales de energía y descanso. La compra completa quita este límite de prueba.
- [x] Traducir y verificar tras recargar los títulos de ficha de App Store en las 11 variantes, además de los nombres nativos ya implementados. Español aprobado: **Mi Caniche: mascota virtual**; francés con calificador por colisión: **Mon Caniche : animal virtuel**. [Tabla de nombres](docs/IDIOMAS.md).
- [x] Configurar los datos mínimos Sandbox de Apple: `com.betitoglez.mypoodle`, no consumible `mypoodle.full_version`, 11 nombres/descripciones, precio base España **1,99 €** y disponibilidad **175 territorios**, ambos autorizados y guardados; acuerdo de pago activo.
- [x] Crear y verificar candidata **0.5.0 (33)** Release/Archive con 3D activo, firma de distribución y SHA-256; PR #6 fusionada tras revisión limpia de Codex.
- [x] Subir la candidata (33) con Organizer: ContentDelivery confirma transferencia correcta sin errores y con una advertencia futura de SDK.
- [x] Procesamiento Ready to Test y build (33) en **MVP Sandbox**, con el propietario como único tester; instalada y abierta en iPhone, versión confirmada por devicectl.
- [ ] Resolver/verificar disponibilidad de producto Sandbox: en la primera prueba y al reintentar no aparece el precio. Metadatos recién guardados; comprobar propagación antes de atribuir el fallo a código. [Diagnóstico](docs/TESTFLIGHT.md#diagnóstico-del-producto-no-disponible).
- [ ] Aceptación física de compra iPhone: compra, cancelación, pendiente/aprobación/rechazo, restauración en entorno de prueba, reinicio, offline y revocación/reembolso. No borrar la partida personal para probar restauración.
- [ ] La primera beta incluye idiomas y modo foto; no se declara lista con esos requisitos pendientes. El alta remota y una compilación local tampoco acreditan una compra Sandbox correcta.

## Implementado y verificado previamente

- [x] Caniche 3D y catálogo de prendas/accesorios, cuidados y dos minijuegos conectados. El propietario confirma el 3D en iPhone 0.4.13 (31).
- [x] Tres músicas locales por contexto, 37 efectos activos y ajustes persistentes; PR #4 fusionada, 187 pruebas correctas y revisión final de Codex sin incidencias.
- [x] Bundle ID definitivo `com.betitoglez.mypoodle`; compra única `mypoodle.full_version`; sin anuncios ni venta de monedas.
- [x] Guardado local, adopción, necesidades/salud y puerta adulta. El guardado de la compra se conserva separado de la partida.
- [x] Compra y aceptación Android documentadas en el clon original: compra, cancelación, pendientes aprobada/rechazada, restauración con derecho existente, reembolso y reinicio offline. Incorporar las correcciones a main y repetir la candidata actual.

## Minijuegos nuevos: definición pendiente

Son candidatos del MVP ampliado, no juegos ya implementados. Antes de construirlos fijar cuáles entran en la beta/MVP, reglas, duración, premios, acceso gratuito/completo y arte.

- [ ] Memory de parejas: descubrir cartas y encontrar parejas; tamaño de tablero y dificultad por definir.
- [ ] Memory de perritos tipo Simón: repetir una secuencia de perritos/colores/sonidos; acceso sin sonido y dificultad por definir.
- [ ] Laberinto: conducir al caniche a la meta; controles, niveles y obstáculos por definir.
- [ ] Cada juego premium futuro debe usar el mismo cupo gratuito de una partida cada 24 h, con IDs estables y guardado compatible.

## Aceptación y preparación de publicación

- [ ] Revisar los 11 idiomas en adopción, cuidados, juegos, compras, modo foto, ajustes, ayuda, privacidad y estados de error; precios localizados por la tienda.
- [ ] Matriz 3D: colores, cortes y prendas, giro, descanso, cuidados y juegos; verificar que la carga o el respaldo se identifican correctamente durante QA.
- [ ] Pruebas físicas de música/efectos, silencio, llamadas/interrupciones y segundo plano en iPhone y Android.
- [ ] Medir arranque y 60 s por escena, memoria y diez ciclos de navegación en dispositivo de menor rendimiento.
- [ ] Android: actualizar prueba interna y restaurar el derecho en instalación limpia/dispositivo de prueba.
- [ ] Tipografías y cobertura CJK/cirílico, créditos y licencias de recursos, privacidad/soporte definitivos, accesibilidad, capturas y fichas localizadas.
- [ ] TestFlight y Play Internal: actualización conservando datos, feedback y cierre de incidencias. Producción requiere una decisión posterior del propietario.

## Después del MVP

- [ ] Exportación/importación de partida detrás de la puerta adulta, sin servidor.
- [ ] Logros/álbum de pegatinas y nuevas actividades.
- [ ] Recordatorios locales opcionales desde la zona adulta.
