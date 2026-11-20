import 'package:my_poodle/l10n/localized_widgets.dart';

import 'dart:math' as math;

import 'package:flutter/semantics.dart';

import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../app/feedback.dart';
import '../../data/photo_album.dart';
import '../../domain/balance.dart';
import '../../domain/pet_name.dart';
import '../../domain/photo_caption.dart';
import '../../domain/rules.dart';
import '../ask_adult_view.dart';
import '../navigation.dart';
import '../theme.dart';
import '../widgets/celebrations.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';
import '../widgets/photo_art.dart';

enum _EditorTab { stickers, frames, text }

/// Paso «Decorar foto»: pegatinas, marco y una línea de texto sobre la foto
/// recién hecha. Decorar es gratis; solo se cobra al desbloquear un pack.
/// Devuelve true si la foto se guardó en el álbum. Volver o «Descartar» no
/// guarda ni cobra nada.
class PhotoEditorScreen extends StatefulWidget {
  const PhotoEditorScreen({super.key, required this.png, required this.album});

  /// Foto capturada (escena Flutter + visor 3D ya compuestos).
  final Uint8List png;
  final PhotoAlbum album;

  /// Máximo de pegatinas en una foto.
  static const maxStickers = 12;

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  ui.Image? _photo;
  Object? _decodeError;
  _EditorTab _tab = _EditorTab.stickers;
  final List<PlacedSticker> _stickers = [];
  int? _selected;
  int _nextUid = 0;
  String? _frame;
  final _text = TextEditingController();
  String _textStyle = 'text.plain';
  int _color = 0;
  bool _busy = false;
  bool _saving = false;

