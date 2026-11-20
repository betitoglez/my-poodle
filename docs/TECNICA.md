# Diseño técnico de Flutter + Flame

## Arquitectura vigente para la beta · 19-11-2026

Flutter y dominio Dart puro, visor WebGL 3D local con puente iOS/Android y respaldo 2D. Bundle ID com.betitoglez.mypoodle y producto mypoodle.full_version permanecen estables. La beta exige localización de interfaz/nombre, guardado compatible del idioma y cupos premium, captura del render nativo y álbum privado. No se añaden cuentas de jugador ni backend. El flujo de compras se valida finalmente en Sandbox/TestFlight.


Implementación móvil para iOS y Android, con partida local e independiente por instalación. El visor 3D actual y sus puentes nativos amplían la base inicial de Flame; el diseño web conserva valor de referencia visual.

## Herramientas y responsabilidades

| Parte | Elección e integración |
|---|---|
| Aplicación | Flutter, canal estable, Dart incluido en el SDK. Fijar versión exacta compatible en F00 y registrarla en ESTADO; no se presupone instalado ni compilado |
| Juego | Flame dentro de GameWidget para mascota, cuidados y minijuegos. Sprites, atlas, SpriteAnimationComponent, componentes hijos y CameraComponent. El caniche móvil usa el visor WebGL local; Flame compone escenarios, efectos y minijuegos con respaldo 2D |
| UI | Widgets Flutter para navegación, formularios, armario, HUD y modales. Referencia lógica 390×844; SafeArea, LayoutBuilder y teclado nativo. Una sola ruta activa y un dueño por gesto |
| Dominio | Dart puro, clases inmutables, reloj inyectable, operaciones serializadas; jsonDecode/jsonEncode de dart:convert con validación explícita |
| Recursos | JSON, PNG con transparencia, atlas y secuencias por capas empaquetados en assets y declarados en pubspec.yaml. Audio local de Mureka/ElevenLabs; elegir un único paquete de reproducción compatible en F03 |
| Pruebas | flutter_test para dominio/widgets, integración con integration_test del SDK, pruebas de componentes Flame con avance de tiempo controlado y hardware real |
| Plataformas | Proyecto android/ con Gradle/Kotlin y proyecto ios/ con Xcode/Swift; MethodChannel pequeño para ruta y exclusión de backup. APK de desarrollo, AAB e IPA de distribución |
| Compra | `in_app_purchase` (plugin oficial de flutter.dev: StoreKit en iOS y Google Play Billing en Android) para un único producto no consumible. Única dependencia nativa de terceros justificada; ver [Versión completa](#versión-completa-compra-única) |

Resolver versiones compatibles de Flame y paquetes en F00, conservar pubspec.lock de la aplicación y registrar flutter --version, flutter doctor -v y herramientas nativas. Sin servidor, carga remota de recursos, base de datos, publicidad, analítica ni framework de inyección adicional. Referencias: [Flutter para juegos](https://docs.flutter.dev/resources/games-toolkit), [FlameGame](https://docs.flame-engine.org/latest/flame/game.html).

## Archivos y composición

```text
lib/
  main.dart
  app/           app_root.dart, app_router.dart, app_lifecycle.dart
  domain/        pet_state.dart, needs_clock.dart, wallet_rules.dart, activity_result.dart,
                 entitlements.dart
  data/          save_store.dart, catalogs.dart, catalog_loader.dart, entitlement_store.dart
  platform/      local_storage_channel.dart
  ui/            adoption_view.dart, home_view.dart, care_view.dart, wardrobe_view.dart,
                 games_view.dart, results_view.dart, ask_adult_view.dart, parental_gate.dart,
                 full_version_view.dart
  game/          pet_component.dart, appearance_resolver.dart, care_game.dart,
                 orchard_game.dart, frisbee_game.dart, game_registry.dart, game_session.dart
  store/         store_provider.dart, iap_store.dart, simulated_store.dart, no_store.dart,
                 store_controller.dart
assets/          data/, images/pet/, images/rooms/, images/ui/, audio/, fonts/
android/        configuración y puente de almacenamiento Kotlin
ios/            configuración y puente de almacenamiento Swift
test/          domain/, data/, ui/, game/
integration_test/ app_flow_test.dart
tool/           validate_content.dart, validate_localizations.dart, build_testflight.sh
```

AppRoot construye reloj, catálogos, SaveStore, EntitlementStore, StoreController y sesión una vez. Un estado observable sencillo entrega revisiones confirmadas a widgets y componentes. Bootstrap carga antes de decidir Adopción o Casa. Los minijuegos se registran por ID en GameRegistry, no por nombre de archivo o ruta ejecutable tomada del JSON. Mantener una instancia de juego por ruta, creada fuera de build; al salir pausar, cancelar sesión y liberar listeners, audio y recursos exclusivos. Compartir atlas de la mascota sin duplicarlos por combinación.

## Contratos entre capas

| Operación | Parámetros | Efecto e invariantes |
|---|---|---|
| Adopt | nombre validado, reloj | Solo sin partida. Cuatro artículos base, estadísticas, revisión 1 y saldo 0 |
| AdvanceTime | estado, nowUtc | Copia con necesidades y cursor actualizados en la misma revisión |
| BeginActivity | ID de catálogo, versión | sessionId en memoria; pasos, colisiones y puntuación provisional no van a disco. Un juego `full` sin versión completa se rechaza con `requiresFull` y no crea sesión. Los cuidados no consultan la versión |
| Finish | sessionId, resultado tipado | Deriva del catálogo premio/efecto. Solo la sesión guarda; callback duplicado devuelve recibo previo |
| BuyAndEquip | itemId, revisión mostrada, versión | Relee coste, valida saldo/ranura; poseído se equipa gratis aunque sea `full`. Artículo `full` no poseído sin versión completa → `requiresFull` sin mutar. Revisión obsoleta refresca y pide confirmar si cambia el gasto |
| CanAccess | tier, Entitlement | Función pura del dominio: `free` siempre; `full` solo con `Entitlement.full`. La UI la usa para mostrar candados; las reglas la vuelven a aplicar |
| ApplyStoreEvent | evento verificado de la tienda, ID de evento | Idempotente por ID. Comprada o restaurada → full; revocada confirmada → no full; pendiente, cancelada o error → sin cambio de derecho. Guarda el documento de derecho antes de publicar. Nunca toca monedas, propiedad ni partida |
| Pause / Resume | ciclo de vida | Pausar bucle Flame, entrada y audio. Vaciar gestos, requerir Continuar; actualizar necesidades al regresar. Proceso terminado vuelve al menú |
| ApplyAppearance | IDs adquiridos por ranura | Resolver color, corte, ropa y cuello; restablecer capas base y aplicar máscaras, atlas, anclajes y orden de dibujo. Mismo resultado en casa, cuidados y juegos |

## Caniche modular 2D

PetComponent agrupa cuerpo, patas, orejas, cola, pelo, ropa, cuello y expresión. Un reloj de animación común selecciona pose/fotograma y transformaciones de las piezas. Compartir origen, escala, anclajes y metadatos por pose; el orden de dibujo puede variar por pose y cada prenda puede tener partes delanteras/traseras. El color afecta solo a las máscaras de pelaje y conserva sombras. Los cortes cambian las piezas de pelo correspondientes.

La v1 usa sprites y secuencias por capas con transformaciones sencillas, sin runtime de animación esquelética adicional. Si se necesita deformación compleja, evaluar una dependencia por separado. No generar una imagen completa por combinación: 6 colores × 8 cortes × 12 prendas × 10 accesorios permitirían 5.760 apariencias con piezas reutilizables. Es un ejemplo de capacidad, no un catálogo comprometido. El catálogo inicial tiene 2 opciones por ranura y 16 combinaciones comprobables. Todas las piezas necesitan variantes compatibles con las poses/vistas usadas. Si falta una pieza, aplicar fallback visible y detectar el defecto en validación de contenido.

## Documento persistente v1

```json
{
  "schemaVersion": 1, "revision": 1, "lastCommitId": "adopcion-1",
  "name": "Miel", "needsCursorUtc": 1794744000,
  "satiety100": 6500, "hygiene100": 7000, "mood100": 7500, "energy100": 8000,
  "coins": 0, "owned": ["coat.apricot","hair.natural","outfit.none","neck.none"],
  "appearance": {"coat":"coat.apricot","hair":"hair.natural","outfit":"outfit.none","neck":"neck.none"},
  "bestFruit": 0, "bestFrisbee": 0, "muted": false, "reducedMotion": false
}
```

Android: resolver Context.getNoBackupFilesDir() en Kotlin por MethodChannel y crear MyPoodle debajo. Revisar reglas de backup y transferencia entre dispositivos para todos los archivos de partida. iOS: crear directorio privado bajo Application Support en Swift, aplicar URLResourceValues.isExcludedFromBackup al directorio y comprobarlo tras recrearlo. Cubrir principal, copia y temporales. Probar migración directa y restauración en ambos sistemas. No asumir que un directorio estándar de un plugin queda excluido por defecto. [Android Auto Backup](https://developer.android.com/identity/data/autobackup) · [Apple Foundation](https://developer.apple.com/documentation/foundation/urlresourcevalues/isexcludedfrombackup).

**Escritura.** Una cola asíncrona serializa mutaciones; nunca solapar dos escrituras ni bloquear el hilo de UI con E/S síncrona. Desactivar acción mientras se guarda. Copiar estado, aplicar regla, asignar revisión +1 e ID de operación. Escribir save.tmp en el mismo volumen, flush y cierre, releer y validar. Preparar copia válida de principal mediante temporal independiente y reemplazarla; después promover save.tmp sobre principal con rename/reemplazo atómico validado en ambos destinos. No borrar principal antes de promover. Si la API Dart no ofrece las garantías comprobadas, usar reemplazo nativo en el mismo volumen mediante el puente. Publicar estado y recibo solo tras éxito. Resultado incierto: releer lastCommitId antes de reintentar. Inyectar fallos en todas las fronteras; no dar garantías de durabilidad frente a pérdida de energía sin validación nativa.

**Lectura.** Sin archivos → Adopción. Principal válido → cargar. Principal inválido o ausente → validar copia y promoverla con seguridad. Nunca confirmar compras desde un temporal huérfano. Ambos dañados → preservar y ofrecer reinicio adulto. Esquema futuro → mantener archivos y pedir actualizar. Añadir conversión pura y fixture por versión de esquema; copia antes del primer guardado migrado. Se conservan IDs, monedas, reglas y esquema v1: no hay build publicada que requiera migrar desde otro motor.

**Catálogos.** balance-v1.json es la fuente; F01 lo empaqueta en assets/data/balance-v1.json y comprueba equivalencia. Separar balance de metadatos visuales (atlas, poses, anclajes, máscaras y prioridades) en assets/data/appearance-v1.json. Validar IDs únicos, costes enteros no negativos, referencias, cuatro fallbacks gratuitos y límites de métricas/recompensas. Cada artículo y cada juego declara `"tier": "free"` o `"tier": "full"` (ausente es error de validación); los artículos iniciales y al menos un juego deben ser `free`, y cada ranura debe tener un artículo `free` comprable. El bloque `fullVersion` declara `productId`. El reparto por versión es el de [FUNCIONAL](FUNCIONAL.md#versión-gratuita-y-versión-completa). El bloque `ads` se elimina al retirar la publicidad. Retirar un cosmético mantiene su propiedad y muestra fallback. Logs: evento/revisión, nunca nombre o contenido de partida.

## Versión completa (compra única)

Decisión del 17 de noviembre de 2026; reglas de producto en [FUNCIONAL](FUNCIONAL.md#versión-gratuita-y-versión-completa). Sin publicidad: se retiran `AdsController`, `NoAds`, la banda simulada del modo demostración y el bloque `ads` del balance.

**Dependencia.** F07.5 fija `in_app_purchase` 3.3.1, `in_app_purchase_android` 0.5.5 e `in_app_purchase_storekit` 0.4.17 (Flutter 3.50.0 / Dart 3.14.0). Android mínimo 24, iOS del proyecto 15.0. El adaptador Android depende de Play Billing 9.1.0 y StoreKit usa StoreKit 2 por defecto. `crypto` 3.0.8 resuelto en el lockfile calcula SHA-256 de IDs. Versiones verificadas en [pub.dev](https://pub.dev/packages/in_app_purchase) y en el código de los paquetes descargados; el manifiesto y la dependencia efectivos de Android siguen pendientes de build. `in_app_purchase`, mantenido por el equipo de Flutter, con implementación federada para StoreKit en iOS y Google Play Billing en Android. Al actualizar, volver a comprobar compatibilidad, requisitos de Billing/StoreKit y mínimos de sistema; registrar el resultado en ESTADO. Sin intermediarios (RevenueCat, Adapty…): añadirían SDK, datos y cuenta externa sin necesidad para un solo producto.

**Producto.** Un único producto no consumible. ID propuesto `mypoodle.full_version`, igual en las dos tiendas; confirmar con el identificador definitivo de la app antes de crearlo, porque no se puede reutilizar tras borrarlo. El ID vive en el bloque `fullVersion` del balance; el precio no está en la app: se muestra el `price` localizado que devuelve la tienda.

**Capas.**

| Pieza | Responsabilidad |
|---|---|
| `domain/entitlements.dart` | `Entitlement` inmutable (`full`, `state`: none, pending, purchased, revoked) y reglas puras: `canAccess(tier)`, `apply(event)`, idempotencia por ID de evento. Sin Flutter ni plugin |
| `store/store_provider.dart` | Interfaz: `Stream<StoreEvent> events`, `Future<StoreProduct?> loadProduct()`, `Future<void> buy()`, `Future<void> restore()`, `Future<StoreOwnership> queryOwnership()` (owned / notOwned / unknown), `dispose()`. `StoreEvent`: pending, purchased, restored, canceled, error(código), revoked, con ID de evento |
| `store/iap_store.dart`, `iap_client.dart`, `default_store.dart` | Adaptador de `in_app_purchase`. Se crea solo en Android/iOS; las mismas plataformas se seleccionan en Debug/Profile/Release. Web y escritorio usan NoStore sin acceder al singleton del plugin. IapClient permite probar el adaptador sin canales nativos |
| `store/simulated_store.dart` | Pruebas y modo demostración: disponible, sin producto, sin red, demora, cancelación, error, pendiente → aprobado/rechazado, revocación y eventos duplicados |
| `store/store_provider.dart` (`NoStore`) | Web y entornos sin tienda: producto no disponible, derecho según caché |
| `store/store_controller.dart` | Escucha eventos, aplica reglas del dominio, persiste con EntitlementStore, publica el derecho confirmado y finaliza transacciones |
| `data/entitlement_store.dart` | Documento de derecho con el mismo escritor atómico que la partida |
| `ui/parental_gate.dart`, `ask_adult_view.dart`, `full_version_view.dart` | Puerta adulta, aviso de candado y pantalla de compra; solo emiten intenciones |

**Arranque.** Cargar el documento de derecho junto a la partida; si falta o está dañado, `full = false` sin bloquear el arranque. StoreController se suscribe al flujo de compras **antes de mostrar Casa**, para recibir transacciones pendientes o completadas fuera de la app. Después, sin bloquear la UI: cargar el producto y, en Android con conexión, consultar la propiedad (consulta silenciosa de compras). Una consulta de propiedad iniciada antes de un evento no puede revocar el derecho que acaba de confirmar ese evento. Se ignoran derechos simulados al usar el proveedor nativo, también en Debug. Las consultas de disponibilidad/producto/propiedad tienen límite de 15 s y no bloquean la entrada al juego. En iOS no llamar a restaurar automáticamente; solo con el botón «Restaurar compras», porque puede pedir iniciar sesión en la tienda.

**Flujo de compra.** Puerta adulta → `buy()` → evento. Al recibir purchased o restored de `mypoodle.full_version`: aplicar regla, escribir el documento, publicar y solo entonces llamar a `completePurchase` si el plugin lo indica (`pendingCompletePurchase`). Si la escritura falla, no completar: la tienda volverá a entregar la transacción. Pending deja `state = pending` y no desbloquea. Canceled y error mantienen el estado anterior y muestran el mensaje correspondiente. Ignorar eventos de otro producto y duplicados por ID.

**Revocación.** Aplicar `full = false` solo con una respuesta positiva de la tienda: en Android, consulta de compras correcta sin el producto; en iOS, `revocationDate` en el JSON de la transacción StoreKit 2 verificada que expone `SK2PurchaseDetails.sk2Transaction`. El plugin entrega esa actualización como `purchased`; IapStore la traduce a `revoked`. El JSON solo se procesa en memoria. No se infiere una revocación de una restauración vacía en iOS. Sin red, error o resultado `unknown`: conservar la caché. Al revocar, la propiedad de artículos ya comprados con monedas no cambia.

**Verificación.** Sin servidor no hay validación de recibos propia: se confía en la verificación de la plataforma (transacciones firmadas de StoreKit y estado PURCHASED de Play) que entrega el plugin. Riesgo aceptado: un dispositivo manipulado puede editar la caché local. No guardar recibos ni datos de la cuenta.

**Documento de derecho** (`entitlement.json`, en el mismo directorio privado que la partida; principal, copia y temporal como la partida):

```json
{"schemaVersion": 1, "productId": "mypoodle.full_version", "full": true,
 "state": "purchased", "source": "store", "updatedUtc": 1794744000,
 "lastEventIds": ["a1f3…"]}
```

`lastEventIds` guarda un resumen (hash) de los últimos IDs de transacción para la idempotencia; nunca el ID en claro, el recibo ni datos de la cuenta. `source` puede ser `store` o `simulated`; un documento `simulated` se ignora en Release. Reiniciar la partida borra principal, copia y temporales de la partida, no este documento. La partida mantiene el esquema v1 sin cambios.

**Plataformas.** Android: el plugin añade el permiso `com.android.vending.BILLING`; comprobarlo en el manifiesto fusionado y en el APK. La comprobación Android de esta sesión también detecta INTERNET y ACCESS_NETWORK_STATE añadidos por DataTransport transitivo de Billing 9.1.0, y el permiso signature de receptores internos de AndroidX; ver ESTADO. El inventario esperado debe incluir su procedencia y volver a revisarse al actualizar dependencias. iOS: capacidad In-App Purchase en el target Runner y un archivo de configuración StoreKit (`ios/Runner/MyPoodle.storekit`) seleccionado en el esquema de depuración para probar sin la tienda real. Compartir en familia se activa en App Store Connect.

**Modo demostración.** Superpone un derecho solo en memoria sobre el controlador normal y añade «Simular versión completa», «Simular compra pendiente» y «Simular reembolso». No escribe el documento real de derecho y se restaura al salir.


**Configuración local F07.5.** `ios/Runner/MyPoodle.storekit` contiene el no consumible y está seleccionado en Run/Debug y Test del esquema compartido Runner. No configura las consolas ni los precios reales. In-App Purchase está habilitado en SystemCapabilities; el archivo StoreKit se copia solo al bundle de pruebas, no a los recursos de producción. Se usa Swift Package Manager de Flutter (no hay Podfile). Android declara explícitamente BILLING; no se fija ni fuerza una versión de Billing en Gradle de la app. Billing 9.1.0 ya está verificada en el grafo Gradle resuelto, el manifiesto fusionado y el metadato del APK; ver el registro Android de ESTADO.

## Idiomas, cupo diario y fotografías

`lib/l10n/` ofrece 11 catálogos JSON locales, resolución por idioma/script y selector persistido en `Preferences.language`. Valores antiguos sin idioma usan el sistema; los no soportados resuelven inglés. `InfoPlist.strings` y recursos Android localizan el nombre nativo. Las interpolaciones conservan nombres de jugador e importes de tienda. La puerta adulta escribe números en el idioma activo.

El documento v1 añade opcionalmente `premiumTrialStartedUtc: {gameId: utcSeconds}`. Los guardados antiguos empiezan sin consumos. `beginGame` serializa la confirmación del inicio y del cupo, y solo entrega sesión después de guardar; fallo de disco conserva el intento. El reloj UTC define 86.400 segundos, sin desbloquear por retroceso. No requiere servicio remoto. Reiniciar la partida desde la zona adulta crea una partida nueva; el cupo local no es un sistema antifraude de cuenta.

`PhotoScreen` compone el fondo Flutter y una captura PNG del canvas 3D mediante el canal nativo `snapshot`. `PhotoAlbum` guarda imágenes y un índice separados de partida y compras; límite de 24 fotos, temporales y sustitución del índice. No solicita cámara ni lee la fototeca, y no sube imágenes. Desde el detalle, tras la puerta adulta, `PhotoGallery` copia el PNG al carrete por el canal `my_poodle/photos`: iOS con permiso de solo añadir (`NSPhotoLibraryAddUsageDescription`), Android 10+ con MediaStore en `Pictures/My Poodle` sin permiso, y Android 7–9 con `WRITE_EXTERNAL_STORAGE` limitado a `maxSdkVersion=28`. Denegar o fallar no altera el álbum privado. Ver [TestFlight](TESTFLIGHT.md) para el build verificable y [Idiomas](IDIOMAS.md).

## Compras pendientes iOS y herramienta interna de reembolso

StoreKit no entrega un evento de rechazo de Ask to Buy. La pantalla iOS mantiene disponible otra solicitud mientras el derecho sigue pendiente; solo purchased/restored concede full. Android conserva la espera porque admite reconciliación silenciosa. Regresión: `test/ui/ios_pending_purchase_test.dart`, rechazo sin evento, nueva solicitud y aprobación; también comprueba que la espera Android se conserva.

`POODLE_PURCHASE_QA=true` añade «Reembolso de prueba» solo a la zona adulta iOS de la build interna, al tener full y fuera de demo. Por defecto está oculto. El canal nativo `my_poodle/purchase_qa` acepta solo requestSandboxRefund, usa el producto fijo y la última transacción verificada, exige entorno Sandbox y ausencia de revocación, y abre la hoja nativa. Rechaza producción, transacciones no verificadas/ausentes e iOS anterior a 16. No guarda IDs ni recibos. Solicitud enviada no revoca por sí sola: la retirada del derecho depende del evento StoreKit verificado. `test/ui/sandbox_refund_button_test.dart` cubre concurrencia, cancelación y error sin detalles privados.
