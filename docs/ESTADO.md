# Estado de la implementación

Registro vivo. Distingue **implementado**, **probado en este Mac** (pruebas automáticas, compilación, navegador) y **probado en dispositivo** (ninguno todavía).

## Sesión 2026-11-16 · Prototipo completo Flutter + Flame

Encargo: [PROMPT_PROTOTIPO_FLUTTER_DART](../README.md#prototipo-flutter) (prototipo de experiencia con las 19 vistas, cuidados, dos minijuegos y personalización persistente). Repositorio sin commits previos.

### Entorno y versiones

| Herramienta | Versión | Nota |
|---|---|---|
| Flutter | 3.50.0 stable (rev. ab2912035e, 2026-11-09) | Instalado con Homebrew en esta sesión |
| Dart | 3.14.0 | Incluido en Flutter |
| Flame | 1.38.2 | `pubspec.lock` versionado |
| material_ui | 1.11.1 | Material separado del framework desde Flutter 3.47 |
| characters | 1.4.1 | Conteo de grafemas del nombre |
| web | 1.1.2 | `localStorage` en la vista previa web |
| Xcode / CocoaPods | 26.6 (17F113) / 1.17.0 | Compilación iOS de simulador correcta |
| Android SDK | **No instalado** | `flutter doctor`: «Unable to locate Android SDK». Sin APK |

### Cobertura del plan (FASES.md)

| ID | Estado | Detalle |
|---|---|---|
| 00.1 | Hecho parcial | Flutter, Xcode y Chrome detectados. Falta Android SDK/JDK |
| 00.2 | Hecho | Proyecto `android/`, `ios/`, `web/` generado con `flutter create --org dev.mypoodle` (identificador provisional, confirmar con el propietario) |
| 00.3 | Hecho | Flame, flutter_test, `lib/domain` sin Flutter/Flame. Fuente local pendiente (se usan fuentes del sistema) |
| 00.4 | Hecho parcial | Vertical en Android/iOS/web; escenas en `GameWidget`. Build iOS simulador sí; APK no (sin SDK); sin instalación en dispositivo |
| 01.1–01.4 | Hecho | `PetState`, `NeedsClock`, `SaveStore` (principal/copia/temporal, fallos inyectables), catálogo y cartera, `Finish` con sesión |
| 02.1–02.3 | Hecho | Arranque, Adopción, Casa, Cocina; caniche por capas |
| 02.4 | Pendiente de dispositivo | Recorrido verificado en pruebas de widgets y en Chrome; falta modo avión en teléfono |
| 03.1–03.2 | Hecho con arte provisional | Caniche vectorial por capas (`PetPainter`), máscaras de pelaje, 2 cortes, peto y pañuelo, poses frontal y perfil, metadatos en `assets/data/appearance-v1.json`. Sin atlas PNG final |
| 03.3 | Hecho | Armario con vista previa aislada, compra única, cancelar/descartar |
| 03.4 | Pendiente | Sin audio producido; ajustes de música/efectos guardados; efectos = háptica |
| 04.1–04.3 | Hecho | Baño (toque y arrastre), Peluquería con espejo y acceso a cortes, Paseo con 3 paradas |
| 04.4 | No incluido | Veterinario: ampliación posterior fuera de las 19 vistas (reglas en balance y dominio) |
| 04.5 | Hecho parcial | Un solo `pointerId` por gesto en `SceneView`; sin prueba en hardware |
| 05.1–05.4 | Hecho | Simulación pura a 1/120 s, barrido, tolerancias, checkpoint, premio 2 + manzanas |
| 06.1–06.4 | Hecho | Frisbee con proyección afín, guía de 16 muestras de la misma función, asistido; catálogo de juegos |
| 07.1 | Hecho parcial | `NoAds` y espacio de banner simulado (modo demostración). Sin `SimulatedAds` ni política de intersticial |
| 07.2–08.3 | Pendiente | Proveedor publicitario, medición en hardware, firma y tiendas (requieren datos del propietario) |

### Pruebas ejecutadas (este Mac, 2026-11-16)

| Comando | Resultado |
|---|---|
| `flutter analyze` | Sin incidencias |
| `dart run tool/validate_content.dart` | «Contenido válido: 8 artículos, 2 poses, 9 imágenes» |
| `flutter test --coverage` | **54/54 pasan**. Cobertura de líneas 75 % (dominio 89 %, datos 92 %, UI 80 %, juego 64 %) |
| `flutter build web --release` | Correcto |
| `flutter build ios --simulator --debug` | Correcto (`build/ios/iphonesimulator/Runner.app`, incluye el canal Swift) |
| `flutter build apk` | **No ejecutado**: falta Android SDK |

Casos cubiertos por pruebas automáticas (`test/`):

- Dominio (E01–E05, E08–E10): nombre NFC/grafemas/saltos de línea; reloj 899/900 s, 2 h → 59, 48 h → 41, reloj hacia atrás; cuidados con tope; cartera 9/10/12 → rechazo/0/2, reequipar gratis, 16 combinaciones; premios 2/9/14 y 3/6/9/12; recorrido 0 → 12 → 2 → 11; catálogo inválido.
- Guardado (E06, E07): JSON truncado con copia, principal ausente, esquema futuro preservado, ambos dañados, cosmético retirado, temporal huérfano, fallo inyectado en cada frontera de escritura, reinicio y marcador pendiente, archivo real en disco.
- Simulaciones (A03, A04): huerto completo con piloto (12 manzanas, sin caídas), igual resultado a 30 y 60 fps, caída y reaparición, avance grande sin atravesar, un salto por intención; frisbee 3/3 asistidos a 30 y 60 fps, gesto corto, guía = vuelo, tolerancia ≤ 1.
- Recorridos de la app real (`test/ui/app_flow_test.dart`, recorridos 1–12 del encargo): adoptar y reabrir; comer completo (+20 una vez) y abandono a medias; frisbee 12 monedas → pañuelo → 2 → quitar/usar sin coste → vista previa de plata descartada; pausa congela el tiempo del huerto; abandonar sin premio; huerto completo con premio; reinicio cancelado y confirmado; modo demostración aislado; 320×568, 430×932 y 834×1194 con teclado abierto en Adopción.

### Comprobado en navegador (Chrome, vista previa web 390×844)

Adopción con «María José», persistencia tras recargar, Casa, Cuidados, Baño con espuma por zonas, Frisbee con arrastre y asistidos (3/3, +12), resultado, compra del pañuelo (12 → 2), quitar y «Usar» gratis (sigue 2), Huerto. Capturas en [docs/capturas](capturas/). El panel del navegador estaba oculto y limitaba fotogramas: no sirve como medida de rendimiento.

### No comprobado / pendiente con dato que falta

| Pendiente | Qué falta |
|---|---|
| Ejecución en simulador iOS | Permiso de acceso al simulador en el panel de Claude (no respondido en esta sesión) |
| Instalación en iPhone/Android reales, modo avión, segundo plano real, rendimiento | Hardware conectado y autorizado; Android SDK |
| Exclusión de backup verificada (iOS `isExcludedFromBackup`, Android `noBackupFilesDir` + reglas) | Código escrito; requiere prueba de restauración/transferencia en dispositivos |
| Audio (Mureka/ElevenLabs) | Archivos y licencias |
| Arte final por capas (atlas, pivotes, poses) | Producción artística; el caniche actual es vectorial provisional |
| Fuentes Young Serif / Nunito empaquetadas | Descargar TTF con licencia OFL y declararlas en `pubspec.yaml` |
| Textos de privacidad definitivos | Responsable legal; la vista P18 está marcada como provisional |
| Identificador de app, firma, fichas de tienda | Decisión y credenciales del propietario |

### Incidencias conocidas

- Normalización NFC parcial: se componen las letras latinas con diacríticos habituales (á, ñ, ü, ç…); Dart no trae normalización Unicode completa.
- El acceso adulto es una pulsación mantenida de 2 s: provisional, revisar antes de publicar (normas de apps infantiles).
- En la vista previa web el primer clic tras recargar a veces no llega (panel del navegador oculto); no se reproduce en pruebas de widgets.

## Sesión 2026-11-17 · Salas ilustradas con Meshy

- Generadas 6 salas y 2 referencias del caniche con la API de Meshy (`image-to-image`, `nano-banana-pro`): 8 tareas correctas, **72 créditos** (saldo 932 → 860). Origen, prompts y tareas en [arte/meshy/FUENTES.md](arte/meshy/FUENTES.md).
- Integradas las salas en `StageGame`: imagen anclada al suelo, punto de apoyo y altura del caniche por sala (`RoomArt.of`), vuelta al dibujo vectorial si la imagen no carga. Afecta a Casa, Adopción, Cocina, Baño, Peluquería, Armario y resultados.
- Comprobación: `flutter analyze` sin incidencias, `validate_content` (15 imágenes), `flutter test` 54/54, `flutter build web` correcto. Revisada Casa en Chrome a 390×844 ([captura](capturas/casa-salas.jpg), [comparativa](capturas/comparativa-meshy.jpg)). Las demás salas no se han revisado visualmente dentro de la app.
- El CLI de Meshy no se usó: el entorno bloqueó su descarga con npm; se llamó a la API directamente con `MESHY_API_KEY`.
- Pendiente: el caniche vectorial desentona con las salas ilustradas. El piloto (`docs/arte/meshy/pet_*.png`) muestra que Meshy da un caniche coherente, pero entero, no por capas.

## Sesión 2026-11-17 · Piloto 2 del caniche por capas (Meshy)

- 8 variantes alineadas, **72 créditos** (saldo 860 → 788). Detalle en [arte/meshy/FUENTES.md](arte/meshy/FUENTES.md).
- Resultado: viable. Las 16 combinaciones del catálogo se componen con 2 bases (rizo, pompón), una matriz de color para el pelaje y 2 capas superpuestas (peto y pañuelo) extraídas por diferencia: [hoja de 16 combinaciones](capturas/meshy-16-combinaciones.jpg). Ropa, pañuelo y expresiones conservan la pose de la base (IoU 0,97–0,99).
- Integrado después en la sesión siguiente (ver abajo).
- Pendiente para integrar: pañuelo de perfil, variantes del salto (pompón, peto, pañuelo), expresiones del pompón, pose de comer/dormir; pintor por sprites (`ColorFilter.matrix` + capas) con las mismas poses y anclajes.

## Sesión 2026-11-17 · Caniche ilustrado por capas integrado

- 4 variantes más (36 créditos; saldo 788 → 752). Total de la jornada con Meshy: 180 créditos.
- Atlas reproducible: `tool/arte/build_pet_sprites.py` + `pet_sprites_spec.json` → `assets/images/pet/` (14 capas WebP) y `assets/data/pet-sprites-v1.json`.
- `PetSprites` carga el atlas sin bloquear el arranque; `PetPainter` lo usa cuando cubre el aspecto y, si falta alguna pieza o aún no ha cargado, dibuja el vectorial. Pelaje por `ColorFilter.matrix`, base por peinado, expresiones (parpadeo, alegría) en frente, capas de artículos en orden; galope alternando apoyo y salto; reacciones por transformaciones.
- Comprobación: `flutter analyze` sin incidencias; `validate_content` comprueba que cada peinado y artículo tiene capa en las 3 poses; `flutter test` **55/55** (nueva prueba: 16 combinaciones × 2 poses × 13 reacciones pintadas con el atlas); `flutter build web` correcto. Revisado en Chrome 390×844: Casa, Armario (vista previa pompón + peto + pañuelo, [captura](capturas/armario-sprites.jpg)) y Huerto (salto). Cuidados y Frisbee no revisados visualmente con el atlas.
- Limitaciones: no hay pose de comer ni de dormir propias (se simulan con transformaciones y ojos cerrados); el galope usa dos fotogramas; el espejo de peluquería y las zonas de espuma siguen posiciones aproximadas del caniche vectorial.
