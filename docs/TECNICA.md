# Diseño técnico de Flutter + Flame

Decisión confirmada el 16 de noviembre de 2026. Juego móvil completamente 2D para iOS y Android, con partida local e independiente por instalación. El diseño web es una referencia visual; la implementación Flutter comienza en F00.

## Herramientas y responsabilidades

| Parte | Elección e integración |
|---|---|
| Aplicación | Flutter, canal estable, Dart incluido en el SDK. Fijar versión exacta compatible en F00 y registrarla en ESTADO; no se presupone instalado ni compilado |
| Juego | Flame dentro de GameWidget para mascota, cuidados y minijuegos. Sprites, atlas, SpriteAnimationComponent, componentes hijos y CameraComponent. Todo se renderiza en 2D |
| UI | Widgets Flutter para navegación, formularios, armario, HUD y modales. Referencia lógica 390×844; SafeArea, LayoutBuilder y teclado nativo. Una sola ruta activa y un dueño por gesto |
| Dominio | Dart puro, clases inmutables, reloj inyectable, operaciones serializadas; jsonDecode/jsonEncode de dart:convert con validación explícita |
| Recursos | JSON, PNG con transparencia, atlas y secuencias por capas empaquetados en assets y declarados en pubspec.yaml. Audio local de Mureka/ElevenLabs; elegir un único paquete de reproducción compatible en F03 |
| Pruebas | flutter_test para dominio/widgets, integración con integration_test del SDK, pruebas de componentes Flame con avance de tiempo controlado y hardware real |
| Plataformas | Proyecto android/ con Gradle/Kotlin y proyecto ios/ con Xcode/Swift; MethodChannel pequeño para ruta y exclusión de backup. APK de desarrollo, AAB e IPA de distribución |

Resolver versiones compatibles de Flame y paquetes en F00, conservar pubspec.lock de la aplicación y registrar flutter --version, flutter doctor -v y herramientas nativas. Sin servidor, carga remota de recursos, base de datos ni framework de inyección adicional. Referencias: [Flutter para juegos](https://docs.flutter.dev/resources/games-toolkit), [FlameGame](https://docs.flame-engine.org/latest/flame/game.html).

## Archivos y composición

```text
lib/
  main.dart
  app/           app_root.dart, app_router.dart, app_lifecycle.dart
  domain/        pet_state.dart, needs_clock.dart, wallet_rules.dart, activity_result.dart
  data/          save_store.dart, catalogs.dart, catalog_loader.dart
  platform/      local_storage_channel.dart
  ui/            adoption_view.dart, home_view.dart, care_view.dart, wardrobe_view.dart,
                 games_view.dart, results_view.dart
  game/          pet_component.dart, appearance_resolver.dart, care_game.dart,
                 orchard_game.dart, frisbee_game.dart, game_registry.dart, game_session.dart
  ads/           ads_provider.dart, no_ads.dart, simulated_ads.dart, ads_controller.dart
assets/          data/, images/pet/, images/rooms/, images/ui/, audio/, fonts/
android/        configuración y puente de almacenamiento Kotlin
ios/            configuración y puente de almacenamiento Swift
test/          domain/, data/, ui/, game/
integration_test/ app_flow_test.dart
tool/           validate_content.dart
```

AppRoot construye reloj, catálogos, SaveStore y sesión una vez. Un estado observable sencillo entrega revisiones confirmadas a widgets y componentes. Bootstrap carga antes de decidir Adopción o Casa. Los minijuegos se registran por ID en GameRegistry, no por nombre de archivo o ruta ejecutable tomada del JSON. Mantener una instancia de juego por ruta, creada fuera de build; al salir pausar, cancelar sesión y liberar listeners, audio y recursos exclusivos. Compartir atlas de la mascota sin duplicarlos por combinación.

## Contratos entre capas

| Operación | Parámetros | Efecto e invariantes |
|---|---|---|
| Adopt | nombre validado, reloj | Solo sin partida. Cuatro artículos base, estadísticas, revisión 1 y saldo 0 |
| AdvanceTime | estado, nowUtc | Copia con necesidades y cursor actualizados en la misma revisión |
| BeginActivity | ID de catálogo | sessionId en memoria; pasos, colisiones y puntuación provisional no van a disco |
| Finish | sessionId, resultado tipado | Deriva del catálogo premio/efecto. Solo la sesión guarda; callback duplicado devuelve recibo previo |
| BuyAndEquip | itemId, revisión mostrada | Relee coste, valida saldo/ranura; poseído se equipa gratis. Revisión obsoleta refresca y pide confirmar si cambia el gasto |
| Pause / Resume | ciclo de vida | Pausar bucle Flame, entrada, audio y reloj publicitario. Vaciar gestos, requerir Continuar; actualizar necesidades al regresar. Proceso terminado vuelve al menú |
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

**Catálogos.** balance-v1.json es la fuente; F01 lo empaqueta en assets/data/balance-v1.json y comprueba equivalencia. Separar balance de metadatos visuales (atlas, poses, anclajes, máscaras y prioridades) en assets/data/appearance-v1.json. Validar IDs únicos, costes enteros no negativos, referencias, cuatro fallbacks gratuitos y límites de métricas/recompensas. Retirar un cosmético mantiene su propiedad y muestra fallback. Logs: evento/revisión, nunca nombre o contenido de partida.

## Publicidad aislada

AdsController evalúa ruta, tiempo activo y número de impresiones. Banner solo en casa y fuera de controles. Intersticial solo al regresar tras resultado guardado; propuesta inicial 900 s activos y uno por sesión, deshabilitado hasta validar proveedor. No-fill, demora o error mantienen navegación y premios. Descartar callbacks con ID de petición anterior.

NoAds y SimulatedAds permiten implementar sin red. Antes de integrar un proveedor infantil verificar soporte Flutter mantenido, compatibilidad iOS/Android y dependencias de mediación o puente nativo. No trasladar automáticamente un SDK de otro motor ni dar por aceptado un proveedor. Ver ENTREGA para configuración y publicación.
