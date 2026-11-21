import 'package:my_poodle/l10n/localized_widgets.dart';

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_root.dart';
import '../../app/app_scope.dart';
import '../../data/photo_album.dart';
import '../../domain/balance.dart';
import '../../game/scenes/stage_game.dart';
import '../../platform/photo_gallery.dart';
import '../navigation.dart';
import '../parental_gate.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/live_poodle_view.dart';
import '../widgets/scene_view.dart';

class PhotoScreen extends StatefulWidget {
  const PhotoScreen({super.key});
  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  final _background = GlobalKey();
  final _live = LivePoodleController();
  HomeGame? _game;
  bool _resting = false;
  bool _saving = false;
  late PhotoAlbum _album;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = AppScope.of(context);
    _album = PhotoAlbum(c.store.backend);
    _game ??= HomeGame(
      painter: PetPainterScope.of(context),
      look: c.look,
      reducedMotion: c.reducedMotion,
    );
    _game!.setLook(c.look);
    _game!.setDecor(c.pet.decor);
  }

  bool get _showModel =>
      LivePoodleView.enabled &&
      !_live.failed &&
      LivePoodleView.supports(AppScope.read(context).pet.appearance);

  Future<void> _takePhoto() async {
    if (_saving || (_showModel && !_live.ready)) return;
    setState(() => _saving = true);
    ui.Image? back;
    ui.Image? front;
    ui.Image? composed;
    try {
      final boundary =
          _background.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      back = await boundary.toImage(pixelRatio: 2);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImage(back, Offset.zero, Paint());
      if (_showModel) {
        final png = await _live.snapshot();
        if (png == null) throw StateError('Escena no disponible');
        final codec = await ui.instantiateImageCodec(png);
        front = (await codec.getNextFrame()).image;
        codec.dispose();
        canvas.drawImageRect(
          front,
          Rect.fromLTWH(0, 0, front.width.toDouble(), front.height.toDouble()),
          Rect.fromLTWH(0, 0, back.width.toDouble(), back.height.toDouble()),
          Paint(),
        );
      }
      final picture = recorder.endRecording();
      composed = await picture.toImage(back.width, back.height);
      picture.dispose();
      final bytes = await composed.toByteData(format: ui.ImageByteFormat.png);
      await _album.save(bytes!.buffer.asUint8List());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: LText('Foto guardada en tu álbum.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: LText(
              'No se ha podido guardar la foto. Comprueba que el álbum no esté lleno e inténtalo de nuevo.',
            ),
          ),
        );
      }
    } finally {
      back?.dispose();
      front?.dispose();
      composed?.dispose();
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    _game!.useLiveBed = _showModel;
    _game!.pet.showSprite = !_showModel;
    _game!.setResting(_resting);
    return Scaffold(
      appBar: AppBar(
        title: const LText('Modo foto'),
        actions: [
          TextButton.icon(
            label: const LText('Álbum'),
            icon: const Icon(Icons.photo_library_rounded),
            onPressed: () =>
                pushScreen(context, PhotoAlbumScreen(album: _album)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: LText(
                'Gira a tu caniche, elige su pose y guarda el recuerdo.',
              ),
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(
                    key: _background,
                    child: SceneView(
                      game: _game!,
                      semanticsLabel: 'Escena para la foto de tu caniche',
                      onDragUpdate: _showModel
                          ? (_, _, delta) => _live.rotate(delta.dx)
                          : null,
                    ),
                  ),
                  if (_showModel)
                    LivePoodleView(
                      controller: _live,
                      wardrobe: false,
                      appearance: c.pet.appearance,
                      reducedMotion: c.reducedMotion,
                      resting: _resting,
                      idle: true,
                      passiveBed: true,
                      hygiene: c.pet.needPoints(Need.hygiene),
                      onStatusChanged: () {
                        if (mounted) setState(() {});
                      },
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconButton(
                        tooltip: localizeNullable(
                          context,
                          'Girar a la izquierda',
                        ),
                        onPressed: _live.ready ? () => _live.rotate(-60) : null,
                        icon: const Icon(Icons.rotate_left_rounded),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _resting = !_resting),
                        child: LText(_resting ? 'De pie' : 'Tumbarse'),
                      ),
                      IconButton(
                        tooltip: localizeNullable(
                          context,
                          'Girar a la derecha',
                        ),
                        onPressed: _live.ready ? () => _live.rotate(60) : null,
                        icon: const Icon(Icons.rotate_right_rounded),
                      ),
                      IconButton(
                        tooltip: localizeNullable(context, 'Volver de frente'),
                        onPressed: _live.ready ? _live.front : null,
                        icon: const Icon(Icons.center_focus_strong_rounded),
                      ),
                    ],
                  ),
                  AppButton(
                    label: _saving ? 'Guardando foto…' : 'Hacer foto',
                    icon: Icons.camera_alt_rounded,
                    big: true,
                    expand: true,
                    onPressed: _saving || (_showModel && !_live.ready)
                        ? null
                        : _takePhoto,
                  ),
                  const SizedBox(height: 8),
                  const LText(
                    'Las fotos se guardan en el álbum de esta app (hasta 24). Una persona adulta puede copiarlas al carrete del móvil.',
                    style: AppText.small,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhotoAlbumScreen extends StatefulWidget {
  const PhotoAlbumScreen({super.key, required this.album});
  final PhotoAlbum album;
  @override
  State<PhotoAlbumScreen> createState() => _PhotoAlbumScreenState();
}

class _PhotoAlbumScreenState extends State<PhotoAlbumScreen> {
  late Future<List<AlbumPhoto>> _photos = widget.album.load();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const LText('Álbum de fotos')),
    body: FutureBuilder<List<AlbumPhoto>>(
      future: _photos,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(() => _photos = widget.album.load()),
              child: const LText('No se pudo abrir el álbum. Reintentar'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final photos = snapshot.data!;
        if (photos.isEmpty) {
          return const Center(
            child: LText('Tu álbum está vacío. Haz tu primera foto.'),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            return InkWell(
              onTap: () async {
                await pushScreen(
                  context,
                  PhotoDetailScreen(album: widget.album, photo: photo),
                );
                if (mounted) setState(() => _photos = widget.album.load());
              },
              child: FutureBuilder<Uint8List>(
                future: widget.album.read(photo),
                builder: (context, image) => image.hasData
                    ? Image.memory(
                        image.data!,
                        fit: BoxFit.cover,
                        semanticLabel: localizeNullable(
                          context,
                          'Foto de tu caniche',
                        ),
                      )
                    : const Center(child: Icon(Icons.photo_rounded)),
              ),
            );
          },
        );
      },
    ),
  );
}

class PhotoDetailScreen extends StatefulWidget {
  const PhotoDetailScreen({
    super.key,
    required this.album,
    required this.photo,
  });
  final PhotoAlbum album;
  final AlbumPhoto photo;
  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  late final Future<Uint8List> _image = widget.album.read(widget.photo);
  bool _deleting = false;
  bool _exporting = false;

  /// Copia la foto al carrete del sistema tras la puerta adulta: sale de la
  /// app, igual que un enlace externo. El permiso del sistema se pide después.
  Future<void> _exportToGallery() async {
    if (_exporting || _deleting) return;
    if (!await ParentalGate.show(context) || !mounted) return;
    setState(() => _exporting = true);
    var result = GalleryExportResult.failed;
    try {
      result = await PhotoGallery.save(
        await _image,
        name: 'MyPoodle-${widget.photo.id}',
      );
    } catch (_) {
      result = GalleryExportResult.failed;
    }
    if (!mounted) return;
    setState(() => _exporting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: LText(switch (result) {
          GalleryExportResult.saved => 'Foto guardada en el carrete del móvil.',
          GalleryExportResult.denied => 'Sin permiso para guardar en el carrete. Actívalo en los ajustes del móvil.',
          GalleryExportResult.failed => 'No se ha podido guardar la foto en el carrete. Inténtalo de nuevo.',
        }),
      ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const LText('¿Eliminar esta foto?'),
        content: const LText('La foto se quitará del álbum de esta app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const LText('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const LText('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await widget.album.remove(widget.photo);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: LText(
              'No se ha podido eliminar la foto. Inténtalo de nuevo.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const LText('Foto de tu caniche'),
      actions: [
        IconButton(
          tooltip: localizeNullable(context, 'Eliminar foto'),
          onPressed: _deleting || _exporting ? null : _delete,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
    ),
    bottomNavigationBar: PhotoGallery.supported
        ? SafeArea(
            minimum: const EdgeInsets.all(12),
            child: FutureBuilder<Uint8List>(
              future: _image,
              builder: (context, image) => AppButton(
                key: const Key('photo-export'),
                label: _exporting
                    ? 'Guardando en el carrete…'
                    : 'Guardar en el carrete',
                icon: Icons.download_rounded,
                secondary: true,
                expand: true,
                onPressed: image.hasData && !_exporting && !_deleting
                    ? _exportToGallery
                    : null,
              ),
            ),
          )
        : null,
    body: FutureBuilder<Uint8List>(
      future: _image,
      builder: (context, image) => image.hasData
          ? Center(
              child: InteractiveViewer(
                child: Image.memory(
                  image.data!,
                  semanticLabel: localizeNullable(
                    context,
                    'Foto de tu caniche',
                  ),
                ),
              ),
            )
          : Center(
              child: image.hasError
                  ? const LText('No se ha podido abrir la foto.')
                  : const CircularProgressIndicator(),
            ),
    ),
  );
}
