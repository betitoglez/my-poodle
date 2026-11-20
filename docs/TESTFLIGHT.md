# Primera beta de TestFlight

## Requisitos de esta beta

11 variantes (es/en/fr/de/pt-BR/it/ru/ko/ja/zh-Hans/zh-Hant), inglés de respaldo y nombres localizados; modo foto 3D y álbum privado; cupo gratuito de cada juego premium cada 24 h; compras nativas con restauración accesible. Los nuevos juegos de parejas, Simón y laberinto siguen por definir y no se anuncian como incluidos.

## Identidad y situación de Apple · 20-11-2026

- Team `79KBLB95KX`, Bundle ID `com.betitoglez.mypoodle`, Apple ID app `6836995483`, SKU `mypoodle-ios`; inglés principal. Los **11 títulos de ficha están guardados y verificados tras recargar**; ver [IDIOMAS](IDIOMAS.md).
- Producto no consumible `mypoodle.full_version` (`6837002992`) con 11 nombres/descripciones. **Precio base real de 1,99 € guardado y comprobado en Current Price**, España (EUR). Disponibilidad en los **175 países y regiones** guardada tras autorización explícita del propietario. Acuerdo Paid Apps **Active**. Family Sharing permanece desactivado; captura de revisión y publicación comercial pendientes.
- PR #5 de compras integrada (`f08fb2d`). PR #6 fusionada (`bbdee915`) tras segunda revisión de Codex sin incidencias sobre `793f62a`; 221 pruebas correctas y foto nativa en dos poses. PR #7 de documentación fusionada (`3ce260b`) con revisión limpia.
- **0.5.0 (33) subida, procesada y Ready to Test**, añadida al grupo interno **MVP Sandbox**, con el propietario como único tester. El propietario confirma instalada y abierta desde TestFlight; `devicectl` comprueba versión/build y Bundle ID en el iPhone. No se ha publicado en producción.
- **Compra Sandbox confirmada por el propietario en el iPhone**: el precio ya aparece, cancelar funciona y la compra de prueba desbloquea la versión completa en **0.5.0 (33)**. La disponibilidad inicial se resolvió sin nueva build ni reinstalación. También confirma reinicio, uso offline y restauración con derecho existente conservando mascota, monedas y armario. Pendiente/rechazo/revocación y restauración limpia siguen sin aceptación física. [Registro físico](reviews/testflight-20261120/iphone-sandbox.json).

**Comprobación física básica de la beta interna superada:** el propietario confirma además dos fotos 3D (de pie y tumbado), giro/ropa, guardado, conservación tras cerrar/reabrir y consulta del álbum según el recorrido solicitado. Borrado de fotos en dispositivo, revisión lingüística/accesibilidad/rendimiento y matriz ampliada siguen pendientes. La build continúa siendo la misma (33).

[Evidencia de configuración](reviews/testflight-20261120/apple-configuration.json), [precio](reviews/testflight-20261120/apple-pricing.jpg), [disponibilidad](reviews/testflight-20261120/apple-availability.jpg) y [TestFlight listo](reviews/testflight-20261120/testflight-ready33.jpg).

IPA (33), SHA-256 `9ec48847bc4cdfa70767fd23e9780ba6c5e823692fb97947eac0a4b2abd33073`: firma estricta de distribución, 3D y 11 catálogos/nombres nativos verificados. Las actualizaciones de documentación y metadatos no requieren recompilarla. ContentDelivery confirmó transferencia sin errores y con advertencia 90725 sobre SDK exigido desde abril de 2027; Apple terminó el procesamiento y la build ya es instalable.

## Incidencia inicial de producto no disponible · resuelta

