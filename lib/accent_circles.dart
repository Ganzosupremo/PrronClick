// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:material_ui/material_ui.dart';

import 'l10n/app_localizations.dart';
import 'song.dart';

/// One circle per beat, sized by its accent; a silent beat is an empty ring.
/// With [onTap], tapping a beat changes its accent.
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
    Widget circle(int i) {
      final level = levels[i], on = i == current;
      final radius = const [18.0, 16.0, 14.0, 14.0][level];
      // The level shows as how much orange; the beat playing as full orange
      // with a light ring, so it never looks like a strong beat.
      final fill = switch (level) {
        _ when on && level != accentSilent => scheme.primary,
        accentStrong => scheme.primary.withValues(alpha: 0.75),
        accentMedium => scheme.primary.withValues(alpha: 0.35),
        accentNormal => scheme.surfaceContainerHighest,
        _ => null,
      };
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: on
              ? Border.all(color: scheme.onSurface, width: 3)
              : level == accentSilent
              ? Border.all(color: scheme.outline, width: 2)
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
                child: SizedBox.square(
                  dimension: 48,
                  child: Center(child: circle(i)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
