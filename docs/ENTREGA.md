# Compilación y distribución Flutter

## Estado y procedimiento de la beta

La primera beta exige 11 idiomas, ambos chinos, nombres localizados y modo foto, además de las compras nativas y el intento diario. El procedimiento actual y los estados reales de Apple están en [TESTFLIGHT](TESTFLIGHT.md). La publicación de producción es posterior.

## Preparación

Completar F00. Registrar versión exacta de Flutter/Dart/Flame, lockfile y herramientas nativas con flutter --version y flutter doctor -v. Identificador definitivo confirmado por el propietario el 17-11-2026: `com.betitoglez.mypoodle` en Android (namespace/applicationId) e iOS (Bundle ID); nombre My Poodle. RunnerTests usa `com.betitoglez.mypoodle.RunnerTests`. El producto conserva `mypoodle.full_version`. El cambio desde los IDs provisionales crea otra instalación y no migra la partida automáticamente; conservar las apps anteriores de prueba. Fijar version en pubspec.yaml (por ejemplo 0.1.0+1 solo para ficha nueva) y números internos crecientes. Firma y claves en almacén seguro local, nunca en repositorio o logs. Revisar requisitos actuales de SDK y tiendas al preparar candidata.

La app ya está implementada. Estos comandos son el procedimiento de validación; solo los resultados registrados en ESTADO acreditan compilación o prueba. Desde la raíz:

```sh
flutter pub get
flutter analyze
dart run tool/validate_content.dart
flutter test
flutter build apk --debug
flutter build appbundle --release
flutter build ios --debug --no-codesign
tool/build_testflight.sh
```

