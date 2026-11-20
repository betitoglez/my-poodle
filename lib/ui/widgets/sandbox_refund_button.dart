import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/localized_widgets.dart';

/// Solo se incluye en la interfaz de una build interna de QA. El puente nativo
/// comprueba además el entorno firmado de la transacción antes de abrir la hoja.
class SandboxRefundButton extends StatefulWidget {
  const SandboxRefundButton({super.key});

  static const enabled = bool.fromEnvironment('POODLE_PURCHASE_QA');
  static const channel = MethodChannel('my_poodle/purchase_qa');

  @override
  State<SandboxRefundButton> createState() => _SandboxRefundButtonState();
}

class _SandboxRefundButtonState extends State<SandboxRefundButton> {
  bool _opening = false;

  Future<void> _request() async {
    if (_opening) return;
    setState(() => _opening = true);
    String? message;
    try {
      final result = await SandboxRefundButton.channel.invokeMethod<String>(
        'requestSandboxRefund',
      );
      if (result == 'submitted') {
        message = 'Solicitud enviada';
      } else if (result != 'cancelled') {
        throw StateError('Unknown refund request result');
      }
    } catch (_) {
      message = 'No se ha podido completar. Inténtalo de nuevo.';
    }
    if (!mounted) return;
    setState(() => _opening = false);
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: LText(message)));
    }
    // Solicitar no equivale a revocar: el derecho solo cambia cuando el
    // flujo verificado de StoreKit entrega la transacción actualizada.
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
    key: const Key('sandbox-refund'),
    onPressed: _opening ? null : _request,
    icon: _opening
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.receipt_long_rounded),
    label: const LText('Reembolso de prueba'),
  );
}
