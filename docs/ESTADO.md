# Estado de la implementación

## Comprobación física básica de beta interna superada · 20-11-2026

- **iPhone / TestFlight 0.5.0 (33)**: tras compra y cancelación correctas, el propietario confirma **«Todo correcto: reinicio, offline y restauración conservan el estado»**. Recorrido solicitado: cierre completo, modo avión y reapertura con versión completa; reconectar y Restaurar compras, conservando mascota, monedas y armario. Es restauración con derecho existente, no instalación limpia.
- Foto/álbum: confirma **«Sí, las dos fotos 3D se guardan y conservan»** para el recorrido de caniche vestido con giro, foto de pie y tumbado, cierre/reapertura y consulta/ampliación en el álbum. Borrado físico de fotos sigue pendiente. No se han recogido fotos personales, recibos ni credenciales.
- Primera beta interna funcional disponible con 11 variantes, prueba diaria premium y modo foto. Comprobación básica de compra y foto superada; no se declara cerrada la matriz ampliada: pendiente/aprobación/rechazo, restauración limpia y revocación/reembolso en entorno dedicado, revisión lingüística/accesibilidad, rendimiento, audio/interrupciones y catálogo 3D.
- [Registro físico actualizado](reviews/testflight-20261120/iphone-sandbox.json). Solo documentación/evidencia; la app instalada y la IPA siguen siendo la build (33), sin recompilar ni reinstalar.

## Compra Sandbox física confirmada · 20-11-2026

- El propietario confirma a las 10:08 (Madrid): «ya sale el precio» en la beta **0.5.0 (33)**. Después confirma: **«La cancelación funciona y la compra desbloquea la versión completa»**. Entorno de la app instalada: TestFlight/Sandbox. Resultado manual del propietario, sin capturar credenciales ni recibos.
- La incidencia inicial de producto no disponible queda resuelta sin cambiar código, build ni reinstalar. Compatible con propagación de metadatos de Apple; no se demuestra la causa por ese resultado.
- Solicitada la prueba de cerrar/reabrir sin conexión y restaurar con conexión conservando la partida, y la captura/álbum físico de dos poses. Pendientes hasta recibir resultado; no se acreditan por la compra básica ni por pruebas de simulador. Casos de pendiente/rechazo, restauración limpia y revocación/reembolso siguen pendientes en entorno dedicado.
- [Registro de aceptación física](reviews/testflight-20261120/iphone-sandbox.json). Las entradas anteriores conservan el estado observado antes de esta confirmación.

## Beta instalada, títulos y precio guardados · 20-11-2026

- Los 11 títulos de ficha están guardados y comprobados en una vista recargada: [tabla](IDIOMAS.md) y [registro](reviews/testflight-20261120/apple-configuration.json). Español: Mi Caniche: mascota virtual; francés: Mon Caniche : animal virtuel. Alemán/portugués conservan nombre corto; errores repetidos de una vista anterior resueltos desde estado actualizado, sin retirar localizaciones.
- Precio base **1,99 €**, España (EUR), guardado y visible en Current Price. Disponibilidad en **175 países/regiones** guardada tras autorización explícita. Acuerdo Paid Apps activo. La autorización resuelve los bloqueos previos de revisión automática; no se envía app/IAP a revisión comercial ni se publica producción.
- Apple terminó el procesamiento de **0.5.0 (33)**: **Ready to Test**, grupo interno **MVP Sandbox**, un tester (propietario). [Captura](reviews/testflight-20261120/testflight-ready33.jpg). El propietario confirma instalada y abierta desde TestFlight; devicectl confirma `com.betitoglez.mypoodle`, 0.5.0, build 33 en el iPhone 16 Pro.
- **Compra no acreditada**: el propietario informa producto/precio no disponible, también al Reintentar. Se acababan de guardar precio/disponibilidad; Apple documenta hasta una hora de propagación. Se comprueban identidad/producto, selección de tienda nativa en Release, firma/App ID y acuerdo activo. Propagación es una hipótesis; no se declara causa demostrada ni éxito de compra. Reintentar consulta; si persiste tras esa ventana, diagnosticar respuesta nativa sin datos sensibles. La beta instalada no cierra la aceptación física.
- [Precio guardado](reviews/testflight-20261120/apple-pricing.jpg), [disponibilidad guardada](reviews/testflight-20261120/apple-availability.jpg). Solo se versionan configuración pública y evidencia de la app; no datos bancarios/fiscales, credenciales, recibos ni partida.

