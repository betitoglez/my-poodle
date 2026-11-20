# My Poodle / Mi Caniche

Adopta un caniche toy, dale un nombre y cuídalo día a día. En el huerto saltarás con él para recoger frutas. En el prado le lanzarás un frisbee. Con las monedas que ganéis podrás elegir el color de su pelo, vestirlo y probar cortes de peluquería.

La descarga es gratuita y lo básico se juega para siempre sin pagar. Cada minijuego premium permite una partida gratis cada 24 horas sin la versión completa. Una compra única de 1,99 € (o 1,99 US$) desbloquea la versión completa: más minijuegos, más armario y las novedades futuras. Sin anuncios y sin vender monedas. Detalle en [Versión gratuita y versión completa](docs/FUNCIONAL.md#versión-gratuita-y-versión-completa).

**[Abrir el diseño del juego](docs/disenos.html)** desde el clon. Incluye el recorrido de adopción y un selector de pantallas y tamaños para revisión. [Ver las pantallas a tamaño fijo](docs/arte/pantallas.jpg).

| Documento | Uso |
|---|---|
| [Instrucciones del agente](CLAUDE.md) | Inicio de cada sesión y orden de ejecución |
| [Producto y economía](docs/FUNCIONAL.md) | Reglas de adopción, tiempo, cuidados, catálogo, recompensas y versión completa |
| [Arquitectura Flutter + Flame](docs/TECNICA.md) | Visor 3D local, escenas Flame, contratos, esquema y persistencia |
| [Integración de componentes](docs/INTEGRACION.md) y [balance importable](docs/datos/balance-v1.json) | Composición Flutter/Flame, puente nativo de backup, datos locales y diagnóstico |
| [Implementación por entregas](docs/FASES.md) | Secuencia, archivos, acciones concretas y condiciones de salida |
| [Minijuegos](docs/JUEGOS.md) | Física, entradas, niveles, puntuación y extensión del catálogo |
| [Pantallas y arte](docs/UI-UX.md) | Composición, interacción, accesibilidad y proceso de arte 2D por capas y audio |
| [Verificación](docs/PRUEBAS.md) | Fixtures, comandos y recorridos de aceptación por dispositivo |
| [Build y distribución](docs/ENTREGA.md) | Configuración nativa, compra integrada y precios, firma, beta, publicación y recuperación |
| [Estado](docs/ESTADO.md) | Versiones, pruebas ejecutadas, evidencia y pendientes |

La app utiliza Flutter + Flame para la interfaz y las escenas, con el caniche y vestuario 3D locales en iOS/Android y un respaldo 2D. Partida, economía, álbum y ajustes son privados de cada instalación, sin cuentas de jugador ni backend. La música cambia entre Casa/menús, juegos y cuidados. El historial de compilación y aceptación está en [ESTADO](docs/ESTADO.md); la preparación de la primera beta está en [TESTFLIGHT](docs/TESTFLIGHT.md).

## MVP Flutter

Adopción, cuidados, salud, Huerto saltarín, Frisbee en el prado y armario de 43 artículos. La primera beta incluye modo foto con poses/giro y álbum privado de hasta 24 fotos, prueba diaria por juego premium y 11 variantes de idioma: es, en, fr, de, pt-BR, it, ru, ko, ja, zh-Hans y zh-Hant. Inglés es el respaldo. La app se llama «Mi Caniche» en español y «My Poodle» en inglés; [nombres por idioma](docs/IDIOMAS.md).

Parejas, Simón de perritos y laberinto están propuestos y pendientes de definición en [TODO](TODO.md). No se presentan como juegos implementados.

### Ejecutar

Requiere Flutter estable 3.50 o compatible (Dart 3.14).

```bash
flutter pub get
```

```bash
flutter run -d chrome
```

```bash
flutter run --dart-define=POODLE_LIVE_3D=true -d <id-del-dispositivo>
```

En móvil, la opción anterior activa los diseños 3D. Para compilar la versión de iPhone usar `tool/build_ios_3d.sh`, que también comprueba que el visor está activado. La vista web usa la representación 2D.

Comprobaciones antes de compilar:

```bash
flutter analyze
dart run tool/validate_content.dart
dart run tool/validate_localizations.dart
flutter test
```

Para generar la candidata interna de TestFlight: `tool/build_testflight.sh`, con firma autorizada en Xcode. El script verifica idiomas y 3D; una compilación no acredita procesamiento ni compra Sandbox.

Pruebas de integración en iPhone y Android conectados: ver [recorrido físico iOS](docs/PRUEBAS.md#recorrido-físico-ios).

Compilaciones verificadas en esta máquina: `flutter build web --release` y `flutter build ios --simulator --debug`. Android SDK 36 y JDK 17 ya están instalados. Hay APK Release de desarrollo, y Billing 9.1.0 está verificada en el grafo y el manifiesto del binario; ver ESTADO para los recorridos físicos.

### Estructura

| Carpeta | Responsabilidad |
|---|---|
| `lib/domain/` | Dart puro: estado, reloj de necesidades, reglas de cuidados y cartera, sesiones, pasos de actividades y simulaciones de los minijuegos (`games/`) |
| `lib/data/` | Documento v1, guardado con principal/copia/temporal y recuperación |
| `lib/platform/` | Directorio privado: canal `my_poodle/storage` (Kotlin `noBackupFilesDir`, Swift Application Support excluido de backup) y `localStorage` en web |
| `lib/app/` | Arranque, estado compartido (`AppController`, `ChangeNotifier`), textos con variantes, feedback |
| `lib/game/` | Flame: caniche por capas (`pet/`), salas 2D (`scenes/`), escenas de cuidados (`care/`), `orchard_game.dart`, `frisbee_game.dart`, catálogo de juegos |
| `lib/ui/` | Tema centralizado, componentes reutilizables (botones, saldo, indicadores, diálogos, marco de actividad) y pantallas |
| `assets/` | `data/balance-v1.json` (copia validada de `docs/datos`), `data/appearance-v1.json`, ilustraciones recortadas |
| `test/` | Dominio, guardado, simulaciones y recorridos de la app |
| `tool/validate_content.dart` | Valida catálogo, metadatos visuales y recursos |

La UI solo emite intenciones; `AppController` aplica las reglas puras, serializa escrituras y publica el estado confirmado. Compras y premios pasan por `Rules.applyLook`, `Rules.finishCare` y `Rules.finishGame`, con un ID de operación por sesión para no duplicar.

### Dependencias

| Paquete | Motivo |
|---|---|
| `flame` | Escenas 2D, bucle de juego y minijuegos (decisión del propietario) |
| `material_ui` | Widgets Material (separados del framework desde Flutter 3.47) |
| `characters` | Contar el nombre por grafemas (1–16) |
| `web` | `localStorage` para la vista previa web |
| `in_app_purchase` 3.3.1 | Producto no consumible con StoreKit 2 / Google Play |
| `in_app_purchase_android` 0.5.5 / `in_app_purchase_storekit` 0.4.17 | APIs oficiales de consulta de propiedad y metadatos de revocación |
| `crypto` | SHA-256 de IDs de evento; no se guardan recibos ni IDs en claro |

Sin backend, analítica ni SDK publicitario. Compras mediante el plugin oficial de Flutter y sus implementaciones federadas. Android/iOS usan `IapStore` en Debug, Profile y Release; web/escritorio usan `NoStore`. `SimulatedStore` solo se inyecta expresamente en pruebas. Los derechos simulados no se aceptan al usar una tienda nativa ni en Release. Ver [TECNICA](docs/TECNICA.md#versión-completa-compra-única) y [pruebas StoreKit](docs/PRUEBAS.md#compras-nativas-f075).

### Modo demostración

Casa → Ajustes → «Soy un adulto» → puerta numérica → Zona adulta → «Entrar en modo demostración». Usa una partida de muestra en memoria (etiqueta DEMO visible): necesidades bajas o llenas, 0/9/10/12/100 monedas, combinaciones de aspecto y simulación de versión completa, pendiente y reembolso. Al salir se recupera la partida normal sin cambios.

### Qué es provisional

| Área | Estado | Para la versión publicable |
|---|---|---|
| Caniche | Ilustrado por capas generado con Meshy: base por peinado y pose (frente, perfil, espalda, salto, comer, dormir, galope), pelaje por matriz de color y capas de ropa y cuello ([cómo ampliarlo](docs/arte/meshy/FUENTES.md#cómo-ampliar-el-armario)). El vectorial queda como respaldo | Revisar derechos de uso; más poses si se añaden actividades |
| Salón, cocina, baño, peluquería, armario y cojín de adopción | Ilustraciones generadas con Meshy a partir de las referencias de `docs/arte` ([origen](docs/arte/meshy/FUENTES.md)); el sendero del paseo sigue siendo vectorial | Revisar derechos de uso de Meshy; ilustrar el sendero |
| Fondos del huerto y del prado, miniaturas de tarjetas | Recortes de las ilustraciones de referencia del propietario (`docs/arte`) | Confirmar derechos y exportar a resolución final |
| Armario ampliado | Peinados osito y cachorro, ropa, accesorios y colores nuevos con capas generadas por Meshy; los colores de una prenda son variantes de tono de una sola capa. Los artículos y peinados nuevos no tienen capas de salto, comer ni galope: en esas poses se usa el perfil o no se dibujan | Capas propias para cada pose |
| Animaciones | Transformaciones por capas sobre un reloj común (reposo, parpadeo, caricia, comida, baño, cepillado, trote, olfateo, carrera, salto, captura, celebración, descanso) | Secuencias dibujadas |
| Audio | [37 efectos locales activos](docs/audio/EFECTOS.md), reproducción por acción y ajuste de efectos guardado | Pistas instrumentales |
| Tipografía | Fuentes del sistema | Empaquetar Young Serif y Nunito (OFL) |
| Textos | Privacidad marcada como provisional; resto de textos de juego definitivos para revisión | Política legal real |
| Veterinario y dormir | Escenas con efectos vectoriales (estetoscopio, lupa, pastilla, manta, noche); consulta ilustrada con Meshy | Animaciones dibujadas |
| Acceso adulto | Puerta con número escrito en letras y espera tras tres fallos | Revisión de aceptación en teléfonos |
| Monetización | Sin anuncios. 18 artículos y Frisbee gratis; 24 artículos y Huerto requieren versión completa. Adaptador nativo y StoreKit local implementados | Compra/cancelación iPhone TestFlight (33) confirmadas; completar persistencia, restauración y escenarios restantes ([estado](docs/ESTADO.md)) |

La beta interna iPhone **0.5.0 (33)** está procesada e instalada. Identidad definitiva `com.betitoglez.mypoodle`, producto `mypoodle.full_version`, precio Apple base 1,99 € y 11 títulos de ficha configurados. El propietario confirma que ya aparece el precio, la cancelación funciona y la compra Sandbox desbloquea la versión completa; reinicio/offline/restauración y el resto de aceptación siguen pendientes. Ver [TestFlight](docs/TESTFLIGHT.md). Antes de producción faltan aceptación de compras y dispositivos, revisión lingüística/arte/licencias, fichas y capturas definitivas, preparación de ambas tiendas y autorización comercial del propietario.

Capturas: [escenas ilustradas](docs/capturas/escenas-ilustradas.jpg) · [poses del caniche](docs/capturas/poses-caniche.jpg) · [armario con el caniche ilustrado](docs/capturas/armario-sprites.jpg) · [16 combinaciones](docs/capturas/meshy-16-combinaciones.jpg) · [comparativa con Meshy](docs/capturas/comparativa-meshy.jpg) · [Casa](docs/capturas/casa-salas.jpg) · [Casa antes](docs/capturas/casa.jpg) · [Cuidados](docs/capturas/cuidados.jpg) · [Baño](docs/capturas/bano.jpg) · [Huerto](docs/capturas/huerto.jpg) · [Frisbee](docs/capturas/frisbee.jpg) · [Resultado](docs/capturas/resultado-juego.jpg) · [Armario](docs/capturas/armario.jpg).
