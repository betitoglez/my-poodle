# Planning vigente · My Poodle / Mi Caniche

Actualizado el 20-11-2026. Sustituye las fichas antiguas centradas en un juego exclusivamente 2D. Flutter gestiona interfaz y dominio; el caniche y las actividades móviles usan el visor 3D local, con respaldo 2D. Los registros históricos de ESTADO no se reescriben como éxitos actuales.

## Alcance y decisiones confirmadas

- Gratis con compra única no consumible de versión completa; sin publicidad ni venta de monedas. Una partida local por instalación, sin login de jugadores ni backend.
- Primera beta TestFlight con **11 variantes de idioma y modo foto**. Inglés es el respaldo; español muestra el nombre Mi Caniche. Chino simplificado y tradicional son requisitos separados.
- Juegos premium: un intento gratuito por juego cada 24 horas para quien no tenga la compra. El inicio confirmado consume el cupo; abandono lo consume y un fallo de guardado no. Propiedad de artículos y cupo de juegos son reglas distintas.
- Nuevos candidatos: parejas, Simón de perritos y laberinto. Su inclusión exacta y reglas quedan por definir; no bloquear el hito de compras con un juego cuya definición no está aprobada.
- El objetivo inmediato es una beta funcional en **Sandbox de TestFlight**, no una publicación de producción.

## Secuencia de trabajo y criterios de salida

| Fase | Estado actual | Trabajo pendiente | Criterio de cierre |
|---|---|---|---|
| F00 · Entorno e identidad | Implementado | Mantener builds reproducibles y localización del nombre | Mismo Bundle ID/producto y builds identificables; 3D activo comprobado |
| F01 · Partida y reglas | Implementado y probado | Idioma persistente, cupo premium por juego y almacenamiento del álbum | Carga de partidas antiguas, operaciones atómicas y pruebas de fallos/reinicio |
| F02 · Adopción/Casa | Implementado | Localizar UI y añadir acceso a modo foto | Recorrido completo en los 11 idiomas y sin modificar la partida al fotografiar |
| F03 · 3D, armario y audio | Implementado; aceptación física parcial | Revisión visual de catálogo y poses; licencias/fuentes | Matriz física y audio/silencio correctos; recursos locales y sin red |
| F04 · Cuidados | Implementado; aceptación parcial | Traducciones, accesibilidad y regresión de gestos 3D | Comer/beber/baño/paseo/peluquería/dormir/veterinario correctos en ambos sistemas |
| F05–F06 · Huerto/Frisbee | Implementado | Cupo gratuito premium y mensajes de disponibilidad; definir próximos juegos | Un inicio gratuito cada 24 h por juego, persistente y sin dobles reservas |
| F07.1–F07.4 · Versión completa | Implementado | Compatibilidad del cupo con candados, energía y compra | Cosméticos premium siguen exigiendo la compra; una prueba de juego no compra derechos |
| F07.5 · Correcciones de compra | Integrado en main | PR #5 (`f08fb2d`): restauración, cancelación/pending Android y reconciliación al reanudar | 193 pruebas y análisis correctos; Codex sin incidencias. Compra/cancelación y reinicio/offline/restauración iPhone TestFlight (33) confirmados |
| F07.6 · Apple Sandbox | Compra/cancelación y persistencia/restauración físicas confirmadas | Build 33: precio, desbloqueo, reinicio/offline y restauración con partida conservada correctos; pendientes escenarios avanzados y restauración limpia | Precio/hoja Sandbox, compra/cancelación/pendiente/restauración/revocación y persistencia acreditados |
| F07.7 · Aceptación móvil | Parcial | Offline iPhone confirmado para el derecho completo; quedan interrupciones, accesibilidad, rendimiento y cobertura 3D | Dispositivo, build y evidencia por caso; no confundir prueba automática con física |
| F08 · TestFlight | Primera beta interna funcional; comprobación básica superada | 0.5.0 (33) en MVP Sandbox e instalada: compra/cancelación, reinicio/offline/restauración y foto 3D/álbum confirmados. Continuar QA ampliada y feedback | Build procesada por Apple, instalable desde TestFlight y compra Sandbox probada |
| F09 · Idiomas MVP | Implementado y probado automáticamente | 11 títulos de ficha guardados y verificados; catálogos, nombres nativos y selector implementados. Revisión lingüística y aceptación física pendientes | Catálogos completos, persistencia, nombres nativos y recorridos sin desbordes; revisión lingüística identificada |
| F10 · Modo foto MVP | Captura/álbum probados físicamente | Dos poses 3D, giro/ropa, conservación tras reabrir y álbum confirmados; comprobar borrado físico y matriz de aspectos | Imagen real del render; fotos conservadas tras reiniciar; sin acceso a fotos ajenas |
| F11 · Juegos nuevos | Por definir | Parejas, Simón de perritos y laberinto | Reglas, premios, tier y alcance aprobados antes de implementar |

F09 y F10 forman parte de F08 y están incluidos en la primera beta interna: 11 variantes empaquetadas y foto/álbum con comprobación física básica. La beta no cierra la revisión lingüística ni la aceptación ampliada de producción. F11 mantiene definición pendiente por indicación del propietario.

## Ruta de integración

1. Partir del main remoto actual y conservar los cambios locales de otros clones.
2. Integrar las correcciones de compras con sus regresiones; mantener los avances 3D y audio.
3. Implementar la prueba de juego premium y sus casos de frontera de 24 h, fallo de guardado y concurrencia.
4. Incorporar idiomas y nombres localizados, incluyendo alfabetos CJK/cirílico, y el modo foto.
5. Ejecutar análisis, validadores, pruebas y build Release/Archive; verificar flag 3D y assets.
6. Preparar y subir a TestFlight, completar configuración Apple y pruebas Sandbox con el propietario.
7. Registrar por separado implementado, compilado, subido, procesado y probado físicamente. No marcar pasos remotos sin observar su resultado.

## Aceptación mínima de compras

Compra única → acceso al catálogo completo y Huerto; cancelación/error → sin entrega y con reintento; pendiente → sin entrega hasta confirmación; restaurar → conservar partida/monedas; reinicio/offline → derecho confirmado conservado; reembolso/revocación → retirada del derecho sin borrar la partida. La prueba gratuita de juegos no altera la propiedad de la versión completa.
