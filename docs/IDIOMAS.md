# Idiomas y nombres de la app

La primera beta y el MVP incluyen 11 variantes. Inglés es el idioma de respaldo para un sistema no soportado. El selector de Ajustes permite elegir idioma o seguir el dispositivo, y conserva la elección al cerrar.

| Variante | Nombre en la app y el icono | Título de App Store guardado |
|---|---|---|
| Inglés · en | My Poodle | My Poodle |
| Español · es | Mi Caniche | Mi Caniche: mascota virtual |
| Francés · fr | Mon Caniche | Mon Caniche : animal virtuel |
| Alemán · de | Mein Pudel | Mein Pudel |
| Portugués de Brasil · pt-BR | Meu Poodle | Meu Poodle |
| Italiano · it | Il mio Barboncino | Il mio Barboncino |
| Ruso · ru | Мой пудель | Мой пудель |
| Coreano · ko | 나의 푸들 | 나의 푸들 |
| Japonés · ja | マイプードル | マイプードル |
| Chino simplificado · zh-Hans | 我的贵宾犬 | 我的贵宾犬 |
| Chino tradicional · zh-Hant | 我的貴賓犬 | 我的貴賓犬 |

Los 11 títulos de ficha están guardados y verificados tras recargar App Store Connect el 20-11-2026; [registro](reviews/testflight-20261120/apple-configuration.json) y [captura de localizaciones](reviews/testflight-20261120/apple-titles.jpg). Español y francés llevan un descriptor por disponibilidad del nombre comercial. Los errores repetidos de alemán/portugués de una vista anterior se resolvieron usando el estado actualizado de Apple; ambos conservan su nombre corto. No se retiró ninguna localización.

El nombre bajo el icono depende del idioma de la app en el sistema iOS/Android; el selector interno cambia la interfaz y conserva la elección. Bundle ID `com.betitoglez.mypoodle`, SKU `mypoodle-ios` y producto `mypoodle.full_version` no cambian entre países o idiomas. Los títulos de ficha se preparan para la próxima versión de tienda; la beta interna no equivale a una publicación comercial.

Los catálogos se empaquetan en `assets/l10n/`; no hay traducción ni envío de datos de jugador durante el uso. Los nombres introducidos, fotos e importes de la tienda se conservan. La traducción inicial se ha preparado con asistencia automática y necesita revisión lingüística humana antes de producción, especialmente instrucciones de juego y términos de vestuario. Cambiar una frase de origen exige actualizar todos los catálogos y verificar sus parámetros.

Validación: `dart run tool/validate_localizations.dart` y `flutter test test/l10n test/ui/localization_photo_test.dart`. Los textos nativos de la tienda se gestionan aparte en App Store Connect/Google Play.