## Títulos localizados y subida de beta · 20-11-2026

- El propietario exige el título traducido también en la ficha de tienda de las 11 variantes. Los nombres dentro de la app y bajo el icono ya están empaquetados. Elige **Mi Caniche: mascota virtual** para la ficha española y autoriza expresamente el precio base real de **1,99 €**. El precio todavía no está guardado en Apple. Francés requiere **Mon Caniche : animal virtuel** por colisión del nombre corto; verificar persistencia remota tras renovar sesión.
- PR #6 fusionada en main `bbdee915` tras segunda revisión de Codex sin incidencias sobre `793f62a`, con tres hilos anteriores resueltos. **221 pruebas** correctas y prueba nativa de foto en las dos poses. IPA **0.5.0 (33)** firmada y verificada; SHA-256 `9ec48847bc4cdfa70767fd23e9780ba6c5e823692fb97947eac0a4b2abd33073`. El árbol de código de main coincide con el revisado y empaquetado.
- El propietario desbloqueó el Mac e inició sesión en Xcode. Organizer reconoce la cuenta/equipo y se abrió explícitamente el Archive correcto (33); no se recompiló el workspace antiguo abierto en Xcode. Se inició distribución **TestFlight Internal Only** y se observó la espera de respuesta de análisis de App Store Connect. El Mac se volvió a bloquear antes de comprobar el resultado final. La sesión web caducó; se solicita renovarla para títulos/precio.
- El registro ContentDelivery del Archive (33) confirma **UPLOAD SUCCEEDED with no errors, 1 warning** a las 08:16:41 (hora local). Organizer indica «Upload completed with warnings»: el aviso 90725 trata del requisito de SDK que empieza en abril de 2027. La transferencia queda acreditada por ese registro; procesamiento en TestFlight, grupo con build distribuida, instalación y compra Sandbox continúan sin acreditar. Última versión física confirmada: **0.4.13 (31)**.

## Revisión de la candidata 0.5.0 (33) · 20-11-2026

