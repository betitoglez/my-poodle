import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../domain/appearance.dart';
import '../navigation.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';

class _Page extends StatelessWidget {
  const _Page({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final l = Layout.of(context);
    final c = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
              padding: EdgeInsets.fromLTRB(
                l.gutter,
                AppSpace.s,
                l.gutter,
                AppSpace.xl,
              ),
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, {required this.children, this.icon});
  final String title;
  final IconData? icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.l),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadii.m),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.plum),
                  const SizedBox(width: AppSpace.s),
                ],
                Expanded(child: Text(title, style: AppText.subtitle)),
              ],
            ),
            const SizedBox(height: AppSpace.s),
            ...children,
          ],
        ),
      ),
    ),
  );
}

/// P16 · Ajustes: música, efectos, movimiento reducido, ayuda y acceso adulto.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final p = c.prefs;
    return _Page(
      title: 'Ajustes',
      children: [
        _Section(
          'Sonido y movimiento',
          icon: Icons.tune_rounded,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.music_note_rounded),
              title: const Text('Música'),
              subtitle: const Text('Pendiente de audio final'),
              value: p.music,
              onChanged: c.saving
                  ? null
                  : (v) => commitOrRecover(
                      context,
                      () => c.updatePrefs(p.copyWith(music: v)),
                    ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.volume_up_rounded),
              title: const Text('Efectos'),
              subtitle: const Text('Respuesta táctil y sonidos de acción'),
              value: p.effects,
              onChanged: c.saving
                  ? null
                  : (v) => commitOrRecover(
                      context,
                      () => c.updatePrefs(p.copyWith(effects: v)),
                    ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.motion_photos_off_rounded),
              title: const Text('Movimiento reducido'),
              subtitle: const Text(
                'Animaciones más cortas y cámara sin desplazamientos',
              ),
              value: p.reducedMotion,
              onChanged: c.saving
                  ? null
                  : (v) => commitOrRecover(
                      context,
                      () => c.updatePrefs(p.copyWith(reducedMotion: v)),
                    ),
            ),
          ],
        ),
        _Section(
          'Ayuda',
          icon: Icons.help_rounded,
          children: [
            AppButton(
              label: 'Cómo se juega y créditos',
              icon: Icons.menu_book_rounded,
              secondary: true,
              expand: true,
              onPressed: () => pushScreen(context, const HelpScreen()),
            ),
            const SizedBox(height: AppSpace.s),
            TextButton(
              onPressed: () => c.updatePrefs(p.copyWith(seenHints: {})),
              child: const Text('Volver a mostrar las ayudas iniciales'),
            ),
          ],
        ),
        _Section(
          'Para personas adultas',
          icon: Icons.lock_rounded,
          children: [
            const Text(
              'Partida, privacidad, publicidad y reinicio.',
              style: AppText.body,
            ),
            const SizedBox(height: AppSpace.m),
            AdultGateButton(
              onUnlocked: () => pushScreen(context, const AdultZoneScreen()),
            ),
          ],
        ),
      ],
    );
  }
}