Ejecutar builds de forma secuencial. Configurar firma antes del AAB/IPA. La compra real solo funciona en builds instaladas desde la tienda o con el entorno de pruebas de cada plataforma. iOS sin codesign comprueba compilación y no produce una app distribuible. Salidas habituales: build/app/outputs/flutter-apk/app-debug.apk, build/app/outputs/bundle/release/app-release.aab, build/ios/archive/ y build/ios/ipa/. Registrar la ruta efectiva devuelta por el SDK fijado. Guardar logs, hashes y símbolos generados junto a la candidata. Referencias: [Android con Flutter](https://docs.flutter.dev/deployment/android), [iOS con Flutter](https://docs.flutter.dev/deployment/ios).

## Android

1. Verificar SDK/JDK y teléfono con flutter doctor -v y flutter devices. Configurar applicationId, orientación y versiones mínimas/objetivo en android/ según Flutter, plugins y requisitos actuales de Play. No fijar niveles por una guía histórica.
2. Ejecutar flutter run -d <device-id> o instalar APK con adb install -r build/app/outputs/flutter-apk/app-debug.apk. Aceptar autorización USB en el teléfono. Probar offline, ciclo de vida y almacenamiento; diagnosticar logs filtrados sin datos de partida.
3. Firma Release configurada en Gradle desde `android/key.properties` (plantilla sin secretos en `android/key.properties.example`). No hay fallback a firma debug: sin keystore, `validateSigningRelease` falla. Clave de subida RSA 2048 generada el 17-11-2026 con autorización del propietario; material privado local en `~/.config/my-poodle/signing/` (keystore y propiedades 0600; directorio 0700), excluido de Git. El propietario debe guardar una copia segura del directorio completo fuera de este Mac antes de depender de él para distribución. Activar/verificar Play App Signing en la ficha al subir la build. [Firma Android](https://developer.android.com/studio/publish/app-signing).
4. Generar AAB, validar con bundletool y comprobar firma/hash/versionCode. Instalar desde pruebas internas de Play; AAB no se instala directamente con adb. Probar actualización con identidad de firma compatible.
5. Completar audiencia, privacidad, seguridad de datos, anuncios (ninguno), compras integradas, clasificación, países, soporte, capturas reales y pruebas que exija la cuenta. Publicar candidata probada cuando el propietario autorice distribución. [Lanzamiento Play](https://support.google.com/googleplay/android-developer/answer/9859348).

## iOS

Para probar la versión actual con los diseños 3D, ejecutar `tool/build_ios_3d.sh`. Este script compila la entrada normal en Profile con `--dart-define=POODLE_LIVE_3D=true` y comprueba la opción y el GLB empaquetado. Un `flutter build ios` sin esa opción muestra el respaldo 2D, aunque el modelo esté dentro de los assets. No confundir un paquete que contiene el modelo con una compilación que activa el visor.

1. Preparar Xcode y toolchain iOS de Flutter. Mantener configuración y puente Swift en ios/; resolver dependencias nativas según el método soportado por el SDK/plugins elegidos. Bundle ID, versión y build number deben coincidir con ficha.
2. Abrir ios/Runner.xcworkspace cuando corresponda al proyecto generado. Seleccionar Team autorizado y provisioning, conectar iPhone y ejecutar Runner o flutter run -d <device-id>. Probar teclado, audio, interrupciones y exclusión de backup en hardware.
3. Ejecutar tool/build_testflight.sh con firma válida. Inspeccionar archivo en Organizer y validar/distribuir a TestFlight/App Store. Conservar dSYM y metadatos de exportación. [Carga de builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/).
4. Probar instalación/actualización vía TestFlight. Preparar privacidad, licencias, capturas, clasificación y notas sobre adopción, juegos, versión completa y puerta adulta. Enviar la build exacta verificada y liberar según decisión del propietario.

## Compra integrada, precios y fichas

Una sola variante de build, sin publicidad. La versión completa es un producto no consumible (`mypoodle.full_version`, ver [TECNICA](TECNICA.md#versión-completa-compra-única)). Crear el producto, firmar acuerdos y fijar precios requiere la cuenta del propietario; mientras falte, probar con el archivo StoreKit local en Xcode y con SimulatedStore inyectado en pruebas. El arranque normal de móvil ya usa IapStore. Registrar en ESTADO el dato pendiente.

**Precio.** 1,99 € y 1,99 US$, impuestos incluidos. Resto de divisas: equivalente de 1,99 € del día de configuración, redondeado al punto de precio más cercano terminado en ,49 o ,99 (empate: el más bajo). Divisas sin decimales: terminación 49 o 99 en la última cifra que admita la tienda. Si una tienda no ofrece ese punto, usar el más cercano y anotarlo como excepción. Registrar aquí, al configurar, la tabla aplicada (divisa, precio, fecha y tipo de cambio de referencia):

| Divisa | Precio | Origen |
|---|---:|---|
| EUR | 1,99 | Fijado por el propietario; España verificado en Play el 17-11-2026 |
| USD | 1,99 | Fijado por el propietario; EE. UU. verificado en Play el 17-11-2026 (impuestos locales pendientes de hoja nativa) |
| Otras | Pendiente | Calcular al crear el producto con la regla anterior |

**Google Play.**

1. Ficha My Poodle creada el 17-11-2026 (juego gratuito, es-ES, `com.betitoglez.mypoodle`), sin publicar a producción. Completar/verificar el perfil de pagos (cuenta de comerciante) del propietario.
2. AAB 0.1.0+1 firmado y procesado por Google el 17-11-2026; **disponible para testers internos** desde las 21:53 mostradas por la consola. Sustituido por **0.1.0+2** a las 22:18, con restauración accesible tras comprar; mismo paquete y certificado, actualización desde Play. Última build interna: **0.1.0+3**, disponible el 18-11-2026 a las 08:22 mostradas por consola; corrige cancelación sin ID y tratamiento de pendientes. BILLING reconocido. Lista exclusiva My Poodle - prueba interna y su licencia de pruebas guardadas. [Aceptar la prueba e instalar](https://play.google.com/apps/internaltest/4701341682215171492).
3. Crear el producto único `mypoodle.full_version` (compra única, no consumible), nombre «Versión completa», descripción «Desbloquea el Huerto y 24 artículos para personalizar el armario de tu caniche.» y activo. En el modelo actual de productos únicos, usar una opción de compra de tipo Comprar (Buy) y marcarla como compatible con versiones anteriores (backwards compatible). El adaptador Dart de in_app_purchase_android 0.5.5 utiliza `oneTimePurchaseOfferDetails`, aunque la biblioteca nativa sea Billing 9.1.0: debe existir una oferta compatible para esa ruta. No añadir ofertas múltiples o alquiler sin adaptar y probar la integración. Configurado y activo el 17-11-2026: `full-version-buy`, Comprar, Retrocompatible, sin unidades múltiples. Disponibilidad inicial solo España (1,99 EUR) y EE. UU. (1,99 USD); resto y países nuevos no disponibles hasta revisión de precios. [Modelo de productos únicos de Play](https://support.google.com/googleplay/android-developer/answer/16430488?hl=es), [compatibilidad de la consulta individual de oferta](https://developer.android.com/google/play/billing/one-time-product-multi-purchase-options-offers).
4. Fijar 1,99 € como precio base y revisar país por país la conversión automática: sustituir los precios que no terminen en ,49 o ,99 según la regla.
5. Cuenta del propietario confirmada en el Xiaomi y añadida a la lista de prueba interna y de licencias. **Validados manualmente el 17–18-11-2026:** precio 1,99 €, compra sin cargo con tarjeta de prueba y desbloqueo del Huerto; reinicio offline con derecho conservado; actualización a build 2 y restauración con compra existente; en build 3, cancelación con Atrás y compras pendientes con tarjeta lenta rechazada/aprobada. Reembolso con Quitar acceso confirmado en consola y móvil. Los recorridos conservan caniche y monedas. Build 1 ocultaba la restauración y build 2 bloqueaba la cancelación; ambos corregidos y repetidos en hardware. Queda restaurar en una instalación nueva u otro dispositivo. Resultados y límites detallados en ESTADO; 132 pruebas automatizadas pasan con la corrección de build 3.

**App Store.** Alta remota pendiente: el inicio de sesión sufrió errores 502/504 el 17-11-2026. El formulario volvió a cargar en un reintento; falta completar acceso y registrar en Apple el Bundle ID local definitivo.

1. Aceptar el acuerdo de apps de pago y completar datos bancarios y fiscales del propietario.
2. Crear la compra integrada de tipo **No consumible** con ID `mypoodle.full_version`, nombre y descripción en español, captura para revisión y **Compartir en familia** activado.
3. Elegir 1,99 € como precio base y ajustar manualmente los storefronts cuyo precio no termine en ,49 o ,99, dentro de los puntos de precio de Apple.
4. Probar con el archivo StoreKit local, después con cuentas sandbox (incluida aprobación familiar) y con TestFlight.
5. Enviar la primera compra integrada junto con la versión de la app que la usa.

**Fichas y normas.** Declarar «Contiene compras integradas» y «Sin anuncios». Si se elige la categoría Kids de Apple o el programa Families de Play: compra solo tras la puerta adulta, sin publicidad ni analítica de terceros, sin enlaces externos sin puerta y sin presión de compra. Seguridad de datos y privacidad: la app no recoge datos; revisar cómo declara cada tienda los datos que procesa su propio sistema de pago. Verificar las normas vigentes antes de publicar: [Apple Kids](https://developer.apple.com/app-store/review/guidelines/#kids-category), [compras integradas de Apple](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase), [Google Play Families](https://support.google.com/googleplay/android-developer/answer/9893335), [in_app_purchase](https://pub.dev/packages/in_app_purchase).

## Candidata y recuperación

Ejecutar validación de catálogos, referencias, poses, fuentes, rutas registradas y permisos antes de Release. Bloquear Release si el ID del producto falta, si SimulatedStore o un documento de derecho `simulated` pueden activarse, o si el manifiesto contiene permisos distintos de los previstos. Registrar SHA Git, hashes, esquema, versiones, teléfonos y QA; diferenciar comprobaciones pendientes.

Ante incidencia, detener distribución gradual si está disponible, preparar actualización con número superior y lector compatible con partida ya escrita, conservando el documento de derecho existente. Probar sobre la build afectada antes de distribuir. No se ha compilado ni publicado ninguna candidata por actualizar esta documentación.


## Pruebas locales de compra (F07.5)

Abrir `ios/Runner.xcworkspace` en Xcode, esquema Runner y configuración Debug. Run → Options ya selecciona `Runner/MyPoodle.storekit`: una compra local no hace cargos ni requiere producto en App Store Connect. Desde Zona adulta → Versión completa se consulta el precio de la tienda local y se compra/restaura. Para sandbox/TestFlight desactivar el archivo StoreKit en las opciones de Run; Archive/Release no lo utiliza. No usar los precios del archivo para acreditar precios configurados en las consolas.

`RunnerTests` prueba el camino StoreKit → plugin → controlador Dart → archivo de derecho con `SKTestSession`. Ejecutar en simulador dedicado siguiendo [PRUEBAS](PRUEBAS.md#compras-nativas-f075); no usar una instalación con partida personal. El producto local permite activar Ask to Buy, errores y transacciones desde Debug → StoreKit → Manage Transactions. F07.6 sigue requiriendo sandbox y Play Internal, autorización y cuentas del propietario.

Versiones fijadas: plugin 3.3.1, Android 0.5.5 (declara Billing 9.1.0), StoreKit 0.4.17. El mínimo Android de la app es 24; el objetivo/compilación siguen la toolchain Flutter. Antes de publicar revisar el grafo Gradle y el manifiesto fusionado. [Calendario oficial de Billing](https://developer.android.com/google/play/billing/deprecation-faq): Billing 9 admite nuevas apps/actualizaciones hasta el 31 de agosto de 2028 según la consulta del 17 de noviembre de 2026; volver a verificar al distribuir.
