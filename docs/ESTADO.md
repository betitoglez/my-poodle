# Estado de la implementación

Registro vivo. Distingue **implementado**, **probado en este Mac** (pruebas automáticas, compilación, navegador) y **probado en dispositivo** (ninguno todavía).

## Sesión 2026-11-16 · Prototipo completo Flutter + Flame

Encargo: [PROMPT_PROTOTIPO_FLUTTER_DART](../README.md#prototipo-flutter) (prototipo de experiencia con las 19 vistas, cuidados, dos minijuegos y personalización persistente). Repositorio sin commits previos.

### Entorno y versiones

| Herramienta | Versión | Nota |
|---|---|---|
| Flutter | 3.50.0 stable (rev. ab2912035e, 2026-11-09) | Instalado con Homebrew en esta sesión |
| Dart | 3.14.0 | Incluido en Flutter |
| Flame | 1.38.2 | `pubspec.lock` versionado |
| material_ui | 1.11.1 | Material separado del framework desde Flutter 3.47 |
| characters | 1.4.1 | Conteo de grafemas del nombre |
| web | 1.1.2 | `localStorage` en la vista previa web |
| Xcode / CocoaPods | 26.6 (17F113) / 1.17.0 | Compilación iOS de simulador correcta |
| Android SDK | **No instalado** | `flutter doctor`: «Unable to locate Android SDK». Sin APK |

### Cobertura del plan (FASES.md)

| ID | Estado | Detalle |
|---|---|---|
| 00.1 | Hecho parcial | Flutter, Xcode y Chrome detectados. Falta Android SDK/JDK |
| 00.2 | Hecho | Proyecto `android/`, `ios/`, `web/` generado con `flutter create --org dev.mypoodle` (identificador provisional, confirmar con el propietario) |
| 00.3 | Hecho | Flame, flutter_test, `lib/domain` sin Flutter/Flame. Fuente local pendiente (se usan fuentes del sistema) |
| 00.4 | Hecho parcial | Vertical en Android/iOS/web; escenas en `GameWidget`. Build iOS simulador sí; APK no (sin SDK); sin instalación en dispositivo |
| 01.1–01.4 | Hecho | `PetState`, `NeedsClock`, `SaveStore` (principal/copia/temporal, fallos inyectables), catálogo y cartera, `Finish` con sesión |
| 02.1–02.3 | Hecho | Arranque, Adopción, Casa, Cocina; caniche por capas |
| 02.4 | Pendiente de dispositivo | Recorrido verificado en pruebas de widgets y en Chrome; falta modo avión en teléfono |
| 03.1–03.2 | Hecho con arte provisional | Caniche vectorial por capas (`PetPainter`), máscaras de pelaje, 2 cortes, peto y pañuelo, poses frontal y perfil, metadatos en `assets/data/appearance-v1.json`. Sin atlas PNG final |
| 03.3 | Hecho | Armario con vista previa aislada, compra única, cancelar/descartar |
| 03.4 | Pendiente | Sin audio producido; ajustes de música/efectos guardados; efectos = háptica |
| 04.1–04.3 | Hecho | Baño (toque y arrastre), Peluquería con espejo y acceso a cortes, Paseo con 3 paradas |
| 04.4 | No incluido | Veterinario: ampliación posterior fuera de las 19 vistas (reglas en balance y dominio) |
| 04.5 | Hecho parcial | Un solo `pointerId` por gesto en `SceneView`; sin prueba en hardware |
| 05.1–05.4 | Hecho | Simulación pura a 1/120 s, barrido, tolerancias, checkpoint, premio 2 + manzanas |
| 06.1–06.4 | Hecho | Frisbee con proyección afín, guía de 16 muestras de la misma función, asistido; catálogo de juegos |
| 07.1 | Hecho parcial (plan anterior, sustituido) | `NoAds` y espacio de banner simulado (modo demostración). El 17 de noviembre F07 pasa a versión completa sin publicidad: ver la sesión de esa fecha |
| 07.2–08.3 | Pendiente | Versión completa, medición en hardware, firma y tiendas (requieren datos del propietario) |

### Pruebas ejecutadas (este Mac, 2026-11-16)

| Comando | Resultado |
|---|---|
| `flutter analyze` | Sin incidencias |
| `dart run tool/validate_content.dart` | «Contenido válido: 8 artículos, 2 poses, 9 imágenes» |
| `flutter test --coverage` | **54/54 pasan**. Cobertura de líneas 75 % (dominio 89 %, datos 92 %, UI 80 %, juego 64 %) |
| `flutter build web --release` | Correcto |
| `flutter build ios --simulator --debug` | Correcto (`build/ios/iphonesimulator/Runner.app`, incluye el canal Swift) |
| `flutter build apk` | **No ejecutado**: falta Android SDK |

Casos cubiertos por pruebas automáticas (`test/`):

- Dominio (E01–E05, E08–E10): nombre NFC/grafemas/saltos de línea; reloj 899/900 s, 2 h → 59, 48 h → 41, reloj hacia atrás; cuidados con tope; cartera 9/10/12 → rechazo/0/2, reequipar gratis, 16 combinaciones; premios 2/9/14 y 3/6/9/12; recorrido 0 → 12 → 2 → 11; catálogo inválido.
- Guardado (E06, E07): JSON truncado con copia, principal ausente, esquema futuro preservado, ambos dañados, cosmético retirado, temporal huérfano, fallo inyectado en cada frontera de escritura, reinicio y marcador pendiente, archivo real en disco.
- Simulaciones (A03, A04): huerto completo con piloto (12 manzanas, sin caídas), igual resultado a 30 y 60 fps, caída y reaparición, avance grande sin atravesar, un salto por intención; frisbee 3/3 asistidos a 30 y 60 fps, gesto corto, guía = vuelo, tolerancia ≤ 1.
- Recorridos de la app real (`test/ui/app_flow_test.dart`, recorridos 1–12 del encargo): adoptar y reabrir; comer completo (+20 una vez) y abandono a medias; frisbee 12 monedas → pañuelo → 2 → quitar/usar sin coste → vista previa de plata descartada; pausa congela el tiempo del huerto; abandonar sin premio; huerto completo con premio; reinicio cancelado y confirmado; modo demostración aislado; 320×568, 430×932 y 834×1194 con teclado abierto en Adopción.

### Comprobado en navegador (Chrome, vista previa web 390×844)

Adopción con «María José», persistencia tras recargar, Casa, Cuidados, Baño con espuma por zonas, Frisbee con arrastre y asistidos (3/3, +12), resultado, compra del pañuelo (12 → 2), quitar y «Usar» gratis (sigue 2), Huerto. Capturas en [docs/capturas](capturas/). El panel del navegador estaba oculto y limitaba fotogramas: no sirve como medida de rendimiento.

### No comprobado / pendiente con dato que falta

| Pendiente | Qué falta |
|---|---|
| Ejecución en simulador iOS | Permiso de acceso al simulador en el panel de Claude (no respondido en esta sesión) |
| Instalación en iPhone/Android reales, modo avión, segundo plano real, rendimiento | Hardware conectado y autorizado; Android SDK |
| Exclusión de backup verificada (iOS `isExcludedFromBackup`, Android `noBackupFilesDir` + reglas) | Código escrito; requiere prueba de restauración/transferencia en dispositivos |
| Audio (Mureka/ElevenLabs) | Archivos y licencias |
| Arte final por capas (atlas, pivotes, poses) | Producción artística; el caniche actual es vectorial provisional |
| Fuentes Young Serif / Nunito empaquetadas | Descargar TTF con licencia OFL y declararlas en `pubspec.yaml` |
| Textos de privacidad definitivos | Responsable legal; la vista P18 está marcada como provisional |
| Identificador de app, firma, fichas de tienda | Decisión y credenciales del propietario |

### Incidencias conocidas

- Normalización NFC parcial: se componen las letras latinas con diacríticos habituales (á, ñ, ü, ç…); Dart no trae normalización Unicode completa.
- El acceso adulto es una pulsación mantenida de 2 s: provisional, revisar antes de publicar (normas de apps infantiles).
- En la vista previa web el primer clic tras recargar a veces no llega (panel del navegador oculto); no se reproduce en pruebas de widgets.

## Sesión 2026-11-17 · Salas ilustradas con Meshy

- Generadas 6 salas y 2 referencias del caniche con la API de Meshy (`image-to-image`, `nano-banana-pro`): 8 tareas correctas, **72 créditos** (saldo 932 → 860). Origen, prompts y tareas en [arte/meshy/FUENTES.md](arte/meshy/FUENTES.md).
- Integradas las salas en `StageGame`: imagen anclada al suelo, punto de apoyo y altura del caniche por sala (`RoomArt.of`), vuelta al dibujo vectorial si la imagen no carga. Afecta a Casa, Adopción, Cocina, Baño, Peluquería, Armario y resultados.
- Comprobación: `flutter analyze` sin incidencias, `validate_content` (15 imágenes), `flutter test` 54/54, `flutter build web` correcto. Revisada Casa en Chrome a 390×844 ([captura](capturas/casa-salas.jpg), [comparativa](capturas/comparativa-meshy.jpg)). Las demás salas no se han revisado visualmente dentro de la app.
- El CLI de Meshy no se usó: el entorno bloqueó su descarga con npm; se llamó a la API directamente con `MESHY_API_KEY`.
- Pendiente: el caniche vectorial desentona con las salas ilustradas. El piloto (`docs/arte/meshy/pet_*.png`) muestra que Meshy da un caniche coherente, pero entero, no por capas.

## Sesión 2026-11-17 · Piloto 2 del caniche por capas (Meshy)

- 8 variantes alineadas, **72 créditos** (saldo 860 → 788). Detalle en [arte/meshy/FUENTES.md](arte/meshy/FUENTES.md).
- Resultado: viable. Las 16 combinaciones del catálogo se componen con 2 bases (rizo, pompón), una matriz de color para el pelaje y 2 capas superpuestas (peto y pañuelo) extraídas por diferencia: [hoja de 16 combinaciones](capturas/meshy-16-combinaciones.jpg). Ropa, pañuelo y expresiones conservan la pose de la base (IoU 0,97–0,99).
- Integrado después en la sesión siguiente (ver abajo).
- Pendiente para integrar: pañuelo de perfil, variantes del salto (pompón, peto, pañuelo), expresiones del pompón, pose de comer/dormir; pintor por sprites (`ColorFilter.matrix` + capas) con las mismas poses y anclajes.

## Sesión 2026-11-17 · Caniche ilustrado por capas integrado

- 4 variantes más (36 créditos; saldo 788 → 752). Total de la jornada con Meshy: 180 créditos.
- Atlas reproducible: `tool/arte/build_pet_sprites.py` + `pet_sprites_spec.json` → `assets/images/pet/` (14 capas WebP) y `assets/data/pet-sprites-v1.json`.
- `PetSprites` carga el atlas sin bloquear el arranque; `PetPainter` lo usa cuando cubre el aspecto y, si falta alguna pieza o aún no ha cargado, dibuja el vectorial. Pelaje por `ColorFilter.matrix`, base por peinado, expresiones (parpadeo, alegría) en frente, capas de artículos en orden; galope alternando apoyo y salto; reacciones por transformaciones.
- Comprobación: `flutter analyze` sin incidencias; `validate_content` comprueba que cada peinado y artículo tiene capa en las 3 poses; `flutter test` **55/55** (nueva prueba: 16 combinaciones × 2 poses × 13 reacciones pintadas con el atlas); `flutter build web` correcto. Revisado en Chrome 390×844: Casa, Armario (vista previa pompón + peto + pañuelo, [captura](capturas/armario-sprites.jpg)) y Huerto (salto). Cuidados y Frisbee no revisados visualmente con el atlas.
- Limitaciones: no hay pose de comer ni de dormir propias (se simulan con transformaciones y ojos cerrados); el galope usa dos fotogramas; el espejo de peluquería y las zonas de espuma siguen posiciones aproximadas del caniche vectorial.

## Sesión 2026-11-17 · Poses, atrezo y escenas ilustradas

- 24 imágenes Meshy, **216 créditos** (saldo 752 → 536). Detalle y tareas en [arte/meshy/FUENTES.md](arte/meshy/FUENTES.md).
- **Fase 1 (código):** referencias del cuerpo calculadas desde el atlas; espuma, marcas del baño y mechones de la peluquería colocados con ellas; frisbee con intercepción en el aire, disco en la boca al atrapar y volver, caniche un 35 % mayor; agua de la ducha en trazos; ayudas iniciales arriba para no tapar patas, cuenco ni bañera; atrezo cargado sin bloquear la escena (con respaldo vectorial).
- **Fase 2 (atrezo):** bañera con el caniche dentro, espuma ilustrada, cuenco que se vacía por tercios, peluquería con espejo pintado y reflejo de perfil.
- **Fase 3 (poses):** comer, dormir (descanso en Casa sin el cojín vectorial), galope de 3 fotogramas y trote de 4, despeinado por zonas, en todas las combinaciones de pelaje, peinado, ropa y cuello.
- **Comprobación:** `flutter analyze` sin incidencias; `validate_content` (7 poses ilustradas, 19 imágenes); `flutter test` **55/55** (la prueba del atlas cubre las 7 poses, el despeinado, las referencias y la selección de fotogramas); `flutter build web` correcto. Escenas renderizadas desde Flame con las imágenes reales: [cocina, baño, peluquería, descanso y frisbee](capturas/escenas-ilustradas.jpg), [poses y combinaciones](capturas/poses-caniche.jpg). En el navegador solo se revisó la cocina: el panel oculto limita los fotogramas y el propietario lo estaba usando.
- **Pendiente:** ver las animaciones a velocidad real en un dispositivo (masticar, galope, salto del frisbee); la peluquería tiene un tono distinto al resto de salas; el sendero del paseo sigue siendo vectorial.

## Sesión 2026-11-17 · Salud, veterinario, dormir, armario ampliado y cuatro ángulos

**Petición:** iconos de estado estilo Tamagotchi en el visor, veterinario con pastilla, enfermar (hambre, cansancio, suciedad o azar; máximo una vez por semana), dormir en su cama, más artículos en el armario con precios crecientes (y colores de una misma prenda al mismo precio), submenús de accesorios y ver al caniche desde cuatro ángulos. Las barras ya cambiaban con el tiempo (`NeedsClock`).

**Versiones:** Flutter 3.50.0, Dart 3.14, Flame 1.38.2. Esquema de guardado v1 sin cambios de versión: los campos nuevos (`sickSinceUtc`, `lastSickUtc`, `sickSeed`, ranuras `head/eyes/collar/paws`) son opcionales y una partida antigua (4 ranuras) carga sana y con las ranuras nuevas vacías. Probado también con una partida real de la sesión anterior guardada en el navegador.

**Implementado**
- Dominio: salud (`PetState`, `NeedsClock`, `Rules`), `CareKind.sleep/vet`, `PetCondition`, `SleepActivity`, `VetActivity`; reglas en `docs/FUNCIONAL.md` y `balance-v1.json` (`health`, `status`, `care.sleep`, `care.vet`, 42 `styles`; los dos JSON idénticos).
- UI: `StatusBubbles` (cinco iconos, columna junto al borde para no tapar al caniche), barra de salud, sugerencia por urgencia, tarjetas Dormir y Veterinario (insignia «¡Malito!»), pantallas y resultados, `TurnControl` de cuatro ángulos (Casa y Armario), armario con Colores/Peinados/Ropa/Accesorios y submenús, ropa agrupada por variedad, miniaturas ampliadas, modo demostración con «Ponerlo malito/Curarlo».
- Arte: 66 imágenes con Meshy (`nano-banana-2-lite`) + 4 correcciones; atlas de 92 WebP, pose de espalda, iconos de estado, cama, manta, consulta del veterinario. **237 créditos** (saldo 536 → 299). Detalle en [arte/meshy/FUENTES.md](arte/meshy/FUENTES.md).
- Carga perezosa de capas (`PetSprites.preload`/`PetPainter.warm`) para no cargar las 92 imágenes al arrancar.

**Pruebas:** `flutter analyze` sin incidencias; `dart run tool/validate_content.dart` (42 artículos, 8 poses, 27 imágenes); `flutter test` **84/84** (nuevas: `test/domain/health_test.dart`, `test/ui/features_test.dart` —iconos, veterinario enfermo y sano, dormir completo y abandonado, compra de lazo, precios por variedad, cuatro ángulos—, y ampliaciones de reglas y atlas); `flutter build web` correcto.

**Errores encontrados y corregidos en esta pasada:** el botón «Apagar la luz» no se activaba nunca porque la pantalla no se reconstruía al terminar de ponerse la manta; el encabezado de variedad del armario desbordaba en 354 px; la manta tapaba la cara del caniche.

**Comprobado a ojo en Chrome (390×844):** Casa con cinco iconos encendidos y caniche malito (tinte verdoso y gotas), veterinario completo (corazón, patas, pastilla, resultado «Malito → Sano»), armario (colores con precios crecientes, accesorios con submenús, vista previa de corona, diálogo de salir con cambios, vista de espaldas con corona), dormir (cama, manta, noche con luna y Zzz). Una partida de la sesión anterior cargó correctamente.

**No comprobado / limitaciones:** animaciones a velocidad real (el panel del navegador limita fotogramas); dispositivos reales; hueco visual por pulir tras mover la manta (ajustada sin volver a mirarla); los peinados y artículos nuevos no tienen pose de salto, comer ni galope (se usa el perfil o no se dibujan); la ropa de colores es una variante de tono de una sola capa (algunos tonos pueden verse menos naturales); aviso: el navegador conserva en caché los JSON del juego entre compilaciones locales (forzar recarga al probar).

## Sesión 2026-11-17 · Correcciones tras revisión de código

**Tarea:** corregir los hallazgos de la revisión del commit `8660bfb`. Flutter 3.50.0, sin cambios de esquema, balance ni dependencias.

**Implementado**
- `PetComponent.setLook`: el camino inmediato anula la carga pendiente; una carga antigua ya no sustituye a un aspecto más reciente.
- Casa: al acostarse, `TurnControl` vuelve a «De frente», el mismo ángulo con el que se dibuja.
- `VetGame.tapAt` no avanza mientras dura la animación del paso, igual que el botón.
- Malito se ve en todas las escenas de cuidado y en el Armario (`PetFx.withSick`; Baño y Peluquería conservan el estado).
- `StatusBubbles` solo anima si hay algún icono encendido.
- Resultado del veterinario: la subida de salud sale del recibo (`healthPoints` antes/después), no de un «+65» fijo.
- `PetCondition.need` unifica la relación estado→medida (`Rules.mostUrgent`, botón y navegación de Casa); `Texts.needActions` sustituye los textos repetidos; las pestañas del Armario usan el nombre e icono de su ranura.
- Sin cambios: el plazo semanal sigue contando desde que enferma (regla documentada en `FUNCIONAL.md`: «curar no reinicia el plazo de la semana»).

**Pruebas:** `flutter analyze` sin incidencias; `validate_content` correcto; `flutter test` **87/87** (nuevas: giro tras descansar —falla sin la corrección—, iconos que solo laten encendidos, relación estado→medida). No probado en dispositivo ni a ojo en navegador.

## Sesión 2026-11-17 · Decisión de monetización (solo documentación)

**Decisión del propietario:** descarga gratuita con lo básico jugable para siempre y una compra única «Versión completa» de 1,99 € / 1,99 US$; otras divisas al equivalente redondeado a ,49 o ,99. Sin publicidad, suscripciones ni venta de monedas. Cuidados y salud nunca se bloquean.

**Documentos actualizados:** FUNCIONAL (reparto gratis/completa de los 42 artículos y los dos juegos, reglas y precio), UI-UX (candados, «Pide ayuda a un adulto», pantalla Versión completa, puerta adulta), TECNICA (`in_app_purchase`, capas `store/`, documento de derecho, flujo de compra, revocación), ENTREGA (configuración de Play y App Store, tabla de precios, fichas), INTEGRACION (recorrido gratuito y diagnóstico), JUEGOS (`tier` por juego), FASES (F07 reescrita como 07.1–07.7), PRUEBAS (E11–E15, P06 y compra en dispositivo), README y CLAUDE.md.

**Implementado:** nada todavía. El código sigue con todo desbloqueado, `NoAds` y la banda simulada en el modo demostración. `balance-v1.json` aún no tiene `tier` ni `fullVersion`: se añaden en la tarea 07.1, a la vez en `docs/datos` y en `assets/data`, para no romper la validación de equivalencia.

**Datos pendientes del propietario:** identificador definitivo de la app (condiciona el ID del producto `mypoodle.full_version`), perfil de pagos de Play, acuerdo de apps de pago de Apple con datos bancarios y fiscales, y aprobación de la tabla de precios por divisa.


## Sesión 2026-11-17 · F07.1–07.4 versión completa con tienda simulada

**Tareas:** 07.1 a 07.4 de [FASES](FASES.md). Flutter 3.50.0 / Dart 3.14.0 / Flame 1.38.2. Sin dependencias nuevas: `in_app_purchase` llega en 07.5. Partida en esquema v1 sin cambios.

**Implementado**
- **07.1** Publicidad retirada: borrados `lib/ads/`, `AdsController`, `BannerSlot`, el interruptor de banda del modo demostración y el bloque `ads` del balance. `tier` en los 42 artículos (18 gratis y 24 de la versión completa) y en los dos juegos (Frisbee gratis, Huerto completo), y `fullVersion.productId = mypoodle.full_version`, en las dos copias de `balance-v1.json`. `Balance.fromJson` exige `tier`, un artículo inicial gratis, un artículo gratis comprable por ranura, un juego gratis y el producto. `tool/validate_content.dart` también rechaza el bloque `ads` y los SDK de anuncios, analítica o intermediarios de compras en `pubspec.yaml`.
- **07.2** Dominio puro `domain/entitlements.dart`: `Tier`, `Entitlement`, `StoreEvent` y `EntitlementRules` (`canAccess` y `apply`, idempotente por ID con memoria de 20; pendiente no desbloquea; cancelado o error solo deshacen un pendiente; revocación explícita). `Rules.applyLook(…, fullVersion:)` devuelve `RequiresFull` sin mutar si hay algo completo no poseído; `Rules.gameTier`, `Rules.lockedItems`.
- **07.3** `store/`: `StoreProvider`, `NoStore`, `SimulatedStore` (sin red, sin producto, demora, cancelación, error, pendiente aprobada o rechazada, reembolso, eventos repetidos) y `StoreController` (escribe el derecho → publica → cierra la transacción; si no se guarda, no se cierra; `notOwned` revoca, `unknown` conserva). `data/entitlement_store.dart`: `entitlement.json` con principal, copia y temporal; esquema futuro preservado; documento simulado ignorado en Release. AppRoot lo conecta y espera `purchases.start()` antes de Adopción o Casa. Proveedor: inyectable; por defecto `SimulatedStore` en debug/profile y `NoStore` en Release hasta 07.5. Reiniciar la partida no toca el derecho.
- **07.4** UI: candado «Versión completa» en la tarjeta del Huerto (botón «Ver») y en los artículos del Armario (se prueban; el botón pasa a «Versión completa»). `ui/ask_adult_view.dart` («Pide ayuda a un adulto», Volver conserva la vista previa), `ui/parental_gate.dart` (número 21–99 en letras, teclado numérico, nuevo número tras cada fallo, espera de 30 s tras tres fallos que no se salta cerrando) en lugar de la pulsación de 2 s en Ajustes y en el reinicio de partida dañada, `ui/full_version_view.dart` con cargando, disponible, no disponible sin conexión, comprando, restaurando, esperando la aprobación, desbloqueada, cancelada, error con Reintentar, «Restaurar compras» y enlace a Privacidad. Entrada desde Zona adulta. Modo demostración: empieza gratis y añade «Simular versión completa», «Simular compra pendiente» y «Simular reembolso», solo en memoria. `AppController.beginGame` rechaza un juego completo sin derecho (segunda comprobación tras la tarjeta). Textos de Zona adulta, Privacidad y Ayuda reescritos: sin publicidad y con la compra única.

**Pruebas (este Mac)**

| Comando | Resultado |
|---|---|
| `flutter analyze` | Sin incidencias |
| `dart run tool/validate_content.dart` | «42 artículos (18 gratis, 24 de la versión completa), producto mypoodle.full_version, 8 poses ilustradas, 27 imágenes» |
| `flutter test` | **110/110** pasan |
| `flutter build web --release` | Correcto |

- Nuevas: `test/domain/entitlements_test.dart` (reparto del catálogo, E11, E12, E13), `test/data/entitlement_store_test.dart` (E14), `test/store/store_controller_test.dart` (E15, compra, cancelada, error, pendiente aprobada y rechazada, sin red, restaurar, demostración, NoStore), `test/ui/gate_test.dart` reescrita para la puerta nueva, P06 en `app_flow_test.dart` a 320×568 y 430×932 (candados, Volver sin cambios, fallo y acierto de la puerta, sin red → Reintentar, cancelada, error, pendiente → aprobada, sin ofertas en Casa). Los recorridos del Huerto y las compras de artículos completos del Armario arrancan con `SimulatedStore(owned: true)`.
- P06 encontró un desborde de 20 px del diálogo de la puerta adulta en 320×568: corregido con contenido desplazable.
- Navegador (build Release, 375×812): candado en el Huerto, «Pide ayuda a un adulto», puerta adulta y pantalla Versión completa en estado «No disponible ahora» (Release usa `NoStore`). El primer toque en «Soy un adulto» tras la transición no respondió y el segundo sí; no se reprodujo en las pruebas de widgets.

**No probado / pendiente**
- 07.5 `in_app_purchase` (`IapStore`, capacidad In-App Purchase y archivo StoreKit en iOS, permiso de facturación en Android) y 07.6 producto real en las tiendas: dependen de la verificación de versiones y de los datos del propietario de la sesión anterior.
- Evento de la tienda que llega en mitad de un juego: la app no abre pantallas por eventos, pero no hay prueba de widget específica.
- Nada probado en dispositivo.
