# Idiomas y nombres de la app

La primera beta y el MVP incluyen 11 variantes. Inglés es el idioma de respaldo para un sistema no soportado. El selector de Ajustes permite elegir idioma o seguir el dispositivo, y conserva la elección al cerrar.

| Variante | Nombre de la app |
|---|---|
| Inglés · en | My Poodle |
| Español · es | Mi Caniche |
| Francés · fr | Mon Caniche |
| Alemán · de | Mein Pudel |
| Portugués de Brasil · pt-BR | Meu Poodle |
| Italiano · it | Il mio Barboncino |
| Ruso · ru | Мой пудель |
| Coreano · ko | 나의 푸들 |
| Japonés · ja | マイプードル |
| Chino simplificado · zh-Hans | 我的贵宾犬 |
| Chino tradicional · zh-Hant | 我的貴賓犬 |

El nombre bajo el icono depende del idioma de la app en el sistema iOS/Android; el selector interno cambia la interfaz. Bundle ID `com.betitoglez.mypoodle`, SKU `mypoodle-ios` y producto `mypoodle.full_version` no cambian entre países o idiomas. El título de la ficha de App Store también debe traducirse en las 11 variantes; el inglés no sustituye a los títulos de los demás idiomas. La disponibilidad del nombre comercial se comprueba por separado: Apple ha rechazado «Mi Caniche» por estar ocupado y el propietario ha elegido **Mi Caniche: mascota virtual** para la ficha española. El título francés necesita el calificador **Mon Caniche : animal virtuel** por otra colisión. Estos calificadores de tienda no cambian el nombre dentro de la app ni bajo el icono. El resto de fichas usará el nombre de la tabla, sujeto a disponibilidad. La persistencia de las localizaciones de tienda sigue pendiente de comprobar tras renovar la sesión web de Apple.

Los catálogos se empaquetan en `assets/l10n/`; no hay traducción ni envío de datos de jugador durante el uso. Los nombres introducidos, fotos e importes de la tienda se conservan. La traducción inicial se ha preparado con asistencia automática y necesita revisión lingüística humana antes de producción, especialmente instrucciones de juego y términos de vestuario. Cambiar una frase de origen exige actualizar todos los catálogos y verificar sus parámetros.

Validación: `dart run tool/validate_localizations.dart` y `flutter test test/l10n test/ui/localization_photo_test.dart`. Los textos nativos de la tienda se gestionan aparte en App Store Connect/Google Play.