/// P17 · Zona adulta.
class AdultZoneScreen extends StatelessWidget {
  const AdultZoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    return _Page(
      title: 'Zona adulta',
      children: [
        _Section(
          'Guardado en este dispositivo',
          icon: Icons.phone_iphone_rounded,
          children: [
            Text(
              'La partida de ${c.state?.name ?? 'tu caniche'} (nombre, monedas, armario y ajustes) se guarda solo en esta instalación, '
              'sin cuentas, servidores ni copias en la nube. Si desinstalas la app o cambias de teléfono, la partida '
              'no se transfiere y el nuevo dispositivo empieza por la adopción.',
              style: AppText.body,
            ),
          ],
        ),
        _Section(
          'Publicidad',
          icon: Icons.campaign_rounded,
          children: [
            Text(
              'Este prototipo no muestra anuncios ni incluye SDK publicitarios (${AppScope.adsOf(context).provider.name}). '
              'Una futura versión podría reservar un banner en Casa, siempre separado de los controles y sin afectar a '
              'premios ni partida. Las compras con dinero real no existen.',
              style: AppText.body,
            ),
          ],
        ),
        _Section(
          'Privacidad',
          icon: Icons.privacy_tip_rounded,
          children: [
            const Text(
              'No se recogen datos personales ni analítica externa.',
              style: AppText.body,
            ),
            const SizedBox(height: AppSpace.s),
            AppButton(
              label: 'Leer privacidad',
              icon: Icons.article_rounded,
              secondary: true,
              expand: true,
              onPressed: () => pushScreen(context, const PrivacyScreen()),
            ),
          ],
        ),
        _Section(
          'Modo demostración',
          icon: Icons.science_rounded,
          children: [
            const Text(
              'Revisa necesidades bajas, saldo, banner y combinaciones con una partida de muestra en memoria. '
              'La partida normal no se modifica y vuelve al salir.',
              style: AppText.body,
            ),
            const SizedBox(height: AppSpace.s),
            AppButton(
              label: c.demo
                  ? 'Herramientas de demostración'
                  : 'Entrar en modo demostración',
              icon: Icons.science_rounded,
              secondary: true,
              expand: true,
              onPressed: () {
                if (!c.demo) c.enterDemo();
                pushScreen(context, const DemoScreen());
              },
            ),
          ],
        ),
        _Section(
          'Reiniciar partida',
          icon: Icons.restart_alt_rounded,
          children: [
            const Text(
              'Borra la partida de este dispositivo y vuelve a la adopción.',
              style: AppText.body,
            ),
            const SizedBox(height: AppSpace.s),
            AppButton(
              label: 'Reiniciar partida…',
              icon: Icons.delete_forever_rounded,
              secondary: true,
              expand: true,
              onPressed: () async {
                if (c.demo) c.exitDemo();
                final name = AppScope.read(context).state?.name ?? 'tu caniche';
                if (await showResetDialog(context, name) && context.mounted) {
                  await AppScope.read(context).resetGame();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  }
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// P18 · Privacidad: vista de lectura preparada para los textos definitivos.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Privacidad',
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpace.m),
          decoration: BoxDecoration(
            color: AppColors.plumSoft,
            borderRadius: BorderRadius.circular(AppRadii.s),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.plum),
              SizedBox(width: AppSpace.s),
              Expanded(
                child: Text(
                  'TEXTO PROVISIONAL. No es una política legal. Debe sustituirse por el texto definitivo '
                  'revisado antes de publicar.',
                  style: AppText.subtitle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.l),
        const _Section(
          'Qué guarda el juego',
          children: [
            Text(
              'Nombre del caniche, necesidades, monedas, artículos del armario, récords y ajustes, '
              'únicamente en el almacenamiento privado de este dispositivo.',
              style: AppText.body,
            ),
          ],
        ),
        const _Section(
          'Qué no hace',
          children: [
            Text(
              'No hay cuentas, servidores, sincronización, analítica externa, publicidad real ni compras con dinero.',
              style: AppText.body,
            ),
          ],
        ),
        const _Section(
          'Pendiente para publicación',
          children: [
            Text(
              'Responsable, contacto, base legal, proveedores (si se integra publicidad) y adaptación a '
              'las normas de apps infantiles de cada tienda.',
              style: AppText.body,
            ),
          ],
        ),
      ],
    );
  }
}

/// P19 · Ayuda y créditos.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const _Page(
      title: 'Ayuda y créditos',
      children: [
        _Section(
          'Cuidados',
          icon: Icons.volunteer_activism_rounded,
          children: [
            Text(
              'Comer, bañar, pasear, cepillar y dormir mejoran sus indicadores. Puedes hacerlos aunque estén llenos. '
              'Si sales antes de terminar, no se aplica la mejora. Los iconos de arriba se encienden cuando tiene '
              'hambre, está sucio, triste, cansado o malito: tócalos para atenderle.',
              style: AppText.body,
            ),
          ],
        ),
        _Section(
          'Salud',
          icon: Icons.medical_services_rounded,
          children: [
            Text(
              'Si pasa hambre, mucho cansancio o suciedad —o a veces sin motivo— puede ponerse malito, pero como mucho '
              'una vez por semana y nunca es grave. El veterinario le da una pastilla y se pone bueno enseguida.',
              style: AppText.body,
            ),
          ],
        ),
        _Section(
          'Juegos',
          icon: Icons.sports_esports_rounded,
          children: [
            Text(
              'En el Huerto saltarín tocas para saltar y recoges manzanas. En el Frisbee arrastras hacia arriba '
              'para lanzar. Al terminar una partida ganas monedas.',
              style: AppText.body,
            ),
          ],
        ),
        _Section(
          'Armario',
          icon: Icons.checkroom_rounded,
          children: [
            Text(
              'Prueba colores, peinados, ropa y accesorios gratis. Solo pagas al confirmar. Lo que compras es tuyo '
              'para siempre y puedes quitártelo y ponértelo sin volver a pagar.',
              style: AppText.body,
            ),
          ],
        ),
        _Section(
          'Créditos',
          icon: Icons.favorite_rounded,
          children: [
            Text(
              'My Poodle · prototipo Flutter + Flame.\n'
              'Ilustraciones de referencia de escenas y fondos: material del propietario del proyecto (docs/arte).\n'
              'Caniche, salas y efectos: dibujo vectorial provisional generado por código.\n'
              'Tipografía: fuentes del sistema (pendiente empaquetar Young Serif y Nunito con licencia OFL).\n'
              'Audio: pendiente (música Mureka y efectos ElevenLabs según el plan).',
              style: AppText.body,
            ),
            SizedBox(height: AppSpace.s),
            Text(
              'No hay enlaces externos en esta versión. Si se añaden, pasarán por la zona adulta.',
              style: AppText.small,
            ),
          ],
        ),
      ],
    );
  }
}

