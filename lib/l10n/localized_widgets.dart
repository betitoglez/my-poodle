import 'package:material_ui/material_ui.dart';

import 'app_strings.dart';
export 'app_strings.dart';

/// Texto visible localizado. Los datos introducidos por el usuario usan verbatim.
class LText extends StatelessWidget {
  const LText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.semanticsLabel,
    this.textScaler,
    this.textDirection,
    this.locale,
    this.strutStyle,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.verbatim = false,
  });
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool? softWrap;
  final String? semanticsLabel;
  final TextScaler? textScaler;
  final TextDirection? textDirection;
  final Locale? locale;
  final StrutStyle? strutStyle;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;
  final bool verbatim;
  @override
  Widget build(BuildContext context) => Text(
    verbatim ? data : localize(context, data),
    style: style,
    textAlign: textAlign,
    overflow: overflow,
    maxLines: maxLines,
    softWrap: softWrap,
    semanticsLabel: semanticsLabel == null
        ? null
        : localize(context, semanticsLabel!),
    textScaler: textScaler,
    textDirection: textDirection,
    locale: locale,
    strutStyle: strutStyle,
    textWidthBasis: textWidthBasis,
    textHeightBehavior: textHeightBehavior,
    selectionColor: selectionColor,
  );
}

class LSemantics extends StatelessWidget {
  const LSemantics({
    super.key,
    this.child,
    this.label,
    this.hint,
    this.value,
    this.button,
    this.selected,
    this.enabled,
    this.onTap,
    this.excludeSemantics = false,
    this.container = false,
    this.liveRegion = false,
    this.image,
    this.header,
  });
  final Widget? child;
  final String? label, hint, value;
  final bool? button, selected, enabled, image, header;
  final VoidCallback? onTap;
  final bool excludeSemantics, container, liveRegion;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label == null ? null : localize(context, label!),
    hint: hint == null ? null : localize(context, hint!),
    value: value == null ? null : localize(context, value!),
    button: button,
    selected: selected,
    enabled: enabled,
    image: image,
    header: header,
    onTap: onTap,
    excludeSemantics: excludeSemantics,
    container: container,
    liveRegion: liveRegion,
    child: child,
  );
}

class LNavigationDestination extends StatelessWidget {
  const LNavigationDestination({
    super.key,
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.enabled = true,
  });
  final Widget icon;
  final String label;
  final Widget? selectedIcon;
  final bool enabled;
  @override
  Widget build(BuildContext context) => NavigationDestination(
    icon: icon,
    selectedIcon: selectedIcon,
    label: localize(context, label),
    enabled: enabled,
  );
}
