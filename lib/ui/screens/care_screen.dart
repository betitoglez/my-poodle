import 'package:my_poodle/l10n/localized_widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../app/background_music.dart';
import '../../app/texts.dart';
import '../../domain/balance.dart';
import '../../domain/rules.dart';
import '../navigation.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';
import 'care_activity_screens.dart';
import 'main_shell.dart';

class _CareCard {
  const _CareCard(this.kind, this.image, this.subtitle, this.build);
  final CareKind kind;
  final String image;
  final String subtitle;
  final Widget Function() build;
}

/// P04 · Cuidados: cuatro tarjetas ilustradas disponibles desde la adopción.
class CareScreen extends StatelessWidget {
  const CareScreen({super.key});

  static final _cards = [
    _CareCard(
      CareKind.feed,
      'assets/images/cards/kitchen.jpg',
      'Cuenco y tres bocados',
      () => const FeedScreen(),
    ),
    _CareCard(
      CareKind.bath,
      'assets/images/cards/bath.jpg',
      'Ducha, esponja, aclarado y secador',
      () => const BathScreen(),
    ),
    _CareCard(
      CareKind.walk,
      'assets/images/cards/walk.jpg',
      'Tres paradas en el sendero',
      () => const WalkScreen(),
    ),
    _CareCard(
      CareKind.groom,
      'assets/images/cards/salon.jpg',
      'Peine, tijeras y secador',
      () => const GroomScreen(),
    ),
    _CareCard(
      CareKind.sleep,
      'assets/images/cards/cushion.jpg',
      'A su cama, con manta',
      () => const SleepScreen(),
    ),
    _CareCard(
      CareKind.vet,
      'assets/images/rooms/vet.jpg',
      'Revisión y pastilla',
      () => const VetScreen(),
    ),
    _CareCard(
      CareKind.drink,
      'assets/images/cards/kitchen.jpg',
      'Llena el cuenco de agua',
      () => const DrinkScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final l = Layout.of(context);
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          TabHeader(kicker: 'La rutina de ${c.pet.name}', title: 'Cuidados'),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.fromLTRB(
                l.gutter,
                AppSpace.s,
                l.gutter,
                AppSpace.l,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: l.tablet ? 4 : 2,
                mainAxisSpacing: AppSpace.m,
                crossAxisSpacing: AppSpace.m,
                childAspectRatio: l.compact ? 0.82 : 0.76,
              ),
              itemCount: _cards.length,
              itemBuilder: (context, i) {
                final card = _cards[i];
                final rule = c.balance.care[card.kind.name]!;
                final sick = c.pet.isSick && card.kind == CareKind.vet;
                return _IllustratedCard(
                  image: card.image,
                  title: Texts.careTitles[card.kind]!,
                  subtitle: card.subtitle,
                  effects: rule.delta,
                  cures: rule.cures,
                  price: card.kind == CareKind.vet ? Rules.vetCost : null,
                  waitSeconds: c.careWaitSeconds(card.kind),
                  badge: sick ? '¡Malito!' : null,
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.hideCurrentSnackBar();
                    final blocked = c.careBlocked(card.kind);
                    if (blocked != null) {
                      showCareBlocked(context, card.kind, blocked);
                      return;
                    }
                    if (c.pet.restingSinceUtc != null &&
                        !await saveOrRecover(
                          context,
                          () => c.setHomeResting(false),
                        )) {
                      return;
                    }
                    if (context.mounted) {
                      pushScreen(
                        context,
                        card.build(),
                        music: MusicTrack.activities,
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IllustratedCard extends StatelessWidget {
  const _IllustratedCard({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.effects,
    required this.cures,
    this.price,
    required this.onTap,
    this.badge,
    this.waitSeconds = 0,
  });
  final String? badge;
  final int waitSeconds;
  final String image;
  final String title;
  final String subtitle;
  final Map<Need, int> effects;
  final bool cures;
  final int? price;
  final VoidCallback onTap;

  String _amount(int change) => '${change >= 0 ? '+' : '−'}${change.abs()}';

  Widget _effect(IconData icon, Color color, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 3),
      LText(text, style: AppText.small.copyWith(fontWeight: FontWeight.w800)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final details = [
      if (cures) 'Cura la salud',
      for (final e in effects.entries)
        '${_amount(e.value)} ${Texts.needLabels[e.key]}',
      if (price != null) '$price monedas',
    ].join('. ');
    return LSemantics(
      button: true,
      onTap: onTap,
      label: '$title. $subtitle. $details.${badge == null ? '' : ' $badge'}',
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.m),
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(image, fit: BoxFit.cover),
                    if (waitSeconds > 0)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Chip(
                          avatar: const Icon(Icons.timer_rounded, size: 16),
                          label: LText(countdown(waitSeconds), verbatim: true),
                        ),
                      ),
                    if (badge != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.coral,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: LText(
                            badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LText(title, style: AppText.subtitle),
                    LText(
                      subtitle,
                      style: AppText.small,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 7,
                      runSpacing: 2,
                      children: [
                        if (cures)
                          _effect(
                            Icons.medical_services_rounded,
                            AppColors.coral,
                            'Cura',
                          ),
                        for (final e in effects.entries)
                          _effect(e.key.icon, e.key.color, _amount(e.value)),
                        if (price != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CoinIcon(size: 15),
                              const SizedBox(width: 3),
                              Flexible(
                                child: LText(
                                  '$price monedas',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.small.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
