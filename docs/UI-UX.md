# Dirección de arte y pantallas

## Dirección de la beta MVP · 19-11-2026

Usar el caniche y vestuario 3D existentes en móvil; verificar la opción de compilación. Soportar 11 variantes, nombres localizados y alfabetos CJK/cirílico, texto largo y accesibilidad. El modo foto muestra el aspecto actual, permite posar/girar y conserva capturas en un álbum privado. En juegos premium se muestra el intento gratuito disponible y la espera de 24 h sin confundirla con una compra.


[Galería de pantallas](arte/pantallas.jpg) · [Diseño interactivo sin conexión](disenos.html) · [Escenarios](arte/escenas.png) · [Prendas, corte y pelaje](arte/armario.png) · [Caniche de perfil](arte/caniche.png).

## Identidad visual

El protagonista es un caniche toy albaricoque: hocico fino, orejas caídas, ojos almendrados oscuros, patas finas y rizos reconocibles a tamaño pequeño. La casa tiene yeso crema, arcos, madera y tejidos. Cocina y salón comparten la luz de la mañana. En baño predominan lavanda y porcelana. El exterior usa verde y ocre; la fruta y el disco destacan en rojo y coral. Mantener ojos, hocico y patas legibles en todos los encuadres. El arte generado define paleta, silueta, atmósfera y encuadre para producir las piezas 2D definitivas.

La UI combina títulos serif redondeados (familia de referencia Young Serif), texto funcional sans (Nunito) y sustitutas locales en la demo. Colores de interfaz: crema #fff8e9, tinta #34283b, ciruela #5c354e, hoja #375e50, moneda dorada #e9b657. Panel crema de esquinas suaves sobre la escena, botones primarios sólidos de texto claro, secundarios con borde y focus visible. El saldo utiliza disco dorado y número. Cada instrucción explica un único gesto.

## Composición por pantalla

| Pantalla | Escena, información y controles | Transición y estados |
|---|---|---|
| Adopción | Retrato sobre cojín, «Tu caniche toy», campo Nombre, sugerencia y Adoptar | Teclado deja visible la confirmación; error bajo el campo; doble toque crea solo una partida |
| Casa | Nombre, retrato del salón, saldo y cuatro indicadores. Accesos Cuidados, Juegos y Armario | Sugerencia para la necesidad más baja; mascota responde a caricia. Sin banners ni ofertas |
| Alimentación | Cámara frente a cuenco, tres marcas y botón Dar un bocado | Escala del alimento disminuye, ojos siguen la mano, último paso abre resumen de saciedad |
| Baño | Bañera lavanda, contador de zonas, botones de ducha y esponja según fase | Espuma visible donde ya se ha trabajado; contorno y toque alternativo por zona |
| Paseo | Vista del sendero, próxima parada y tres huellas | Cámara acompaña con suavidad y permite omitir movimiento de cámara si está reducido |
| Peluquería | Caniche y espejo a media distancia, tres mechones, peine y acceso a cortes | Diferenciar terminar el cepillado y comprar/probar un estilo; precio siempre visible |
| Armario | Vestidor con luz frontal, indicador de saldo, pestañas Ropa, Artículos, Colores y Cortes | Mostrar el perro con la selección. Confirmación expresa el saldo restante; estado propio, equipado, precio o candado «Versión completa». Un artículo con candado se prueba en la vista previa y su botón abre «Pide ayuda a un adulto» |
| Juegos | Dos tarjetas con imagen del huerto y del prado, título y acción | Elegir abre instrucciones, jugar, pausar, repetir o volver. Sin la versión completa, el Huerto lleva candado y abre «Pide ayuda a un adulto» |
| Huerto | Cámara lateral, próximo bancal visible, contador de frutas, tiempo y botón de salto | Saltar con un toque. Confirmar fruta por brillo/sonido breve; caer devuelve al último apoyo |
| Frisbee | Campo despejado, aro destino, disco y guía de trayectoria | Flecha de arrastre con alternativa de toque. Mostrar intentos y aciertos; bloquear entrada durante devolución |
| Resultado | Cuidado o juego recién terminado, caniche, cambio de necesidad o monedas y saldo | Confirmado tras escritura; al fallar guardar ofrecer Reintentar. Nunca superponer una oferta al premio |
| Pide ayuda a un adulto | Caniche con el candado, «Esto es de la versión completa. Pide ayuda a un adulto», botones «Soy un adulto» y «Volver» | Volver regresa a donde estaba, sin perder la vista previa. «Soy un adulto» abre la puerta adulta |
| Versión completa | Solo tras la puerta adulta. Lista corta de lo que incluye, «Pago único. Sin anuncios. Las monedas se ganan jugando», botón «Desbloquear por {precio de la tienda}», «Restaurar compras» y enlace a privacidad | Estados: cargando, disponible, no disponible sin conexión, comprando, esperando la aprobación, desbloqueada («¡Gracias! Ya tienes la versión completa») y error con Reintentar. Al terminar vuelve al punto de partida con el contenido desbloqueado |

## Puerta adulta

