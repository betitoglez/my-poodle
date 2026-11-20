import 'package:my_poodle/l10n/localized_widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../app/feedback.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import 'care_screen.dart';
import 'games_screen.dart';
import 'home_screen.dart';
import 'wardrobe_screen.dart';

/// Navegación principal: Casa, Cuidados, Juegos y Armario. Solo la pestaña
/// activa existe, de modo que hay una única escena Flame en ejecución.
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ShellScope.maybeOf(context)?.force(ShellTab.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.maybeOf(context)!;
    return ListenableBuilder(
      listenable: shell,
      builder: (context, _) {
        final tab = shell.tab;
        return Scaffold(
          body: _TabFadeIn(
            key: ValueKey(tab),
            reducedMotion: navigationReducedMotion(context),
            child: switch (tab) {
              ShellTab.home => const HomeScreen(),
              ShellTab.care => const CareScreen(),
              ShellTab.games => const GamesScreen(),
              ShellTab.wardrobe => const WardrobeScreen(),
            },
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NavigationBar(
                selectedIndex: tab.index,
                onDestinationSelected: (i) {
                  if (i != tab.index) {
                    AppScope.feedbackOf(context).play(Sfx.tap, haptic: false);
                    shell.go(ShellTab.values[i]);
                  }
                },
                destinations: const [
                  LNavigationDestination(
                    icon: Icon(Icons.home_rounded),
                    label: 'Casa',
                  ),
                  LNavigationDestination(
                    icon: Icon(Icons.volunteer_activism_rounded),
                    label: 'Cuidados',
                  ),
                  LNavigationDestination(
                    icon: Icon(Icons.sports_esports_rounded),
                    label: 'Juegos',
                  ),
                  LNavigationDestination(
                    icon: Icon(Icons.checkroom_rounded),
                    label: 'Armario',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Fundido de entrada de la pestaña nueva (~180 ms). Deliberadamente no es un
/// fundido cruzado (`AnimatedSwitcher`): la pestaña anterior se desmonta en el
/// mismo fotograma, como antes, para que nunca convivan dos escenas Flame ni
/// dos vistas nativas del caniche. No guarda estado propio: cada pestaña se
/// construye al entrar, igual que sin animación, y `leaveGuard` sigue
/// resolviéndose en [ShellController.go] antes de cambiar. Con movimiento
/// reducido la pestaña aparece sin animación.
class _TabFadeIn extends StatefulWidget {
  const _TabFadeIn({
    super.key,
    required this.reducedMotion,
    required this.child,
  });
  final bool reducedMotion;
  final Widget child;

  static const duration = Duration(milliseconds: 180);

  @override
  State<_TabFadeIn> createState() => _TabFadeInState();
}

class _TabFadeInState extends State<_TabFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _TabFadeIn.duration,
    value: widget.reducedMotion ? 1 : 0,
  );

  late final _opacity = CurvedAnimation(parent: _c, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    if (!widget.reducedMotion) _c.forward();
  }

  @override
  void didUpdateWidget(_TabFadeIn old) {
    super.didUpdateWidget(old);
    if (widget.reducedMotion) _c.value = 1;
  }

  @override
  void dispose() {
    _opacity.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}

/// Cabecera común de pestaña: título, saldo y acción opcional.
class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.kicker,
    required this.title,
    this.trailing,
    this.literalTitle = false,
  });
  final String kicker;
  final String title;
  final Widget? trailing;
  final bool literalTitle;

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LText(
                  kicker.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Color(0xFF375E50),
                  ),
                ),
                LText(
                  title,
                  verbatim: literalTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium!
                      .copyWith(fontSize: 26),
                ),
              ],
            ),
          ),
          if (c.demo)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: DemoBadge(),
            ),
          CoinBalance(coins: c.pet.coins),
          ?trailing,
        ],
      ),
    );
  }
}
