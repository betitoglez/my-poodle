# Verificación reproducible

Preparar test/domain, test/data, test/ui, test/game e integration_test. IClock ofrece UTC y reloj monótono activo independiente; FakeClock avanza explícitamente. SaveStore recibe directorio temporal único y escritor con fallos inyectables. La tienda usa SimulatedStore; ninguna prueba automática depende de la tienda real. El recorrido adopción-compra utiliza dominio real.

## Ejecutar desde la raíz Flutter

Tras implementar F00 y los casos correspondientes:

```sh
flutter pub get
flutter analyze
dart run tool/validate_content.dart
flutter test --coverage
flutter devices
flutter test integration_test/app_flow_test.dart -d <device-id>
```

El validador y el test de integración son archivos que se crearán en F01/F02. Sustituir device-id por dispositivo real/emulador disponible. Exigir salida correcta y casos realmente ejecutados; conservar informes y logs con fecha/revisión. Avanzar componentes con tiempo controlado; evitar pumpAndSettle sobre un bucle Flame infinito. Una prueba de widgets no acredita backup nativo ni firma. [Pruebas de integración Flutter](https://docs.flutter.dev/testing/integration-tests).

## Casos de dominio y disco

| ID | Preparación y acción | Resultado obligatorio |
|---|---|---|
| E01 | Adoptar «  Miel  », «María José», nombre con acento combinante, vacío y 17 grafemas | Normalización NFC y recorte en los válidos; los inválidos no crean archivo |
| E02 | Fixture adoptada con saciedad 65. Avanzar 899 s, 1 s, otras 7 ventanas de 900 s | 65 → 64,25 → 59. Cursor reproduce el mismo valor tras reiniciar |
| E03 | Avanzar 48 h, volver una hora y consultar de nuevo | Pérdida limitada a 8 h, nuevo cursor conserva fracción y la lectura repetida no reaplica el tiempo |
| E04 | Completar comida con saciedad 95, paseo con energía 2, cepillado dos veces con mismo token | Saciedad 100, energía 0, higiene aumenta una sola vez por sesión confirmada |
| E05 | Saldo 9, 10 y 12 ante pañuelo; cancelar vista previa, comprar y reequipar | Operaciones rechazadas/canceladas no mutan; saldos 0 y 2 en las compras válidas, propiedad única |
| E06 | Texto JSON truncado, principal ausente con copia, versión futura, identificador de cosmético retirado | Recuperación de copia válida; esquema futuro preservado; fallback visual mantiene propiedad |
| E07 | Interrumpir antes de escribir, a mitad del temporal, tras cerrar temporal, tras reemplazar pero antes del recibo | Reabrir muestra última revisión válida. Reintentar con el mismo ID nunca suma dos premios |
| E08 | Enviar Finish después de cancelar, colisión duplicada de fruta, tres callbacks de disco para un tiro | Monedas y puntuación se conceden solo por eventos válidos y terminales |
| E09 | 0/7/12 frutas y 0/1/2/3 capturas | Premios 2/9/14 y 3/6/9/12. Métricas fuera de rango se rechazan |
| E10 | Construir catálogo con ID duplicada, referencia rota o artículo en ranura errónea | ValidateContent falla e identifica el recurso defectuoso antes de compilar |
| E11 | Sin versión completa: comprar outfit.sweater_red con 100 monedas, comprar neck.coral con 12, empezar Huerto y Frisbee, completar los seis cuidados | Jersey y Huerto → `requiresFull` sin mutar saldo ni propiedad; pañuelo → saldo 2; Frisbee y cuidados funcionan igual que con versión completa |
| E12 | Con versión completa: comprar jersey con 32 monedas y empezar Huerto. Después aplicar revocación confirmada | Compra correcta (saldo 0) y sesión creada. Tras revocar, el jersey sigue en propiedad, equipado y reequipable gratis; Huerto y compras `full` nuevas → `requiresFull` |
| E13 | Aplicar purchased, el mismo evento dos veces, restored, pending, canceled, error y un evento de otro producto | Un solo cambio a full; pending no desbloquea; canceled, error y otro producto no cambian el derecho; nunca cambian monedas ni propiedad |
| E14 | Documento de derecho ausente, truncado, con esquema futuro y con `source: simulated` en Release. Reiniciar la partida con versión completa | Ausente o dañado → gratis y la app arranca; esquema futuro se preserva; simulado se ignora en Release. El reinicio conserva la versión completa |
| E15 | Fallo inyectado al escribir el documento tras un evento purchased; sin red al arrancar con caché full; consulta Android `unknown` y `notOwned` | Sin escritura no se completa la transacción y se reintenta al reentregarla. Sin red se mantiene full. `unknown` conserva, `notOwned` revoca |

## Pruebas de interacción Flutter + Flame

1. **P01** Abrir Boot con directorio vacío, escribir Miel, adoptar, abrir cuenco y ofrecer tres bocados. Cambiar escena y recargar desde disco. Nombre Miel, saciedad 85, saldo 0 con reloj fijo.
2. **P02** Empezar baño, tocar una zona dos veces, salir. Comparar estado con fixture. Completar la secuencia con tres zonas distintas y aclarar. Higiene pasa de 70 a 95.
3. **P03** Caminar hasta tres puntos, pausar al segundo, reanudar y terminar. Ánimo 90 y energía 75 desde adopción. Cepillar y cancelar compra de corte; el corte natural permanece.
4. **P04** Completar el frisbee con tres capturas y reingresar al armario. Probar pañuelo, confirmar dos veces rápidamente, desequipar y reequipar. Saldo final 2 y propiedad única. Interrumpir una partida nueva de frisbee sin premio.
5. **P05** Inyectar 7 recogidas mediante colisiones en Orchard, caer y reaparecer, terminar. Añade 9 monedas aunque temporizador y meta terminen juntos. Enlazar con P04 produce saldo 11.
6. **P06** Sin versión completa, tocar el Huerto y un jersey: aparece «Pide ayuda a un adulto» y Volver regresa sin cambios. Fallar la puerta adulta tres veces (espera de 30 s), acertarla, comprar con SimulatedStore en cada estado (sin red, cancelada, error, pendiente → aprobada) y comprobar que solo la confirmada desbloquea. Un evento que llega mientras se juega al frisbee no abre ninguna pantalla ni cambia el premio. Ninguna oferta aparece al arrancar, en Casa ni en Resultado.
7. **P07** Alternar Home, CareRoom y juegos diez veces. Verificar un solo AppRoot, una instancia activa de juego y un oyente por evento. Usar Flutter DevTools en profile para buscar crecimiento persistente de atlas, componentes o audio.

## Matriz sobre teléfonos

- En pruebas de widgets y emuladores/simuladores comprobar 320×568, 390×844, 430×932 y un Android 360×800 lógico con navegación gestual. Probar apertura del teclado en adopción, textos largos, indicación de monedas y botón primario. Ambos pulgares deben poder jugar. Repetir en silencio y con movimiento reducido.
- En al menos un iPhone y un Android real: instalar limpia, jugar en modo avión, enviar al fondo durante salto, disco, compra y guardado, forzar cierre y arrancar de nuevo. Android Atrás sigue la navegación prevista, iOS puede perder foco por interrupción del sistema. Cerrar teclado no adopta ni cancela la partida.
- Para actualización, instalar A, adoptar y comprar pañuelo; instalar B sobre A con la misma firma/identidad. Nombre, saldo y aspecto quedan intactos. Para transferencia, migrar A a un segundo dispositivo por la vía del sistema; el segundo debe abrir Adopción y el primero conservar el pañuelo. Ejecutar el caso en ambos ecosistemas. Una reinstalación limpia no sustituye a esta prueba de migración.
- En teléfono de menor rendimiento elegido, medir arranque frío y 60 s por escena tras 10 s de calentamiento con Flutter DevTools en profile. Objetivos iniciales: 30 fps, p95 de fotograma ≤ 33,4 ms, arranque a pantalla interactiva ≤ 5 s, sin crecimiento sostenido tras diez ciclos. Medir desarrollo para diagnóstico y repetir percepción/carga con candidata Release. Si falla, identificar CPU/GPU/IO, ajustar atlas, transparencias, repintado o inicialización y repetir el mismo recorrido.
- Compra en dispositivo (iPhone y Android): con el archivo StoreKit en simulador, con sandbox o TestFlight en iPhone y con la prueba interna de Play y una cuenta de licencias en Android. Comprar, cerrar la app durante la confirmación y reabrir (se desbloquea una sola vez); compra pendiente y aprobación familiar; cancelar; restaurar tras reinstalar; reembolso de prueba; modo avión con versión completa ya comprada. Comprobar el precio localizado en al menos dos países o divisas de prueba.
- Evidencia por prueba: ID, SHA, versión Flutter/build number, dispositivo/OS, fixture, esperado, observado, captura o informe y estado. Un caso pendiente de hardware se queda pendiente. La apertura del diseño HTML verifica UX de referencia, no ejecuta estas pruebas Flutter/Flame.

## Personalización y simulación 2D

- **A01** Las 16 combinaciones iniciales conservan las otras ranuras al modificar una; comparar reposo, carrera, salto y captura en casa y juegos. Máscara de pelaje no tiñe ojos, ropa ni accesorios.
- **A02** Verificar cada pieza en todas las poses/vistas, pivotes y prioridades; detectar referencias o fotogramas ausentes antes de build. Añadir una pieza nueva sin duplicar animaciones completas por combinación.
- **A03** Ejecutar huerto con igual secuencia de entrada a 30/60 fps: misma trayectoria, frutas y premio; probar barrido con avance grande para evitar atravesar plataformas. El cambio de ropa no altera hitbox.
- **A04** Frisbee: mismas coordenadas de campo producen igual acierto/premio en cada tamaño; guía, disco y sombra coinciden con su proyección. Pausa no consume vuelo ni intento.
