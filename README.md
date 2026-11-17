# My Poodle

Adopta un caniche toy, dale un nombre y cuídalo día a día. En el huerto saltarás con él para recoger frutas. En el prado le lanzarás un frisbee. Con las monedas que ganéis podrás elegir el color de su pelo, vestirlo y probar cortes de peluquería.

**[Abrir el diseño del juego](docs/disenos.html)** desde el clon. Incluye el recorrido de adopción y un selector de pantallas y tamaños para revisión. [Ver las pantallas a tamaño fijo](docs/arte/pantallas.jpg).

| Documento | Uso |
|---|---|
| [Instrucciones del agente](CLAUDE.md) | Inicio de cada sesión y orden de ejecución |
| [Producto y economía](docs/FUNCIONAL.md) | Reglas de adopción, tiempo, cuidados, catálogo y recompensas |
| [Arquitectura Flutter + Flame](docs/TECNICA.md) | Stack 2D, rutas, componentes, contratos, esquema y persistencia |
| [Integración de componentes](docs/INTEGRACION.md) y [balance importable](docs/datos/balance-v1.json) | Composición Flutter/Flame, puente nativo de backup, datos locales y diagnóstico |
| [Implementación por entregas](docs/FASES.md) | Secuencia, archivos, acciones concretas y condiciones de salida |
| [Minijuegos](docs/JUEGOS.md) | Física, entradas, niveles, puntuación y extensión del catálogo |
| [Pantallas y arte](docs/UI-UX.md) | Composición, interacción, accesibilidad y proceso de arte 2D por capas y audio |
| [Verificación](docs/PRUEBAS.md) | Fixtures, comandos y recorridos de aceptación por dispositivo |
| [Build y distribución](docs/ENTREGA.md) | Configuración nativa, publicidad, firma, beta, publicación y recuperación |
| [Estado](docs/ESTADO.md) | Versiones, pruebas ejecutadas, evidencia y pendientes |

El repositorio contiene la especificación y el diseño interactivo. La decisión del 16 de noviembre de 2026 fija **Flutter + Flame y arte completamente 2D** para personaje, escenarios y minijuegos. El prototipo Flutter jugable está en este repositorio (ver abajo y [ESTADO](docs/ESTADO.md)); las fases de firma, publicidad y tiendas siguen pendientes. Los valores de balance y los objetivos de rendimiento son valores iniciales de diseño que el agente puede implementar y medir. Una partida por instalación, economía local, juego offline e infraestructura propia sin coste mensual. [GitHub](https://github.com/betitoglez/my-poodle) · `git@github.com:betitoglez/my-poodle.git` · clon del propietario en `/Users/agonzalez/Projects/Personal/my-poodle`.

## Prototipo Flutter

Experiencia completa y navegable: 19 vistas, cuatro cuidados, Huerto saltarín y Frisbee en el prado con Flame, armario con 16 combinaciones y partida guardada solo en el dispositivo. Todo el texto visible está en español.

### Ejecutar

Requiere Flutter estable 3.50 o compatible (Dart 3.14).

```bash
flutter pub get
```

```bash
flutter run -d chrome
```

```bash
flutter run -d <id-del-dispositivo>
```

Comprobaciones antes de compilar:

```bash
flutter analyze && dart run tool/validate_content.dart && flutter test
```

Compilaciones verificadas en esta máquina: `flutter build web --release` y `flutter build ios --simulator --debug`. Android necesita instalar el Android SDK (`flutter doctor`).

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
| `web` | `localStorage` para la vista previa web sin dependencias de plugins |

Sin backend, analítica, SDK publicitario ni plugins nativos de terceros.

### Modo demostración

Casa → Ajustes → «Mantén pulsado para entrar» (2 s) → Zona adulta → «Entrar en modo demostración». Usa una partida de muestra en memoria (etiqueta DEMO visible): necesidades bajas o llenas, 0/9/10/12/100 monedas, combinaciones de aspecto y el espacio de banner en Casa. Al salir se recupera la partida normal sin cambios.

### Qué es provisional

| Área | Estado | Para la versión publicable |
|---|---|---|
| Caniche | Ilustrado por capas generado con Meshy: base por peinado y pose (frente, perfil, salto), pelaje por matriz de color y capas de ropa y cuello ([cómo ampliarlo](docs/arte/meshy/FUENTES.md#cómo-ampliar-el-armario)). El vectorial queda como respaldo | Poses propias de comer y dormir, más fotogramas de carrera, revisar derechos de uso |
| Salón, cocina, baño, peluquería, armario y cojín de adopción | Ilustraciones generadas con Meshy a partir de las referencias de `docs/arte` ([origen](docs/arte/meshy/FUENTES.md)); el sendero del paseo sigue siendo vectorial | Revisar derechos de uso de Meshy; ilustrar el sendero |
| Fondos del huerto y del prado, miniaturas de tarjetas | Recortes de las ilustraciones de referencia del propietario (`docs/arte`) | Confirmar derechos y exportar a resolución final |
| Animaciones | Transformaciones por capas sobre un reloj común (reposo, parpadeo, caricia, comida, baño, cepillado, trote, olfateo, carrera, salto, captura, celebración, descanso) | Secuencias dibujadas |
| Audio | No hay archivos; efectos con respuesta háptica y ajustes guardados | Música Mureka y efectos ElevenLabs, un reproductor y licencias por archivo |
| Tipografía | Fuentes del sistema | Empaquetar Young Serif y Nunito (OFL) |
| Textos | Privacidad marcada como provisional; resto de textos de juego definitivos para revisión | Política legal real |
| Acceso adulto | Pulsación mantenida | Revisar con las normas infantiles de cada tienda |
| Publicidad | Solo `NoAds` y banda simulada; punto de integración en `AdsController.onReturnHome` | Elegir proveedor compatible con Flutter y audiencia infantil (ver ENTREGA) |

Falta además para publicar: Android SDK y pruebas en teléfonos reales (modo avión, segundo plano, restauración de copia, rendimiento), identificador de app definitivo (ahora `dev.mypoodle.my_poodle`), firma, fichas y autorización de distribución del propietario.

Capturas de la vista previa web: [armario con el caniche ilustrado](docs/capturas/armario-sprites.jpg) · [16 combinaciones](docs/capturas/meshy-16-combinaciones.jpg) · [comparativa con Meshy](docs/capturas/comparativa-meshy.jpg) · [Casa](docs/capturas/casa-salas.jpg) · [Casa antes](docs/capturas/casa.jpg) · [Cuidados](docs/capturas/cuidados.jpg) · [Baño](docs/capturas/bano.jpg) · [Huerto](docs/capturas/huerto.jpg) · [Frisbee](docs/capturas/frisbee.jpg) · [Resultado](docs/capturas/resultado-juego.jpg) · [Armario](docs/capturas/armario.jpg).
