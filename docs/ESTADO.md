# Estado de la implementación

Registro vivo. Distingue **implementado**, **probado en este Mac** (pruebas automáticas, compilación, navegador) y **probado en dispositivo** (smoke test en iPhone; ver última sesión).

**Resumen vigente, 17-11-2026:** F07.1–07.4 completas; adaptador y configuración F07.5 implementados, 126 pruebas Flutter correctas y builds web/iOS correctos. Smoke tests iPhone/Xiaomi en Profile y persistencia entre procesos correctos; offline y pausa en Xiaomi confirmados manualmente. F07.5 sigue pendiente de aceptación de compras nativas: StoreKitTest falla en el simulador instalado y faltan los recorridos de compra en tiendas; Android SDK y APK ya están disponibles (ver sesión Android). Ver el registro F07.5; las tablas de sesiones anteriores son históricas.

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

## Sesión 2026-11-17 · Icono de la app y pantalla de arranque nativa

**Tarea:** sustituir el icono y el arranque por defecto de Flutter en Android, iOS y web (recursos de 00.4/08.1). Flutter 3.50.0, Xcode 26.6, Python 3.9 + Pillow 11.3 + numpy (solo herramienta local). Sin cambios en `lib/`, `pubspec.yaml`, esquema ni identificadores de paquete.

**Implementado**
- Diseño: cabeza del caniche feliz de Meshy (`docs/arte/meshy/originales/front_happy.webp`, sin créditos nuevos) sobre degradado ciruela (`AppColors.plum`), sin texto y fondo opaco. Se limpia el halo gris del recorte. Originales de 1024 px en [arte/icono/](arte/icono/): icono, capas adaptativas (primer plano, fondo, monocromo) y arranque.
- Generador reproducible: `python3 tool/arte/build_app_icons.py` escribe todos los tamaños; no añade dependencias al proyecto.
- Android: `mipmap-anydpi-v26/ic_launcher.xml` (fondo, primer plano y `monochrome` para iconos temáticos de Android 13; la silueta lleva ojos, trufa y boca recortados) y `ic_launcher.png` heredado por densidad (mdpi–xxxhdpi).
- iOS: los 19 tamaños de `AppIcon.appiconset` sin canal alfa (1024 comprobado con `sips`). `CFBundleName` pasa de `my_poodle` a «My Poodle».
- Web: `favicon.png` (32 px), `Icon-192/512`, `Icon-maskable-192/512` (zona segura del 80 %), `manifest.json` con fondo crema y tema ciruela, título de app iOS «My Poodle».
- Arranque, todo sobre `#FFF8E9` (`AppColors.cream`, fondo del `Scaffold` de `LoadingScreen`) con el caniche en un disco ciruela centrado:
  - Android 12+: `values-v31` y `values-night-v31/styles.xml` con `windowSplashScreenBackground` y `windowSplashScreenAnimatedIcon` (`drawable-*/splash_icon.png`, 288 dp con el disco en 190 dp para la máscara de 192 dp). Mismo crema en modo oscuro porque el juego no tiene tema oscuro.
  - Android ≤ 11: `drawable(-v21)/launch_background.xml` con color `@color/splash_background` y el mismo icono. `NormalTheme` usa también el crema.
  - iOS: `LaunchScreen.storyboard` con fondo crema y `LaunchImage` de 192 pt (@1x/@2x/@3x).
  - Web: capa `#splash` en `index.html` que se retira con el evento `flutter-first-frame`.

**Probado en este Mac**
- `flutter build web` correcto. En la vista previa web (servidor local): favicon, iconos y `splash.png` responden 200, fondo del `body` `rgb(255, 248, 233)`, la capa de arranque desaparece tras el primer fotograma y se ve centrada al reinsertarla.
- Revisados a ojo los PNG a 1024, 48, 32, 24 y 16 px: la cara se reconoce a 48 px; a 16 px (favicon pequeño) queda una mancha albaricoque con orejas.
- `flutter build ios --simulator --debug` correcto: `Assets.car` contiene `AppIcon` y `LaunchImage`, `CFBundleName` = «My Poodle».
- Simulador iOS (iPhone 17 Pro, iOS 26.5, instalado con `simctl`, sin el panel): arranque crema con el disco centrado, paso a Adopción sin destello de color e icono «My Poodle» en la pantalla de inicio. [Captura](arte/icono/simulador-ios.jpg).
- Android: no compilado (sigue sin Android SDK); los XML no se han validado con `aapt2`.

**No probado en dispositivo / pendiente**
- Icono adaptativo con distintas máscaras de lanzador, icono temático de Android 13, arranque de Android 12+ y ≤ 11: requiere Android SDK y un dispositivo o emulador.
- Icono y arranque en un iPhone real (solo comprobado en simulador).
- Si el icono se aprueba como definitivo, revisar con el propietario los términos comerciales de Meshy (ver [FUENTES.md](arte/meshy/FUENTES.md)) antes de publicar.

## Sesión 2026-11-17 · F07.5 compras nativas implementadas; validación parcial

**Alcance:** adaptador nativo, arranque, configuración y pruebas. Sin cambios de balance, monedas, catálogo ni esquema de partida. Sin productos creados en consolas, compras reales ni publicación. F07.5 sigue abierta por las pruebas nativas y Android pendientes.

### Versiones verificadas

| Pieza | Versión / requisito observado |
|---|---|
| Flutter / Dart / Flame | 3.50.0 (ab2912035e) / 3.14.0 / 1.38.2 |
| `in_app_purchase` | 3.3.1, fijado en pubspec y lockfile |
| Implementación Android / StoreKit | 0.5.5 / 0.4.17, fijadas como dependencias directas por usar sus APIs oficiales |
| Play Billing | 9.1.0 declarada en el Gradle del paquete Android descargado; grafo resuelto y manifiesto fusionado pendientes |
| Android | mínimo 24 en la app; compile/target heredados de Flutter; Android SDK ausente |
| iOS | mínimo 15.0 existente; StoreKit 2 por defecto; Swift Package Manager de Flutter |
| Crypto | 3.0.8 resuelto; SHA-256 para IDs de eventos |
| Xcode / simulador | 26.6 (17F113) / iPhone 17 Pro, runtime iOS 26.5 (23F77), creado solo para esta prueba |

