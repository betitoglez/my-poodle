import 'package:material_ui/material_ui.dart';

/// Tokens centralizados: color, tipografía, espaciado, radios y tamaños.
abstract final class AppColors {
  static const cream = Color(0xFFFFF8E9);
  static const creamDeep = Color(0xFFF3E7D0);
  static const ink = Color(0xFF34283B);
  static const inkSoft = Color(0xFF5E5262);
  static const plum = Color(0xFF5C354E);
  static const plumSoft = Color(0xFFEBDDE6);
  static const leaf = Color(0xFF375E50);
  static const leafSoft = Color(0xFFDCE8DF);
  static const coin = Color(0xFFE9B657);
  static const coinDeep = Color(0xFF8A5A1C);
  static const coral = Color(0xFFE0705A);
  static const lavender = Color(0xFFB8A6D9);
  static const focus = Color(0xFF7661A8);
  static const disabled = Color(0xFFCFC6B8);
  static const overlay = Color(0x8834283B);

  static const satiety = Color(0xFFD9853B);
  static const hygiene = Color(0xFF6E8FD0);
  static const mood = Color(0xFFD9597A);
  static const energy = Color(0xFF4E9A6A);
}

abstract final class AppSpace {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class AppRadii {
  static const s = 10.0;
  static const m = 16.0;
  static const l = 24.0;
  static const pill = 999.0;
}

abstract final class AppSizes {
  /// Objetivo táctil mínimo (unidades lógicas).
  static const touch = 48.0;
  static const bigButton = 64.0;
  static const reference = Size(390, 844);
}

abstract final class AppText {
  /// Títulos serif redondeados: Young Serif es la referencia; mientras no se
  /// empaquete la fuente con licencia se usan serif del sistema.
  static const titleFamilyFallback = [
    'Young Serif',
    'Georgia',
    'Noto Serif',
    'serif',
  ];

  static const display = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.italic,
    color: AppColors.plum,
    fontFamilyFallback: titleFamilyFallback,
    height: 1.1,
  );
  static const title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.plum,
    fontFamilyFallback: titleFamilyFallback,
    height: 1.15,
  );
  static const subtitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
  );
  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
    height: 1.35,
  );
  static const small = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.inkSoft,
  );
  static const kicker = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.8,
    color: AppColors.leaf,
  );
  static const number = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.plum,
    primary: AppColors.plum,
    onPrimary: AppColors.cream,
    secondary: AppColors.leaf,
    surface: AppColors.cream,
    onSurface: AppColors.ink,
  );
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadii.m),
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,
    textTheme: const TextTheme(
      headlineMedium: AppText.display,
      titleLarge: AppText.title,
      titleMedium: AppText.subtitle,
      bodyLarge: AppText.body,
      bodyMedium: AppText.body,
      bodySmall: AppText.small,
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppText.title,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(AppSizes.touch, AppSizes.touch),
        backgroundColor: AppColors.plum,
        foregroundColor: AppColors.cream,
        disabledBackgroundColor: AppColors.disabled,
        disabledForegroundColor: AppColors.inkSoft,
        shape: shape,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.l,
          vertical: AppSpace.m,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(AppSizes.touch, AppSizes.touch),
        foregroundColor: AppColors.plum,
        side: const BorderSide(color: AppColors.plum, width: 2),
        shape: shape,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.l,
          vertical: AppSpace.m,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(AppSizes.touch, AppSizes.touch),
        foregroundColor: AppColors.plum,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(AppSizes.touch, AppSizes.touch),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.creamDeep,
      indicatorColor: AppColors.plumSoft,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 13,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w900
              : FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? AppColors.plum
              : AppColors.inkSoft,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.cream
            : AppColors.inkSoft,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.leaf
            : AppColors.creamDeep,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.l),
      ),
      titleTextStyle: AppText.title,
      contentTextStyle: AppText.body,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpace.l,
        vertical: AppSpace.l,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.m),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.m),
        borderSide: const BorderSide(color: Color(0xFFB7AB97)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.m),
        borderSide: const BorderSide(color: AppColors.focus, width: 3),
      ),
    ),
    focusColor: AppColors.focus.withValues(alpha: 0.25),
  );
}

/// Reglas de adaptación centralizadas (referencia 390×844).
class Layout {
  Layout(this.size);
  final Size size;

  static Layout of(BuildContext context) => Layout(MediaQuery.sizeOf(context));

  bool get compact => size.height < 680 || size.width < 360;
  bool get tablet => size.shortestSide >= 600;
  double get gutter =>
      tablet ? 24 : (compact ? 12 : (size.width >= 420 ? 20 : 16));

  /// Ancho máximo del contenido en tableta (panel centrado).
  double get maxContentWidth => tablet ? 640 : double.infinity;
}
