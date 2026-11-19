# My Poodle

Adopta un caniche toy, dale un nombre y cuídalo día a día. En el huerto saltarás con él para recoger frutas. En el prado le lanzarás un frisbee. Con las monedas que ganéis podrás elegir el color de su pelo, vestirlo y probar cortes de peluquería.

La descarga es gratuita y lo básico se juega para siempre sin pagar. Una compra única de 1,99 € (o 1,99 US$) desbloquea la versión completa: más minijuegos, más armario y las novedades futuras. Sin anuncios y sin vender monedas. Detalle en [Versión gratuita y versión completa](docs/FUNCIONAL.md#versión-gratuita-y-versión-completa).

**[Abrir el diseño del juego](docs/disenos.html)** desde el clon. Incluye el recorrido de adopción y un selector de pantallas y tamaños para revisión. [Ver las pantallas a tamaño fijo](docs/arte/pantallas.jpg).

| Documento | Uso |
|---|---|
| [Instrucciones del agente](CLAUDE.md) | Inicio de cada sesión y orden de ejecución |
| [Producto y economía](docs/FUNCIONAL.md) | Reglas de adopción, tiempo, cuidados, catálogo, recompensas y versión completa |
| [Arquitectura Flutter + Flame](docs/TECNICA.md) | Stack 2D, rutas, componentes, contratos, esquema y persistencia |
| [Integración de componentes](docs/INTEGRACION.md) y [balance importable](docs/datos/balance-v1.json) | Composición Flutter/Flame, puente nativo de backup, datos locales y diagnóstico |
| [Implementación por entregas](docs/FASES.md) | Secuencia, archivos, acciones concretas y condiciones de salida |
| [Minijuegos](docs/JUEGOS.md) | Física, entradas, niveles, puntuación y extensión del catálogo |
| [Pantallas y arte](docs/UI-UX.md) | Composición, interacción, accesibilidad y proceso de arte 2D por capas y audio |
| [Verificación](docs/PRUEBAS.md) | Fixtures, comandos y recorridos de aceptación por dispositivo |
| [Build y distribución](docs/ENTREGA.md) | Configuración nativa, compra integrada y precios, firma, beta, publicación y recuperación |
| [Estado](docs/ESTADO.md) | Versiones, pruebas ejecutadas, evidencia y pendientes |

El repositorio contiene la especificación y el diseño interactivo. La decisión del 16 de noviembre de 2026 fija **Flutter + Flame y arte completamente 2D** para personaje, escenarios y minijuegos. El prototipo Flutter jugable está en este repositorio (ver abajo y [ESTADO](docs/ESTADO.md)); el flujo de versión completa y el adaptador nativo están implementados; la validación móvil y la configuración de tiendas siguen pendientes. Los valores de balance y los objetivos de rendimiento son valores iniciales de diseño que el agente puede implementar y medir. Una partida por instalación, economía local, juego offline e infraestructura propia sin coste mensual. [GitHub](https://github.com/betitoglez/my-poodle) · `git@github.com:betitoglez/my-poodle.git` · clon del propietario en `/Users/agonzalez/Projects/Personal/my-poodle`.

## Prototipo Flutter

Experiencia completa y navegable: 19 vistas, seis cuidados (comer, bañar, pasear, peluquería, dormir y veterinario), iconos de estado estilo Tamagotchi y salud (el caniche puede ponerse malito, como mucho una vez por semana, y lo cura el veterinario), Huerto saltarín y Frisbee en el prado con Flame, armario con 42 artículos (colores, peinados, ropa por variedad y accesorios con submenús), caniche visible desde cuatro ángulos y partida guardada solo en el dispositivo. Todo el texto visible está en español.

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
flutter analyze && dart run tool/validate_content.dart && flutter test
```

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
| Monetización | Sin anuncios. 18 artículos y Frisbee gratis; 24 artículos y Huerto requieren versión completa. Adaptador nativo y StoreKit local implementados | Validaciones pendientes de F07.5 y producto real/sandbox en F07.6 ([estado](docs/ESTADO.md)) |

Falta además para publicar: completar la aceptación en teléfonos reales (modo avión, segundo plano, restauración de copia, rendimiento), identificador de app definitivo (ahora `dev.mypoodle.my_poodle`), producto «Versión completa» y precios en ambas tiendas, firma, fichas y autorización de distribución del propietario.

Capturas: [escenas ilustradas](docs/capturas/escenas-ilustradas.jpg) · [poses del caniche](docs/capturas/poses-caniche.jpg) · [armario con el caniche ilustrado](docs/capturas/armario-sprites.jpg) · [16 combinaciones](docs/capturas/meshy-16-combinaciones.jpg) · [comparativa con Meshy](docs/capturas/comparativa-meshy.jpg) · [Casa](docs/capturas/casa-salas.jpg) · [Casa antes](docs/capturas/casa.jpg) · [Cuidados](docs/capturas/cuidados.jpg) · [Baño](docs/capturas/bano.jpg) · [Huerto](docs/capturas/huerto.jpg) · [Frisbee](docs/capturas/frisbee.jpg) · [Resultado](docs/capturas/resultado-juego.jpg) · [Armario](docs/capturas/armario.jpg).