  // Estado del gesto de escala/giro de la pegatina activa.
  double _startScale = 1;
  double _startRotation = 0;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  Future<void> _decode() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.png);
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _photo = frame.image);
    } catch (e) {
      if (mounted) setState(() => _decodeError = e);
    }
  }

  @override
  void dispose() {
    _photo?.dispose();
    _text.dispose();
    super.dispose();
  }

  PlacedSticker? get _active =>
      _stickers.where((s) => s.uid == _selected).firstOrNull;

  /// Texto válido o vacío (sin texto).
  String get _caption => switch (PhotoCaption.validate(_text.text)) {
    ValidName(:final value) => value,
    InvalidName() => '',
  };

  String? get _captionError => switch (PhotoCaption.validate(_text.text)) {
    InvalidName(error: NameError.tooLong) =>
      'Máximo ${PhotoCaption.maxGraphemes} caracteres.',
    InvalidName(error: NameError.invalidCharacters) =>
      'Usa solo letras, números y signos en una línea.',
    _ => null,
  };

  PhotoDecoration _decoration(BuildContext context) => PhotoDecoration(
    frame: _frame,
    stickers: List.of(_stickers),
    text: _caption,
    textStyle: _textStyle,
    textColor: photoTextColors[_color].$2,
    words: {
      for (final s in _stickers)
        if (photoBubbleWord(s.id) case final word?)
          s.id: localize(context, word),
    },
  );

  // ------------------------------------------------------------ packs

  /// Abre (o compra) el pack de [pack]. Devuelve true si ya se puede usar.
  Future<bool> _unlock(PhotoPack pack) async {
    final c = AppScope.read(context);
    if (c.photoPackOwned(pack)) return true;
    if (c.photoPackLocked(pack)) {
      await showAskAdult(context);
      return false;
    }
    if (pack.cost > c.pet.coins) {
      await _insufficient(pack.cost - c.pet.coins, pack.cost);
      return false;
    }
    final ok = await showPurchaseDialog(
      context,
      title: 'Desbloquear pack',
      items: [photoPackLabel(pack.id)],
      price: pack.cost,
      balance: c.pet.coins,
      confirmLabel: 'Desbloquear',
      note: 'Se desbloquea una sola vez. Hacer fotos sigue siendo gratis.',
    );
    if (!ok || !mounted) return false;
    setState(() => _busy = true);
    final r = await commitOrRecover<PurchaseOutcome>(
      context,
      () => c.buyPhotoPack(pack.id),
    );
    if (!mounted) return false;
    setState(() => _busy = false);
    switch (r) {
      case Purchased(cost: final paid):
        if (paid > 0) {
          AppScope.feedbackOf(context).play(Sfx.coins);
          ConfettiBurst.show(context, reducedMotion: c.reducedMotion);
        }
        return true;
      case InsufficientCoins(:final missing, cost: final price):
        await _insufficient(missing, price);
      case RequiresFull():
        await showAskAdult(context);
      case null:
        break;
    }
    return false;
  }

  Future<void> _insufficient(int missing, int price) async {
    final choice = await showInsufficientDialog(
      context,
      missing: missing,
      price: price,
    );
    if (choice == InsufficientChoice.games && mounted) {
      goToTab(context, ShellTab.games);
    }
  }

  Future<void> _usePiece(PhotoPack pack, String piece) async {
    if (_busy || _saving) return;
    if (pack.kind == PhotoPackKind.sticker &&
        AppScope.read(context).photoPackOwned(pack) &&
        _stickers.length >= PhotoEditorScreen.maxStickers) {
      _snack('Ya hay ${PhotoEditorScreen.maxStickers} pegatinas en la foto.');
      return;
    }
    if (!await _unlock(pack) || !mounted) return;
    if (pack.kind == PhotoPackKind.sticker &&
        _stickers.length >= PhotoEditorScreen.maxStickers) {
      return;
    }
    setState(() {
      switch (pack.kind) {
        case PhotoPackKind.sticker:
          final n = _stickers.length;
          final sticker = PlacedSticker(
            uid: _nextUid++,
            id: piece,
            center: Offset(.3 + (n % 3) * .2, .3 + (n ~/ 3 % 3) * .15),
          );
          _stickers.add(sticker);
          _selected = sticker.uid;
        case PhotoPackKind.frame:
          _frame = piece;
        case PhotoPackKind.text:
          _textStyle = piece;
      }
    });
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: LText(text)));

  // ------------------------------------------------------------ pegatinas

  void _edit(PlacedSticker s, void Function() change) {
    setState(() {
      change();
      s.scale = s.scale.clamp(PlacedSticker.minScale, PlacedSticker.maxScale);
      s.center = Offset(s.center.dx.clamp(0, 1), s.center.dy.clamp(0, 1));
    });
  }

  void _move(PlacedSticker s, Offset delta) =>
      _edit(s, () => s.center += delta);
  void _grow(PlacedSticker s, double factor) =>
      _edit(s, () => s.scale *= factor);
  void _turn(PlacedSticker s) => _edit(s, () => s.rotation += math.pi / 8);
  void _remove(PlacedSticker s) => setState(() {
    _stickers.remove(s);
    if (_selected == s.uid) _selected = null;
  });

  // ------------------------------------------------------------ guardar

  Future<void> _save() async {
    final photo = _photo;
    if (photo == null || _saving || _busy) return;
    if (_captionError != null) {
      setState(() => _tab = _EditorTab.text);
      return;
    }
    setState(() => _saving = true);
    try {
      final png = await _decoration(context).compose(photo);
      await widget.album.save(png);
      // TODO(logros): c.recordPhotoTaken()
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        _snack(
          'No se ha podido guardar la foto. Comprueba que el álbum no esté lleno e inténtalo de nuevo.',
        );
      }
    }
  }

  void _discard() {
    if (_saving) return;
    Navigator.of(context).pop(false);
  }

  // ------------------------------------------------------------ interfaz

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final l = Layout.of(context);
    final blocked = _busy || _saving;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: const LText(
            'Decorar foto',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12, left: 6),
              child: CoinBalance(coins: c.pet.coins),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                flex: l.compact ? 4 : 5,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.s),
                  child: _canvas(context),
                ),
              ),
              Expanded(
                flex: l.compact ? 5 : 4,
                child: Panel(
                  padding: EdgeInsets.fromLTRB(
                    l.gutter,
                    AppSpace.s,
                    l.gutter,
                    AppSpace.s,
                  ),
                  child: Column(
                    children: [
                      _tabs(),
                      const SizedBox(height: AppSpace.s),
                      Expanded(
                        child: SingleChildScrollView(
                          child: switch (_tab) {
                            _EditorTab.stickers => _stickerPanel(c),
                            _EditorTab.frames => _framePanel(c),
                            _EditorTab.text => _textPanel(c),
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpace.s),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              key: const Key('photo-editor-discard'),
                              label: 'Descartar',
                              icon: Icons.delete_outline_rounded,
                              secondary: true,
                              expand: true,
                              onPressed: _saving ? null : _discard,
                            ),
                          ),
                          const SizedBox(width: AppSpace.s),
                          Expanded(
                            child: AppButton(
                              key: const Key('photo-editor-save'),
                              label: _saving ? 'Guardando foto…' : 'Guardar',
                              icon: Icons.check_rounded,
                              expand: true,
                              onPressed: _photo == null || blocked
                                  ? null
                                  : _save,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _canvas(BuildContext context) {
    final photo = _photo;
    if (photo == null) {
      return Center(
        child: _decodeError == null
            ? const CircularProgressIndicator()
            : const LText('No se ha podido abrir la foto.'),
      );
    }
    final decoration = _decoration(context);
    return Center(
      child: AspectRatio(
        aspectRatio: photo.width / photo.height,
        child: LayoutBuilder(
          builder: (context, box) {
            final size = box.biggest;
            final base = PlacedSticker.baseSide(size);
            return ClipRect(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _selected = null),
                      child: LSemantics(
                        image: true,
                        label: 'Foto de tu caniche',
                        child: RawImage(image: photo, fit: BoxFit.fill),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _BasePainter(decoration)),
                    ),
                  ),
                  for (final s in _stickers) _placed(context, s, size, base),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _placed(
    BuildContext context,
    PlacedSticker s,
    Size size,
    double base,
  ) {
    final side = base * s.scale;
    final selected = s.uid == _selected;
    final step = 0.05;
    return Positioned(
      left: s.center.dx * size.width - side / 2,
      top: s.center.dy * size.height - side / 2,
      width: side,
      height: side,
      child: Semantics(
        label: localize(context, 'Pegatina: ${photoPieceLabel(s.id)}'),
        button: true,
        selected: selected,
        onTap: () => setState(() => _selected = s.uid),
        customSemanticsActions: {
          CustomSemanticsAction(
            label: localize(context, 'Mover a la izquierda'),
          ): () =>
              _move(s, Offset(-step, 0)),
          CustomSemanticsAction(
            label: localize(context, 'Mover a la derecha'),
          ): () =>
              _move(s, Offset(step, 0)),
          CustomSemanticsAction(label: localize(context, 'Mover arriba')): () =>
              _move(s, Offset(0, -step)),
          CustomSemanticsAction(label: localize(context, 'Mover abajo')): () =>
              _move(s, Offset(0, step)),
          CustomSemanticsAction(label: localize(context, 'Más grande')): () =>
              _grow(s, 1.2),
          CustomSemanticsAction(label: localize(context, 'Más pequeña')): () =>
              _grow(s, 1 / 1.2),
          CustomSemanticsAction(label: localize(context, 'Girar')): () =>
              _turn(s),
          CustomSemanticsAction(
            label: localize(context, 'Borrar pegatina'),
          ): () =>
              _remove(s),
        },
        excludeSemantics: true,
        child: GestureDetector(
          key: ValueKey('placed-sticker-${s.uid}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _selected = s.uid),
          onScaleStart: (_) {
            _startScale = s.scale;
            _startRotation = s.rotation;
            setState(() => _selected = s.uid);
          },
          onScaleUpdate: (d) => _edit(s, () {
            s.center += Offset(
              d.focalPointDelta.dx / size.width,
              d.focalPointDelta.dy / size.height,
            );
            if (d.pointerCount > 1) {
              s.scale = _startScale * d.scale;
              s.rotation = _startRotation + d.rotation;
            }
          }),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: selected
                  ? Border.all(color: AppColors.focus, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(AppRadii.s),
            ),
            child: Transform.rotate(
              angle: s.rotation,
              child: CustomPaint(
                painter: _StickerPainter(
                  s.id,
                  photoBubbleWord(s.id) == null
                      ? null
                      : localize(context, photoBubbleWord(s.id)!),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabs() => Row(
    children: [
      for (final (tab, label, icon) in [
        (_EditorTab.stickers, 'Pegatinas', Icons.emoji_emotions_rounded),
        (_EditorTab.frames, 'Marcos', Icons.filter_frames_rounded),
        (_EditorTab.text, 'Texto', Icons.text_fields_rounded),
      ])
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _TabButton(
              label: label,
              icon: icon,
              selected: _tab == tab,
              onTap: () => setState(() => _tab = tab),
            ),
          ),
        ),
    ],
  );

  /// Botones accesibles para la pegatina elegida.
  Widget _stickerTools(BuildContext context, PlacedSticker s) {
    const step = 0.05;
    Widget tool(String tip, IconData icon, VoidCallback onPressed) =>
        IconButton(
          tooltip: localize(context, tip),
          onPressed: onPressed,
          icon: Icon(icon),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LText(
          'Pegatina: ${photoPieceLabel(s.id)}',
          style: AppText.small,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            tool('Mover a la izquierda', Icons.arrow_back_rounded, () {
              _move(s, const Offset(-step, 0));
            }),
            tool('Mover arriba', Icons.arrow_upward_rounded, () {
              _move(s, const Offset(0, -step));
            }),
            tool('Mover abajo', Icons.arrow_downward_rounded, () {
              _move(s, const Offset(0, step));
            }),
            tool('Mover a la derecha', Icons.arrow_forward_rounded, () {
              _move(s, const Offset(step, 0));
            }),
            tool('Más grande', Icons.zoom_in_rounded, () => _grow(s, 1.2)),
            tool(
              'Más pequeña',
              Icons.zoom_out_rounded,
              () => _grow(s, 1 / 1.2),
            ),
            tool('Girar', Icons.rotate_right_rounded, () => _turn(s)),
            tool('Borrar pegatina', Icons.delete_rounded, () => _remove(s)),
          ],
        ),
        const Divider(),
      ],
    );
  }

  Widget _stickerPanel(AppController c) {
    final active = _active;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (active != null)
          _stickerTools(context, active)
        else
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpace.s),
            child: LText(
              'Toca una pegatina para ponerla. Arrástrala con un dedo; con dos, gírala y cambia su tamaño.',
              style: AppText.small,
            ),
          ),
        for (final pack in c.balance.photoPacksOf(PhotoPackKind.sticker))
          _packSection(pack),
      ],
    );
  }

  Widget _framePanel(AppController c) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: AppSpace.s,
        runSpacing: AppSpace.s,
        children: [
          _PieceTile(
            id: 'frame.none',
            label: photoPieceLabel('frame.none'),
            state: _frame == null ? 'Puesto' : 'Gratis',
            selected: _frame == null,
            locked: false,
            onTap: () => setState(() => _frame = null),
          ),
        ],
      ),
      for (final pack in c.balance.photoPacksOf(PhotoPackKind.frame))
        _packSection(pack),
    ],
  );

  Widget _textPanel(AppController c) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        key: const Key('photo-editor-text'),
        controller: _text,
        maxLines: 1,
        maxLength: PhotoCaption.maxGraphemes,
        textInputAction: TextInputAction.done,
        inputFormatters: [
          FilteringTextInputFormatter.deny(RegExp(r'[\u0000-\u001f\u007f]')),
        ],
        decoration: InputDecoration(
          labelText: localize(context, 'Texto de la foto'),
          errorText: _captionError == null
              ? null
              : localize(context, _captionError!),
        ),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: AppSpace.xs),
      const LText('Color del texto', style: AppText.small),
      Wrap(
        spacing: AppSpace.s,
        children: [
          for (var i = 0; i < photoTextColors.length; i++)
            LSemantics(
              button: true,
              selected: _color == i,
              label: photoTextColors[i].$1,
              excludeSemantics: true,
              onTap: () => setState(() => _color = i),
              child: InkResponse(
                onTap: () => setState(() => _color = i),
                child: Container(
                  width: AppSizes.touch,
                  height: AppSizes.touch,
                  padding: const EdgeInsets.all(6),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: photoTextColors[i].$2,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == i
                            ? AppColors.focus
                            : AppColors.inkSoft,
                        width: _color == i ? 4 : 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      for (final pack in c.balance.photoPacksOf(PhotoPackKind.text))
        _packSection(pack),
    ],
  );

  Widget _packSection(PhotoPack pack) {
    final c = AppScope.of(context);
    final owned = c.photoPackOwned(pack);
    final locked = c.photoPackLocked(pack);
    final status = pack.free
        ? 'Gratis'
        : owned
        ? 'En propiedad'
        : locked
        ? 'Versión completa'
        : '${pack.cost} monedas';
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: LText(
                  photoPackLabel(pack.id),
                  style: AppText.subtitle.copyWith(fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (locked)
                const Icon(Icons.lock_rounded, size: 16, color: AppColors.plum)
              else if (!owned)
                const CoinIcon(size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: LText(
                  status,
                  style: AppText.small,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Wrap(
            spacing: AppSpace.s,
            runSpacing: AppSpace.s,
            children: [
              for (final piece in pack.pieces)
                _PieceTile(
                  id: piece,
                  label: photoPieceLabel(piece),
                  word: photoBubbleWord(piece) == null
                      ? null
                      : localize(context, photoBubbleWord(piece)!),
                  state: owned
                      ? (_frame == piece || _textStyle == piece
                            ? 'Puesto'
                            : 'Gratis')
                      : status,
                  selected: _frame == piece || _textStyle == piece,
                  locked: !owned,
                  lockedFull: locked,
                  onTap: () => _usePiece(pack, piece),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LSemantics(
    button: true,
    selected: selected,
    label: label,
    excludeSemantics: true,
    onTap: onTap,
    child: Material(
      color: selected ? AppColors.plum : Colors.white,
      borderRadius: BorderRadius.circular(AppRadii.s),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.s),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.touch),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.cream : AppColors.plum,
              ),
              LText(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.cream : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Ficha de una pieza: dibujo vectorial, candado si no se posee.
class _PieceTile extends StatelessWidget {
  const _PieceTile({
    required this.id,
    required this.label,
    required this.state,
    required this.selected,
    required this.locked,
    required this.onTap,
    this.lockedFull = false,
    this.word,
  });
  final String id;
  final String label;
  final String? word;
  final String state;
  final bool selected;
  final bool locked;
  final bool lockedFull;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LSemantics(
    button: true,
    selected: selected,
    label: label,
    value: state,
    excludeSemantics: true,
    onTap: onTap,
    child: Material(
      key: Key('photo-piece-$id'),
      color: selected ? AppColors.plumSoft : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.s),
        side: BorderSide(
          color: selected ? AppColors.plum : const Color(0x22000000),
          width: selected ? 3 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.all(6),
                child: Opacity(
                  opacity: locked ? .55 : 1,
                  child: id == 'frame.none'
                      ? const Icon(
                          Icons.do_not_disturb_alt_rounded,
                          color: AppColors.inkSoft,
                        )
                      : CustomPaint(painter: _ThumbPainter(id, word)),
                ),
              ),
              if (locked)
                Positioned(
                  top: 2,
                  right: 2,
                  child: lockedFull
                      ? const LockBadge(compact: true)
                      : const Icon(
                          Icons.lock_rounded,
                          size: 16,
                          color: AppColors.coinDeep,
                        ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _BasePainter extends CustomPainter {
  _BasePainter(this.decoration);
  final PhotoDecoration decoration;
  @override
  void paint(Canvas canvas, Size size) => decoration.paintBase(canvas, size);
  @override
  bool shouldRepaint(_BasePainter old) => true;
}

class _StickerPainter extends CustomPainter {
  _StickerPainter(this.id, this.word);
  final String id;
  final String? word;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    PhotoArt.paintSticker(canvas, id, size.shortestSide, word: word);
  }

  @override
  bool shouldRepaint(_StickerPainter old) => old.id != id || old.word != word;
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.id, this.word);
  final String id;
  final String? word;
  @override
  void paint(Canvas canvas, Size size) {
    if (id.startsWith('sticker.')) {
      canvas.translate(size.width / 2, size.height / 2);
      PhotoArt.paintSticker(canvas, id, size.shortestSide * .9, word: word);
    } else if (id.startsWith('frame.')) {
      canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.creamDeep);
      PhotoArt.paintFrame(canvas, size, id);
    } else {
      canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.creamDeep);
      PhotoArt.paintTextSample(canvas, size, id);
    }
  }

  @override
  bool shouldRepaint(_ThumbPainter old) => old.id != id || old.word != word;
}
