// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:material_ui/material_ui.dart';

import 'app_state.dart';

/// The screen flash, laid over a whole page: bright on each click that
/// sounds (the engine's rules), gone a third of a beat later. Above 180 BPM
/// only the bar's first beat flashes: more than three flashes a second can
/// trigger seizures. [beat] and [tempo] are the engine's, polled each frame.
class ScreenFlash extends StatelessWidget {
  const ScreenFlash({
    super.key,
    required this.state,
    required this.beat,
    required this.tempo,
  });

  final AppState state;
  final double beat;
  final double tempo;

  @override
  Widget build(BuildContext context) {
    final lib = state.library;
    final felt = lib.flash || lib.flashCountIn
        ? state.engine.lastFelt(tempo > 180)
        : null;
    final flash = felt != null && (felt.count ? lib.flashCountIn : lib.flash)
        ? (1 - (beat - felt.at) * 3).clamp(0.0, 1.0) *
              (felt.downbeat ? 0.5 : 0.3)
        : 0.0;
    if (flash == 0) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: ColoredBox(
        color: (felt!.downbeat ? scheme.primary : scheme.tertiary).withValues(
          alpha: flash,
        ),
      ),
    );
  }
}