Fuentes consultadas el 17 de noviembre de 2026: [plugin oficial](https://pub.dev/packages/in_app_purchase), [Android](https://pub.dev/packages/in_app_purchase_android), [StoreKit](https://pub.dev/packages/in_app_purchase_storekit) y el código de las versiones descargadas. [Calendario Billing](https://developer.android.com/google/play/billing/deprecation-faq): Billing 9 figura admitida para nuevas apps y actualizaciones hasta 31-08-2028; revisar de nuevo antes de distribuir.

### Implementado

- `store/iap_client.dart`: frontera inyectable con el plugin oficial; compra no consumible, restauración, consulta Android y confirmación. Datos de compra nativos solo en memoria.
- `store/iap_store.dart`: suscripción al escuchar los eventos antes de Casa; precio localizado, producto ausente, pendiente, cancelación, error, compra y restauración. ID estable SHA-256 separado por estado para que una aprobación no se descarte como duplicado de su pendiente. Solo entrega el producto del balance. Confirma únicamente cuando lo pide `pendingCompletePurchase`, después de guardar el derecho. Si guardar o confirmar falla, permite la reentrega. No registra excepciones nativas de confirmación con posibles datos de transacción.
- Android consulta propiedad sin interacción: devuelve `owned` para compra confirmada, `notOwned` solo ante respuesta correcta sin el producto, `unknown` para error, timeout, no disponible o pendiente. Reentrega las compras consultadas para confirmar las que aún estén pendientes de acknowledgement.
- iOS no restaura automáticamente. Lee `revocationDate` del JSON de la transacción StoreKit 2 verificada que entrega el plugin y traduce la actualización a `revoked`; no interpreta una restauración vacía como reembolso. El JSON no se persiste.
- `default_store.dart` y AppRoot: IapStore en Android/iOS para Debug/Profile/Release; NoStore en web/escritorio sin tocar el singleton nativo. SimulatedStore solo por inyección expresa. El modo demostración conserva su superposición en memoria. Los derechos simulados se ignoran con proveedor nativo incluso en Debug, y siempre en Release.
- StoreController ignora eventos de otros productos y descarta consultas de propiedad anteriores a un evento más reciente, evitando revocar una compra recién confirmada.
- iOS: capacidad In-App Purchase, `Runner/MyPoodle.storekit` con un no consumible local y selección en Run/Debug y Test del esquema compartido. El archivo se copia solo a los recursos de RunnerTests. Android: permiso BILLING explícito y mínimo 24; la app no fuerza la biblioteca Billing.
- `RunnerTests.swift`: prueba nativa escrita para compra/reembolso → plugin → Dart → archivo de derecho. Compila, pero su ejecución está bloqueada por el fallo de StoreKitTest descrito abajo; no se acredita su recorrido.
- README, TODO, FASES, TECNICA, INTEGRACION, PRUEBAS y ENTREGA reconciliados con lo implementado y sus límites. Retiradas las referencias obsoletas del README a banner, todo desbloqueado y pulsación adulta de 2 s.

### Verificado en este Mac

| Comando / comprobación | Resultado |
|---|---|
| `flutter analyze` | Sin incidencias; repetido tras los ajustes finales |
| `dart run tool/validate_content.dart` | 42 artículos (18 gratis / 24 completos), producto, 8 poses y 27 imágenes válidos |
| `flutter test --reporter expanded` | **124/124 pasan** |
| `flutter test test/store --reporter expanded` | **23/23 pasan** tras el ajuste final del fallback de ID vacío y del log de confirmación |
| `flutter build web --release` | Correcto; también el dry run Wasm |
| `flutter build ios --simulator --debug` | Correcto, plugin registrado y compilado con Swift Package Manager |
| `xcodebuild test`, simulador dedicado | Compila app y RunnerTests. Prueba nativa **fallida**: StoreKitTest no puede guardar la configuración (SKInternalErrorDomain Code=3) y `buyProduct` devuelve `notEntitled`; no llega a compra ni reembolso |
| `flutter build apk --debug` | **No compila**: «No Android SDK found». No se acredita APK ni manifiesto fusionado |
| `git diff --check` | Correcto |

Pruebas nuevas: 11 del adaptador nativo con IapClient falso, dos del controlador y un recorrido de widgets con compra externa durante Frisbee (conserva pantalla y monedas). Incluyen consulta Android con compra y pendiente, revocación StoreKit, fallo de disco antes de confirmar, fallo de confirmación y reentrega, privacidad del documento, duplicados y separación de proveedores. Los clientes falsos no sustituyen una compra en la hoja nativa.

La prueba nativa se intentó sin firma y con firma ad hoc de simulador, con StoreKit local en Run y Test: mismo Code=3/notEntitled. No se usó firma de distribución. El comportamiento observado coincide con el [hilo de Apple sobre StoreKitTest e iOS 26.5](https://developer.apple.com/forums/thread/826971); la coincidencia es una inferencia, no una causa demostrada aquí. Repetir con un runtime compatible o desde Xcode y registrar el resultado real. Informes locales de esta sesión: `/private/tmp/my-poodle-f075/StoreKit-run2.xcresult` y `StoreKit-run3.xcresult`; logs Flutter y builds en el mismo directorio (temporales, no versionados).

### Pendiente para cerrar F07.5 y continuar

1. Resolver StoreKitTest en un runtime compatible y acreditar compra, pendiente/aprobación/rechazo, cancelación, restauración, reinicio y reembolso desde la app/hoja nativa. La prueba Swift añadida cubre compra/reembolso cuando el entorno permita ejecutarla; el resto requiere recorrido adicional.
2. Instalar/configurar Android SDK y JDK, compilar APK y verificar `com.android.vending.BILLING`, metadato de versión Billing y permisos efectivos en el manifiesto fusionado. Verificar el grafo Gradle.
3. F07.6: confirmar Bundle ID/applicationId y producto definitivos; acuerdos de pagos, consolas, precios y pruebas sandbox/TestFlight/Play Internal con las cuentas del propietario. Un producto ausente muestra «No disponible ahora» y permite seguir jugando gratis.
4. F07.7: dispositivos reales, modo avión con derecho cacheado, segundo plano, restauración/transferencia y rendimiento. Ninguna compra nativa ni recorrido móvil real queda acreditado por esta sesión.


## Sesión 2026-11-17 · Smoke test físico en iPhone (Profile)

**Dispositivo y build:** iPhone 16 Pro, iOS 27.2.1, Flutter 3.50.0 / Dart 3.14.0, app 0.1.0+1. Firma de desarrollo con el Team ya configurado. Arranque normal Debug observado en Xcode con Impeller/Metal; después pruebas en Profile. No se publicó ni se hicieron compras.

**Implementado para las pruebas:** `integration_test` del SDK Flutter, `integration_test/device_smoke_test.dart` y `test_driver/integration_test.dart`. Se usan dominio, navegación, sprites, canal Swift y FileBackend reales, con la partida de prueba en `MyPoodle/qa/QA_RUN`. IapStore real; no se llama a comprar ni restaurar. El harness registra TestTextInput para inyectar texto en Profile: no acredita el teclado nativo.

### Resultados físicos

| Comprobación | Resultado |
|---|---|
| Firma, instalación y lanzamiento | Correctos en Debug y Profile; el primer lanzamiento Debug esperó al desbloqueo del teléfono y al depurador |
| Entrada normal tras los tests | Reinstalada `lib/main.dart` en Profile. Flutter perdió la conexión al terminar; se relanzó con devicectl y se verificó un proceso vivo que corresponde a la instalación actual, con el teléfono desbloqueado. El propietario confirma: «Sí, carga rápido y se ve el juego» |
| Primer proceso Profile | **Pasa**: Adopción, entrada de nombre, tres bocados, saciedad 65→85 una vez, monedas 0, archivo de partida nativo, acceso adulto y consulta del producto en Versión completa |
| Segundo proceso Profile | **Pasa**: conserva nombre, monedas, revisión y mejora de alimentación tras nueva ejecución; proveedor IapStore y caché simulada desactivada |
| Desde MyPoodleApp a pantalla | 24 ms en primera fase; 15 ms al reabrir |
| Desde MyPoodleApp a escena Flame cargada | 244 ms en primera fase; 247 ms al reabrir |
| Regresión en Mac | **124/124 pruebas Flutter pasan** tras añadir integration_test; flutter analyze y git diff --check correctos |

Evidencia resumida versionada en [pruebas/iphone-2026-11-17.json](pruebas/iphone-2026-11-17.json). Los informes originales del driver y logs están en `/private/tmp/my-poodle-device-qa/` (temporales, no versionados). Las dos invocaciones definitivas usaron QA_RUN=iphone_20261117_f y `--keep-app-running`, y finalizaron con «All tests passed» y «Leaving the application running».

**Interpretación de la demora inicial:** la carga lenta comunicada por el propietario ocurrió en el primer despliegue Debug. Hubo compilación, instalación, espera de desbloqueo y conexión del depurador. La demora no se reprodujo en la parte Flutter medida en Profile, pero estas dos muestras empiezan al crear MyPoodleApp: excluyen el arranque nativo, no garantizan que todas las capas del caniche estén listas y no acreditan el objetivo de arranque frío total ni la matriz de rendimiento. El propietario confirma que la entrada normal en Profile carga rápido y muestra el juego. Medir lanzamiento completo con Instruments si la demora vuelve a ocurrir; esta confirmación visual no es una medición de arranque frío.

**Incidencias del harness:** los primeros intentos fallaron en la automatización de texto; corregido el registro de TestTextInput para Profile. El primer intento de verificar reapertura falló porque `flutter drive` desinstala la app al terminar por defecto (`FlutterDriverService.stop` en el SDK), no porque fallase el lector de la partida. Los intentos iniciales retiraron la instalación del teléfono y sus datos; no se debe afirmar que una partida normal creada durante esos intentos se conservó. Se corrigieron comandos y documentación con `--keep-app-running`; la repetición definitiva conservó los archivos y pasó. No se borró ninguna partida mediante el código del test. Los comandos reproducibles están en [PRUEBAS](PRUEBAS.md#recorrido-físico-ios).

**Pendientes:** teclado iOS real, modo avión, interrupciones/segundo plano, restauración/transferencia de backup, muestreo de 60 s por escena, StoreKit local/sandbox (F07.5/07.6), Android SDK y aceptación Android. El smoke test físico cubre parte de F07.7, no cierra esa fase ni F07.5.


## Sesión 2026-11-17 · Reanudación corregida; offline y pausa Android comprobados

**Base:** 0a87e95; repositorio limpio al comenzar la corrección de reanudación. La continuación Android posterior usa Flutter drive con --keep-app-running; no se ha desinstalado la app en esas pruebas.

**Hallazgo y corrección:** AppController.onResumed solo se invocaba desde ActivityFrame. En Casa, Armario, Juegos o Ajustes, volver del segundo plano no notificaba inmediatamente al estado compartido; podía esperar al temporizador de 30 s. AppRoot ahora registra un WidgetsBindingObserver y notifica al controlador en resumed, retirándolo en dispose. ActivityFrame conserva la pausa de la escena y la obligación de pulsar Continuar, delegando el refresco compartido en AppRoot para evitar duplicarlo. No cambia guardado, balance, compras ni física.

**Pruebas:** `test/ui/lifecycle_test.dart` añade regreso a Casa tras una hora con FakeClock (saciedad 31→28, hambre visible al primer refresco, sin escribir una revisión) y frisbee congelado durante inactive/paused y tras resumed hasta Continuar, sin monedas. El helper de app_flow_test acepta un Clock inyectable. La prueba de Casa falla con AppRoot de 0a87e95 y pasa con la corrección. La batería completa pasa **126/126**; flutter analyze, validate_content y git diff --check correctos.

**Alcance de la evidencia:** los eventos de ciclo de vida de estas dos pruebas se inyectan desde el binding de widgets en el Mac. No acreditan interrupciones reales de iOS ni modo avión. Los logs temporales están en `/private/tmp/my-poodle-lifecycle/`.

**Validación física:** el propietario confirmó modo avión/Wi-Fi desactivado, comida y conservación al cerrar/reabrir en el Xiaomi (ver sesión Android); offline iPhone sigue pendiente. Build Profile compilada correctamente con `flutter build ios --profile` (Runner.app, 33,3 MB), preparada sin instalarla mientras el propietario hace esa comprobación. El propietario confirmó después en el Xiaomi que, tras salir al inicio de Android durante Frisbee y volver, aparece «En pausa» y solo continúa al pulsar Continuar. No se extiende esa prueba física a iOS. El refresco de necesidades tras una ausencia suficientemente larga requiere tiempo real o fixture controlada y sigue sin acreditarse físicamente.


## Sesión 2026-11-17 · Primera instalación en Android físico (Release)

**Base:** 0a87e95. Entorno instalado en el Mac: JDK 17 (Homebrew `openjdk@17`), SDK de Android en `~/Library/Android/sdk` con platform-tools 37.0.1, plataforma 36 y build-tools 36.0.0; `flutter config --android-sdk/--jdk-dir` apuntando a ellos y `flutter doctor` con Android correcto.

**Build:** `flutter build apk --release` → `app-release.apk` de 58,0 MB, firmado con la clave de depuración de la plantilla (no apto para tienda). El primer intento falló en `:in_app_purchase_android:lintVitalAnalyzeRelease` por un error interno de lint de AGP («Unexpected failure during lint analysis»). [android/build.gradle.kts](../android/build.gradle.kts) desactiva `lintVital*` solo en subproyectos distintos de `:app`; el lint de la app se mantiene. Con eso compila.

| Comprobación | Resultado |
| --- | --- |
| Dispositivo | Xiaomi Redmi A5 (25028RN03Y), Android 15, GPU Mali, Impeller sobre Vulkan |
| Instalación | `adb install -r` → Success |
| Arranque en frío | `am start -W`: 683 ms hasta la primera actividad dibujada; proceso estable |
| Primera pantalla | Adopción visible con arte, textos, sugerencias y botones sin desbordes |
| Errores | Ninguno de Flutter ni `AndroidRuntime`; solo avisos `mali_gralloc` de formatos no soportados, del driver y sin efecto visible |

**No acreditado todavía:** splash nativo de Android 12+ (el arranque es demasiado rápido para capturarlo) e icono adaptativo en el lanzador; adopción y recorrido completo; consulta del producto en Google Play (sin producto en consola, F07.6); modo avión, segundo plano y rendimiento de 60 s (F07.7). Implementado e instalado no equivale a aceptación Android.


## Sesión 2026-11-17 · Verificación Android en Redmi A5

**Entorno:** confirmado `flutter doctor -v` sin incidencias: Android SDK 36 / build-tools 36.0.0, JDK 17.0.21, dispositivo Xiaomi Redmi A5 (25028RN03Y), Android 15/API 35, arm64. Se conservan los cambios Android de la sesión anterior, incluido el workaround de lint; no se han reescrito ni revertido.

**Verificación del APK Release existente y del grafo:** `:app:dependencyInsight --configuration releaseRuntimeClasspath --dependency com.android.billingclient:billing --offline` correcto, versión **9.1.0** resuelta. El manifiesto fusionado y `aapt dump permissions` del APK confirman mínimo 24, objetivo 36 y metadato `com.google.android.play.billingclient.version=9.1.0`.

| Permiso en Release | Procedencia comprobada |
|---|---|
| `com.android.vending.BILLING` | Declaración de la app y Billing |
| `android.permission.INTERNET` | `transport-backend-cct:3.1.8`, transitivo de Billing |
| `android.permission.ACCESS_NETWORK_STATE` | `transport-backend-cct` / `transport-runtime:3.1.8`, transitivos de Billing |
| `dev.mypoodle.my_poodle.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | AndroidX core 1.15.0, protección signature para receptores internos |

La procedencia se comprobó en el reporte de fusión y en el POM de Billing descargado. No aparecen permisos de cámara, micrófono, ubicación ni AD_ID. Se corrige la expectativa documental anterior de «solo BILLING»; no se han eliminado dependencias a ciegas ni atribuido al SDK un comportamiento de recogida de datos no medido. La ficha de seguridad de datos y los textos definitivos deberán considerar también el tratamiento del SDK de facturación, como ya prevé F08. Se añade `/android/.kotlin/` a .gitignore por ser caché generada.

**Pruebas físicas automatizadas:** `integration_test/device_smoke_test.dart` ahora admite Android/iOS e informa la plataforma. Mismos datos QA aislados, IapStore real, sin comprar/restaurar; ambas invocaciones Profile usaron **--keep-app-running**, sin desinstalar ni reiniciar la partida normal.

| Caso | Resultado observado |
|---|---|
| Primer proceso Profile | **Pasa**: adopción, nombre, comida 65→85, monedas 0, guardado nativo, puerta adulta, consulta de producto y documento de prueba |
| Segundo proceso Profile | **Pasa**: conserva nombre, monedas, revisión y alimentación en un proceso nuevo; IapStore y rechazo de derechos simulados |
| Tiempos de reapertura desde MyPoodleApp | 40 ms a Casa, 375 ms a escena Flame cargada; excluyen arranque nativo y no acreditan todas las capas finales |
| Tiempo del primer proceso | **Descartado**: incluye varios minutos con pantalla apagada hasta desbloqueo del propietario; no se interpreta como carga lenta de la app |
| Offline manual | **Pasa, confirmado por el propietario**: modo avión, Wi-Fi desactivado, comida, cerrar desde selector y reabrir; conserva caniche y cambios |
| Segundo plano físico manual | **Pasa, confirmado por el propietario**: salir al inicio de Android durante un lanzamiento de Frisbee, esperar y volver; aparece «En pausa» y solo sigue al pulsar Continuar |
| Análisis estático | Correcto al ampliar el harness a Android |

El teléfono se detectó en reposo durante el primer recorrido (`mWakefulness=Asleep`); tras desbloquearlo el recorrido avanzó y terminó correctamente. Los avisos Mali de formatos R8/RGBA no se acompañaron de errores de Flutter/AndroidRuntime en la comprobación de ese proceso. Se conserva evidencia resumida en [pruebas/android-2026-11-17.json](pruebas/android-2026-11-17.json); logs temporales en `/private/tmp/my-poodle-android-qa/`.

**Entrega en el teléfono:** `flutter build apk --release --target=lib/main.dart` correcto (58,0 MB), `adb install -r` → Success, parada y lanzamiento de la actividad normal con `am start -W` → Status ok. Se conserva la instalación y sus datos; queda la entrada normal Release con la corrección de reanudación, no el harness. La firma sigue siendo la de depuración de la plantilla: no es un paquete publicable. Se mantiene el workaround de lint añadido antes de esta sesión; el lint completo de los plugins no se acredita.

**Pendientes:** compra real de prueba, pendiente/cancelación/restauración/reembolso en Play Internal (producto y cuenta del propietario, F07.6); StoreKit local/sandbox iOS; offline/segundo plano iPhone; teclado real, transferencia/restauración de backup y rendimiento de 60 s por escena. Android SDK, APK, grafo y manifiesto dejan de estar bloqueados. La confirmación offline corresponde al Xiaomi y no acredita offline en iPhone.


## Sesión 2026-11-17 · Identidad definitiva y compra preparada en Play (F07.6)

**Base:** `fb4a500`, commit y push directo a `main` completados antes de comenzar el alta. El propietario confirmó **My Poodle** y **`com.betitoglez.mypoodle` en Android e iOS**. Se actualizan namespace/applicationId, paquete y ruta Kotlin de MainActivity y Bundle IDs de Runner/RunnerTests. El producto conserva `mypoodle.full_version`, no consumible. El nombre visible ya era My Poodle. Las pruebas físicas anteriores corresponden a los IDs provisionales: el nuevo ID crea otra app y no migra automáticamente la partida. Se conservan las instalaciones anteriores de los teléfonos.

**Google Play:** ficha creada en la cuenta del propietario tras su autorización expresa de las declaraciones de políticas y exportación. Nombre My Poodle, paquete `com.betitoglez.mypoodle` (disponibilidad comprobada), idioma es-ES, juego gratuito. Google exigía subir una build con BILLING antes de habilitar el alta del producto. Tras procesar el AAB, el producto quedó creado y activo:

| Dato | Configuración verificada en consola |
|---|---|
| Producto | `mypoodle.full_version` |
| Nombre | Versión completa |
| Descripción es-ES | Desbloquea el Huerto y 24 artículos para personalizar el armario de tu caniche. |
| Opción de compra | `full-version-buy`, Comprar, **Activo**, **Retrocompatible** |
| España | **1,99 EUR**, fila principal con IVA 21 % y 4 anulaciones de ubicación |
| Estados Unidos | **1,99 USD**, fila principal sin IVA y 7 anulaciones de ubicación |
| Resto de territorios y nuevos países | No disponibles hasta revisar los precios |
| Unidades múltiples | Desactivadas |
| Clasificación del contenido | Contenido digital; categoría fiscal predeterminada Ventas de apps digitales |

**Detalle de precio observado:** el editor masivo aplicado a España transformó una entrada de 1,99 EUR en 2,39 EUR en la tabla final. Se corrigió la entrada a 1,64 EUR y se verificó **1,99 EUR** antes de activar. Para EE. UU. se eligió USD y 1,99; la tabla confirma **1,99 USD**. No se interpreta el número escrito en el editor como prueba del precio final. La hoja nativa y las anulaciones territoriales requieren verificación; no se ha acreditado el precio final en todos los estados/territorios. Resto de divisas pendiente de la regla de ENTREGA.

**Compatibilidad del plugin:** in_app_purchase_android 0.5.5 convierte productos únicos desde `oneTimePurchaseOfferDetails` (oferta individual). Google devuelve en esa ruta la oferta compatible con versiones anteriores. La consola confirma **Retrocompatible** en la primera opción Comprar creada; no se han añadido ofertas múltiples ni alquiler. La dependencia nativa sigue siendo Billing 9.1.0. Fuente: [Google, opciones múltiples y ofertas](https://developer.android.com/google/play/billing/one-time-product-multi-purchase-options-offers), consultada el 17-11-2026. La configuración de consola no sustituye la compra física.

**Canal interno:** lista exclusiva «My Poodle - prueba interna» con la cuenta del propietario confirmada por él como la usada en el Xiaomi, seleccionada y guardada en el canal. Añadida esa lista también a Licencia para testing, conservando las listas preexistentes y RESPOND_NORMALLY. Google confirmó los cambios guardados. La revisión inicial solo advertía que faltaban testers; tras asignarlos pasó a «Ya se puede publicar», sin advertencias. Versión **0.1.0+1** lanzada al canal interno: consola **Activo**, **Disponible para testers internos**, fecha mostrada 17 nov 21:53. Sin lanzamiento a producción. Nombre temporal de Play: `com.betitoglez.mypoodle (unreviewed)` hasta completar la ficha y revisión.

Enlace para aceptar la prueba e instalar desde Play: https://play.google.com/apps/internaltest/4701341682215171492. El propietario confirma instalación desde Play en el Xiaomi y precio **1,99 €** visible en Zona adulta → Versión completa. Al abrir Comprar confirma que la hoja de Google Play muestra la tarjeta de prueba y el aviso de que no se cobrará. La consulta nativa y el entorno sin cargo quedan acreditados por su confirmación manual. El propietario confirma después compra con la tarjeta de prueba que siempre se aprueba, reconocimiento de la versión completa y acceso al Huerto. **Compra nativa y desbloqueo: pasa (confirmación manual del propietario)**. No se ha inspeccionado un pedido ni extraído recibos/tokens; la confirmación funcional no acredita por sí sola acknowledgement en la consola. El propietario confirma también cierre desde el selector, modo avión y Wi-Fi desactivado, reapertura y acceso al Huerto: **persistencia del derecho comprado y uso offline tras reinicio: pasa**. La restauración manual no llegó a ejecutarse en build 1 porque se ocultaba el botón al tener el derecho (corregido en la sesión siguiente). Restauración en instalación nueva o segundo dispositivo también pendiente. Solo usar el método de pago de prueba de la cuenta con licencia para acreditar una compra sin cargo.

**Firma Android:** clave de subida RSA 2048, alias `upload`, validez 10.000 días, generada con autorización del propietario en `~/.config/my-poodle/signing/`; directorio 0700 y keystore/propiedades 0600. No hay contraseñas ni claves en Git/logs. `android/key.properties` ignorado; plantilla de ejemplo sin secretos. Gradle Release usa la configuración `release`, sin fallback a debug. Comprobado que, retirando temporalmente las propiedades, `:app:validateSigningRelease --offline` falla «Keystore file not set for signing config release»; propiedades restauradas. Copia segura fuera de este Mac a cargo del propietario, aún no acreditada.

| Verificación local | Resultado |
|---|---|
| flutter analyze | Sin incidencias |
| validate_content | 42 artículos, producto, 8 poses y 27 imágenes válidos |
| APK Release de identidad | Compila, 58,0 MB; todavía debug firmado antes del cambio de firma. aapt confirma paquete/actividad definitivos, BILLING, minSdk 24 y targetSdk 36 |
| AAB Release firmado | Compila, 57,7 MB, 0.1.0+1; procesado y aceptado por Google |
| Firma AAB | jarsigner verifica la firma; certificado CN=My Poodle Upload |
| iOS Release sin firma | Compila, 24,4 MB; Info.plist confirma `com.betitoglez.mypoodle` |
| Xcode y diff | plutil -lint y git diff --check correctos |

Huella SHA-256 del certificado de subida `77:9B:49:7A:BA:88:C2:60:CD:1D:A9:51:FF:99:56:A0:F8:29:CD:2C:8D:A2:60:D5:54:5B:15:94:F2:17:ED:B7`. SHA-256 del AAB `d510cd01b91f4d901c12660cba25fbdb81e92bb3573e18de9b9f3e7c9b448042`. El permiso interno AndroidX ahora usa `com.betitoglez.mypoodle.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. Evidencia resumida: [pruebas/google-play-2026-11-17.json](pruebas/google-play-2026-11-17.json).

**Apple:** errores 502/504 durante el inicio de sesión. El formulario reapareció en un reintento, pero el propietario confirma que sigue fallando y pide continuar con Android. No se ha accedido a la cuenta ni creado Bundle ID, ficha o producto remoto. La compilación local con el ID definitivo no acredita registro ni firma de distribución Apple.

**Pendientes F07.6:** pendiente/aprobación/rechazo, cancelación, restauración en instalación nueva/otro dispositivo y reembolso; revisión de precios/impuestos por territorios antes de ampliar disponibilidad; verificar pagos/acuerdos antes de producción; alta y sandbox Apple cuando vuelva el servicio. F07.5 y F07.7 conservan los pendientes físicos previos. Para acceso a producción, esta cuenta muestra además la exigencia de prueba cerrada con 12 testers durante 14 días; no bloqueó el canal interno.


## Sesión 2026-11-17 · Restaurar compras accesible tras comprar

**Hallazgo físico:** después de la compra y el reinicio offline comprobados, el propietario no encontraba «Restaurar compras» y veía «Reiniciar partida». Revisado el código: en 0.1.0+1 el botón de restauración solo se construía con `!p.full`, dentro de la pantalla Versión completa. La indicación de probarlo después de comprar era incorrecta. **La restauración física no se ejecutó en build 1.** Se indicó no pulsar Reiniciar partida; no se borra ni reinstala la app.

**Corrección:** FullVersionScreen mantiene Restaurar compras visible con y sin derecho, detrás de la puerta adulta existente; se desactiva mientras la tienda está ocupada. El acceso desde Zona adulta pasa a «Ver versión completa y restaurar compras» al tenerla comprada. El estado Restaurando compras… tiene prioridad sobre el agradecimiento y, si falla, muestra un aviso junto al derecho conservado. Su texto puede ajustarse en pantallas estrechas, evitando el desborde detectado a 320 px. No se modifican reglas de derecho, importes, monedas, formato de guardado ni reinicio de partida.

**Verificación local:** test/ui/full_version_restore_test.dart usa una tienda simulada controlable y el flujo real desde Zona adulta a 320×568: restaura con derecho ya existente, muestra progreso y desactiva el botón, termina con el derecho y archivo de partida intactos; después simula error y conserva ambos. Batería completa **127/127**, flutter analyze sin incidencias. Estas pruebas no acreditan restauración desde Google Play ni recuperación de una instalación nueva.

**Distribución:** versión incrementada a **0.1.0+2** para una actualización por Google Play con el mismo applicationId y firma. AAB firmado compilado correctamente (57,7 MB), misma huella de certificado de subida comprobada con keytool y firma verificada con jarsigner. SHA-256 `8a03cc075f2af85c34ab9f9035cd8df5d5eb096854d6cfb2bbf424f0f2e2666d`. Google procesó y revisó el AAB sin incidencias («Ya se puede publicar»). **Build 2 disponible para testers internos**, canal Activo, fecha mostrada 17 nov 22:18. Misma lista de testers y compra integrada, sin lanzamiento a producción. **Validación física: pasa, confirmación manual del propietario en Xiaomi tras actualizar a build 2.** El botón aparece, la restauración termina sin error y conserva el Huerto, el caniche y las monedas. Es una restauración con un derecho existente en la misma instalación; no acredita recuperación en una instalación nueva ni otro teléfono. La compra y uso offline de build 1 ya confirmados se conservan como evidencia histórica.


## Sesión 2026-11-17 · Cancelación, pendiente y reembolso Android

**Entorno:** Xiaomi del propietario, build Play Internal 0.1.0+2 y cuenta con licencia ya confirmadas. Partida existente conservada; no se borra ni reinstala. El propietario solicita expresamente estas pruebas.

**Reembolso en consola:** pedido original de My Poodle identificado por la etiqueta «Prueba: Versión completa», producto `mypoodle.full_version` y opción `full-version-buy`. Antes de la acción figuraba Procesado; su historial no mostraba reembolso automático. No se interpreta ese dato como una lectura directa del flag de acknowledgement. Reembolso de prueba al 100 %, motivo Otro y **Quitar acceso** seleccionado. La consola confirma **Reembolsado**, total 0,00 EUR, historial de reembolso del 17 nov 21:50:48 UTC. No se copia el token de compra ni se guardan IDs de pedido en el repositorio. Comprobación física confirmada por el propietario el **18-11-2026**: tras cerrar y reabrir con conexión vuelve el candado del Huerto, conservando caniche y monedas. **Reembolso con revocación: pasa**, con resultado de consola y confirmación manual en Xiaomi.

**Siguientes casos:** con la propiedad retirada, cerrar la hoja de compra sin confirmar para probar cancelación; después usar las tarjetas de prueba lentas para pendiente y aprobación/rechazo. Durante pendiente el Huerto debe seguir bloqueado. Registrar cada resultado físico por separado. Fuente del protocolo: [Google, pruebas de Billing](https://developer.android.com/google/play/billing/test?hl=en), consultada el 17-11-2026. La fila inicial «Pendiente / Order received» de un pedido aprobado al instante no acredita una compra pendiente observada en la app.


## Sesión 2026-11-18 · Continuación de aceptación Billing en Xiaomi

El propietario confirma el resultado físico del reembolso iniciado el día anterior: Huerto otra vez bloqueado, caniche y monedas conservados tras reabrir con conexión. Se registra como prueba manual sobre build 2, distinta de la confirmación del reembolso en consola. **Cancelación física en build 2: falla.** El propietario cierra la hoja con Atrás sin confirmar y la app mantiene indefinidamente el spinner «Comprando…». No se da por pasada la cancelación; no se inicia la prueba pendiente hasta distribuir la corrección.


### Corrección de cancelación y compras pendientes · build 3

**Causa reproducida:** in_app_purchase_android 0.5.5 emite PurchaseDetails con `productID` vacío y estado canceled/error cuando no hay una transacción. IapStore filtraba esos eventos por no coincidir con el producto y StoreController quedaba en buying. Se aceptan solo errores/cancelaciones genéricos sin producto en Android; compras, restauraciones, pendientes sin producto y eventos con otro producto siguen descartados. Los fallos genéricos no se envían a confirmación nativa.

**Pendientes revisadas antes de la prueba física:** restorePurchases de esa versión del plugin marca restored también en transacciones cuyo estado nativo sigue siendo pending. IapStore comprueba ahora PurchaseStateWrapper: una pendiente sigue siendo pending aunque se presente como restored y nunca se confirma; un éxito con estado nativo inválido se rechaza. La consulta de propiedad usa el estado nativo purchased. StoreController cancela una pendiente desaparecida solo ante consulta correcta sin propiedad; error/unknown conserva la pendiente. Al reanudar se consulta de nuevo la propiedad en proveedores con silentOwnershipQuery (Android), además del refresco de necesidades. iOS no inicia una restauración silenciosa.

**Regresiones:** cinco casos nuevos fallan antes de la corrección: cancelación sin producto, error sin producto, pendiente marcada restored, pendiente ausente tras consulta correcta y propiedad cambiada durante segundo plano. Pasan después; también se comprueba que una pendiente cancelada no se confirma. El recorrido de reanudación conserva exactamente el archivo de partida. Batería completa **132/132**, flutter analyze sin incidencias. Son pruebas con clientes falsos/tienda simulada y eventos de ciclo de vida inyectados; no acreditan pendiente o cancelación física corregidas. Logs temporales `/private/tmp/my-poodle-build3-before.log`, `my-poodle-build3-after.log` y `my-poodle-build3-final-tests.log`.

**Distribución:** versión 0.1.0+3 preparada para Play Internal, mismo paquete y firma. AAB compilado correctamente (57,8 MB), firma verificada con jarsigner y mismo certificado de subida. SHA-256 `72a0ebdee59afc839fcaff8309174234e9eaeaf6435bc053911c7eb45d5ec30f`. Google procesó y revisó sin incidencias («Ya se puede publicar»). **Disponible para testers internos**, canal Activo, fecha mostrada **18 nov 08:22**, versión **0.1.0 (3) - cancelación y compras pendientes**. **Cancelación física corregida: pasa**, confirmación manual del propietario en Xiaomi tras actualizar a build 3: al salir con Atrás desaparece Comprando…, aparece Compra cancelada, siguen el candado del Huerto, el caniche y las monedas. Aceptación de tarjetas lentas pendiente. No se borra la partida ni se modifica el catálogo o el precio.


**Continuación manual 18-11-2026, build 3:** cancelación con Atrás confirmada sin bloqueo ni cambios de partida. Siguiente prueba solicitada: tarjeta de prueba lenta que rechaza tras unos minutos, empezando por aviso de espera, Huerto bloqueado y monedas conservadas. Inicio y resultado pendiente/rechazado aún sin confirmar; no se marca pasada por la cancelación anterior.


**Tarjeta lenta que rechaza, estado inicial:** el propietario confirma en build 3 el aviso «Esperando la aprobación», Huerto bloqueado y monedas sin cambios tras confirmar la compra con el método de prueba. Esto acredita el estado pendiente sin entrega anticipada. Restauración durante la espera y resolución final del rechazo aún pendientes de confirmación.


**Restauración durante pendiente:** el propietario pulsa Restaurar compras y comunica que continúa mostrando «Esperando la aprobación». No se observa desbloqueo anticipado; se interpreta como conservación del estado pendiente, que es el resultado esperado. No se acredita por ese reporte un indicador de progreso visible ni una inspección del token/acknowledgement. Se solicita esperar la resolución de la tarjeta lenta y volver desde el inicio de Android con conexión para verificar salida de pendiente y reintento.


**Tarjeta lenta rechazada, resolución:** el propietario confirma que, tras unos minutos y volver a la app con conexión, desaparece la espera, permite volver a comprar y conserva Huerto bloqueado, caniche y monedas. **Pendiente → rechazada: pasa en build 3 (confirmación manual)**. Google Play muestra además el pedido de `mypoodle.full_version` del 18 nov 07:39 UTC como **Cancelado**, total **0,00 EUR**. No se registra el ID de pedido. La prueba anterior de reembolso sigue separada en consola como Reembolsado.

**Tarjeta lenta que aprueba, estado inicial:** el propietario confirma espera, Huerto aún bloqueado y monedas conservadas antes de la aprobación. Resolución final y desbloqueo tras volver a la app pendientes de confirmación; no se marca aprobada por haber iniciado el pago.


**Tarjeta lenta aprobada, resolución:** el propietario confirma que, tras esperar y volver a My Poodle con conexión, reconoce la versión completa, permite entrar al Huerto y conserva caniche y monedas. **Pendiente → aprobada: pasa en build 3 (confirmación manual)**. El estado inicial pendiente y su bloqueo se observaron antes de esta confirmación; no se atribuye compra instantánea a este caso.

### Resultado de esta aceptación Android

| Caso | Resultado físico acreditado |
|---|---|
| Cancelar la hoja con Atrás | Pasa en build 3: sale de Comprando…, aviso de cancelación, Huerto bloqueado y partida/monedas conservadas |
| Pendiente con tarjeta lenta de rechazo | Pasa: aviso de espera y sin desbloqueo; Restaurar compras mantiene la espera; tras rechazo y reanudación permite reintentar sin alterar partida/monedas. Consola: Cancelado, 0,00 EUR |
| Pendiente con tarjeta lenta de aprobación | Pasa: no desbloquea durante espera; tras aprobación y reanudación reconoce la versión completa y abre Huerto, conservando partida/monedas |
| Reembolso con Quitar acceso | Pasa: consola Reembolsado y, al reabrir con conexión, Huerto bloqueado; caniche y monedas conservados |

Resultados comunicados manualmente por el propietario en Xiaomi; consola del reembolso y rechazo observada por el agente. No se han leído archivos privados de partida, tokens o recibos en el teléfono. La batería automatizada de la corrección permanece en **132/132**; no se repite por incorporar estos resultados documentales. La instalación termina con la versión completa confirmada por la última compra de prueba, sin cargos reales y sin borrar ni reinstalar la app.

**Pendientes actuales:** restauración del derecho en una instalación nueva/otro dispositivo; configuración y aceptación iOS; precios/impuestos internacionales, revisión de pagos/acuerdos y requisitos de publicación. Permanecen también los casos de F07.7 aún no acreditados. La prueba de restauración con derecho existente no equivale a recuperar una compra desde una instalación vacía, ni recupera la partida local.

## Sesión 20-11-2026 · Revisión de código de la tienda (F07.5)

**Tarea:** corregir los hallazgos de la revisión del trabajo de builds 2–3. Flutter 3.50.0 estable; sin cambios de dependencias.

- Fallos genéricos Android sin producto: `IapStore` solo los acepta con una hoja de compra abierta y los emite sin producto. Las reglas del dominio ya no rebajan una compra pendiente ante cancelaciones/errores sin producto, ni ante errores del adaptador (`purchase_stream`, `invalid_android_purchase_state`…). Solo una cancelación o error del propio producto descarta la pendiente.
- `SimulatedStore.queryOwnership` devuelve `unknown` mientras hay una pendiente, como Google Play; reanudar ya no la cancela en desarrollo.
- Versión completa con derecho: avisa si la restauración no encuentra compras nuevas y usa un texto de error genérico.
- Firma Android: `storeFile` relativo a `android/`; PRUEBAS documenta que Release exige `key.properties` y la alternativa `--profile` sin clave.

| Comando | Resultado |
|---|---|
| `flutter analyze` | Sin incidencias |
| `flutter test` | **133/133** pasan |
| Build Android firmada | **No ejecutada** en esta sesión; el cambio de ruta de `storeFile` no se ha verificado con Gradle |

Implementado y probado de forma automatizada; no probado en dispositivo.
