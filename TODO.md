# TODO · My Poodle

Recomendaciones de la revisión del 17 de noviembre de 2026. El plan por tareas está en [docs/FASES.md](docs/FASES.md) y el estado real en [docs/ESTADO.md](docs/ESTADO.md). Marca aquí lo que se complete y registra la evidencia en ESTADO.

## Falta para publicar

- [x] **F07.5 · Adaptador nativo y configuración.** `IapStore` Android/iOS, precio localizado, compra/restauración, eventos, guardado antes de confirmar, StoreKit local y capacidad iOS, BILLING en Android. Ver [ESTADO](docs/ESTADO.md): implementar no equivale a cerrar todas las pruebas de aceptación.
- [ ] **Cerrar validación F07.5.** APK y manifiesto fusionado (falta Android SDK), StoreKitTest bloqueado en iOS 26.5 (Code=3/notEntitled), y recorridos nativos de compra, pendiente, cancelación, restauración y reembolso todavía sin acreditar.
- [ ] **F07.6 · Productos y cuentas reales.** IDs definitivos, acuerdos de pagos, producto en ambas consolas, precios y pruebas sandbox/Play Internal en teléfonos.
- [x] **Smoke test iPhone en Profile.** Adopción, alimentación, guardado nativo, puerta adulta, consulta de tienda y conservación entre procesos; evidencia en ESTADO.
- [ ] **F07.7 · Aceptación móvil restante.** Modo avión, segundo plano, transferencia/restauración y rendimiento en iPhone/Android reales.

- [x] **Icono de la app.** Android, iOS y web usan el logo de Flutter. Icono adaptativo en Android (fondo, primer plano y monocromo para iconos temáticos de Android 13+), todos los tamaños de iOS (1024 px sin canal alfa) y favicon e iconos web. *Hecho (5545986); falta comprobarlo en Android y en un iPhone real.*
- [x] **Pantalla de arranque (splash).** Android solo pinta el fondo del sistema; en iOS `LaunchImage` es un PNG transparente (pantalla vacía). Configurar la SplashScreen de Android 12+, el `launch_background` anterior y el `LaunchScreen` de iOS con el mismo color que `LoadingScreen`, sin destello al pasar a Flutter. *Hecho (5545986); falta comprobarlo en Android y en un iPhone real.*
- [ ] **Audio (FASES 03.4).** No hay ningún sonido; hoy los efectos son solo háptica. Música corta en bucle, efectos de cuidados, minijuegos e interfaz, con canales Music/Pet/UI y silencio persistente. Registrar origen y licencia de cada archivo.
- [ ] **Fuente local con licencia (FASES 00.3).** Se usan fuentes del sistema, que difieren entre Android e iOS.
- [ ] **Coherencia del arte.** El sendero del paseo sigue siendo vectorial y la peluquería tiene un tono distinto al resto de salas.
- [ ] **Nombre e identificador definitivos.** `CFBundleName` es `my_poodle`; los IDs `dev.mypoodle.*` son provisionales y condicionan el producto `mypoodle.full_version`.
- [ ] **Ficha de tienda (FASES 08.x).** URL de política de privacidad, capturas reales, clasificación por edades y formularios de privacidad de Play y App Store.

## Funcionales

- [ ] **Más valor en la versión completa.** Hoy se paga por 24 artículos y un minijuego (Huerto). Añadir un tercer minijuego `full` siguiendo [docs/JUEGOS.md](docs/JUEGOS.md).
- [ ] **No perder el caniche al cambiar de móvil.** La partida se excluye de la copia de seguridad a propósito: la compra se restaura en el móvil nuevo, pero el caniche no. Exportar e importar la partida (archivo o código) detrás de la puerta adulta, sin servidor.
- [ ] **Inglés.** Solo hay español y los precios ya contemplan dólares. Localizar con `flutter_localizations` y textos en ARB.
- [ ] **Objetivos a medio plazo.** Álbum de pegatinas o logros locales, sin monedas de pago, que den motivos para volver.
- [ ] **Primera partida guiada.** Guía corta en Casa aprovechando los `seenHints` existentes.
- [ ] **Accesibilidad.** `Semantics` en botones y escenas, prueba con texto grande y revisión de contraste.
- [ ] **Recordatorios opcionales.** Notificaciones locales («Miel tiene hambre») desactivadas por defecto y activables solo desde la Zona adulta. Requiere justificar el plugin.

## Estéticas

- [ ] **Reacciones al tocarlo.** Corazones al acariciarlo, mover la cola, seguir el dedo con la mirada y reposos variados (bostezar, rascarse).
- [ ] **Luz según la hora.** La ventana de Casa cambia con la hora local, en coherencia con dormir.
- [ ] **Pequeñas celebraciones.** Confeti al estrenar ropa, monedas que se suman una a una al ganar y transiciones suaves entre salas.
- [ ] **Modo foto.** Posar al caniche con su ropa y guardarlo en un álbum dentro del juego, sin compartir fuera.