/// Herramientas del modo demostración (solo afectan a la partida de muestra).
class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    if (!c.demo) {
      return const _Page(
        title: 'Demostración',
        children: [Text('El modo demostración no está activo.')],
      );
    }
    final b = c.balance;
    Widget combo(String label, Appearance a) => OutlinedButton(
      onPressed: () => c.demoAppearance(a),
      child: Text(label),
    );
    final base = b.initialAppearance;
    return _Page(
      title: 'Demostración',
      children: [
        _Section(
          'Partida de muestra',
          icon: Icons.science_rounded,
          children: [
            Text(
              'Saldo actual: ${c.state?.coins ?? 0} monedas. Nada de esto se guarda en la partida normal.',
              style: AppText.body,
            ),
          ],
        ),
        _Section(
          'Necesidades',
          children: [
            Wrap(
              spacing: AppSpace.s,
              runSpacing: AppSpace.s,
              children: [
                OutlinedButton(
                  onPressed: c.demoLowNeeds,
                  child: const Text('Necesidades bajas'),
                ),
                OutlinedButton(
                  onPressed: c.demoFullNeeds,
                  child: const Text('Necesidades llenas'),
                ),
              ],
            ),
          ],
        ),
        _Section(
          'Salud',
          children: [
            Wrap(
              spacing: AppSpace.s,
              runSpacing: AppSpace.s,
              children: [
                OutlinedButton(
                  onPressed: () => c.demoSetSick(true),
                  child: const Text('Ponerlo malito'),
                ),
                OutlinedButton(
                  onPressed: () => c.demoSetSick(false),
                  child: const Text('Curarlo'),
                ),
              ],
            ),
          ],
        ),
        _Section(
          'Monedas',
          children: [
            Wrap(
              spacing: AppSpace.s,
              runSpacing: AppSpace.s,
              children: [
                for (final n in [0, 9, 10, 12, 100])
                  OutlinedButton(
                    onPressed: () => c.demoSetCoins(n),
                    child: Text('$n monedas'),
                  ),
              ],
            ),
          ],
        ),
        _Section(
          'Aspecto (combinaciones)',
          children: [
            Wrap(
              spacing: AppSpace.s,
              runSpacing: AppSpace.s,
              children: [
                combo('Base', base),
                combo(
                  'Plata + pompón',
                  base
                      .withSlot(Slot.coat, 'coat.silver')
                      .withSlot(Slot.hair, 'hair.pom'),
                ),
                combo(
                  'Peto + pañuelo',
                  base
                      .withSlot(Slot.outfit, 'outfit.teal')
                      .withSlot(Slot.neck, 'neck.coral'),
                ),
                combo(
                  'Todo',
                  base
                      .withSlot(Slot.coat, 'coat.silver')
                      .withSlot(Slot.hair, 'hair.pom')
                      .withSlot(Slot.outfit, 'outfit.teal')
                      .withSlot(Slot.neck, 'neck.coral'),
                ),
                combo(
                  'Blanco + osito + jersey',
                  base
                      .withSlot(Slot.coat, 'coat.white')
                      .withSlot(Slot.hair, 'hair.teddy')
                      .withSlot(Slot.outfit, 'outfit.sweater_blue')
                      .withSlot(Slot.eyes, 'eyes.sun'),
                ),
                combo(
                  'Negro + vestido + corona',
                  base
                      .withSlot(Slot.coat, 'coat.black')
                      .withSlot(Slot.outfit, 'outfit.dress_pink')
                      .withSlot(Slot.head, 'head.crown')
                      .withSlot(Slot.collar, 'collar.pearls')
                      .withSlot(Slot.paws, 'paws.booties'),
                ),
              ],
            ),
          ],
        ),
        _Section(
          'Casa',
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mostrar espacio de banner en Casa'),
              value: c.bannerPreview,
              onChanged: (_) => c.demoToggleBanner(),
            ),
          ],
        ),
        AppButton(
          label: 'Salir del modo demostración',
          icon: Icons.logout_rounded,
          expand: true,
          onPressed: () {
            c.exitDemo();
            Navigator.of(context).popUntil((r) => r.isFirst);
          },
        ),
      ],
    );
  }
}
