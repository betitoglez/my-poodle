# Compilación y distribución Flutter

## Preparación

Completar F00. Registrar versión exacta de Flutter/Dart/Flame, lockfile y herramientas nativas con flutter --version y flutter doctor -v. Comprobar identificador con el propietario antes de registrar tienda. Fijar version en pubspec.yaml (por ejemplo 0.1.0+1 solo para ficha nueva) y números internos crecientes. Firma y claves en almacén seguro local, nunca en repositorio o logs. Revisar requisitos actuales de SDK y tiendas al preparar candidata.

Los comandos siguientes son para la app que se implementará en F00; no acreditan que ya exista o compile. Desde la raíz:

```sh
flutter pub get
flutter analyze
dart run tool/validate_content.dart
flutter test
flutter build apk --debug
flutter build appbundle --release
flutter build ios --debug --no-codesign
flutter build ipa --release
```

Ejecutar builds de forma secuencial. Configurar firma antes del AAB/IPA. La compra real solo funciona en builds instaladas desde la tienda o con el entorno de pruebas de cada plataforma. iOS sin codesign comprueba compilación y no produce una app distribuible. Salidas habituales: build/app/outputs/flutter-apk/app-debug.apk, build/app/outputs/bundle/release/app-release.aab, build/ios/archive/ y build/ios/ipa/. Registrar la ruta efectiva devuelta por el SDK fijado. Guardar logs, hashes y símbolos generados junto a la candidata. Referencias: [Android con Flutter](https://docs.flutter.dev/deployment/android), [iOS con Flutter](https://docs.flutter.dev/deployment/ios).

## Android

1. Verificar SDK/JDK y teléfono con flutter doctor -v y flutter devices. Configurar applicationId, orientación y versiones mínimas/objetivo en android/ según Flutter, plugins y requisitos actuales de Play. No fijar niveles por una guía histórica.
2. Ejecutar flutter run -d <device-id> o instalar APK con adb install -r build/app/outputs/flutter-apk/app-debug.apk. Aceptar autorización USB en el teléfono. Probar offline, ciclo de vida y almacenamiento; diagnosticar logs filtrados sin datos de partida.
3. Configurar firma Release en Gradle con clave de subida y propiedades locales excluidas de Git. El propietario conserva alias, credenciales y copia segura. Activar Play App Signing en la ficha. [Firma Android](https://developer.android.com/studio/publish/app-signing).
4. Generar AAB, validar con bundletool y comprobar firma/hash/versionCode. Instalar desde pruebas internas de Play; AAB no se instala directamente con adb. Probar actualización con identidad de firma compatible.
5. Completar audiencia, privacidad, seguridad de datos, anuncios (ninguno), compras integradas, clasificación, países, soporte, capturas reales y pruebas que exija la cuenta. Publicar candidata probada cuando el propietario autorice distribución. [Lanzamiento Play](https://support.google.com/googleplay/android-developer/answer/9859348).

## iOS

1. Preparar Xcode y toolchain iOS de Flutter. Mantener configuración y puente Swift en ios/; resolver dependencias nativas según el método soportado por el SDK/plugins elegidos. Bundle ID, versión y build number deben coincidir con ficha.
2. Abrir ios/Runner.xcworkspace cuando corresponda al proyecto generado. Seleccionar Team autorizado y provisioning, conectar iPhone y ejecutar Runner o flutter run -d <device-id>. Probar teclado, audio, interrupciones y exclusión de backup en hardware.
3. Ejecutar flutter build ipa --release con firma válida. Inspeccionar archivo en Organizer y validar/distribuir a TestFlight/App Store. Conservar dSYM y metadatos de exportación. [Carga de builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/).
4. Probar instalación/actualización vía TestFlight. Preparar privacidad, licencias, capturas, clasificación y notas sobre adopción, juegos, versión completa y puerta adulta. Enviar la build exacta verificada y liberar según decisión del propietario.

## Compra integrada, precios y fichas

Una sola variante de build, sin publicidad. La versión completa es un producto no consumible (`mypoodle.full_version`, ver [TECNICA](TECNICA.md#versión-completa-compra-única)). Crear el producto, firmar acuerdos y fijar precios requiere la cuenta del propietario; mientras falte, desarrollar con SimulatedStore y el archivo StoreKit local, y registrar en ESTADO el dato pendiente.

**Precio.** 1,99 € y 1,99 US$, impuestos incluidos. Resto de divisas: equivalente de 1,99 € del día de configuración, redondeado al punto de precio más cercano terminado en ,49 o ,99 (empate: el más bajo). Divisas sin decimales: terminación 49 o 99 en la última cifra que admita la tienda. Si una tienda no ofrece ese punto, usar el más cercano y anotarlo como excepción. Registrar aquí, al configurar, la tabla aplicada (divisa, precio, fecha y tipo de cambio de referencia):

| Divisa | Precio | Origen |
|---|---:|---|
| EUR | 1,99 | Fijado por el propietario |
| USD | 1,99 | Fijado por el propietario |
| Otras | Pendiente | Calcular al crear el producto con la regla anterior |

**Google Play.**

1. Completar el perfil de pagos (cuenta de comerciante) del propietario.
2. Subir una build con el plugin a un canal de prueba interna; Play solo deja crear productos integrados en apps que declaren la facturación.
3. Crear el producto único `mypoodle.full_version` (compra única, no consumible), nombre «Versión completa», descripción en español y activo.
4. Fijar 1,99 € como precio base y revisar país por país la conversión automática: sustituir los precios que no terminen en ,49 o ,99 según la regla.
5. Añadir cuentas de prueba de licencias e instalar desde la prueba interna para comprar sin cargo. Probar compra, pendiente (método de pago lento), cancelación, reembolso desde la consola y reinstalación.

**App Store.**

1. Aceptar el acuerdo de apps de pago y completar datos bancarios y fiscales del propietario.
2. Crear la compra integrada de tipo **No consumible** con ID `mypoodle.full_version`, nombre y descripción en español, captura para revisión y **Compartir en familia** activado.
3. Elegir 1,99 € como precio base y ajustar manualmente los storefronts cuyo precio no termine en ,49 o ,99, dentro de los puntos de precio de Apple.
4. Probar con el archivo StoreKit local, después con cuentas sandbox (incluida aprobación familiar) y con TestFlight.
5. Enviar la primera compra integrada junto con la versión de la app que la usa.

**Fichas y normas.** Declarar «Contiene compras integradas» y «Sin anuncios». Si se elige la categoría Kids de Apple o el programa Families de Play: compra solo tras la puerta adulta, sin publicidad ni analítica de terceros, sin enlaces externos sin puerta y sin presión de compra. Seguridad de datos y privacidad: la app no recoge datos; revisar cómo declara cada tienda los datos que procesa su propio sistema de pago. Verificar las normas vigentes antes de publicar: [Apple Kids](https://developer.apple.com/app-store/review/guidelines/#kids-category), [compras integradas de Apple](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase), [Google Play Families](https://support.google.com/googleplay/android-developer/answer/9893335), [in_app_purchase](https://pub.dev/packages/in_app_purchase).

## Candidata y recuperación

Ejecutar validación de catálogos, referencias, poses, fuentes, rutas registradas y permisos antes de Release. Bloquear Release si el ID del producto falta, si SimulatedStore o un documento de derecho `simulated` pueden activarse, o si el manifiesto contiene permisos distintos de los previstos. Registrar SHA Git, hashes, esquema, versiones, teléfonos y QA; diferenciar comprobaciones pendientes.

Ante incidencia, detener distribución gradual si está disponible, preparar actualización con número superior y lector compatible con partida ya escrita, conservando el documento de derecho existente. Probar sobre la build afectada antes de distribuir. No se ha compilado ni publicado ninguna candidata por actualizar esta documentación.