- Codex #6 detectó tres P2: giro de foto expresado en radianes frente a píxeles, etiquetas sin traducir al comprar varios artículos y colisión entre colas de escritura de dos pantallas del álbum. Corregidos: giro visible por toque, traducción individual y cola compartida por backend mediante referencias débiles.
- La carrera se reproduce antes de la corrección (`photos-v1.json.tmp` ausente); la regresión pasa después. **221/221 pruebas** correctas y análisis sin incidencias.
- Prueba nativa iOS con un simulador aislado **My Poodle Photo QA**, sin compras y con partida/álbum en memoria: PNG nativo 542×639, 37.709 píxeles de modelo visibles, cambio medio 16,08 por canal al girar, foto compuesta de 1.085.332 bytes y dos fotos (de pie y tumbado). Inspección visual correcta; [foto](reviews/testflight-20261120/photo.png), [tumbado](reviews/testflight-20261120/resting-photo.png) y [métricas](reviews/testflight-20261120/results.json). No sustituye aceptación en el iPhone físico.
- La exportación automática encontró `No Accounts`; se creó el perfil explícito My Poodle App Store 20261120 y se exportó la IPA (32) con el certificado local existente. Firma de distribución estricta, 3D y 11 catálogos/nombres nativos verificados. Se prepara la (33) con las correcciones anteriores; el registro de la IPA concreta se genera localmente con su SHA-256.
- App Store Connect: producto no consumible con 11 idiomas y grupo interno MVP Sandbox preparado, distribución manual. Ninguna build subida/distribuida todavía. El Mac está bloqueado y Xcode sin sesión, por lo que se ha solicitado desbloqueo/inicio de sesión; siguen pendientes precio autorizado y variante de nombre español de ficha.
- Se solicita segunda revisión de Codex antes de fusionar; el resultado autoritativo de revisión/fusión está en [PR #6](https://github.com/betitoglez/my-poodle/pull/6).

## Candidata MVP 0.5.0 (32) · 20-11-2026

- Rama `codex/mvp-testflight-purchases` rebasada sobre main `f08fb2d`.
- Interfaz de 11 variantes y nombres nativos implementados: 559 mensajes por idioma, selector persistente, inglés de respaldo y ambos scripts chinos. La traducción inicial requiere revisión lingüística humana antes de producción.
- Modo foto con composición Flutter + PNG del visor nativo y álbum privado de 24 fotos; cupo premium de 24 h por juego, confirmado antes de entregar la sesión. Casos de fallo, concurrencia y reinicio probados.
- Análisis y validadores de contenido/idiomas correctos; **218/218 pruebas**. Los 11 recorridos de pantalla 320×568 cubren nombre literal, foto/álbum, juegos y pregunta adulta. Compilación iOS Release sin firma correcta con 3D activo; aún no acredita captura nativa en iPhone.
- Ficha Apple e IAP no consumible creados; IAP `6837002992` con 11 nombres/descripciones localizados. Precio real bloqueado por revisión automática hasta autorización explícita de 1,99 €. La variante del nombre español de ficha espera elección por colisión de «Mi Caniche».
- En preparación: Archive/IPA firmado, revisión de Codex, subida/procesamiento y aceptación Sandbox/3D física. No se consideran completados por este registro.

## Actualización de integración · 19-11-2026

- Compras: PR #5 fusionada en main (`f08fb2d`), 193 pruebas y revisión Codex sin incidencias. Esto no acredita compra física iPhone.
- App ID explícito registrado con In-App Purchase y ficha App Store Connect creada: Apple ID `6836995483`, Bundle ID `com.betitoglez.mypoodle`, SKU `mypoodle-ios`, inglés principal.
- Apple rechaza el nombre exacto de ficha «Mi Caniche» por estar ocupado; se espera elección del propietario para una variante. El nombre nativo español sigue siendo Mi Caniche.
- En desarrollo y validación: 11 idiomas, nombre nativo localizado, modo foto y cupo gratuito de juegos premium. La primera beta no se publica sin estos requisitos.

Registro vivo. Distingue **implementado**, **probado en este Mac** (pruebas automáticas, compilación, navegador) y **probado en dispositivo** (smoke test en iPhone; ver última sesión).

**Resumen histórico, 17-11-2026:** F07.1–07.4 completas; adaptador y configuración F07.5 implementados, 126 pruebas Flutter correctas y builds web/iOS correctos. Smoke tests iPhone/Xiaomi en Profile y persistencia entre procesos correctos; offline y pausa en Xiaomi confirmados manualmente. F07.5 sigue pendiente de aceptación de compras nativas: StoreKitTest falla en el simulador instalado y faltan los recorridos de compra en tiendas; Android SDK y APK ya están disponibles (ver sesión Android). Ver el registro F07.5; las tablas de sesiones anteriores son históricas.

## Sesión 2026-11-19 · MVP y preparación de TestFlight

Nuevo alcance confirmado: primera beta TestFlight con 11 idiomas, ambos chinos, nombres localizados, modo foto y un intento gratuito de cada juego premium cada 24 h. Inglés es respaldo y español usa Mi Caniche. Parejas, Simón de perritos y laberinto quedan en TODO por definir. Se integran las correcciones locales de compra conservando los avances del main; implementación y aceptación aún en curso. El alta y compra Apple, la subida de una build y su procesamiento no se declaran completados por tener código local.

## Sesión 2026-11-19 · Correcciones pendientes de compras

Integradas desde el clon original, sin sustituir el juego actual: Restaurar compras permanece visible al tener la versión completa, con progreso/error correcto; Android admite cancelación/error sin productID, no entrega ni confirma compras nativamente pendientes y reconcilia al reanudar una pendiente ya cancelada. Se conservan los estados de partida, los efectos y el visor 3D. Pruebas de restauración y reanudación incorporadas; análisis sin incidencias y 33 pruebas específicas correctas. La aceptación nativa iPhone sigue pendiente; estas correcciones no acreditan una compra Sandbox.

## Sesión 2026-11-19 · Revisión de Codex de la PR #4

La revisión de GitHub detecta un P2: una pista podía arrancar después de pedir silencio si la preparación seguía pendiente. Se revalidan las condiciones actuales, la pista solicitada y la destrucción del servicio tras cargar y antes de reanudar. Cinco pruebas de regresión reproducen primero el fallo y pasan con la corrección: silenciar, pausa de actividad, segundo plano, cierre y cambio de pista durante la preparación. Análisis y contenido correctos; **187/187 pruebas** correctas. Corrección subida para una segunda revisión antes de fusionar.

## Sesión 2026-11-19 · Corrección de activación del 3D en iPhone

El propietario detecta que no aparecen los diseños 3D. Causa verificada: `LivePoodleView.enabled` exige `POODLE_LIVE_3D=true`, pero las builds 0.4.11 y 0.4.12 se hicieron sin esa opción. Contenían el GLB y el código nativo, pero mostraban el respaldo 2D; los registros anteriores de empaquetado no acreditaban que el 3D estuviese activo. Fue un error de preparación de esas builds, no una pérdida de los diseños.

Se prepara **0.4.13 (31)** y se añade `tool/build_ios_3d.sh`, que activa la opción y verifica tanto el valor efectivo como el modelo empaquetado. Build Profile **0.4.13 (31)** correcta, instalada sobre la versión previa y abierta en primer plano. El script verifica `POODLE_LIVE_3D=true` decodificando la configuración efectiva y comprueba el GLB empaquetado. Firma estricta correcta. No se han cambiado las reglas ni los diseños: se activa su visor existente. La captura remota de pantalla no está disponible en este entorno. **Confirmación física manual del propietario: «Sí, aparece en 3D».** Esta confirmación acredita la visualización del caniche 3D en el iPhone; no equivale a una revisión completa de cuidados, vestuario o rendimiento.

## Sesión 2026-11-19 · main actualizado y rama rebasada

Por petición del propietario se descarga main directamente de GitHub por HTTPS (SSH agotó el tiempo de conexión), se actualiza main local a `54279f6` y se rebasa `codex/elevenlabs-sfx` sobre ese main. La música queda en un commit propio; los efectos ya incorporados en main por #3 no se duplican. Se conserva `codex/backup-music-before-main-20261119` como referencia previa. Se comprueba que main coincide con GitHub, que es ancestro de la rama y que el árbol tras el rebase coincide con el anterior.

iPhone actualizado y abierto con **0.4.12 (30)**, versión declarada también en pubspec. Análisis y validación correctos, **182/182 pruebas** correctas y build Profile desde la rama rebasada. Firma corregida y verificada antes de instalar. `devicectl` confirma versión y apertura en primer plano con terminación de cualquier instancia anterior. Hay otra instalación antigua `dev.mypoodle.myPoodle` 0.1.0 (1) con el mismo nombre; no se ha desinstalado ni modificado. La instalada y abierta es `com.betitoglez.mypoodle`.

## Sesión 2026-11-19 · iPhone 0.4.11 (29): música y versión actual

Actualización 21:43 (hora de Madrid): tras desbloquear el iPhone, `devicectl` abrió la app en primer plano y se verificó que el proceso del paquete instalado seguía en ejecución. La escucha y revisión visual quedan para la prueba manual del propietario.

Integradas las tres músicas sobre `bb85158` de este worktree, conservando caniche 3D, cuidados ampliados y efectos ElevenLabs. Un único reproductor selecciona Casa/menús, juegos o actividades por ruta; se mantienen las pausas y ajustes independientes de efectos. Fuentes y pistas en [AUDIO](AUDIO.md).

Verificación: análisis sin incidencias, validador correcto, 16 pruebas relevantes y **182/182 pruebas completas** correctas. Build Profile con entrada normal `lib/main.dart`, `--build-name 0.4.11 --build-number 29`; paquete incluye el caniche GLB, los efectos y las tres canciones (hashes coincidentes con las fuentes).

Instalación física completada sobre My Poodle 0.4.10 (28), manteniendo el identificador y sin desinstalar. Se corrigió un rechazo de firma de Flutter.framework por un Info.plist modificado después de firmar: frameworks y app firmados de nuevo con la identidad de desarrollo existente y entitlements preservados; verificación estricta correcta. `devicectl` confirma 0.4.11 (29). Lanzamiento automático bloqueado por el teléfono bloqueado; el propietario puede desbloquearlo y abrir My Poodle. Revisión visual y escucha físicas pendientes.

## Sesión 2026-11-18 · Piloto de prendas integradas

Alcance autorizado e implementado: gorro de lana, familia jersey y pañuelo coral. Seis recursos ilustrados locales, ajuste por pose mediante malla, oclusión del pelaje original y sombras recortadas al cuerpo. El resto del catálogo conserva su representación anterior. Capturas de frente, perfil y carrera sobre albaricoque, blanco y negro en [la revisión del piloto](reviews/integrated-pilot/README.md). Se descartó una primera prueba de texturas planas: no resolvía el volumen del jersey. Análisis limpio y 36 pruebas relevantes correctas, incluyendo facciones y regresión de artículos ajenos al piloto. Revisado visualmente en este Mac; valoración del propietario y dispositivo pendientes. Sin build de distribución; cambios sin commit del clon original respetados.

Segunda revisión del piloto: cuello, puños y bajo del jersey dejan pasar el pelaje del perro mediante contornos curvos. De perfil y en carrera, la manga gira con la pata y su abertura comparte la deformación de la tela. Se regeneraron las capturas del jersey, el pañuelo y el conjunto. La suite completa pasó con 147 pruebas y el análisis estático quedó limpio.

Tercera revisión del piloto. Los bordes del cuello se ajustan por pose para el pañuelo coral, el jersey, la pajarita, el pañuelo de punto y los tres collares. Se añaden tres sprites de espalda y capturas de los accesorios de cuello y el conjunto. La suite completa pasó con 148 pruebas, el análisis quedó limpio y se validaron los recursos. Revisión visual en el Mac.

Cuarta revisión del piloto. El jersey cubre el pecho y la cadera de perfil y se ajusta a ambas patas traseras de espaldas. Solo asoma una franja del pañuelo en la nuca y la cola queda a la vista. Se actualizaron las capturas del juego y las pruebas de cobertura.

## Sesión 2026-11-17 · Cuidados interactivos y revisión visual

Trabajo aislado en `feat/interactive-care`, partiendo de `fb4a500`, para respetar los cambios sin commit del clon original. Se configura el ID común `com.betitoglez.mypoodle` en Android/iOS. **Build de distribución pendiente de actualización de main y rebase por indicación del propietario.** No se ha probado esta revisión en dispositivo.

Implementado: paneles de necesidades y salud pulsables; seis raciones con coste/efectos atómicos y versión completa cuando corresponde; veterinario 30 monedas; dormir +60 energía/+10 ánimo; jugar −20 energía/−10 saciedad; energía cero bloquea actividades excepto dormir. Cada cuidado tiene plazo de 300 s al completar; juegos, tres inicios por ventana móvil de 300 s. Los plazos se guardan con compatibilidad con partidas anteriores.

Baño: ducha mantenida 5 s, cuatro zonas incluyendo cabeza, aclarado 5 s y secador 5 s. Peluquería: peine, tijeras y secador en tres zonas cada uno. Veterinario: seleccionar herramienta, auscultar y examinar manteniendo sobre zona, arrastrar pastilla. Herramientas visibles bajo el dedo; soltar interrumpe el trabajo temporizado. Cuenco dividido detrás/delante del hocico; cama con borde delante y manta limitada al lomo.

Arte: recoloreado por píxel en isolate y caché acotada, conservando facciones oscuras, alfa y microtextura; paletas con luces/sombras. Accesorios por anclajes y trazados escalables que sustituyen las capas contaminadas de pelo. Los accesorios ya no fuerzan pose estática al correr; patas articuladas para cortes sin galope propio. Huerto: seis frutas, césped/raíces/estratos/bancales y penalización de 5 s por caída. Frisbee: cinco intentos. Higiene: cinco fases bajo 65.

Verificación: pruebas del dominio, persistencia, gestos, navegación, reservas concurrentes, catálogo y renders reales. Evidencias reproducibles en `test/game/appearance_review_test.dart` y `test/ui/care_composition_review_test.dart` (`POODLE_REVIEW=1` guarda PNG en `docs/reviews/`). Resultado final de verificaciones, ver registro de entrega de esta revisión. Precio vegano provisional: 15 monedas, pendiente de concretar por el propietario.

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

## Sesión 2026-11-18 · PoC de vestuario 3D

Malla texturizada generada en Meshy 7.1 a partir de tres vistas y vestuario articulado en Blender 5.3.0. Se revisan tres conjuntos, dos cortes y cinco poses en el worktree de `poc/vestuario-3d`. Se reabrió la escena con sus texturas empaquetadas y se verificaron los 16 huesos, las claves de forma, el bucle de 12 imágenes y el recuento de 147.704 a 153.368 triángulos por configuración. Los [resultados y archivos editables](reviews/wardrobe-3d/README.md) incluyen la comparación con el 2D.

### Revisión de ropa y accesorios 3D

Se revisaron los materiales, las costuras, los volantes y el ajuste de los accesorios en Blender 5.3.0. El peto mantiene libre la cola y las botas tienen dos alturas de caña según la prenda. La recogida separa más las patas delanteras y traseras. Se regeneraron las 30 vistas, la comparativa 2D y 3D, la lámina de detalle y el bucle de 12 fotogramas. La escena reabre con las texturas empaquetadas. Las seis configuraciones vestidas tienen entre 148.468 y 162.752 triángulos. [Detalle de las prendas](reviews/wardrobe-3d/detalles-de-ropa.png).

### Montura Meshy y revisión de ángulos 3D

Se generó una montura privada en Meshy 7.1 Estándar por 20 créditos, a partir de una referencia frontal y otra lateral de la pieza. Se ajustó en Blender al hocico y las orejas, con apoyos nasales y lentes claras separadas. Se verificó la escena editable y se regeneraron 42 vistas de los dos peinados. Los seis conjuntos siguen por debajo de 200.000 triángulos. [Ajuste de la montura](reviews/wardrobe-3d/gafas-ajuste.png) · [Ángulos osito](reviews/wardrobe-3d/angulos-osito.png) · [Ángulos pompón](reviews/wardrobe-3d/angulos-pompon.png).

### Build de vestuario 3D en el Xiaomi

APK Release arm64 de 40,4 MB instalada por USB en el Redmi A5 con el nombre Vestuario 3D y el identificador `com.betitoglez.mypoodle.wardrobepreview`. ADB confirmó la instalación y el arranque de la actividad. La lista de paquetes confirmó también la instalación de My Poodle. Tras desbloquear el Xiaomi, se comprobó por toque el cambio de impermeable a peto, de osito a pompón, la vista cenital, la reproducción de la carrera con dos fotogramas distintos y la pose de recogida. El visor quedó abierto con el impermeable y las gafas de frente. En Flutter pasaron el análisis de la entrada de prueba y el test de selección de conjunto, peinado, vista cenital y carrera. Se verificaron 42 imágenes y los seis bucles prerenderizados.

### Casa y Armario con renderizado 3D en tiempo real

La variante Android 0.2.0 incluye la app y carga un GLB local con esqueleto en Casa y Armario. Tiene giro libre, respuesta de la cola a la caricia y una transición reversible entre las dos poses. En el Xiaomi Redmi A5 se comprobó el giro desde varios ángulos, el movimiento de cola, ambas poses y el conjunto de impermeable, gorro y gafas en el armario. Se abrió una partida de Frisbee con el sprite 2D. Pasaron 25 pruebas automatizadas de juegos y recorrido general. La app de prueba usa una partida separada con Miel. Los materiales de las prendas son simplificados y el catálogo sin modelo 3D usa el visor 2D. [Montaje y compilación del visor](reviews/wardrobe-3d/README.md#3d-en-tiempo-real-en-casa-y-armario).

### Telas de Blender en el visor 3D

La versión Android 0.2.1 (4) exporta mapas de color y normales de siete piezas del peto, el vestido y el impermeable. Se verificaron las coordenadas UV, los pesos y el clip de tumbarse del GLB. El APK Release arm64 de 62,3 MB se actualizó por USB en el Redmi A5. Se comprobaron los tres conjuntos de frente, al arrastrar hasta el perfil y tras tumbarse y levantarse. Quedó abierta la vista previa del peto en Armario. La iluminación corresponde a la escena en tiempo real. [Montaje y compilación del visor](reviews/wardrobe-3d/README.md#3d-en-tiempo-real-en-casa-y-armario).

La versión 0.2.2 completa los acabados de los ocho artículos del piloto 3D. Incluye las telas y remates, la lana, el caucho y el acetato con vetas y lentes transparentes. En el Redmi A5 se recorrieron los tres conjuntos con giro y cambio de pose. Se corrigió la holgura al tumbarse y se verificó el GLB final en 16 vistas WebGL con los tres conjuntos y una combinación mixta con corte pompón. En la combinación de impermeable y botas, las cañas todavía rozan las perneras en flexión. El APK Release arm64 de 64,7 MB corresponde a la compilación 6 del paquete de prueba.

La versión 0.2.3 (7) corrige el roce del impermeable con las cuatro botas al tumbarse. El GLB tiene una variante de la animación que adelanta las patas delanteras y deja espacio detrás. Las cañas se acortan al flexionar y vuelven a su altura al levantarse. La revisión de 49 muestras de la transición reprodujo la intersección original y confirmó la separación con la variante corregida. Las capturas WebGL verificaron ambos perfiles y la espalda, y se comprobó la vuelta a la pose de pie. El APK Release arm64 se instaló por USB en el Redmi A5 y se probó el conjunto de perfil y desde atrás antes de dejarlo de pie en el armario. **Looks 3D → Impermeable y botas** abre el conjunto de prueba.

La versión 0.3.0 (8) cubre las 27 prendas y accesorios de `balance-v1.json`, con ocho variantes de color que comparten modelos. Añade el corte cachorro al visor 3D. Se revisaron 12 combinaciones de frente, perfil, espalda y tumbado desde dos ángulos. La comprobación geométrica de 11 pares de prendas y calzado cubrió 49 muestras por par sin cruces de malla. El peto con botas de lluvia se revisó visualmente con la caña recogida bajo la pernera. El conjunto de mayor detalle tiene 155.493 triángulos visibles. Pasaron el análisis de Flutter y las 15 pruebas de recorrido y armario. El APK Release arm64 de 69,4 MB se instaló por USB en el Redmi A5.

Tras desbloquear el Redmi A5, se comprobó la misma compilación con los tres Looks 3D nuevos al girar, tumbarse y levantarse. También se sustituyó el collar de perlas por el de chapa en el conjunto del vestido lila a través del selector del armario. Las miniaturas 2D de Colores pueden mostrar el color base del jersey mientras el visor aplica la variante elegida.

La versión 0.3.1 (9) usa 42 miniaturas WebP capturadas desde el visor 3D para todas las fichas del armario en la variante de prueba. Cada ficha muestra el artículo y la escena superior muestra la combinación. Se verificaron las 42 fichas contra el catálogo, incluido el azul del jersey, y se revisaron Colores, Ropa, Accesorios y Peinados en el Redmi A5 tras instalar el APK Release de 69,8 MB. Al elegir rojo o azul, la variante de la ficha coincidió con el visor en el teléfono. Pasaron el análisis de Flutter y las 15 pruebas de recorrido y armario.

La versión 0.3.2 (10) añade el caniche y el cuenco 3D a **Hora de comer**. La animación sigue el reloj de la actividad, incluida la pausa, y la zona táctil coincide con la proyección del cuenco. Se inspeccionaron 18 vistas WebGL con tres aspectos. En 49 muestras de la animación no se detectó cruce entre las mallas del cuenco, el perro y las botas de lluvia. El hocico queda por debajo del borde durante el bocado. Pasaron las 33 pruebas de comida, recorridos y simulaciones 2D. El APK Release de 69,8 MB quedó instalado por USB en el Redmi A5.

En el Redmi A5 se dio un bocado tocando el cuenco y otro con el botón. En ambos se observó el hocico por debajo del borde y la vuelta a la pose de pie. Tras el primer bocado, el borde del cuenco oculta el pienso restante desde la cámara lateral. Se descartó la comida de prueba antes del tercer bocado y se abrió Frisbee para comprobar su sprite 2D.

La versión 0.3.3 (11) eleva la cámara de **Hora de comer** y reduce la extensión y la altura del montón de pienso en cada bocado. La revisión WebGL distinguió el cuenco lleno, dos tercios, un tercio y vacío, con el hocico por debajo del borde durante el bocado. Las 22 pruebas de comida y recorridos pasaron. El APK Release de 69,8 MB se instaló por USB en el Redmi A5.

Tras desbloquear el Redmi A5, se verificaron el cuenco lleno, dos tercios y un tercio, además del hocico dentro del cuenco al masticar. Se dio el primer bocado tocando el cuenco y el segundo con el botón. Se descartó esa comida de prueba y se dejó seleccionada una ración nueva de pienso diario.

La versión 0.3.4 (12) añade el baño 3D con zonas táctiles sobre el lomo, las patas, el pecho y la cabeza. La ducha, el aclarado y el secador requieren cinco segundos de uso cada uno. La espuma sigue el progreso por zona y el pelaje recupera su acabado durante el secado. Se revisaron siete estados del baño en WebGL. Pasaron las 19 pruebas de cuidados y minijuegos 2D. El APK Release de 69,8 MB se instaló por USB en el Redmi A5.

En el Redmi A5 se completó el baño tocando directamente el caniche. La ducha conservó el progreso al soltar, las cuatro zonas reaccionaron al frotar, y se comprobó la retirada de espuma y el secador. La pantalla de resultado registró +25 de higiene, de 65 a 90, en la partida de prueba.

La versión 0.3.5 (13) añade la consulta veterinaria 3D con mesa, fonendoscopio, lupa y pastilla. Se revisaron seis poses y estados del visor WebGL. Pasaron 51 pruebas de cuidados, salud, coste y simulaciones de minijuegos 2D. Se instaló el APK Release en el Redmi A5 y se completó la consulta en modo demostración. Tras auscultar el pecho, revisar las patas y arrastrar la pastilla al hocico, Miel pasó de Malito a Sano y el saldo pasó de 100 a 70 monedas.

La versión 0.3.6 (14) incorpora la peluquería 3D. Peine, tijeras y secador modifican el pelaje en flequillo, orejas y lomo a medida que avanza el gesto. Los cortes que aún están en el catálogo se pueden previsualizar. Un corte adquirido se guarda en la misma operación que el cuidado. Se comprobaron siete estados WebGL, incluidas las variantes pompón y cachorro, y pasaron 41 pruebas de cuidados, catálogo y minijuegos 2D. El APK Release se instaló por USB en el Redmi A5.

En el Redmi A5 se eligió Corte pompón como vista previa y se completaron los nueve pasos arrastrando directamente sobre el caniche. Se comprobó el aplanado del pelo durante el peinado, la transformación del flequillo con las tijeras y el volumen tras secar. Se dejó abierta la vista previa terminada para revisar el corte.

La versión 0.3.7 (15) incorpora el descanso 3D en **Cuidados → Dormir** y al tocar el medidor de Energía. La cama recibe al caniche en una pose acurrucada. La manta se despliega sobre el cuerpo y sus bordes dejan libre la cabeza. El interruptor atenúa el salón, la cama y el pelaje. Se revisaron ocho estados y variantes en WebGL. Pasaron 43 pruebas, incluidas las de orden, recuperación de energía y los minijuegos 2D. Se instaló y verificó la versión en el Redmi A5 tocando la cama para acostar y arropar a Miel y luego el interruptor de la sala. El resultado registró 100 de energía y +10 de ánimo.

La versión 0.3.8 (16) incorpora el paseo 3D con pisada articulada, sendero de piedra, flores, banco y fuente. Cada parada requiere una indicación explícita de olfatear. Pasaron 33 pruebas de cuidados, recorrido y minijuegos 2D. Se instaló y completó el paseo en el Redmi A5 tocando las huellas y probando también el botón **Olfatear**. El resultado registró +15 de ánimo y −5 de energía.

La versión 0.3.9 (17) incorpora Huerto Saltarín en 3D con galope y salto articulados, bancales de tierra y ladrillo, y seis tipos de fruta en doce colocaciones. El juego conserva la simulación de salto, colección y recuperación. Cada caída descuenta cinco segundos una sola vez y se indica en pantalla. Se revisaron diez estados WebGL, pasaron 30 pruebas automatizadas y el APK Release se instaló en el Redmi A5. Frisbee conserva su escena 2D.

En el Redmi A5 se jugó desde la versión completa del modo demostración. Se hicieron saltos sobre el sendero, se recogieron cuatro frutas distintas y se verificó que una caída mostrara −5 s y devolviera a Miel al último apoyo con la puntuación intacta. La partida terminó con cuatro frutas y seis monedas de premio. Se dejó abierto el resultado para repetir desde allí.

La versión 0.4.0 (18) añade Frisbee 3D con 20 segundos y hasta cinco lanzamientos. Las escenas con visor muestran un indicador de carga. Se ajustó el tinte de los cuatro pelajes alternativos, la pisada del paseo, la cama y los collares. El armario reúne los artículos de cuello y conserva los IDs de guardado existentes. Se añadieron el corte de concurso inspirado en el Continental, una silueta propia para el corte Osito, gestos en reposo, efectos de estado y ocho herramientas ilustradas. Se revisaron los cambios visuales en WebGL. Pasaron 144 pruebas y el APK Release quedó instalado en el Redmi A5. En el teléfono se verificaron la carga con indicador, el jadeo y la cama en Casa, el disco en la boca y el resultado al agotarse el reloj. El lanzamiento por arrastre registró una captura y seis monedas.

## Prototipo de vestuario articulado en 2D

El prototipo ajusta el peto verde, el pañuelo coral y las botas de lluvia con los cortes osito y pompón. Comparte la anatomía por vista y usa el mismo esqueleto de perfil para las fases de carrera. Se activa en desarrollo con `--dart-define=POODLE_ARTICULATED_PILOT=true`.

Las [cinco poses de revisión](reviews/vestuario-articulado/cinco-poses.png) muestran frente, perfil, espalda y carrera en extensión y recogida. La [lámina de piezas](reviews/vestuario-articulado/piezas-por-separado.png) compara el peto con y sin pañuelo o botas. Se regeneran con `POODLE_REVIEW=1 flutter test --no-pub test/game/articulated_wardrobe_review_test.dart`. También quedan las comparativas de [varios conjuntos en 2D](reviews/combinaciones-2d/armario-2d.png) y del [mismo conjunto en varias poses](reviews/combinaciones-2d/mismo-conjunto.png).
