# Conectar Flutter, Flame y los móviles

## Del balance a los recursos

[balance-v1.json](datos/balance-v1.json) es la fuente de edición. En F01 copiarlo a assets/data/balance-v1.json y declarar recursos en pubspec.yaml. CatalogLoader lee JSON mediante rootBundle, valida y crea modelos Dart tipados. Comparar fuente y copia en validación de contenido para evitar divergencias. Los objetivos del frisbee usan targetsField: pares laterales/profundidad lógica para proyección 2D, sin eje tridimensional. Metadatos de apariencia separados como define TECNICA.

**Recorrido de control** (con versión completa simulada): saldo 0 → frisbee con 3 aciertos → 12 → comprar neck.coral → 2 → cancelar huerto → 2 → huerto con 7 manzanas → 11 → reequipar neck.coral → 11. Segundo dispositivo abre Adopción.

**Recorrido gratuito**: saldo 0 → frisbee con 3 aciertos → 12 → comprar neck.coral → 2 → tocar Huerto → «Pide ayuda a un adulto» → Volver → 2 → probar outfit.sweater_red en la vista previa → candado, saldo 2 y aspecto anterior al salir. Comprar la versión completa simulada → el Huerto abre y el jersey muestra su precio en monedas; saldo 2.

## Composición y entrada

1. AppRoot crea catálogos, almacenamiento, documento de derecho, StoreController, reloj, audio y sesión una vez. StoreController se suscribe a la tienda antes de mostrar Casa. Mostrar Loading hasta completar lectura; después Adopción o Casa. Los tests pueden inyectar dependencias, pero el arranque normal usa las reales.
2. AppShell con SafeArea, cabecera, navegación y modales Flutter. Un modal bloquea interacción inferior. Ajustar formularios al teclado; Atrás cierra primero teclado/modal. Salir de actividad descarta progreso sin confirmar.
3. Cada controlador pertenece a una sesión. Crear FlameGame fuera de build y alojarlo en GameWidget; el HUD y botones accesibles son widgets. Al cerrar ruta, pausar y liberar controladores/listeners; ignorar resultados de sesiones anteriores. Animaciones solo dan feedback; dominio concede premios.
4. Botón Saltar y toque de campo emiten la misma intención. Reservar áreas distintas para controles Flutter y entrada Flame; un gesto nunca dispara ambas. Capturar primer pointerId, soltar/cancelar al salir, pausar o perder foco; ignorar segundo dedo. Transformar pantalla → viewport → mundo antes de probar zonas y colisiones.
5. HUD observa estado confirmado. Ante fallo al guardar, mostrar Reintentar/Volver; Volver descarta candidato solo si se verifica la revisión anterior. Ante resultado incierto, releer antes de decidir. Cola de guardado única también al entrar en segundo plano.
6. Sonido y movimiento reducido se guardan localmente. Puerta adulta ([UI-UX](UI-UX.md#puerta-adulta)) antes de comprar, restaurar, entrar en la Zona adulta o abrir enlaces externos. Reinicio opcional: confirmar, usar marcador local para terminar borrado tras cierre y eliminar principal/copia/temporales de la partida antes de Adopción; el documento de derecho se conserva.
7. Validar contenido con tool/validate_content.dart antes de builds. F00 solo exige arranque/casa; exigir juegos y piezas según se incorporan. F08 falla ante recursos ausentes, artículos o juegos sin `tier`, ID de producto vacío o tienda simulada activable en Release.
8. Implementar MethodChannel de almacenamiento en Kotlin y Swift según TECNICA. Propagar errores del sistema y comprobar ruta/atributo de exclusión en diagnóstico local, sin mostrar datos de partida. Probar transferencia real entre teléfonos.
9. Registrar versiones mínimas cubiertas, herramientas nativas, renderer efectivo y permisos del binario. No pedir cámara, micrófono ni ubicación para reproducir recursos empaquetados. El único permiso añadido por la compra es `com.android.vending.BILLING`. Verificar el juego con permisos opcionales denegados.

## Diagnóstico

| Síntoma | Comprobación | Siguiente acción |
|---|---|---|
| No aparece el teléfono | flutter doctor -v, flutter devices y autorización en dispositivo | Completar toolchain, confiar en el Mac o autorizar USB y repetir |
| Sprite ausente o ropa desplazada | pubspec, ruta exacta, atlas, pose, pivote y prioridad | Corregir referencia/metadatos y reproducir misma animación |
| Debug funciona, Release no archiva | Scheme Runner, Team, provisioning y dependencias nativas | Corregir configuración versionada de ios/ y repetir build limpia |
| Play rechaza paquete | ID, versionCode, firma y SDK exigido en consola | Conservar diagnóstico y generar candidata corregida |
| Compra no disponible | Red, ID del producto, producto activo en la consola, build instalada desde el canal de prueba, cuenta de prueba o sandbox, archivo StoreKit en el esquema | Mostrar «No disponible ahora» y seguir con la versión gratuita; corregir configuración y repetir |
| Comprado pero sigue bloqueado | Evento recibido, escritura del documento de derecho, `completePurchase`, ID de producto | Reabrir la app (la tienda reentrega la transacción no completada) o «Restaurar compras»; revisar el orden escribir → publicar → completar |
| Baja fluidez al vestir | Flutter DevTools en profile: carga, atlas duplicados, transparencias y repintados | Precargar piezas de escena, compartir atlas y medir el mismo recorrido |
