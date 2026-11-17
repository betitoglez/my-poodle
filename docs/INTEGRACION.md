# Conectar Flutter, Flame y los móviles

## Del balance a los recursos

[balance-v1.json](datos/balance-v1.json) es la fuente de edición. En F01 copiarlo a assets/data/balance-v1.json y declarar recursos en pubspec.yaml. CatalogLoader lee JSON mediante rootBundle, valida y crea modelos Dart tipados. Comparar fuente y copia en validación de contenido para evitar divergencias. Los objetivos del frisbee usan targetsField: pares laterales/profundidad lógica para proyección 2D, sin eje tridimensional. Metadatos de apariencia separados como define TECNICA.

**Recorrido de control**: saldo 0 → frisbee con 3 aciertos → 12 → comprar neck.coral → 2 → cancelar huerto → 2 → huerto con 7 manzanas → 11 → reequipar neck.coral → 11. Segundo dispositivo abre Adopción.

## Composición y entrada

1. AppRoot crea catálogos, almacenamiento, reloj, audio y sesión una vez. Mostrar Loading hasta completar lectura; después Adopción o Casa. Los tests pueden inyectar dependencias, pero el arranque normal usa las reales.
2. AppShell con SafeArea, cabecera, navegación y modales Flutter. Un modal bloquea interacción inferior. Ajustar formularios al teclado; Atrás cierra primero teclado/modal. Salir de actividad descarta progreso sin confirmar.
3. Cada controlador pertenece a una sesión. Crear FlameGame fuera de build y alojarlo en GameWidget; el HUD y botones accesibles son widgets. Al cerrar ruta, pausar y liberar controladores/listeners; ignorar resultados de sesiones anteriores. Animaciones solo dan feedback; dominio concede premios.
4. Botón Saltar y toque de campo emiten la misma intención. Reservar áreas distintas para controles Flutter y entrada Flame; un gesto nunca dispara ambas. Capturar primer pointerId, soltar/cancelar al salir, pausar o perder foco; ignorar segundo dedo. Transformar pantalla → viewport → mundo antes de probar zonas y colisiones.
5. HUD observa estado confirmado. Ante fallo al guardar, mostrar Reintentar/Volver; Volver descarta candidato solo si se verifica la revisión anterior. Ante resultado incierto, releer antes de decidir. Cola de guardado única también al entrar en segundo plano.
6. Sonido y movimiento reducido se guardan localmente. Puerta adulta antes de enlaces externos. Reinicio opcional: confirmar, usar marcador local para terminar borrado tras cierre y eliminar principal/copia/temporales antes de Adopción.
7. Validar contenido con tool/validate_content.dart antes de builds. F00 solo exige arranque/casa; exigir juegos y piezas según se incorporan. F08 falla ante recursos ausentes o variante monetizada mal configurada.
8. Implementar MethodChannel de almacenamiento en Kotlin y Swift según TECNICA. Propagar errores del sistema y comprobar ruta/atributo de exclusión en diagnóstico local, sin mostrar datos de partida. Probar transferencia real entre teléfonos.
9. Registrar versiones mínimas cubiertas, herramientas nativas, renderer efectivo y permisos del binario. No pedir cámara, micrófono ni ubicación para reproducir recursos empaquetados. Verificar el juego con permisos opcionales denegados.

## Diagnóstico

| Síntoma | Comprobación | Siguiente acción |
|---|---|---|
| No aparece el teléfono | flutter doctor -v, flutter devices y autorización en dispositivo | Completar toolchain, confiar en el Mac o autorizar USB y repetir |
| Sprite ausente o ropa desplazada | pubspec, ruta exacta, atlas, pose, pivote y prioridad | Corregir referencia/metadatos y reproducir misma animación |
| Debug funciona, Release no archiva | Scheme Runner, Team, provisioning y dependencias nativas | Corregir configuración versionada de ios/ y repetir build limpia |
| Play rechaza paquete | ID, versionCode, firma y SDK exigido en consola | Conservar diagnóstico y generar candidata corregida |
| Publicidad no disponible | Red, admisión, soporte Flutter, callback y configuración | Completar recorrido con NoAds y distribuir solo variante coherente con ficha |
| Baja fluidez al vestir | Flutter DevTools en profile: carga, atlas duplicados, transparencias y repintados | Precargar piezas de escena, compartir atlas y medir el mismo recorrido |
