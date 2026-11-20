# Primera beta de TestFlight

## Requisitos de esta beta

11 variantes (es/en/fr/de/pt-BR/it/ru/ko/ja/zh-Hans/zh-Hant), inglés de respaldo y nombres localizados; modo foto 3D y álbum privado; cupo gratuito de cada juego premium cada 24 h; compras nativas con restauración accesible. Los nuevos juegos de parejas, Simón y laberinto siguen por definir y no se anuncian como incluidos.

## Identidad y situación de Apple · 20-11-2026

- Team `79KBLB95KX`, Bundle ID `com.betitoglez.mypoodle`, Apple ID app `6836995483`, SKU `mypoodle-ios`; ficha creada e inglés principal.
- Producto **no consumible** `mypoodle.full_version`, Apple ID `6837002992`, creado. 11 nombres/descripciones de idioma guardados; precio base real de **1,99 € autorizado expresamente por el propietario**, todavía pendiente de guardar en Apple con España (EUR) como territorio base.
- «Mi Caniche» se conserva dentro de la app y bajo el icono. Apple rechaza ese nombre exacto de ficha por estar ocupado; el propietario ha elegido **Mi Caniche: mascota virtual** para la ficha española. Los títulos de ficha deben traducirse en las 11 variantes; ver [IDIOMAS](IDIOMAS.md).
- PR #5 de compras integrada en main (`f08fb2d`), 193 pruebas y Codex sin incidencias. PR #6 fusionada en main (`bbdee915`) tras corregir los tres P2 y recibir una segunda revisión de Codex sin incidencias sobre `793f62a`. Candidata **0.5.0 (33)** exportada, firma estricta, 3D y 11 catálogos/nombres nativos verificados; 221 pruebas correctas. La sesión de Xcode reconoce cuenta y equipo; la subida se inició desde Organizer sobre el Archive correcto. El Mac volvió a bloquearse durante la respuesta de Apple y la sesión web de App Store Connect caducó. ContentDelivery confirma **subida correcta sin errores y con una advertencia** a las 08:16:41 del 20-11-2026. Procesamiento en TestFlight, distribución y compra Sandbox aún sin acreditar.

El grupo interno **MVP Sandbox** está preparado con selección manual de builds; no tiene una build distribuida. El perfil **My Poodle App Store 20261120** está creado para el App ID y coincide con el certificado de distribución disponible. La cuenta en el navegador no inicia automáticamente una sesión de Xcode.

La IPA (33) tiene SHA-256 `9ec48847bc4cdfa70767fd23e9780ba6c5e823692fb97947eac0a4b2abd33073`. El árbol de la candidata revisada coincide con main fusionado; las actualizaciones de documentación o metadatos de tienda no requieren recompilarla. El aviso de Apple 90725 sobre el SDK exigido a partir de abril de 2027 es una advertencia futura. La transferencia correcta se acredita por «UPLOAD SUCCEEDED with no errors, 1 warning» en ContentDelivery; no acredita procesamiento.

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
