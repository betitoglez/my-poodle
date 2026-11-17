import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_root.dart';
import '../../app/app_scope.dart';
import '../../domain/pet_name.dart';
import '../../game/pet/pet_painter.dart';
import '../../game/scenes/room_painter.dart';
import '../../game/scenes/stage_game.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';
import '../widgets/scene_view.dart';

/// P02 · Adopción: caniche inicial, nombre, sugerencias y Adoptar.
class AdoptionScreen extends StatefulWidget {
  const AdoptionScreen({super.key});
  @override
  State<AdoptionScreen> createState() => _AdoptionScreenState();
}

class _AdoptionScreenState extends State<AdoptionScreen> {
  final _name = TextEditingController();
  final _focus = FocusNode();
  StageGame? _game;
  int _suggestion = 0;
  String? _error;
  bool _adopting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_game == null) {
      final c = AppScope.read(context);
      _game = StageGame(
        painter: PetPainterScope.of(context),
        look: c.looks.resolve(c.balance.initialAppearance),
        room: RoomKind.nursery,
        reducedMotion: c.reducedMotion,
        floorY: 0.72,
        petScale: 0.66,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _name.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _suggest() {
    _name.text = PetName.suggestions[_suggestion % PetName.suggestions.length];
    _name.selection = TextSelection.collapsed(offset: _name.text.length);
    _suggestion++;
    _game?.pet.react(PetAnim.happy, seconds: 1.2);
  }

  Future<void> _adopt() async {
    if (_adopting) return;
    final v = PetName.validate(_name.text);
    if (v is InvalidName) {
      setState(
        () => _error = switch (v.error) {
          NameError.empty => 'Escribe un nombre para tu caniche.',
          NameError.tooLong => 'Elige un nombre de 1 a 16 caracteres.',
          NameError.invalidCharacters =>
            'El nombre no puede tener saltos de línea.',
        },
      );
      return;
    }
    setState(() => _adopting = true);
    _focus.unfocus();
    final c = AppScope.read(context);
    await commitOrRecover(context, () => c.adopt(_name.text));
    if (mounted) setState(() => _adopting = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = Layout.of(context);
    final count = PetName.graphemeCount(_name.text);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            // Con teclado o en móvil compacto se reduce el escenario decorativo.
            final sceneH = keyboard
                ? box.maxHeight * 0.22
                : box.maxHeight * (l.compact ? 0.36 : 0.46);
            return Column(
              children: [
                SizedBox(
                  height: sceneH,
                  child: SceneView(
                    game: _game!,
                    semanticsLabel:
                        'Cachorro de caniche albaricoque sobre un cojín',
                    onTap: (_) => _game!.pet.react(PetAnim.happy, seconds: 1.2),
                  ),
                ),
                Expanded(
                  child: Panel(
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text('ADOPCIÓN', style: AppText.kicker),
                                const SizedBox(height: 2),
                                const Text(
                                  'Tu caniche toy',
                                  style: AppText.display,
                                ),
                                const SizedBox(height: AppSpace.xs),
                                const Text(
                                  'Elige el nombre que tendrá en casa.',
                                  style: AppText.body,
                                ),
                                const SizedBox(height: AppSpace.m),
                                TextField(
                                  controller: _name,
                                  focusNode: _focus,
                                  maxLines: 1,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.done,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.deny(
                                      RegExp(r'[\u0000-\u001f\u007f  ]'),
                                    ),
                                    LengthLimitingTextInputFormatter(
                                      PetName.maxGraphemes + 4,
                                    ),
                                  ],
                                  onSubmitted: (_) => _adopt(),
                                  style: AppText.subtitle,
                                  decoration: InputDecoration(
                                    labelText: 'Nombre de tu caniche',
                                    errorText: _error,
                                    counterText:
                                        '$count / ${PetName.maxGraphemes}',
                                    prefixIcon: const Icon(Icons.pets_rounded),
                                  ),
                                ),
                                const SizedBox(height: AppSpace.s),
                                Wrap(
                                  spacing: AppSpace.s,
                                  runSpacing: AppSpace.s,
                                  children: [
                                    for (final n in PetName.suggestions)
                                      ActionChip(
                                        avatar: const Icon(
                                          Icons.auto_awesome_rounded,
                                          size: 18,
                                        ),
                                        label: Text(n),
                                        onPressed: () {
                                          _name.text = n;
                                          _game?.pet.react(
                                            PetAnim.happy,
                                            seconds: 1.2,
                                          );
                                        },
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.padded,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Confirmación fija: visible también con el teclado abierto.
                        const SizedBox(height: AppSpace.s),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: 'Sugerir nombre',
                                icon: Icons.lightbulb_rounded,
                                secondary: true,
                                expand: true,
                                onPressed: _suggest,
                              ),
                            ),
                            const SizedBox(width: AppSpace.s),
                            Expanded(
                              child: AppButton(
                                label: _adopting ? 'Adoptando…' : 'Adoptar',
                                icon: Icons.favorite_rounded,
                                expand: true,
                                onPressed: _adopting ? null : _adopt,
                              ),
                            ),
                          ],
                        ),
                        if (!keyboard) ...[
                          const SizedBox(height: AppSpace.s),
                          const Text(
                            'Empiezas con 0 monedas. Tu partida se guarda solo en este dispositivo.',
                            style: AppText.small,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
