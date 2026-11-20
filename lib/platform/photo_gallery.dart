import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Resultado de copiar una foto del álbum privado al carrete del sistema.
enum GalleryExportResult { saved, denied, failed }

/// Canal pequeño hacia Kotlin/Swift que añade un PNG a la galería del móvil
/// (Android MediaStore en Pictures/My Poodle, iOS Fotos con permiso de solo
/// añadir). No lee la fototeca ni sube nada. Ver docs/TECNICA.md.
class PhotoGallery {
  PhotoGallery._();

  static const channel = MethodChannel('my_poodle/photos');

  /// Solo Android e iOS tienen carrete; web y escritorio no muestran la opción.
  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Copia [png] al carrete. [name] es el nombre de archivo sin extensión.
  static Future<GalleryExportResult> save(
    Uint8List png, {
    required String name,
  }) async {
    if (!supported) return GalleryExportResult.failed;
    try {
      final result = await channel.invokeMethod<String>('saveToGallery', {
        'bytes': png,
        'name': name,
      });
      return switch (result) {
        'saved' => GalleryExportResult.saved,
        'denied' => GalleryExportResult.denied,
        _ => GalleryExportResult.failed,
      };
    } on PlatformException catch (e) {
      return e.code == 'denied'
          ? GalleryExportResult.denied
          : GalleryExportResult.failed;
    } on MissingPluginException {
      return GalleryExportResult.failed;
    }
  }
}
