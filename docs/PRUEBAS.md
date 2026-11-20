# Verificación reproducible

Preparar test/domain, test/data, test/ui, test/game e integration_test. IClock ofrece UTC y reloj monótono activo independiente; FakeClock avanza explícitamente. SaveStore recibe directorio temporal único y escritor con fallos inyectables. Las pruebas Dart usan SimulatedStore o IapClient falso; la prueba nativa local usa StoreKitTest sin cuentas ni cargos. El recorrido adopción-compra utiliza dominio real.

## Ejecutar desde la raíz Flutter

Tras implementar F00 y los casos correspondientes:

```sh
flutter pub get
flutter analyze
dart run tool/validate_content.dart
flutter test --coverage
flutter devices
# Para iPhone: usar los comandos con --keep-app-running de la sección final.
```

El validador y `integration_test/device_smoke_test.dart` existen. El recorrido de integración actual cubre solo el smoke test móvil iOS/Android descrito abajo; no acredita toda la matriz de aceptación. Sustituir device-id por dispositivo real/emulador disponible. Exigir salida correcta y casos realmente ejecutados; conservar informes y logs con fecha/revisión. Avanzar componentes con tiempo controlado; evitar pumpAndSettle sobre un bucle Flame infinito. Una prueba de widgets no acredita backup nativo ni firma. [Pruebas de integración Flutter](https://docs.flutter.dev/testing/integration-tests).

## Casos de dominio y disco

| ID | Preparación y acción | Resultado obligatorio |
|---|---|---|
| E01 | Adoptar «  Miel  », «María José», nombre con acento combinante, vacío y 17 grafemas | Normalización NFC y recorte en los válidos; los inválidos no crean archivo |
| E02 | Fixture adoptada con saciedad 65. Avanzar 899 s, 1 s, otras 7 ventanas de 900 s | 65 → 64,25 → 59. Cursor reproduce el mismo valor tras reiniciar |
| E03 | Avanzar 48 h, volver una hora y consultar de nuevo | Pérdida limitada a 8 h, nuevo cursor conserva fracción y la lectura repetida no reaplica el tiempo |
| E04 | Completar comida con saciedad 95, paseo con energía 2, cepillado dos veces con mismo token | Saciedad 100, energía 0, higiene aumenta una sola vez por sesión confirmada |
| E05 | Saldo 9, 10 y 12 ante pañuelo; cancelar vista previa, comprar y reequipar | Operaciones rechazadas/canceladas no mutan; saldos 0 y 2 en las compras válidas, propiedad única |
| E06 | Texto JSON truncado, principal ausente con copia, versión futura, identificador de cosmético retirado | Recuperación de copia válida; esquema futuro preservado; fallback visual mantiene propiedad |
| E07 | Interrumpir antes de escribir, a mitad del temporal, tras cerrar temporal, tras reemplazar pero antes del recibo | Reabrir muestra última revisión válida. Reintentar con el mismo ID nunca suma dos premios |
| E08 | Enviar Finish después de cancelar, colisión duplicada de fruta, tres callbacks de disco para un tiro | Monedas y puntuación se conceden solo por eventos válidos y terminales |
| E09 | 0/7/12 frutas y 0/1/2/3 capturas | Premios 2/9/14 y 3/6/9/12. Métricas fuera de rango se rechazan |
| E10 | Construir catálogo con ID duplicada, referencia rota o artículo en ranura errónea | ValidateContent falla e identifica el recurso defectuoso antes de compilar |
| E11 | Sin versión completa: comprar outfit.sweater_red con 100 monedas, comprar neck.coral con 12, empezar Huerto y Frisbee, completar los seis cuidados | Jersey y Huerto → `requiresFull` sin mutar saldo ni propiedad; pañuelo → saldo 2; Frisbee y cuidados funcionan igual que con versión completa |
| E12 | Con versión completa: comprar jersey con 32 monedas y empezar Huerto. Después aplicar revocación confirmada | Compra correcta (saldo 0) y sesión creada. Tras revocar, el jersey sigue en propiedad, equipado y reequipable gratis; Huerto y compras `full` nuevas → `requiresFull` |
| E13 | Aplicar purchased, el mismo evento dos veces, restored, pending, canceled, error y un evento de otro producto | Un solo cambio a full; pending no desbloquea; canceled, error y otro producto no cambian el derecho; nunca cambian monedas ni propiedad |
| E14 | Documento de derecho ausente, truncado, con esquema futuro y con `source: simulated` en Release. Reiniciar la partida con versión completa | Ausente o dañado → gratis y la app arranca; esquema futuro se preserva; simulado se ignora en Release. El reinicio conserva la versión completa |
| E15 | Fallo inyectado al escribir el documento tras un evento purchased; sin red al arrancar con caché full; consulta Android `unknown` y `notOwned` | Sin escritura no se completa la transacción y se reintenta al reentregarla. Sin red se mantiene full. `unknown` conserva, `notOwned` revoca |

## Pruebas de interacción Flutter + Flame

1. **P01** Abrir Boot con directorio vacío, escribir Miel, adoptar, abrir cuenco y ofrecer tres bocados. Cambiar escena y recargar desde disco. Nombre Miel, saciedad 85, saldo 0 con reloj fijo.
2. **P02** Empezar baño, tocar una zona dos veces, salir. Comparar estado con fixture. Completar la secuencia con tres zonas distintas y aclarar. Higiene pasa de 70 a 95.
3. **P03** Caminar hasta tres puntos, pausar al segundo, reanudar y terminar. Ánimo 90 y energía 75 desde adopción. Cepillar y cancelar compra de corte; el corte natural permanece.
4. **P04** Completar el frisbee con tres capturas y reingresar al armario. Probar pañuelo, confirmar dos veces rápidamente, desequipar y reequipar. Saldo final 2 y propiedad única. Interrumpir una partida nueva de frisbee sin premio.
5. **P05** Inyectar 7 recogidas mediante colisiones en Orchard, caer y reaparecer, terminar. Añade 9 monedas aunque temporizador y meta terminen juntos. Enlazar con P04 produce saldo 11.
6. **P06** Sin versión completa, tocar el Huerto y un jersey: aparece «Pide ayuda a un adulto» y Volver regresa sin cambios. Fallar la puerta adulta tres veces (espera de 30 s), acertarla, comprar con SimulatedStore en cada estado (sin red, cancelada, error, pendiente → aprobada) y comprobar que solo la confirmada desbloquea. Un evento que llega mientras se juega al frisbee no abre ninguna pantalla ni cambia el premio. Ninguna oferta aparece al arrancar, en Casa ni en Resultado.
7. **P07** Alternar Home, CareRoom y juegos diez veces. Verificar un solo AppRoot, una instancia activa de juego y un oyente por evento. Usar Flutter DevTools en profile para buscar crecimiento persistente de atlas, componentes o audio.

## Matriz sobre teléfonos

- En pruebas de widgets y emuladores/simuladores comprobar 320×568, 390×844, 430×932 y un Android 360×800 lógico con navegación gestual. Probar apertura del teclado en adopción, textos largos, indicación de monedas y botón primario. Ambos pulgares deben poder jugar. Repetir en silencio y con movimiento reducido.
- En al menos un iPhone y un Android real: instalar limpia, jugar en modo avión, enviar al fondo durante salto, disco, compra y guardado, forzar cierre y arrancar de nuevo. Android Atrás sigue la navegación prevista, iOS puede perder foco por interrupción del sistema. Cerrar teclado no adopta ni cancela la partida.
- Para actualización, instalar A, adoptar y comprar pañuelo; instalar B sobre A con la misma firma/identidad. Nombre, saldo y aspecto quedan intactos. Para transferencia, migrar A a un segundo dispositivo por la vía del sistema; el segundo debe abrir Adopción y el primero conservar el pañuelo. Ejecutar el caso en ambos ecosistemas. Una reinstalación limpia no sustituye a esta prueba de migración.
- En teléfono de menor rendimiento elegido, medir arranque frío y 60 s por escena tras 10 s de calentamiento con Flutter DevTools en profile. Objetivos iniciales: 30 fps, p95 de fotograma ≤ 33,4 ms, arranque a pantalla interactiva ≤ 5 s, sin crecimiento sostenido tras diez ciclos. Medir desarrollo para diagnóstico y repetir percepción/carga con candidata Release. Si falla, identificar CPU/GPU/IO, ajustar atlas, transparencias, repintado o inicialización y repetir el mismo recorrido.
- Compra en dispositivo (iPhone y Android): con el archivo StoreKit en simulador, con sandbox o TestFlight en iPhone y con la prueba interna de Play y una cuenta de licencias en Android. Comprar, cerrar la app durante la confirmación y reabrir (se desbloquea una sola vez); compra pendiente y aprobación familiar; cancelar; restaurar tras reinstalar; reembolso de prueba; modo avión con versión completa ya comprada. Comprobar el precio localizado en al menos dos países o divisas de prueba.
- Evidencia por prueba: ID, SHA, versión Flutter/build number, dispositivo/OS, fixture, esperado, observado, captura o informe y estado. Un caso pendiente de hardware se queda pendiente. La apertura del diseño HTML verifica UX de referencia, no ejecuta estas pruebas Flutter/Flame.

## Personalización y simulación 2D

- **A01** Las 16 combinaciones iniciales conservan las otras ranuras al modificar una; comparar reposo, carrera, salto y captura en casa y juegos. Máscara de pelaje no tiñe ojos, ropa ni accesorios.
- **A02** Verificar cada pieza en todas las poses/vistas, pivotes y prioridades; detectar referencias o fotogramas ausentes antes de build. Añadir una pieza nueva sin duplicar animaciones completas por combinación.
- **A03** Ejecutar huerto con igual secuencia de entrada a 30/60 fps: misma trayectoria, frutas y premio; probar barrido con avance grande para evitar atravesar plataformas. El cambio de ropa no altera hitbox.
- **A04** Frisbee: mismas coordenadas de campo producen igual acierto/premio en cada tamaño; guía, disco y sombra coinciden con su proyección. Pausa no consume vuelo ni intento.


## Compras nativas F07.5

- `test/store/iap_store_test.dart`: selección de proveedor móvil/web/escritorio, precio localizado y producto ausente, compra no consumible/rechazo al iniciar, pendiente→aprobada, cancelación/error del flujo, IDs SHA-256 y duplicados, completar solo cuando el plugin lo pide, consulta Android (propiedad, pendiente, ausencia, error), restauración iOS solo explícita, revocación StoreKit y fallos de guardado/confirmación con reentrega. Comprueba que el archivo no contiene IDs originales ni recibos.
- `test/store/store_controller_test.dart`: una consulta anterior a una compra no puede revocarla; un evento de otro producto no modifica el flujo.
- `test/ui/app_flow_test.dart`: una compra externa durante Frisbee no abre rutas, conserva la actividad y no cambia las monedas.
- `ios/RunnerTests/RunnerTests.swift`: compra y reembolso locales hasta el estado persistido en Flutter. El archivo StoreKit forma parte solo de los recursos de RunnerTests. No acredita la interacción con la hoja nativa ni las compras reales.

Comandos Dart: `flutter analyze`, `dart run tool/validate_content.dart`, `flutter test`. Compilar web e iOS secuencialmente. Para la prueba nativa crear un simulador limpio con el runtime iOS disponible (ver `xcrun simctl list runtimes`) y ejecutar:

```sh
xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner \
  -configuration Debug -destination 'platform=iOS Simulator,id=<simulador-dedicado>' \
  -parallel-testing-enabled NO -resultBundlePath /tmp/MyPoodle-StoreKit.xcresult \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES
```

Guardar el `.xcresult` y consultar ESTADO para saber qué casos llegaron a ejecutarse. En esta máquina la prueba nativa falla con Code=3/notEntitled en iOS 26.5; no declararla pasada ni saltarla como éxito. Ver el [reporte de Apple](https://developer.apple.com/forums/thread/826971) y repetir en un runtime compatible o desde Xcode. Pendiente de acreditar en la hoja nativa: comprar, cancelar, aprobación/rechazo familiar, restaurar tras reinstalar y funcionamiento sin red. Las pruebas del adaptador con cliente falso no sustituyen esa aceptación.


## Recorrido físico iOS

`integration_test/device_smoke_test.dart` con el driver `test_driver/integration_test.dart` usa las pantallas y dominio reales, sprites y almacenamiento nativo. Solo inyecta un subdirectorio `MyPoodle/qa/QA_RUN` dentro del directorio privado devuelto por el canal Swift; no toca la partida normal ni la borra. La tienda es IapStore real; no envía compra ni restauración. La entrada de texto del harness está registrada explícitamente para Profile; el teclado iOS real queda fuera de esta prueba.

Dos invocaciones independientes con el mismo QA_RUN acreditan persistencia entre procesos. En la primera usar un ID nuevo, sin espacios ni barras. No reutilizarlo para una nueva partida ni desinstalar la app entre fases. `--keep-app-running` es obligatorio: Flutter drive desinstala la app por defecto al terminar y elimina los datos, incluidos los de la partida normal. No ejecutar el comando sin esta opción sobre una instalación personal. Desde la raíz, sustituyendo `<device-id>` por el iPhone conectado:

```sh
flutter drive --profile --keep-app-running -d <device-id>   --driver=test_driver/integration_test.dart   --target=integration_test/device_smoke_test.dart   --dart-define=QA_RUN=iphone_qa_unico

flutter drive --profile --keep-app-running -d <device-id>   --driver=test_driver/integration_test.dart   --target=integration_test/device_smoke_test.dart   --dart-define=QA_RUN=iphone_qa_unico --dart-define=QA_REOPEN=true
```

Guardar `build/integration_response_data.json` tras cada fase: la siguiente lo reemplaza. `bootToScreenMs` mide desde la creación de MyPoodleApp hasta encontrar Adopción/Casa; `bootToSceneMs`, hasta que la primera escena Flame declara isLoaded (sala cargada). No incluyen el arranque nativo del proceso, no garantizan todas las capas finales del caniche, y no equivalen a una medición de arranque frío con Instruments.

Al terminar reinstalar la entrada normal para dejar fuera el harness:

```sh
flutter run --profile --no-resident -d <device-id>
```

Mantener el iPhone desbloqueado al instalar/lanzar. Nunca interpretar el tiempo de compilación, instalación, espera de desbloqueo o conexión del depurador como tiempo de carga del juego. El modo Profile se usa para aproximar el rendimiento; las pruebas de teclado, segundo plano real, modo avión, transferencia de datos, tienda sandbox y medición de 60 s por escena siguen siendo comprobaciones distintas.


## Reanudación y comprobación manual offline

`test/ui/lifecycle_test.dart` verifica en widgets que Casa refresca necesidades al recibir resumed y que el Frisbee no avanza ni premia mientras está pausado, incluso al volver del segundo plano sin pulsar Continuar. AppRoot observa la reanudación para todas las rutas; ActivityFrame mantiene su pausa explícita. Estas pruebas inyectan eventos y no sustituyen la prueba física.

En el iPhone normal, sin reinstalar ni reiniciar la partida:

1. Activar modo avión y apagar también Wi-Fi; mantener el cable USB si se está depurando. Completar una comida, volver a Casa, cerrar la app desde el selector y reabrir. Comprobar caniche y estado conservados, y que se puede seguir jugando.
2. Abrir Frisbee y lanzar; salir a la pantalla de inicio de iOS, esperar y volver. Debe aparecer «En pausa». El juego debe seguir congelado hasta Continuar y no otorgar monedas por la interrupción. Terminar o abandonar según el flujo normal.
3. Volver a Casa tras una ausencia real; verificar que los indicadores se recalculan al regresar. Las necesidades cambian en bloques de 15 minutos: una ausencia corta puede no cambiar ningún valor y no acredita por sí sola este caso.

Registrar dispositivo, versión instalada, pasos, resultado y quién los observó. Un reporte del propietario se identifica como comprobación manual; una prueba de widgets no se etiqueta como prueba física. Al terminar, restaurar la conectividad del teléfono según la preferencia del propietario.


## Recorrido físico Android

El mismo `integration_test/device_smoke_test.dart` soporta Android. Usar un QA_RUN nuevo con prefijo android y el ID mostrado por flutter devices. Repetir con QA_REOPEN=true para conservar y leer el mismo subdirectorio QA:

```sh
flutter drive --profile --keep-app-running -d <android-id> --driver=test_driver/integration_test.dart --target=integration_test/device_smoke_test.dart --dart-define=QA_RUN=android_qa_unico
flutter drive --profile --keep-app-running -d <android-id> --driver=test_driver/integration_test.dart --target=integration_test/device_smoke_test.dart --dart-define=QA_RUN=android_qa_unico --dart-define=QA_REOPEN=true
```

Mantener el dispositivo desbloqueado y la app en primer plano. Una muestra que incluye suspensión de pantalla se descarta para rendimiento. Guardar el informe JSON tras cada proceso. No omitir --keep-app-running.

Al terminar, reconstruir `flutter build apk --release --target=lib/main.dart` e instalar mediante `adb -s <android-id> install -r build/app/outputs/flutter-apk/app-release.apk`; conservar la identidad y firma de la instalación. Release exige `android/key.properties` con la clave de subida (plantilla en `android/key.properties.example`; `storeFile` absoluto o relativo a `android/`); sin él `validateSigningRelease` falla y no hay firma debug de respaldo. Sin la clave, usar `flutter build apk --profile` para pruebas locales, sabiendo que no acredita firma de distribución. No desinstalar para solucionar una incompatibilidad de firma sin autorización del propietario.

Para validar Billing revisar `aapt dump permissions <apk>`, el manifiesto fusionado y `:app:dependencyInsight --configuration releaseRuntimeClasspath --dependency com.android.billingclient:billing`. Los permisos esperados y su procedencia constan en la sesión Android de ESTADO. La consulta de producto no acredita compra, aprobación, cancelación, restauración ni reembolso.


### Restauración con un derecho ya comprado

En build 0.1.0+2 o posterior: Ajustes → Acceso para personas adultas → puerta adulta → Ver versión completa y restaurar compras → Restaurar compras (desplazar la pantalla si hace falta). Anotar nombre y monedas antes; verificar progreso, fin sin error y conservación del derecho, la partida y las monedas. No usar «Reiniciar partida» para este caso. En build 1 el botón se ocultaba al estar comprada; ese recorrido no podía ejecutarse. Esta comprobación con derecho existente no sustituye restaurar en una instalación nueva, aún pendiente y con riesgo de perder la partida local si se desinstala sin exportación.

Resultado 17-11-2026: el propietario confirma en Xiaomi, tras actualizar desde Play a build 2, botón visible, restauración sin error y conservación del Huerto, caniche y monedas. Recuperación en instalación nueva u otro dispositivo sigue pendiente. «Restaurar compras» recupera el derecho de tienda a la versión completa; no recupera ni transfiere la partida local.


### Cancelación y compras pendientes Android (build 3)

1. Con la compra anterior reembolsada y revocada, comprobar Huerto bloqueado y anotar monedas. Abrir la hoja de Google Play desde Versión completa y salir con Atrás sin confirmar: debe terminar Comprando…, mostrar Compra cancelada y conservar bloqueo/partida/monedas. En build 2 este recorrido físico falló; build 3 corrige el evento genérico de cancelación sin ID de producto.
2. Con la cuenta de licencias y el aviso de no cobrar, seleccionar la tarjeta de prueba lenta que rechaza tras unos minutos. Mientras está pendiente: aviso de espera, Huerto bloqueado y monedas iguales. Restaurar compras durante la espera tampoco debe desbloquear ni confirmar el pago. Tras el rechazo y volver a la app con red (o reabrir), debe salir del estado pendiente y permitir reintentar, sin alterar la partida.
3. Repetir con la tarjeta de prueba lenta que aprueba tras unos minutos. Antes de aprobar, mismo bloqueo y ausencia de cambios de monedas; después de la confirmación de Google, desbloqueo una sola vez. Verificar también al volver del segundo plano o reabrir con conexión.

Protocolo: [Google, pruebas de Billing](https://developer.android.com/google/play/billing/test?hl=en). Registrar resultados físicos separados de pruebas automatizadas; no usar métodos de pago reales ni atribuir aceptación a casos aún pendientes. No es necesario reiniciar o borrar la partida.


Resultado físico 18-11-2026, Xiaomi/build 3, confirmado por el propietario: cancelación con Atrás sin bloqueo; tarjeta lenta rechazada conserva el bloqueo durante la espera y permite reintentar tras el rechazo/reanudación; Restaurar compras durante pendiente conserva la espera; tarjeta lenta aprobada solo desbloquea después de la confirmación y reanudación. En todos conserva caniche y monedas. La consola acredita además pedido lento rechazado como Cancelado (0,00 EUR) y el reembolso anterior como Reembolsado. Restauración en instalación nueva y aceptación iOS siguen pendientes.

## MVP multilingüe, álbum y prueba diaria

- `dart run tool/validate_localizations.dart`: mismos mensajes y parámetros en los 11 catálogos; bloquea catálogos vacíos/incompletos.
- `test/l10n/app_strings_test.dart`: nombres, respaldo inglés, scripts chinos, parámetros, números de puerta adulta y persistencia.
- `test/ui/localization_photo_test.dart`: pantalla 320×568, nombre de jugador literal, controles de foto, álbum, juegos y puerta adulta para cada idioma.
- `test/domain/premium_trial_test.dart` y `test/ui/premium_trial_test.dart`: frontera 86.399/86.400 s, guardados antiguos, compra completa, fallo de escritura, concurrencia y abandono/reinicio.
- `test/data/photo_album_test.dart`: reinicio, eliminación, índice dañado, fallo de reemplazo y capacidad bajo escrituras simultáneas.

En iPhone comprobar con el 3D activo que la foto contiene al caniche con su ropa, pose y giro reales; volver del álbum no altera la partida. Probar guardar, ampliar, borrar y reabrir; los tests de widgets no acreditan el puente WebGL del dispositivo. Probar cambio de idioma, lectura CJK/cirílica, VoiceOver y textos largos a escala grande. La traducción inicial requiere revisión lingüística humana antes de producción. No marcar la compra Sandbox como aceptada por haber pasado la tienda simulada.

### Captura 3D nativa con datos aislados

```sh
flutter drive --driver=test_driver/photo_test.dart --target=integration_test/photo_snapshot_test.dart -d <simulador-propio> --dart-define=POODLE_LIVE_3D=true
```

Usa mascota y álbum en memoria, sin compras. Comprueba píxeles del PNG nativo, giro visible por botón, captura/composición de las dos poses y conservación de aspecto/monedas. El driver guarda PNG y métricas en `.build/photo-evidence/` (o `POODLE_PHOTO_EVIDENCE`). No ejecutar sobre un dispositivo que tenga otra sesión de QA en curso. La evidencia de simulador del 20-11-2026 está en `reviews/testflight-20261120/`.

## Comprobación manual TestFlight 0.5.0 (33) · 20-11-2026

El propietario confirma en iPhone: precio visible, cancelación, compra Sandbox con desbloqueo, reinicio y modo avión con derecho conservado, restauración con derecho existente conservando mascota/monedas/armario, y dos fotos 3D (de pie/tumbado) conservadas tras reabrir el álbum. [Registro por caso](reviews/testflight-20261120/iphone-sandbox.json). Estas comprobaciones manuales de TestFlight no cambian el resultado fallido de StoreKitTest local registrado arriba ni acreditan restauración limpia, pendiente/rechazo o revocación/reembolso. Borrado físico de fotos y QA lingüística, de accesibilidad y rendimiento siguen pendientes.
