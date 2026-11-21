import 'package:my_poodle/l10n/localized_widgets.dart';

import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../app/feedback.dart';
import '../../domain/rules.dart';
import '../ask_adult_view.dart';
import '../theme.dart';
import 'common.dart';

void showCareBlocked(BuildContext context, CareKind kind, String reason) {
  AppScope.feedbackOf(context).play(Sfx.blocked);
  final controller = AppScope.read(context);
  final vetPrice =
      kind == CareKind.vet &&
      controller.pet.coins < Rules.vetCost &&
      reason.startsWith('Necesitas');
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: vetPrice
          ? Row(
              children: [
                const CoinIcon(size: 18),
                const SizedBox(width: 8),
                Expanded(child: LText(reason)),
              ],
            )
          : LText(reason),
    ),
  );
}

class _DialogFrame extends StatelessWidget {
  const _DialogFrame({
    required this.icon,
    required this.title,
    required this.body,
    required this.actions,
  });
  final IconData icon;
  final String title;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpace.l),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(icon, size: 40, color: AppColors.plum),
              const SizedBox(height: AppSpace.s),
              LText(title, style: AppText.title, textAlign: TextAlign.center),
              const SizedBox(height: AppSpace.m),
              DefaultTextStyle(
                style: AppText.body,
                textAlign: TextAlign.center,
                child: body,
              ),
              const SizedBox(height: AppSpace.xl),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpace.s,
                runSpacing: AppSpace.s,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pausa: el juego queda detenido hasta pulsar Continuar.
Future<bool> showPauseDialog(BuildContext context, {bool game = true}) async {
  final r = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (c) => PopScope(
      canPop: false,
      child: _DialogFrame(
        icon: Icons.pause_circle_filled_rounded,
        title: 'En pausa',
        body: LText(
          game
              ? 'El tiempo está detenido. Si sales, se abandona la partida sin premio.'
              : 'Todo está detenido. Si sales, se abandona la actividad sin aplicar su mejora.',
        ),
        actions: [
          AppButton(
            label: 'Salir',
            icon: Icons.logout_rounded,
            secondary: true,
            onPressed: () => Navigator.pop(c, false),
          ),
          AppButton(
            label: 'Continuar',
            icon: Icons.play_arrow_rounded,
            onPressed: () => Navigator.pop(c, true),
          ),
        ],
      ),
    ),
  );
  return r ?? true;
}

