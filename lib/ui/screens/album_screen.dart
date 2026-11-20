import 'package:my_poodle/l10n/localized_widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../domain/achievements.dart';
import '../navigation.dart';
import '../theme.dart';
import '../widgets/celebrations.dart';
import '../widgets/common.dart';
import '../widgets/stickers.dart';

String albumPageTitle(AlbumPage page) => switch (page) {
  AlbumPage.care => 'Cuidados',
  AlbumPage.games => 'Juegos',
  AlbumPage.wardrobe => 'Armario y salón',
  AlbumPage.photos => 'Fotos',
  AlbumPage.special => 'Especiales',
};

IconData albumPageIcon(AlbumPage page) => switch (page) {
  AlbumPage.care => Icons.volunteer_activism_rounded,
  AlbumPage.games => Icons.sports_esports_rounded,
  AlbumPage.wardrobe => Icons.checkroom_rounded,
  AlbumPage.photos => Icons.photo_camera_rounded,
  AlbumPage.special => Icons.auto_awesome_rounded,
};

/// Botón de la cabecera de Juegos que abre el álbum. Un punto avisa de que
/// hay un bono de página por recoger.
class AlbumButton extends StatelessWidget {
  const AlbumButton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final pending = c.achievements.pendingPages(c.pet) > 0;
    void open() => pushScreen<void>(context, const AlbumScreen());
    return LSemantics(
      button: true,
      label: pending
          ? 'Álbum de pegatinas. Hay monedas para recoger.'
          : 'Álbum de pegatinas',
      excludeSemantics: true,
      onTap: open,
      child: IconButton(
        key: const Key('album-button'),
        tooltip: localizeNullable(context, 'Álbum de pegatinas'),
        onPressed: open,
        icon: Badge(
          isLabelVisible: pending,
          backgroundColor: AppColors.coral,
          child: const Icon(Icons.collections_bookmark_rounded),
        ),
      ),
    );
  }
}

/// Álbum de pegatinas: una página por tema con su cuadrícula. Las
/// conseguidas se ven a color con su fecha; las pendientes, en silueta con
/// la pista. Completar una página permite recoger su bono una sola vez.
class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key, this.initialPage = AlbumPage.care});
  final AlbumPage initialPage;

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  late int _index = widget.initialPage.index;
  late final PageController _pages = PageController(initialPage: _index);
  bool _collecting = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int index) {
    setState(() => _index = index);
    if (navigationReducedMotion(context)) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _collect(AlbumPage page) async {
    if (_collecting) return;
    setState(() => _collecting = true);
    final c = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final text = AppStrings.of(context);
    final result = await c.collectAlbumPage(page);
    if (!mounted) return;
    setState(() => _collecting = false);
    switch (result) {
      case Done(:final value):
        if (!c.reducedMotion) {
          ConfettiBurst.show(context, reducedMotion: false);
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              text.text('¡Has recogido ${value.coinsEarned} monedas!'),
            ),
          ),
        );
      case SaveFailed():
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              text.text('No se ha podido guardar. Inténtalo de nuevo.'),
            ),
          ),
        );
      case Ignored():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final l = Layout.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: localizeNullable(context, 'Volver'),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const LText(
          'Álbum de pegatinas',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: l.gutter,
                vertical: AppSpace.s,
              ),
              child: Row(
                children: [
                  for (final page in AlbumPage.values)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpace.s),
                      child: _PageChip(
                        page: page,
                        selected: page.index == _index,
                        unlocked: c.achievements.unlockedOn(c.pet, page),
                        total: Achievements.onPage(page).length,
                        onTap: () => _go(page.index),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  for (final page in AlbumPage.values)
                    _AlbumPageView(
                      key: ValueKey('album-page-${page.name}'),
                      page: page,
                      collecting: _collecting,
                      onCollect: () => _collect(page),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageChip extends StatelessWidget {
  const _PageChip({
    required this.page,
    required this.selected,
    required this.unlocked,
    required this.total,
    required this.onTap,
  });
  final AlbumPage page;
  final bool selected;
  final int unlocked;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = albumPageTitle(page);
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${localize(context, title)}. ${localize(context, '$unlocked de $total pegatinas')}',
      excludeSemantics: true,
      onTap: onTap,
      child: ChoiceChip(
        key: Key('album-chip-${page.name}'),
        selected: selected,
        onSelected: (_) => onTap(),
        avatar: Icon(albumPageIcon(page), size: 18),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [LText(title), Text(' · $unlocked/$total')],
        ),
      ),
    );
  }
}

