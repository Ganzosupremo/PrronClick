// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import 'app_state.dart';
import 'flash.dart';
import 'l10n/app_localizations.dart';
import 'lyrics_view.dart';
import 'song.dart';
import 'theme.dart';

/// The lyrics on the whole screen, under a small stage that stays in view:
/// the song, its section, the beat, the tempo and Play.
class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key, required this.state});

  final AppState state;

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker ticker;

  // Polled from the engine every frame, like the metronome page (which
  // stops polling while this screen covers it).
  double tempo = 120;
  bool playing = false;
  double beat = 0;
  int beatsPerBar = 4;
  double origin = 0;

  AppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    ticker = createTicker((_) {
      final e = state.engine;
      setState(() {
        tempo = e.tempo();
        playing = e.isPlaying();
        beat = e.beat();
        beatsPerBar = e.beatsPerBar();
        origin = e.barOrigin();
      });
    })..start();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final info = state.showInfo;
    final lyrics = state.shownSong?.lyrics;
    final canControl = state.canControl;
    final current = playing && beat >= 0
        ? (beat - origin).floor() % beatsPerBar
        : -1;
    final levels = state.accents?.length == beatsPerBar
        ? state.accents!
        : defaultAccents(beatsPerBar, info.beatUnit);

    final stage = Container(
      color: scheme.surfaceContainer,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            info.song ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.titleLarge,
          ),
          if (info.author != null)
            Text(
              info.author!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium!.copyWith(color: scheme.onSurfaceVariant),
            ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 20,
                      child: Text(
                        playing ? info.section ?? '' : '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium!.copyWith(
                          color: scheme.tertiary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Long bars (12/8, 16/4) shrink to fit the width.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Row(
                        children: [
                          for (var i = 0; i < beatsPerBar; i++)
                            _Dot(
                              on: i == current,
                              downbeat: i == 0,
                              silent: levels[i] == accentSilent,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Text(
                    tempo.round().toString(),
                    style: text.displaySmall!.copyWith(fontSize: 44),
                  ),
                  Text(
                    'BPM',
                    style: text.labelSmall!.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Tooltip(
                message: playing ? t.stop : t.start,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    minimumSize: const Size(64, 64),
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                  ),
                  onPressed: canControl
                      ? () => state.engine.setPlaying(!playing)
                      : null,
                  child: Icon(
                    playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    size: 36,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final page = Scaffold(
      appBar: AppBar(
        leading: CloseButton(onPressed: () => Navigator.of(context).pop()),
        title: PageTitle(t.lyrics),
        actions: [
          IconButton(
            tooltip: t.transposeDown,
            onPressed: canControl && info.transpose > -11
                ? () => state.setTranspose(info.transpose - 1)
                : null,
            icon: const Icon(Icons.remove),
          ),
          Text(
            [
              info.transpose > 0 ? '+${info.transpose}' : '${info.transpose}',
              ?info.key,
            ].join(' · '),
            style: text.labelLarge,
          ),
          IconButton(
            tooltip: t.transposeUp,
            onPressed: canControl && info.transpose < 11
                ? () => state.setTranspose(info.transpose + 1)
                : null,
            icon: const Icon(Icons.add),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          stage,
          Expanded(
            child: lyrics == null
                // A setlist can move on to a song without lyrics.
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        t.noLyrics,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.outline),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
                    child: LyricsView(
                      // A new song starts at its top.
                      key: ValueKey(lyrics),
                      text: lyrics,
                      transpose: info.transpose,
                      section: playing ? info.section : null,
                    ),
                  ),
          ),
        ],
      ),
    );
    return Stack(
      children: [
        page,
        Positioned.fill(
          child: ScreenFlash(state: state, beat: beat, tempo: tempo),
        ),
      ],
    );
  }
}

/// One beat: lit while it plays, amber on the bar's first beat. A silent
/// beat is a ring.
class _Dot extends StatelessWidget {
  const _Dot({required this.on, required this.downbeat, required this.silent});

  final bool on;
  final bool downbeat;
  final bool silent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lit = downbeat ? scheme.primaryContainer : scheme.tertiary;
    final size = downbeat ? 20.0 : 16.0;
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: silent
            ? null
            : on
            ? lit
            : scheme.surfaceContainerHighest,
        border: silent
            ? Border.all(color: on ? lit : scheme.outline, width: 2)
            : null,
        boxShadow: on && !silent
            ? [BoxShadow(color: lit.withValues(alpha: 0.6), blurRadius: 12)]
            : null,
      ),
    );
  }
}
