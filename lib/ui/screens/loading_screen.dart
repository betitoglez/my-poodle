import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';

/// P01 · Inicio y carga. Ante un error permite reintentar sin borrar datos.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({
    super.key,
    this.error,
    this.onRetry,
    this.allowAdultReset = false,
  });
  final String? error;
  final Future<void> Function()? onRetry;
  final bool allowAdultReset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _Logo(),
                const SizedBox(height: AppSpace.xl),
                if (error == null) ...[
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: AppColors.plum,
                      strokeWidth: 4,
                    ),
                  ),
                  const SizedBox(height: AppSpace.m),
                  const Text('Cargando la partida…', style: AppText.body),
                ] else ...[
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 40,
                    color: AppColors.plum,
                  ),
                  const SizedBox(height: AppSpace.s),
                  Text(
                    error!,
                    style: AppText.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpace.l),
                  if (onRetry != null)
                    AppButton(
                      label: 'Reintentar',
                      icon: Icons.refresh_rounded,
                      onPressed: () => onRetry!(),
                    ),
                  if (allowAdultReset) ...[
                    const SizedBox(height: AppSpace.l),
                    AdultGateButton(
                      label: 'Adulto: mantén pulsado para reiniciar',
                      onUnlocked: () async {
                        final c = AppScope.read(context);
                        if (await showResetDialog(
                          context,
                          'la partida dañada',
                        )) {
                          await c.resetGame();
                        }
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'My Poodle',
      excludeSemantics: true,
      child: Column(
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: const BoxDecoration(
              color: AppColors.plumSoft,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/cards/cushion.jpg',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: AppSpace.m),
          const Text('My Poodle', style: AppText.display),
          const Text('Tu caniche toy', style: AppText.kicker),
        ],
      ),
    );
  }
}
