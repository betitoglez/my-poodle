import 'package:my_poodle/l10n/localized_widgets.dart';

import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'theme.dart';
import 'widgets/common.dart';

/// Puerta adulta (docs/UI-UX.md#puerta-adulta): escribir en cifras un número
/// del 21 al 99 mostrado en letras. Protege la compra, «Restaurar compras»,
/// la Zona adulta y los enlaces externos. Solo decide el paso: no emite
/// ninguna intención por sí misma.
class ParentalGate {
  ParentalGate._();

  static const min = 21;
  static const max = 99;
  static const maxFailures = 3;
  static const lockout = Duration(seconds: 30);

  static final _random = Random();

  /// Fuente del número; las pruebas la sustituyen por una fija.
  static int Function() nextNumber = () => min + _random.nextInt(max - min + 1);

  /// Reloj de la espera tras tres fallos; las pruebas lo sustituyen.
  static DateTime Function() now = DateTime.now;

  /// La espera sobrevive a cerrar y reabrir la puerta, para que no se pueda
  /// esquivar saliendo.
  static DateTime? _lockedUntil;
  static int _failures = 0;

  /// Restablece el estado global (pruebas).
  static void reset() {
    _lockedUntil = null;
    _failures = 0;
    nextNumber = () => min + _random.nextInt(max - min + 1);
    now = DateTime.now;
  }

  static const _units = [
    '',
    'uno',
    'dos',
    'tres',
    'cuatro',
    'cinco',
    'seis',
    'siete',
    'ocho',
    'nueve', //
  ];
  static const _twenties = [
    'veinte', 'veintiuno', 'veintidós', 'veintitrés', 'veinticuatro', //
    'veinticinco', 'veintiséis', 'veintisiete', 'veintiocho', 'veintinueve',
  ];
  static const _tens = {
    3: 'treinta', 4: 'cuarenta', 5: 'cincuenta', 6: 'sesenta', //
    7: 'setenta', 8: 'ochenta', 9: 'noventa',
  };

  /// Número del 20 al 99 en letras, en español.
  static String words(int n) {
    assert(n >= 20 && n <= 99);
    if (n < 30) return _twenties[n - 20];
    final t = _tens[n ~/ 10]!;
    final u = n % 10;
    return u == 0 ? t : '$t y ${_units[u]}';
  }

  /// Abre la puerta; true solo si el adulto la supera.
  static Future<bool> show(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _GateDialog(),
    );
    return ok ?? false;
  }
}

class _GateDialog extends StatefulWidget {
  const _GateDialog();
  @override
  State<_GateDialog> createState() => _GateDialogState();
}

class _GateDialogState extends State<_GateDialog> {
  final _text = TextEditingController();
  late int _number = ParentalGate.nextNumber();
  bool _failed = false;
  Timer? _tick;

  int get _waitSeconds {
    final until = ParentalGate._lockedUntil;
    if (until == null) return 0;
    final left = until.difference(ParentalGate.now()).inMilliseconds;
    if (left <= 0) {
      ParentalGate._lockedUntil = null;
      ParentalGate._failures = 0;
      return 0;
    }
    return (left / 1000).ceil();
  }

  @override
  void initState() {
    super.initState();
    if (_waitSeconds > 0) _startTick();
  }

  void _startTick() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_waitSeconds == 0) t.cancel();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    if (_waitSeconds > 0) return;
    if (int.tryParse(_text.text.trim()) == _number) {
      ParentalGate._failures = 0;
      Navigator.of(context).pop(true);
      return;
    }
    ParentalGate._failures++;
    // Otro número, sin revelar la respuesta.
    var next = ParentalGate.nextNumber();
    for (var i = 0; i < 5 && next == _number; i++) {
      next = ParentalGate.nextNumber();
    }
    setState(() {
      _failed = true;
      _number = next;
      _text.clear();
      if (ParentalGate._failures >= ParentalGate.maxFailures) {
        ParentalGate._lockedUntil = ParentalGate.now().add(
          ParentalGate.lockout,
        );
        _startTick();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wait = _waitSeconds;
    return AlertDialog(
      // Pantallas pequeñas y teclado abierto: el contenido se desplaza.
      scrollable: true,
      title: const LText('Pregunta para personas adultas'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wait > 0)
            LText(
              'Demasiados intentos. Espera $wait s para volver a intentarlo.',
              style: AppText.body,
            )
          else ...[
            LText(
              'Escribe en cifras: ${AppStrings.of(context).numberWords(_number)}',
              style: AppText.subtitle,
            ),
            const SizedBox(height: AppSpace.m),
            TextField(
              key: const Key('parental-gate-field'),
              controller: _text,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: localizeNullable(context, 'Número'),
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (_failed) ...[
              const SizedBox(height: AppSpace.s),
              const LText(
                'No es correcto. Prueba con este otro número.',
                style: AppText.small,
              ),
            ],
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const LText('Cancelar'),
        ),
        TextButton(
          onPressed: wait > 0 ? null : _submit,
          child: const LText('Continuar'),
        ),
      ],
    );
  }
}

/// Botón sobrio que abre la puerta adulta y, si se supera, ejecuta
/// [onUnlocked]. Sustituye a la pulsación mantenida de 2 s.
class AdultGateButton extends StatelessWidget {
  const AdultGateButton({
    super.key,
    required this.onUnlocked,
    this.label = 'Acceso para personas adultas',
  });
  final VoidCallback onUnlocked;
  final String label;

  @override
  Widget build(BuildContext context) => AppButton(
    label: label,
    icon: Icons.lock_rounded,
    secondary: true,
    expand: true,
    onPressed: () async {
      if (await ParentalGate.show(context)) onUnlocked();
    },
  );
}
