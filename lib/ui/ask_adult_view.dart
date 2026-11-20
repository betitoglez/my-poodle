import 'package:my_poodle/l10n/localized_widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../app/app_scope.dart';
import 'full_version_view.dart';
import 'navigation.dart';
import 'parental_gate.dart';
import 'screens/wardrobe_screen.dart' show PetThumb;
import 'theme.dart';
import 'widgets/common.dart';

/// Se abre solo al tocar un candado. Volver deja todo como estaba (también
/// la vista previa del armario); «Soy un adulto» pasa por la puerta adulta.
Future<void> showAskAdult(BuildContext context) =>
    pushScreen<void>(context, const AskAdultScreen());

class AskAdultScreen extends StatelessWidget {
  const AskAdultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final l = Layout.of(context);
    return Scaffold(
      appBar: AppBar(title: const LText('Versión completa')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: l.maxContentWidth),
            child: ListView(
              padding: EdgeInsets.all(l.gutter),
              children: [
                SizedBox(
                  height: 220,
                  child: Stack(
                    children: [
                      if (c.state != null)
                        Positioned.fill(child: PetThumb(look: c.look)),
                      const Positioned(
                        right: 24,
                        top: 12,
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.plumSoft,
                          child: Icon(
                            Icons.lock_rounded,
                            size: 34,
                            color: AppColors.plum,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.l),
                const LText(
                  'Esto es de la versión completa. Pide ayuda a un adulto',
                  style: AppText.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpace.xl),
                AppButton(
                  label: 'Soy un adulto',
                  icon: Icons.person_rounded,
                  secondary: true,
                  expand: true,
                  onPressed: () async {
                    if (await ParentalGate.show(context) && context.mounted) {
                      await replaceScreen<void>(
                        context,
                        const FullVersionScreen(),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSpace.m),
                AppButton(
                  label: 'Volver',
                  icon: Icons.arrow_back_rounded,
                  big: true,
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