class _AlbumPageView extends StatelessWidget {
  const _AlbumPageView({
    super.key,
    required this.page,
    required this.collecting,
    required this.onCollect,
  });
  final AlbumPage page;
  final bool collecting;
  final VoidCallback onCollect;

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final l = Layout.of(context);
    final a = c.achievements;
    final s = c.pet;
    final items = Achievements.onPage(page);
    final unlocked = a.unlockedOn(s, page);
    final bonus = a.pageBonus(page);
    final Widget reward;
    if (a.canCollect(s, page)) {
      reward = AppButton(
        key: Key('album-collect-${page.name}'),
        label: 'Recoger $bonus monedas',
        icon: Icons.savings_rounded,
        expand: true,
        big: true,
        onPressed: collecting ? null : onCollect,
      );
    } else if (a.collected(s, page)) {
      reward = _Note(
        icon: Icons.check_circle_rounded,
        text: 'Bono recogido: $bonus monedas.',
      );
    } else {
      reward = _Note(
        icon: Icons.savings_outlined,
        text: 'Completa la página para ganar $bonus monedas.',
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: l.maxContentWidth),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            l.gutter,
            AppSpace.s,
            l.gutter,
            AppSpace.xl,
          ),
          children: [
            LSemantics(
              header: true,
              child: LText(albumPageTitle(page), style: AppText.title),
            ),
            LText(
              '$unlocked de ${items.length} pegatinas',
              style: AppText.body,
            ),
            const SizedBox(height: AppSpace.s),
            reward,
            const SizedBox(height: AppSpace.m),
            LayoutBuilder(
              builder: (context, box) {
                const gap = AppSpace.m;
                final columns = box.maxWidth >= 520 ? 3 : 2;
                final width = (box.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final item in items)
                      SizedBox(
                        width: width,
                        child: _StickerTile(
                          achievement: item,
                          unlockedUtc: s.achievements[item.id],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: AppColors.leaf),
      const SizedBox(width: AppSpace.s),
      Expanded(child: LText(text, style: AppText.body)),
    ],
  );
}

class _StickerTile extends StatelessWidget {
  const _StickerTile({required this.achievement, required this.unlockedUtc});
  final Achievement achievement;
  final int? unlockedUtc;

  @override
  Widget build(BuildContext context) {
    final got = unlockedUtc != null;
    final date = got
        ? MaterialLocalizations.of(context).formatMediumDate(
            DateTime.fromMillisecondsSinceEpoch(unlockedUtc! * 1000),
          )
        : null;
    final status = got ? 'Conseguida el $date' : achievement.hint;
    final label = got
        ? '${localize(context, achievement.title)}. ${localize(context, 'Conseguida el $date')}'
        : '${localize(context, achievement.title)}. ${localize(context, 'Pendiente')}. ${localize(context, achievement.hint)}';
    return Semantics(
      container: true,
      label: label,
      excludeSemantics: true,
      child: Container(
        key: Key('sticker-${achievement.id}'),
        padding: const EdgeInsets.all(AppSpace.s),
        decoration: BoxDecoration(
          color: got ? Colors.white : AppColors.creamDeep,
          borderRadius: BorderRadius.circular(AppRadii.m),
          border: Border.all(
            color: got ? AppColors.coin : AppColors.disabled,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Sticker(sticker: achievement.sticker, unlocked: got),
            const SizedBox(height: AppSpace.xs),
            LText(
              achievement.title,
              textAlign: TextAlign.center,
              style: AppText.subtitle,
            ),
            const SizedBox(height: 2),
            LText(status, textAlign: TextAlign.center, style: AppText.small),
          ],
        ),
      ),
    );
  }
}
