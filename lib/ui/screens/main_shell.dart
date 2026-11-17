import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
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
    final c = AppScope.of(context);
    return ListenableBuilder(
      listenable: shell,
      builder: (context, _) {
        final tab = shell.tab;
        return Scaffold(
          body: switch (tab) {
            ShellTab.home => const HomeScreen(),
            ShellTab.care => const CareScreen(),
            ShellTab.games => const GamesScreen(),
            ShellTab.wardrobe => const WardrobeScreen(),
          },
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Banda de banner separada de la navegación y solo en Casa.
              if (c.bannerPreview && tab == ShellTab.home) const BannerSlot(),
              NavigationBar(
                selectedIndex: tab.index,
                onDestinationSelected: (i) => shell.go(ShellTab.values[i]),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_rounded),
                    label: 'Casa',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.volunteer_activism_rounded),
                    label: 'Cuidados',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.sports_esports_rounded),
                    label: 'Juegos',
                  ),
                  NavigationDestination(
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

/// Cabecera común de pestaña: título, saldo y acción opcional.
class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.kicker,
    required this.title,
    this.trailing,
  });
  final String kicker;
  final String title;
  final Widget? trailing;

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
                Text(
                  kicker.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Color(0xFF375E50),
                  ),
                ),
                Text(
                  title,
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