El 20-11-2026, a las 10:08 (Madrid), el propietario confirma «ya sale el precio». Después confirma cancelación y compra con desbloqueo. No se cambió el binario ni se reinstaló. El resultado es compatible con propagación de Apple, sin demostrar la causa. Apple documenta hasta una hora de propagación en [TN3186](https://developer.apple.com/documentation/technotes/tn3186-troubleshooting-in-app-purchases-availability-in-the-sandbox).

Comprobados Bundle ID y producto coincidentes, App ID explícito con compras, perfil/certificado de distribución válidos, tienda nativa en Release, ausencia de StoreKit local en la IPA, nombres/precio/disponibilidad guardados y acuerdo de pago activo. La app muestra el precio real recibido de StoreKit; no sustituirlo por un importe fijo para habilitar la compra. Repetir la consulta tras propagación con conexión y registrar si aparece el precio o continúa el fallo. Si persiste pasada la ventana indicada por Apple, obtener diagnóstico de la respuesta nativa sin recibos/credenciales antes de cambiar código o reconstruir.

TestFlight usa Sandbox para las compras y no cobra al tester. Una cuenta Sandbox específica sirve para controles como Ask to Buy o revocación; esos casos se preparan en dispositivo de pruebas. No cerrar la sesión de compras de la cuenta personal ni borrar historiales para la primera compra simple. [Documentación de Apple](https://developer.apple.com/documentation/storekit/testing-in-app-purchases-with-sandbox).

## Generación y comprobación

```sh
flutter pub get
flutter analyze
dart run tool/validate_content.dart
dart run tool/validate_localizations.dart
flutter test
tool/build_testflight.sh
```

Fijar un número de build creciente en pubspec. Para exportación manual usar `POODLE_EXPORT_OPTIONS=.build/ExportOptions-TestFlight-local.plist tool/build_testflight.sh`; ese fichero local contiene la asignación del perfil y queda fuera de Git. El script usa Release, la entrada real y `POODLE_LIVE_3D=true`, exportación App Store Connect interna y el Team autorizado. Verifica el GLB, los 11 catálogos y nombres nativos, respaldo inglés e identidad. El archivo StoreKit local sirve para Debug/Test y no debe estar dentro del paquete de distribución. No sustituye Sandbox. Conservar SHA de Git, log, dSYM, SHA-256 de IPA y resultado de firma.

Usar Xcode Organizer para validar y subir el Archive/IPA autorizado, o la vía de carga autenticada que permita la cuenta. Si se requieren nuevos acuerdos, datos bancarios/fiscales o credenciales, el propietario los completa; no se guardan en el repositorio. No enviar a producción. Esperar a que la build figure procesada en TestFlight y añadirla a un grupo interno del propietario. La exportación inicial es solo para pruebas internas; una beta externa requiere su propio flujo de revisión.

## Compra en iPhone

1. Instalar la build exacta desde TestFlight como actualización sobre la app del mismo Bundle ID. Comprobar que conserva mascota y monedas. No desinstalar la partida personal.
2. Abrir Zona adulta → Versión completa. Verificar producto y precio localizado; superar la pregunta en el idioma elegido.
3. Cancelar una compra: continúa gratuita, no hay entrega ni cambios de saldo/armario. Confirmar compra de **prueba** en el entorno Sandbox de TestFlight y comprobar el desbloqueo. Si una hoja indica un cobro real, detener la prueba.
4. Cerrar y reabrir, probar sin conexión tras compra confirmada y restaurar desde la zona adulta incluso estando completa. Registrar el resultado, no credenciales ni recibos.
5. Usar instalación/dispositivo de pruebas para restauración limpia y escenarios de pendiente, rechazo y revocación que permita el entorno. No borrar datos personales para crear esos casos.
6. En la versión gratuita usar el Huerto una vez, abandonar y reabrir: conserva la espera de 24 h. Frisbee sigue libre. En la completa no se aplica el cupo de prueba; se mantienen energía y descanso generales.
7. Cambiar idioma y verificar adopción/Casa, cuidados, juegos, puerta adulta, compra, foto/álbum y mensajes de error. Guardar una foto con ropa/pose/giro 3D, reabrir, ampliar y borrar una foto de prueba.

Registrar versión/build, dispositivo/iOS, entorno, fecha, pasos y resultado en ESTADO. Tener un Archive, una ficha o un producto no equivale a tener una beta instalada ni una compra Sandbox aceptada.
