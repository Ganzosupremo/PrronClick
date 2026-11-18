// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:material_ui/material_ui.dart';

/// Stage-lighting colors: a deep "Congo blue" gel for the room, amber for
/// the downbeat and Play, cyan for the other beats.
abstract final class Stage {
  static const congo = Color(0xFF1A1442);
  static const velvet = Color(0xFF251C57);
  static const haze = Color(0xFF3A2F78);
  static const lavender = Color(0xFFECE8FF);
  static const amber = Color(0xFFFFB020);
  static const cyan = Color(0xFF62D6E8);

  /// The tempo and titles: tall, condensed, readable across a stage.
  static const display = 'Big Shoulders';
  static const body = 'Atkinson Hyperlegible Next';
}

/// A page's title that shrinks to fit instead of being cut: narrow phones
/// with larger system text leave little room next to the actions.
class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: AlignmentDirectional.centerStart,
    child: Text(text, maxLines: 1),
  );
}

ThemeData stageTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Stage.congo,
        brightness: brightness,
      ).copyWith(
        primary: dark ? Stage.amber : const Color(0xFF8F5300),
        onPrimary: dark ? Stage.congo : Colors.white,
        primaryContainer: Stage.amber,
        onPrimaryContainer: Stage.congo,
        secondary: dark ? Stage.lavender : Stage.haze,
        secondaryContainer: dark ? Stage.haze : const Color(0xFFD3CCEE),
        onSecondaryContainer: dark ? Stage.lavender : Stage.congo,
        tertiary: dark ? Stage.cyan : const Color(0xFF00707F),
        surface: dark ? Stage.congo : const Color(0xFFF4F2FB),
        onSurface: dark ? Stage.lavender : Stage.congo,
        surfaceContainerLow: dark
            ? const Color(0xFF201852)
            : const Color(0xFFEEEBF9),
        surfaceContainer: dark ? Stage.velvet : const Color(0xFFE8E4F7),
        surfaceContainerHigh: dark
            ? const Color(0xFF2E2468)
            : const Color(0xFFDFDAF2),
        surfaceContainerHighest: dark ? Stage.haze : const Color(0xFFD3CCEE),
        onSurfaceVariant: dark
            ? const Color(0xFFB9B1E6)
            : const Color(0xFF4A4180),
        outline: dark ? const Color(0xFF8077BF) : const Color(0xFF7A72AE),
        outlineVariant: dark ? Stage.haze : const Color(0xFFCBC4EA),
      );
  final base = ThemeData(
    colorScheme: scheme,
    fontFamily: Stage.body,
    scaffoldBackgroundColor: scheme.surface,
  );
  const display = TextStyle(fontFamily: Stage.display, height: 1);
  final text = base.textTheme.copyWith(
    displayLarge: base.textTheme.displayLarge!.merge(
      display.copyWith(fontWeight: FontWeight.w800),
    ),
    displayMedium: base.textTheme.displayMedium!.merge(
      display.copyWith(fontWeight: FontWeight.w800),
    ),
    displaySmall: base.textTheme.displaySmall!.merge(
      display.copyWith(fontWeight: FontWeight.w800),
    ),
    headlineLarge: base.textTheme.headlineLarge!.merge(
      display.copyWith(fontWeight: FontWeight.w800),
    ),
    headlineMedium: base.textTheme.headlineMedium!.merge(
      display.copyWith(fontWeight: FontWeight.w800),
    ),
    headlineSmall: base.textTheme.headlineSmall!.merge(
      display.copyWith(fontWeight: FontWeight.w600),
    ),
    titleLarge: base.textTheme.titleLarge!.copyWith(
      fontWeight: FontWeight.w700,
    ),
    titleMedium: base.textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.w600,
    ),
    labelLarge: base.textTheme.labelLarge!.copyWith(
      fontWeight: FontWeight.w600,
    ),
  );
  final round = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      // Sizes are added to the theme's styles later (localize): set it here.
      titleTextStyle: text.headlineMedium!.copyWith(
        fontSize: 26,
        color: scheme.onSurface,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: scheme.primaryContainer,
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: scheme.outlineVariant),
      selectedColor: scheme.primaryContainer,
      checkmarkColor: scheme.onPrimaryContainer,
      labelStyle: text.labelLarge,
      secondaryLabelStyle: text.labelLarge!.copyWith(
        color: scheme.onPrimaryContainer,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? scheme.primaryContainer : null,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled)
              ? null
              : s.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : scheme.onSurface,
        ),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
      ),
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 8,
      inactiveTrackColor: scheme.surfaceContainerHighest,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      shape: round,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: round),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      // Amber is for Play and the beat: the other buttons stay quiet.
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        shape: round,
        side: BorderSide(color: scheme.outline),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: round,
    ),
  );
}
