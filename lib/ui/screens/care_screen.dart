import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../app/texts.dart';
import '../../domain/rules.dart';
import '../navigation.dart';
import '../theme.dart';
import '../widgets/common.dart';
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
      'Mojar, enjabonar y aclarar',
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
      'Cepillar tres mechones',
      () => const GroomScreen(),
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
                childAspectRatio: l.compact ? 0.86 : 0.78,
              ),
              itemCount: _cards.length,
              itemBuilder: (context, i) {
                final card = _cards[i];
                final rule = c.balance.care[card.kind.name]!;
                final effects = rule.delta.entries
                    .map(
                      (e) =>
                          '${e.value > 0 ? '+' : '−'}${e.value.abs()} ${Texts.needLabels[e.key]}',
                    )
                    .join(' · ');
                final main = rule.delta.keys.first;
                return _IllustratedCard(
                  image: card.image,
                  title: Texts.careTitles[card.kind]!,
                  subtitle: card.subtitle,
                  footer: effects,
                  footerIcon: main.icon,
                  footerColor: main.color,
                  onTap: () => pushScreen(context, card.build()),
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
    required this.footer,
    required this.footerIcon,
    required this.footerColor,
    required this.onTap,
  });
  final String image;
  final String title;
  final String subtitle;
  final String footer;
  final IconData footerIcon;
  final Color footerColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle. $footer',
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
              Expanded(child: Image.asset(image, fit: BoxFit.cover)),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.subtitle),
                    Text(
                      subtitle,
                      style: AppText.small,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(footerIcon, size: 16, color: footerColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            footer,
                            style: AppText.small.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
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