Protege la compra, «Restaurar compras», la Zona adulta (reinicio y modo demostración) y cualquier enlace externo. Sustituye a la pulsación mantenida de 2 s, que supera cualquier niño. Pide escribir en cifras un número del 21 al 99 mostrado en letras («Escribe en cifras: cuarenta y siete») con teclado numérico. Número aleatorio en cada apertura; un fallo muestra otro número sin revelar la respuesta; tras tres fallos seguidos espera 30 s antes de otro intento. Cerrar o salir la reinicia. El acceso concedido vale solo para la acción solicitada y caduca al salir de la pantalla protegida. Textos de adulto y número escrito en el idioma activo; no usar colores ni animaciones que inviten al niño a pulsar. Revisar antes de publicar con las normas vigentes de Apple Kids y Google Play Families.

## Adaptación al móvil

Diseñar con unidad lógica, no con píxeles físicos. El visor web ofrece 320×568, 390×844 y 430×932. En Flutter usar SafeArea y LayoutBuilder para HUD y paneles; el fondo puede extenderse detrás de los márgenes del sistema. Dejar fondo a sangre, botones con al menos 48×48 unidades, separación ≥8, márgenes laterales 12/16/20. Para Android añadir ensayo 360×800 con navegación por gestos. Orientación vertical también en ambos minijuegos.

En compacto recortar primero aire del entorno y reducir título; el panel puede desplazarse si aparece teclado o el texto crece. En tamaños altos ampliar escena y mantener controles al pie. Descontar cabecera, margen inferior y controles antes de fijar encuadre. En Orchard ajustar cámara o anticipación para garantizar visión del siguiente salto en pantalla estrecha. Objetivo visual de contraste 4,5:1 en texto normal. Usar señal de forma/texto además del color, volumen local, alternativa al arrastre, animaciones cortas y opción de movimiento reducido. Mantener los textos de accesibilidad en botones y estados. Probar tamaño de texto y lectores de pantalla en dispositivo antes de describir compatibilidad.

## Producción del personaje 2D y audio

1. Usar las ilustraciones existentes como dirección de proporción, paleta y atmósfera. Preparar un maestro editable por capas, cuerpo entero, vistas frontal/perfil realmente utilizadas y expresión tranquila. Conservar fuente, fecha y derechos de uso por recurso. Revisar silueta a 96 px.
2. Separar patas traseras, cola, cuerpo, patas delanteras, cabeza, orejas, pelo, expresión, ropa y cuello; algunas prendas requieren piezas delante/detrás. Exportar PNG con transparencia y atlas con margen entre regiones. Misma escala, pivotes y anclajes por pose; registrar metadatos y prioridades en appearance-v1.json. Empezar con atlas de hasta 2048×2048 y ajustar por medición en móvil; cargar piezas necesarias sin rasterizar todas las combinaciones.
3. Preparar reposo, mirada, comida, carrera, olfateo, sacudida, cepillado, salto, captura y celebración. Reposo/carrera en bucle; desplazamiento gobernado por lógica de juego. Sincronizar fotogramas y transformaciones de todas las capas mediante un reloj común. Movimiento reducido mantiene señales esenciales con transiciones mínimas.
4. Colorear solo el pelaje con máscaras y sombreado preservado. Natural/pompón sustituyen pelo de cabeza, orejas, patas o cola según corte. Peto y pañuelo siguen los anclajes del cuerpo/cuello. No asumir que una imagen plana se adapta automáticamente a toda pose. Una prenda que cubre pelo requiere reglas de ocultación explícitas.
5. Revisar las 16 combinaciones iniciales en casa, cuidados y ambos juegos, incluyendo poses extremas y las dos vistas previstas. Comprobar transparencia, orden de dibujo, cuello, orejas y patas. Al crecer el catálogo, validar cada pieza en todas sus poses, pares que se superponen y una muestra combinatoria; no exportar un perro completo por cada apariencia.
6. Preparar bucles de casa/parque con Mureka y efectos de acciones con ElevenLabs. Recortar y equilibrar niveles, empaquetar audio local y probar un único reproductor compatible; precargar efectos cortos. Todo feedback esencial se entiende en silencio. No hay generación de arte/audio durante la partida.

La galería web y los ejemplos de Figma son referencias de UX y arte. La app usa ilustraciones, sprites y composición 2D de PetComponent en todas las pantallas. Los minijuegos de referencia comunican gesto y feedback; la física 2D, persistencia y métricas de producción están en JUEGOS y TECNICA.

## Modo foto

Entrada desde el icono de cámara en Casa. Conserva el aspecto actual; permite girar, volver de frente y alternar pose de pie/tumbado. Capturar no altera necesidades, monedas ni prendas. Una captura confirma el guardado y aparece en el álbum privado. El álbum permite ampliar y eliminar una foto con confirmación. En Android/iOS, «Guardar en el carrete» copia la foto a la galería del móvil tras la puerta adulta y confirma el resultado (guardada, sin permiso o error con reintento). Los controles se redistribuyen en varias líneas cuando el idioma requiere más espacio.
