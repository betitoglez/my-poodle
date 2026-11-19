import 'package:my_poodle/l10n/localized_widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../app/app_scope.dart';
import '../store/store_controller.dart';
import 'navigation.dart';
import 'screens/settings_screens.dart' show PrivacyScreen;
import 'theme.dart';
import 'widgets/common.dart';

/// Pantalla «Versión completa». Solo se llega tras la puerta adulta (desde un
/// candado o desde la Zona adulta). Emite intenciones al StoreController y
/// representa su estado; el precio es siempre el texto de la tienda.
class FullVersionScreen extends StatefulWidget {
  const FullVersionScreen({super.key});

  @override
  State<FullVersionScreen> createState() => _FullVersionScreenState();
}

class _FullVersionScreenState extends State<FullVersionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = AppScope.read(context).purchases;
      p.clearNotice();
      if (p.productStatus == ProductStatus.unavailable) p.loadProduct();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final p = c.purchases;
    final l = Layout.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const LText('Versión completa'),
        actions: [
          if (c.demo)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: DemoBadge(),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: l.maxContentWidth),
            child: ListView(
              padding: EdgeInsets.all(l.gutter),
              children: [
                const _Includes(),
                const SizedBox(height: AppSpace.l),
                _Status(p: p, demo: c.demo),
                const SizedBox(height: AppSpace.l),
                TextButton.icon(
                  key: const Key('restore'),
                  onPressed: p.flow == PurchaseFlow.idle ? p.restore : null,
                  icon: const Icon(Icons.restore_rounded),
                  label: const LText('Restaurar compras'),
                ),
                TextButton.icon(
                  onPressed: () => pushScreen(context, const PrivacyScreen()),
                  icon: const Icon(Icons.privacy_tip_rounded),
                  label: const LText('Privacidad'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Includes extends StatelessWidget {
  const _Includes();

  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s),
      child: Row(
        children: [
          Icon(icon, color: AppColors.plum),
          const SizedBox(width: AppSpace.s),
          Expanded(child: LText(text, style: AppText.body)),
        ],
      ),
    );
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadii.m),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LText('Incluye', style: AppText.subtitle),
            const SizedBox(height: AppSpace.s),
            row(Icons.sports_esports_rounded, 'El Huerto saltarín'),
            row(
              Icons.checkroom_rounded,
              '24 artículos más del armario: colores, peinados, jerséis, '
              'impermeables, vestidos y accesorios',
            ),
            row(
              Icons.auto_awesome_rounded,
              'Las novedades futuras, sin volver a pagar',
            ),
            const SizedBox(height: AppSpace.s),
            const LText(
              'Pago único. Sin anuncios. Las monedas se ganan jugando',
              style: AppText.subtitle,
            ),
          ],
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.p, required this.demo});
  final StoreController p;
  final bool demo;

  @override
  Widget build(BuildContext context) {
    Widget message(IconData icon, String text) => Row(
      children: [
        Icon(icon, color: AppColors.plum),
        const SizedBox(width: AppSpace.s),
        Expanded(child: LText(text, style: AppText.body)),
      ],
    );
    Widget busy(String text) => Row(
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(width: AppSpace.m),
        Expanded(child: LText(text, style: AppText.body)),
      ],
    );

    if (p.flow == PurchaseFlow.restoring) return busy('Restaurando compras…');
    if (p.full) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (p.notice == StoreNotice.error) ...[
            message(
              Icons.info_outline_rounded,
              'No se ha podido restaurar. Inténtalo de nuevo.',
            ),
            const SizedBox(height: AppSpace.m),
          ],
          message(
            Icons.favorite_rounded,
            '¡Gracias! Ya tienes la versión completa',
          ),
          const SizedBox(height: AppSpace.l),
          AppButton(
            label: 'Volver',
            icon: Icons.arrow_back_rounded,
            big: true,
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }
    if (p.flow == PurchaseFlow.buying) return busy('Comprando…');
    if (p.pending) {
      return message(
        Icons.hourglass_top_rounded,
        'Esperando la aprobación. Se desbloqueará cuando la tienda confirme el pago.',
      );
    }

    final notice = switch (p.notice) {
      StoreNotice.error => 'No se ha podido completar. Inténtalo de nuevo.',
      StoreNotice.canceled => 'Compra cancelada. No se ha cobrado nada.',
      StoreNotice.nothingToRestore =>
        'No hay compras anteriores que restaurar en esta cuenta.',
      _ => null,
    };
    final available = demo || p.productStatus == ProductStatus.available;
    final price = p.product?.price ?? (demo ? '1,99 € (simulado)' : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (notice != null) ...[
          message(Icons.info_outline_rounded, notice),
          const SizedBox(height: AppSpace.m),
        ],
        if (!available && p.productStatus == ProductStatus.loading)
          busy('Cargando…')
        else if (!available) ...[
          message(
            Icons.wifi_off_rounded,
            'No disponible ahora. Inténtalo con conexión',
          ),
          const SizedBox(height: AppSpace.m),
          AppButton(
            label: 'Reintentar',
            icon: Icons.refresh_rounded,
            secondary: true,
            expand: true,
            onPressed: p.loadProduct,
          ),
        ] else
          AppButton(
            label: p.notice == StoreNotice.error
                ? 'Reintentar'
                : 'Desbloquear por ${price ?? ''}'.trim(),
            icon: Icons.lock_open_rounded,
            big: true,
            expand: true,
            onPressed: p.buy,
          ),
      ],
    );
  }
}
