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

Ejecutar builds de forma secuencial. Configurar firma antes del AAB/IPA. iOS sin codesign comprueba compilación y no produce una app distribuible. Salidas habituales: build/app/outputs/flutter-apk/app-debug.apk, build/app/outputs/bundle/release/app-release.aab, build/ios/archive/ y build/ios/ipa/. Registrar la ruta efectiva devuelta por el SDK fijado. Guardar logs, hashes y símbolos generados junto a la candidata. Referencias: [Android con Flutter](https://docs.flutter.dev/deployment/android), [iOS con Flutter](https://docs.flutter.dev/deployment/ios).

## Android

1. Verificar SDK/JDK y teléfono con flutter doctor -v y flutter devices. Configurar applicationId, orientación y versiones mínimas/objetivo en android/ según Flutter, plugins y requisitos actuales de Play. No fijar niveles por una guía histórica.
2. Ejecutar flutter run -d <device-id> o instalar APK con adb install -r build/app/outputs/flutter-apk/app-debug.apk. Aceptar autorización USB en el teléfono. Probar offline, ciclo de vida y almacenamiento; diagnosticar logs filtrados sin datos de partida.
3. Configurar firma Release en Gradle con clave de subida y propiedades locales excluidas de Git. El propietario conserva alias, credenciales y copia segura. Activar Play App Signing en la ficha. [Firma Android](https://developer.android.com/studio/publish/app-signing).
4. Generar AAB, validar con bundletool y comprobar firma/hash/versionCode. Instalar desde pruebas internas de Play; AAB no se instala directamente con adb. Probar actualización con identidad de firma compatible.
5. Completar audiencia, privacidad, seguridad de datos, anuncios, clasificación, países, soporte, capturas reales y pruebas que exija la cuenta. Publicar candidata probada cuando el propietario autorice distribución. [Lanzamiento Play](https://support.google.com/googleplay/android-developer/answer/9859348).

## iOS

1. Preparar Xcode y toolchain iOS de Flutter. Mantener configuración y puente Swift en ios/; resolver dependencias nativas según el método soportado por el SDK/plugins elegidos. Bundle ID, versión y build number deben coincidir con ficha.
2. Abrir ios/Runner.xcworkspace cuando corresponda al proyecto generado. Seleccionar Team autorizado y provisioning, conectar iPhone y ejecutar Runner o flutter run -d <device-id>. Probar teclado, audio, interrupciones y exclusión de backup en hardware.
3. Ejecutar flutter build ipa --release con firma válida. Inspeccionar archivo en Organizer y validar/distribuir a TestFlight/App Store. Conservar dSYM y metadatos de exportación. [Carga de builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/).
4. Probar instalación/actualización vía TestFlight. Preparar privacidad, licencias, capturas, clasificación y notas sobre adopción, juegos y publicidad. Enviar la build exacta verificada y liberar según decisión del propietario.

## Publicidad y variantes

Mantener NoAds y SimulatedAds para desarrollo; aislar proveedor real. Antes de escogerlo, documentar soporte Flutter mantenido o puente nativo necesario, coste de mantenimiento, SDKs transitivos, iOS/Android y compatibilidad con audiencia infantil. SuperAwesome/KIDOZ son candidatos pendientes; no asumir integración directa Flutter por su soporte de otros motores. Si se evalúa mediación, inventariar también sus SDKs. No incorporar dependencia nativa solo para una simulación.

Para una variante monetizada implementar configuración nativa separada (flavor/configuración) que excluya SDK y permisos publicitarios del binario NoAds; las variables Dart por sí solas no eliminan plugins nativos. Registrar comandos efectivos por variante al incorporarla. F07 verifica versiones, formatos, datos recogidos, configuración infantil, inventario de prueba y reanudación. Sin admisión/configuración válida, entregar NoAds. La variante de tienda debe coincidir con ficha de privacidad y anuncios.

Verificar reglas actuales antes de publicar: [Apple Kids](https://developer.apple.com/app-store/review/guidelines/#kids-category), [Google Play Families](https://support.google.com/googleplay/android-developer/answer/9893335). Un SDK técnicamente integrable no acredita admisión comercial ni aceptación de tienda.

## Candidata y recuperación

Ejecutar validación de catálogos, referencias, poses, fuentes, rutas registradas y permisos antes de Release. Bloquear variante monetizada con IDs de prueba o configuración incompleta. Registrar SHA Git, hashes, esquema, versiones, teléfonos y QA; diferenciar comprobaciones pendientes.

Ante incidencia, detener distribución gradual si está disponible, preparar actualización con número superior y lector compatible con partida ya escrita, usando NoAds si procede. Probar sobre la build afectada antes de distribuir. No se ha compilado ni publicado ninguna candidata por actualizar esta documentación.
