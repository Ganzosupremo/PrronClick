// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:material_ui/material_ui.dart';

import 'l10n/app_localizations.dart';
import 'song.dart';

/// One bar per beat, as tall as its accent; a silent beat is an empty
/// outline. The beat playing lights up. With [onTap], tapping a beat changes
/// its accent.
class AccentCircles extends StatelessWidget {
  const AccentCircles({
    super.key,
    required this.levels,
    this.current = -1,
    this.onTap,
  });

  final List<int> levels;
  final int current; // beat playing now; -1 = none
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final names = [
      t.accentStrong,
      t.accentMedium,
      t.accentNormal,
      t.accentSilent,
    ];
    Widget bar(int i) {
      final level = levels[i], on = i == current;
      final height = const [56.0, 40.0, 26.0, 26.0][level];
      final silent = level == accentSilent;
      // The height says the accent, so the beat playing can light up in
      // full: amber on the bar's first beat, cyan on the others.
      final lit = i == 0 ? scheme.primaryContainer : scheme.tertiary;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: 30,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: silent
              ? null
              : on
              ? lit
              : scheme.surfaceContainerHighest,
          border: silent
              ? Border.all(color: on ? lit : scheme.outline, width: 2)
              : null,
          boxShadow: on && !silent
              ? [BoxShadow(color: lit.withValues(alpha: 0.6), blurRadius: 18)]
              : null,
        ),
      );
    }

    // Long bars (12/8, 16/4) shrink to fit the width.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        children: [
          for (var i = 0; i < levels.length; i++)
            Semantics(
              label: t.accentBeat(i + 1, names[levels[i]]),
              button: onTap != null,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap == null ? null : () => onTap!(i),
                child: SizedBox(
                  width: 44,
                  height: 64,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: bar(i),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
