import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    MaterialApp(
      title: 'Vestuario 3D',
      theme: buildTheme(),
      debugShowCheckedModeBanner: false,
      home: const _WardrobePreview(),
    ),
  );
}

enum _Look {
  peto('Peto', 'Pañuelo coral y botas de lluvia'),
  vestido('Vestido', 'Lazo y botas de lluvia'),
  impermeable('Impermeable', 'Gorro de punto y gafas de Meshy');

  const _Look(this.label, this.pieces);
  final String label;
  final String pieces;
}

enum _Hair {
  osito('Osito'),
  pompon('Pompón');

  const _Hair(this.label);
  final String label;
}

enum _View {
  front('Frente', 'frente'),
  left('Lado izq.', 'perfil-izquierdo'),
  back('Espalda', 'espalda'),
  right('Lado der.', 'perfil'),
  top('Arriba', 'arriba'),
  run('Carrera', 'carrera'),
  extension('Extensión', 'extension'),
  gather('Recogida', 'recogida');

  const _View(this.label, this.frame);
  final String label;
  final String frame;

  static const orbit = [front, left, back, right];
  static const angles = [front, left, right, top, back];
  static const motion = [run, extension, gather];
}

class _WardrobePreview extends StatefulWidget {
  const _WardrobePreview();

  @override
  State<_WardrobePreview> createState() => _WardrobePreviewState();
}

class _WardrobePreviewState extends State<_WardrobePreview> {
  _Look _look = _Look.impermeable;
  _Hair _hair = _Hair.osito;
  _View _view = _View.front;

  void _rotate(DragEndDetails details) {
    final speed = details.primaryVelocity ?? 0;
    if (speed.abs() < 80) return;
    final index = _View.orbit.indexOf(_view);
    setState(() {
      _view = index < 0
          ? _View.front
          : _View.orbit[(index + (speed < 0 ? 1 : -1)) % _View.orbit.length];
    });
  }

  @override
  Widget build(BuildContext context) {
    final preview =
        'assets/images/wardrobe_preview/'
        '${_hair.name}-${_look.name}-${_view.frame}.webp';
    return Scaffold(
      appBar: AppBar(title: const Text('Vestuario 3D')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                onHorizontalDragEnd: _rotate,
                child: SizedBox(
                  height: constraints.maxWidth.clamp(240.0, 330.0).toDouble(),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.creamDeep,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.ink.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_view != _View.top)
                          Align(
                            alignment: const Alignment(0, 0.60),
                            child: Container(
                              width: constraints.maxWidth * 0.31,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.ink.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        Image.asset(
                          preview,
                          fit: BoxFit.contain,
                          semanticLabel:
                              '${_look.label}, corte ${_hair.label}, ${_view.label}',
                          errorBuilder: (_, _, _) => const Center(
                            child: Text('No se pudo cargar esta vista.'),
                          ),
                        ),
                        Positioned(
                          left: 15,
                          top: 13,
                          child: Text(_view.label, style: AppText.small),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(_look.pieces, style: AppText.subtitle),
            const SizedBox(height: 12),
            _Choices(
              title: 'Conjunto',
              options: _Look.values,
              selected: _look,
              label: (look) => look.label,
              onSelect: (look) => setState(() => _look = look),
            ),
            _Choices(
              title: 'Peinado',
              options: _Hair.values,
              selected: _hair,
              label: (hair) => hair.label,
              onSelect: (hair) => setState(() => _hair = hair),
            ),
            _Choices(
              title: 'Ángulo',
              options: _View.angles,
              selected: _view,
              label: (view) => view.label,
              onSelect: (view) => setState(() => _view = view),
            ),
            _Choices(
              title: 'Movimiento',
              options: _View.motion,
              selected: _view,
              label: (view) => view.label,
              onSelect: (view) => setState(() => _view = view),
            ),
          ],
        ),
      ),
    );
  }
}

class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.title,
    required this.options,
    required this.selected,
    required this.label,
    required this.onSelect,
  });

  final String title;
  final List<T> options;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.small),
        Wrap(
          spacing: 7,
          children: [
            for (final option in options)
              ChoiceChip(
                label: Text(label(option)),
                selected: option == selected,
                onSelected: (_) => onSelect(option),
                showCheckmark: false,
                selectedColor: AppColors.leafSoft,
              ),
          ],
        ),
      ],
    ),
  );
}
