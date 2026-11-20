# TODO · My Poodle / Mi Caniche

Actualizado el 20-11-2026. Este documento recoge el alcance confirmado; [FASES](docs/FASES.md) ordena las entregas y [ESTADO](docs/ESTADO.md) contiene la evidencia. Una tarea implementada no equivale a una prueba física pasada.

## Puerta de salida: primera beta funcional de TestFlight

- [x] Integrar en main las correcciones de compras (PR #5, `f08fb2d`; 193 pruebas y Codex sin incidencias): restauración siempre visible, cancelación Android sin producto, pendientes nativas y reconciliación al reanudar. Mantener partida y monedas.
- [x] Implementar los catálogos locales (11 × 559 mensajes) y selector persistente; 221 pruebas correctas. Localizar toda la app en **11 variantes**: español (es), inglés (en, respaldo), francés (fr), alemán (de), portugués de Brasil (pt-BR), italiano (it), ruso (ru), coreano de Corea del Sur (ko), japonés (ja), chino simplificado (zh-Hans) y chino tradicional (zh-Hant). Selección persistente y detección del sistema; revisar textos largos y accesibilidad.
- [x] Localizar el nombre bajo el icono y en la app: **Mi Caniche** en español, **My Poodle** en inglés/respaldo, y nombre equivalente en cada idioma. No cambiar Bundle ID ni producto de compra.
- [x] **Modo foto del MVP implementado y probado físicamente en iPhone (33)**: caniche vestido con giro y poses de pie/tumbado, captura 3D y fotos conservadas tras reabrir el álbum privado. Borrado físico pendiente. No lee las fotos personales del dispositivo; copiar al carrete exige la puerta adulta.
- [x] **Prueba premium gratuita implementada y probada**: una partida por cada minijuego de la versión completa cada 24 horas, guardada al comenzar. Reiniciar el proceso no renueva el cupo; abandono consume el intento; guardar fallido no lo consume. Se mantienen las reglas generales de energía y descanso. La compra completa quita este límite de prueba.
- [x] Traducir y verificar tras recargar los títulos de ficha de App Store en las 11 variantes, además de los nombres nativos ya implementados. Español aprobado: **Mi Caniche: mascota virtual**; francés con calificador por colisión: **Mon Caniche : animal virtuel**. [Tabla de nombres](docs/IDIOMAS.md).
- [x] Configurar los datos mínimos Sandbox de Apple: `com.betitoglez.mypoodle`, no consumible `mypoodle.full_version`, 11 nombres/descripciones, precio base España **1,99 €** y disponibilidad **175 territorios**, ambos autorizados y guardados; acuerdo de pago activo.
- [x] Crear y verificar candidata **0.5.0 (33)** Release/Archive con 3D activo, firma de distribución y SHA-256; PR #6 fusionada tras revisión limpia de Codex.
- [x] Subir la candidata (33) con Organizer: ContentDelivery confirma transferencia correcta sin errores y con una advertencia futura de SDK.
- [x] Procesamiento Ready to Test y build (33) en **MVP Sandbox**, con el propietario como único tester; instalada y abierta en iPhone, versión confirmada por devicectl.
- [x] Consulta de producto Sandbox disponible: el propietario confirma que aparece el precio; incidencia inicial resuelta sin cambiar la build ni reinstalar. [Registro](docs/TESTFLIGHT.md#incidencia-inicial-de-producto-no-disponible--resuelta).
- [x] Compra y cancelación físicas en iPhone/TestFlight **0.5.0 (33)**: el propietario confirma que cancelar funciona y comprar desbloquea la versión completa.
- [x] Reinicio, offline y restauración con derecho existente en iPhone (33): el propietario confirma que se conserva la versión completa, mascota, monedas y armario.
- [x] Primera beta interna funcional **0.5.0 (33)** disponible e instalada: 11 variantes incluidas, compra/cancelación, reinicio/offline/restauración y foto 3D/álbum con comprobación física básica. La revisión lingüística y la aceptación ampliada continúan pendientes.

## Implementado y verificado previamente

- [x] Caniche 3D y catálogo de prendas/accesorios, cuidados y dos minijuegos conectados. El propietario confirma el 3D en iPhone 0.4.13 (31).
- [x] Tres músicas locales por contexto, 37 efectos activos y ajustes persistentes; PR #4 fusionada, 187 pruebas correctas y revisión final de Codex sin incidencias.
- [x] Bundle ID definitivo `com.betitoglez.mypoodle`; compra única `mypoodle.full_version`; sin anuncios ni venta de monedas.
- [x] Guardado local, adopción, necesidades/salud y puerta adulta. El guardado de la compra se conserva separado de la partida.
- [x] Compra y aceptación Android documentadas en el clon original: compra, cancelación, pendientes aprobada/rechazada, restauración con derecho existente, reembolso y reinicio offline. Correcciones integradas en main por PR #5 y PR #12; repetir aceptación de la candidata actual sigue pendiente.

## Minijuegos nuevos: definición pendiente

Son candidatos del MVP ampliado, no juegos ya implementados. Antes de construirlos fijar cuáles entran en la beta/MVP, reglas, duración, premios, acceso gratuito/completo y arte.

- [ ] Memory de parejas: descubrir cartas y encontrar parejas; tamaño de tablero y dificultad por definir.
- [ ] Memory de perritos tipo Simón: repetir una secuencia de perritos/colores/sonidos; acceso sin sonido y dificultad por definir.
- [ ] Laberinto: conducir al caniche a la meta; controles, niveles y obstáculos por definir.
- [ ] Cada juego premium futuro debe usar el mismo cupo gratuito de una partida cada 24 h, con IDs estables y guardado compatible.

## Aceptación y preparación de publicación

- [x] Distribuir e instalar actualización interna **0.5.0 (34)** en MVP Sandbox, con corrección de espera iOS y reembolso limitado a Sandbox; 226 pruebas y Codex sin incidencias. Versión instalada confirmada por propietario y devicectl.
- [x] Finalizar sesión rápida (34) y recuperar iPhone: ambos archivos originales de compra restituidos y verificados byte por byte; España guardada; propietario confirma cuenta habitual, controles de prueba apagados, español y estado conservado. Sesión finalizada con casos abiertos, no toda la matriz superada.
- [x] Compra sin conexión (modo avión y Wi-Fi apagado): error sin entrega; reconectar y Restaurar recupera completa con todos los datos conservados.
- [x] Comprobar pantalla de compra en inglés y precio en dólares con país temporal United States; cuenta devuelta a España. No equivale a comprar en otra divisa ni revisar todas las traducciones.
- [x] Restaurar en (34) con archivo principal de compra sin derecho: recupera la completa y conserva mascota, monedas, armario y fotos; readback purchased/full=true. Backup retenido y sin reinstalación.
- [ ] Ask to Buy: aprobación/rechazo aplazados por el propietario tras lista de solicitudes vacía. No acreditados por la regresión automática.
- [ ] Reembolso/revocación: bloqueados por «No se puede conectar» en la hoja Apple, incluso con otra conexión; repetir cuando el entorno permita cargar el formulario.
- [ ] Interrupción nativa o cierre durante confirmación, errores forzados de facturación e instalación limpia completa en entorno de pruebas. No borrar la partida personal para crear esos casos.
- [ ] Comprobar en iPhone y Android que «Guardar en el carrete» deja la foto en Fotos/Galería, y el mensaje al denegar el permiso.
- [ ] Comprobar borrado de una foto de prueba en iPhone; captura de dos poses y persistencia del álbum ya confirmadas.
- [ ] Revisar los 11 idiomas en adopción, cuidados, juegos, compras, modo foto, ajustes, ayuda, privacidad y estados de error; precios localizados por la tienda.
- [ ] Matriz 3D: colores, cortes y prendas, giro, descanso, cuidados y juegos; verificar que la carga o el respaldo se identifican correctamente durante QA.
- [ ] Pruebas físicas de música/efectos, silencio, llamadas/interrupciones y segundo plano en iPhone y Android.
- [ ] Medir arranque y 60 s por escena, memoria y diez ciclos de navegación en dispositivo de menor rendimiento.
- [ ] Android: actualizar prueba interna y restaurar el derecho en instalación limpia/dispositivo de prueba.
- [ ] Tipografías y cobertura CJK/cirílico, créditos y licencias de recursos, privacidad/soporte definitivos, accesibilidad, capturas y fichas localizadas.
- [ ] TestFlight y Play Internal: actualización conservando datos, feedback y cierre de incidencias. Producción requiere una decisión posterior del propietario.

## Mejoras de juego propuestas (revisión del 20-11-2026)

Implementadas en la rama `feature/mejoras-juego`, sin fusionar ni probar en dispositivo. [Registro](docs/ESTADO.md).

- [x] Variedad con semilla en los minijuegos: objetivos variables del Frisbee y frutas doradas del Huerto, reproducibles por partida.
- [x] Retos de estrellas (0–3) con mejor marca guardada y retos visibles en las instrucciones.
- [x] Uso para las monedas: decoración del salón (alfombra, pared, planta) con artículos gratuitos y de la versión completa.
- [x] Caniche más vivo: corazones al acariciar y reposos variados en 2D.
- [x] Mirada que sigue el dedo: giro de cabeza en 3D e inclinación del cuerpo en 2D; pendiente de probar en dispositivo.
- [x] Primera partida guiada: comer, jugar y estrenar algo, con opción de saltarla.
- [x] Pequeñas celebraciones: monedas que cuentan, confeti y transiciones suaves que respetan el movimiento reducido.
- [x] Accesibilidad de escenas y juegos: etiquetas de estado, regiones vivas y texto grande sin desbordes.
- [ ] Arte final de la decoración (los dibujos actuales son provisionales) y decoración visible en el visor 3D/foto en dispositivo.
- [ ] Comprobar en iPhone con 3D: decoración bajo el caniche, corazones, guía, transiciones y lector de pantalla (VoiceOver/TalkBack).
- [ ] Revisión lingüística de los 55 textos nuevos en los 11 idiomas.

## Después del MVP

- [ ] Exportación/importación de partida detrás de la puerta adulta, sin servidor.
- [ ] Logros/álbum de pegatinas y nuevas actividades.
- [ ] Recordatorios locales opcionales desde la zona adulta.
