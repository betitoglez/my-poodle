# Música

Las tres pistas son copias sin modificar de los archivos aportados por el propietario desde Descargas.

| Recurso | Uso | Duración aprox. | Archivo original |
|---|---|---|---|
| `assets/audio/background.mp3` | Casa, adopción, menús, instrucciones y resultados | 3:12 | `music_172885862187013_9pZourXjs97kk9aDpeursW_xitkrr.mp3` |
| `assets/audio/games.mp3` | Huerto y Frisbee durante la partida | 1:53 | `music_172891748564993_QXgjk84dEeCAt224CdvZkS_desjat.mp3` |
| `assets/audio/activities.mp3` | Cuidados: comer, beber, bañar, pasear, peluquería, dormir y veterinario | 1:54 | `music_172891748564993_QXgjk84dEeCAt224CdvZkS_mopkzt.mp3` |

Todas son MP3 estéreo, 44,1 kHz, 128 kbit/s. Se reproducen localmente, sin red, en bucle y al 35 % de volumen. No se han editado los empalmes del bucle. Tamaños: Casa 3.079.149 bytes; juegos 1.815.240 bytes; actividades 1.831.959 bytes.

Un único reproductor `audioplayers` 6.8.1 cambia de fuente según la página visible. Al cambiar de contexto se pausa la pista anterior y la nueva comienza desde el principio; navegar entre menús o reconstruir una pantalla no reinicia la pista actual. Un menú abierto desde una actividad usa la pista de Casa y al cerrarlo se recupera la de la actividad. Los diálogos conservan la selección de la página.

Se conserva la posición al silenciar desde Ajustes o pasar a segundo plano mientras no cambie la pista. Se pausa también en los diálogos de pausa y abandono de actividades. La preferencia existente `music` se guarda con la partida. En web comienza tras el primer toque y se reintenta con otro gesto si el navegador bloquea la reproducción. Los fallos de audio no impiden jugar.

Procedencia: archivos facilitados por el propietario; no se ha aportado documentación de autoría o licencia. Se conservan los efectos sonoros de ElevenLabs y la respuesta háptica; véase [EFECTOS](audio/EFECTOS.md). Música y efectos respetan ajustes independientes y comparten una sesión de audio compatible.