/// Salir de una actividad con progreso pendiente. Devuelve true si sale.
Future<bool> showExitActivityDialog(
  BuildContext context, {
  required String activity,
  bool game = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => _DialogFrame(
      icon: Icons.directions_walk_rounded,
      title: '¿Salir de $activity?',
      body: LText(
        game
            ? 'Si sales ahora se abandona esta partida y no se ganan monedas.'
            : 'Si sales ahora se abandona esta actividad y no se aplica su mejora.',
      ),
      actions: [
        AppButton(
          label: 'Salir',
          icon: Icons.logout_rounded,
          secondary: true,
          onPressed: () => Navigator.pop(c, true),
        ),
        AppButton(
          label: game ? 'Seguir jugando' : 'Seguir',
          icon: Icons.play_arrow_rounded,
          onPressed: () => Navigator.pop(c, false),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Comprar y usar: artículos, precio, saldo actual y restante.
Future<bool> showPurchaseDialog(
  BuildContext context, {
  required List<String> items,
  required int price,
  required int balance,
  String title = 'Comprar y usar',
  String confirmLabel = 'Confirmar',
  String? note,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => _DialogFrame(
      icon: Icons.shopping_bag_rounded,
      title: title,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LText(
            items.map((item) => localize(c, item)).join(' · '),
            verbatim: true,
            style: AppText.subtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpace.m),
          _row('Precio', price),
          _row('Saldo actual', balance),
          const Divider(),
          _row('Saldo restante', balance - price, bold: true),
          if (note != null) ...[
            const SizedBox(height: AppSpace.s),
            LText(note, textAlign: TextAlign.center),
          ],
        ],
      ),
      actions: [
        AppButton(
          label: 'Cancelar',
          icon: Icons.close_rounded,
          secondary: true,
          onPressed: () => Navigator.pop(c, false),
        ),
        AppButton(
          label: confirmLabel,
          icon: Icons.check_rounded,
          onPressed: () => Navigator.pop(c, true),
        ),
      ],
    ),
  );
  return r ?? false;
}

Widget _row(String label, int value, {bool bold = false}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 3),
  child: Row(
    children: [
      Expanded(
        child: LText(
          label,
          style: bold ? AppText.subtitle : AppText.body,
          textAlign: TextAlign.left,
        ),
      ),
      const CoinIcon(size: 18),
      const SizedBox(width: 6),
      LText('$value', style: AppText.number),
    ],
  ),
);

enum InsufficientChoice { games, cancel }

/// Monedas insuficientes: diferencia exacta y acceso a Juegos.
Future<InsufficientChoice> showInsufficientDialog(
  BuildContext context, {
  required int missing,
  required int price,
}) async {
  AppScope.feedbackOf(context).play(Sfx.blocked);
  final r = await showDialog<InsufficientChoice>(
    context: context,
    builder: (c) => _DialogFrame(
      icon: Icons.savings_rounded,
      title: 'Faltan $missing ${missing == 1 ? 'moneda' : 'monedas'}',
      body: LText(
        'Cuesta $price. Juega en el huerto o en el prado para conseguir las que faltan.',
      ),
      actions: [
        AppButton(
          label: 'Ahora no',
          icon: Icons.close_rounded,
          secondary: true,
          onPressed: () => Navigator.pop(c, InsufficientChoice.cancel),
        ),
        AppButton(
          label: 'Ir a Juegos',
          icon: Icons.sports_esports_rounded,
          onPressed: () => Navigator.pop(c, InsufficientChoice.games),
        ),
      ],
    ),
  );
  return r ?? InsufficientChoice.cancel;
}

enum PreviewChoice { apply, discard, stay }

/// Salir de una prueba de aspecto: aplicar o descartar.
Future<PreviewChoice> showLeavePreviewDialog(
  BuildContext context, {
  required int cost,
}) async {
  final r = await showDialog<PreviewChoice>(
    context: context,
    builder: (c) => _DialogFrame(
      icon: Icons.checkroom_rounded,
      title: '¿Te quedas con este aspecto?',
      body: LText(
        cost > 0
            ? 'Aplicarlo cuesta $cost monedas. Si lo descartas, vuelve el aspecto anterior.'
            : 'Puedes aplicarlo gratis o descartarlo y volver al aspecto anterior.',
      ),
      actions: [
        AppButton(
          label: 'Descartar',
          icon: Icons.undo_rounded,
          secondary: true,
          onPressed: () => Navigator.pop(c, PreviewChoice.discard),
        ),
        AppButton(
          label: 'Aplicar',
          icon: Icons.check_rounded,
          onPressed: () => Navigator.pop(c, PreviewChoice.apply),
        ),
      ],
    ),
  );
  return r ?? PreviewChoice.stay;
}

/// Reinicio: confirmación explícita antes de eliminar la partida.
Future<bool> showResetDialog(BuildContext context, String petName) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => _DialogFrame(
      icon: Icons.warning_amber_rounded,
      title: '¿Borrar la partida?',
      body: LText(
        'Se eliminarán $petName, sus monedas, su armario y los ajustes de este dispositivo. '
        'No se puede deshacer.',
      ),
      actions: [
        AppButton(
          label: 'Cancelar',
          icon: Icons.close_rounded,
          onPressed: () => Navigator.pop(c, false),
        ),
        AppButton(
          label: 'Borrar partida',
          icon: Icons.delete_forever_rounded,
          secondary: true,
          onPressed: () => Navigator.pop(c, true),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Error al guardar: el estado pendiente se conserva y se puede reintentar.
/// Devuelve true si finalmente se guardó.
Future<bool> resolveSaveFailure(BuildContext context) async {
  final controller = AppScope.read(context);
  while (controller.hasPending) {
    if (!context.mounted) return false;
    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => PopScope(
        canPop: false,
        child: _DialogFrame(
          icon: Icons.sd_card_alert_rounded,
          title: 'No se ha podido guardar',
          body: const LText(
            'El progreso sigue pendiente en este dispositivo. Puedes intentarlo otra vez.',
          ),
          actions: [
            AppButton(
              label: 'Volver',
              icon: Icons.undo_rounded,
              secondary: true,
              onPressed: () => Navigator.pop(c, false),
            ),
            AppButton(
              label: 'Reintentar',
              icon: Icons.refresh_rounded,
              onPressed: () => Navigator.pop(c, true),
            ),
          ],
        ),
      ),
    );
    if (retry == true) {
      if (await controller.retryPending()) return true;
    } else {
      await controller.discardPending();
      return false;
    }
  }
  return true;
}

/// Recupera una escritura de estado sin volver a ejecutar la intención.
Future<bool> saveOrRecover<T>(
  BuildContext context,
  Future<ActionResult<T>> Function() action,
) async => switch (await action()) {
  Done() => true,
  Ignored() => false,
  SaveFailed() => context.mounted && await resolveSaveFailure(context),
};

/// Ejecuta una intención que guarda y resuelve un posible fallo de guardado.
Future<T?> commitOrRecover<T>(
  BuildContext context,
  Future<ActionResult<T>> Function() action,
) async {
  final r = await action();
  switch (r) {
    case Done(:final value):
      return value;
    case Ignored():
      return null;
    case SaveFailed():
      if (!context.mounted) return null;
      final ok = await resolveSaveFailure(context);
      if (!ok || !context.mounted) return null;
      // Tras guardar, la misma intención devuelve el recibo ya confirmado.
      final again = await action();
      return again is Done<T> ? again.value : null;
  }
}

/// Ayuda inicial: un único gesto, fácil de cerrar.
class HintBubble extends StatelessWidget {
  const HintBubble({
    super.key,
    required this.text,
    required this.icon,
    required this.onClose,
  });
  final String text;
  final IconData icon;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(AppRadii.m),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.m,
          AppSpace.xs,
          AppSpace.xs,
          AppSpace.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.coin),
            const SizedBox(width: AppSpace.s),
            Flexible(
              child: LText(
                text,
                style: AppText.body.copyWith(color: AppColors.cream),
              ),
            ),
            IconButton(
              tooltip: localizeNullable(context, 'Cerrar ayuda'),
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, color: AppColors.cream),
            ),
          ],
        ),
      ),
    );
  }
}

/// Retraso cancelable para pasos de animación en widgets.
class Delay {
  Timer? _t;
  void run(Duration d, VoidCallback f) {
    _t?.cancel();
    _t = Timer(d, f);
  }

  void cancel() => _t?.cancel();
}

void showGameBlocked(BuildContext context, String reason) {
  final c = AppScope.read(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: LText(reason),
      action: !c.fullVersion && c.gameWaitSeconds > 0
          ? SnackBarAction(
              label: localize(context, 'Versión completa'),
              onPressed: () => showAskAdult(context),
            )
          : null,
    ),
  );
}

String countdown(int seconds) =>
    '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
