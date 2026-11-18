// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import 'accent_circles.dart';
import 'app_state.dart';
import 'flash.dart';
import 'l10n/app_localizations.dart';
import 'lyrics_screen.dart';
import 'meter_picker.dart';
import 'practice.dart';
import 'repeat_button.dart';
import 'song.dart';

class MetronomePage extends StatefulWidget {
  const MetronomePage({super.key, required this.state});

  final AppState state;

  @override
  State<MetronomePage> createState() => _MetronomePageState();
}

class _MetronomePageState extends State<MetronomePage>
    with SingleTickerProviderStateMixin {
  late final Ticker ticker;

  // Polled from the engine every frame.
  double tempo = 120;
  bool playing = false;
  int peers = 0;
  double beat = 0;
  int beatsPerBar = 4;
  double origin = 0;
  int pendingBeatsPerBar = 0;
  double muteUntil = 0;
  double countUntil = 0;

  _Panel? panel; // null = every section closed

  AppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    ticker = createTicker((_) {
      final e = state.engine;
      setState(() {
        tempo = e.tempo();
        playing = e.isPlaying();
        peers = e.numPeers();
        beat = e.beat();
        beatsPerBar = e.beatsPerBar();
        origin = e.barOrigin();
        muteUntil = e.muteUntil();
        countUntil = e.countUntil();
        // A meter picked by hand starts on the next downbeat: show it right
        // away. A setlist's next song is further off and is not shown.
        final pending = e.pendingBeatsPerBar();
        pendingBeatsPerBar =
            pending > 0 && e.pendingOrigin() - beat <= beatsPerBar
            ? pending
            : 0;
      });
    })..start();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  void setTempo(double bpm) => state.engine.setTempo(bpm.roundToDouble());

  final _taps = <int>[];
  final _tapClock = Stopwatch()..start();

  void _tap() {
    final bpm = tapBpm(_taps, _tapClock.elapsedMilliseconds);
    if (bpm != null) setTempo(bpm);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => _build(context),
    );
  }

  Future<void> _pickMeter(int beats, int unit) async {
    final picked = await pickMeter(context, beats, unit);
    if (picked != null) state.setMeter(picked.$1, picked.$2);
  }

  Widget _build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final canControl = state.canControl;
    final info = state.showInfo;
    final lyrics = state.shownSong?.lyrics;
    // Show the meter the user picked even before its downbeat comes.
    final shownBeats = pendingBeatsPerBar > 0
        ? pendingBeatsPerBar
        : beatsPerBar;
    final accents = state.accents;
    final aboutSong = [?info.section, ?info.key, ?info.note].join(' · ');
    final sectionChange = info.sectionChange;
    String? comingUp;
    if (sectionChange != null && sectionChange > beat) {
      final bars = ((sectionChange - beat) / beatsPerBar).ceil();
      comingUp = t.comingUpSection(
        info.nextSection ?? '',
        t.inBars(bars.clamp(1, 9999)),
      );
    }
    final currentBeat = playing && beat >= 0
        ? (beat - origin).floor() % beatsPerBar
        : -1;
    final bar = ((beat - origin) / beatsPerBar).floor();
    final paused = playing && beat >= origin && beat < muteUntil;
    final counting = playing && !paused && beat >= origin && beat < countUntil;
    final muted =
        playing &&
        state.library.practiceTools &&
        state.gapTrainer &&
        bar % (state.gapPlay + state.gapMute) >= state.gapPlay;

    final lib = state.library;

    final text = Theme.of(context).textTheme;
    final panels = [
      (_Panel.click, Icons.graphic_eq, t.myClick),
      (_Panel.band, Icons.link, t.panelBand),
      if (lib.practiceTools)
        (_Panel.practice, Icons.fitness_center, t.panelPractice),
    ];
    // Practice can be turned off in Settings while its section is open.
    final shownPanel = panels.any((p) => p.$1 == panel) ? panel : null;
    final status = paused
        ? t.statusPause
        : counting
        ? t.countIn
        : muted
        ? t.statusSilence
        : null;

    // The stage: what is playing and the controls used while playing.
    final stage = Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (info.song != null)
                        Text(
                          info.song!,
                          overflow: TextOverflow.ellipsis,
                          style: text.headlineMedium,
                        ),
                      if (info.author != null)
                        Text(
                          info.author!,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium!.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      if (aboutSong.isNotEmpty)
                        Text(
                          aboutSong,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium!.copyWith(
                            color: scheme.tertiary,
                          ),
                        ),
                      if (comingUp != null)
                        Text(
                          comingUp,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall,
                        ),
                    ],
                  ),
                ),
                // The lyrics open on their own screen, under a small stage.
                if (lyrics != null)
                  IconButton.filledTonal(
                    tooltip: t.lyrics,
                    icon: const Icon(Icons.lyrics_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        fullscreenDialog: true,
                        builder: (_) => LyricsScreen(state: state),
                      ),
                    ),
                  ),
                if (state.shareMode != ShareMode.solo)
                  Chip(
                    avatar: const Icon(Icons.link, size: 18),
                    visualDensity: VisualDensity.compact,
                    label: Text(switch (state.shareMode) {
                      ShareMode.leader => t.leaderPeers(peers),
                      ShareMode.follower =>
                        peers == 0 ? t.searchingLeader : t.followingLeader,
                      ShareMode.solo => '',
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // The count-in always counts plainly (see accentLevel in rules.hpp).
            AccentCircles(
              levels: !counting && accents?.length == beatsPerBar
                  ? accents!
                  : defaultAccents(beatsPerBar, info.beatUnit),
              current: currentBeat,
              onTap: canControl
                  ? (i) => state.cycleAccent(i, beatsPerBar)
                  : null,
            ),
            SizedBox(
              height: 24,
              child: status == null
                  ? null
                  : Text(
                      status,
                      textAlign: TextAlign.center,
                      style: text.labelLarge!.copyWith(color: scheme.tertiary),
                    ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RepeatIconButton(
                  filledTonal: true,
                  tooltip: t.tempoDown,
                  onPressed: canControl ? () => setTempo(tempo - 1) : null,
                  icon: const Icon(Icons.remove),
                ),
                // On a narrow phone the number shrinks to fit, always by the
                // same amount: it is measured against an invisible "000",
                // not the tempo shown, so 199 and 200 are the same size.
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            for (final digits in [
                              '000',
                              tempo.round().toString(),
                            ])
                              Opacity(
                                opacity: digits == '000' ? 0 : 1,
                                child: Text(
                                  digits,
                                  style: text.displayLarge!.copyWith(
                                    fontSize: 120,
                                    height: 0.9,
                                    letterSpacing: -2,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          'BPM',
                          style: text.labelLarge!.copyWith(
                            color: scheme.onSurfaceVariant,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                RepeatIconButton(
                  filledTonal: true,
                  tooltip: t.tempoUp,
                  onPressed: canControl ? () => setTempo(tempo + 1) : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            Slider(
              min: 20,
              max: 300,
              value: tempo.clamp(20, 300),
              label: tempo.round().toString(),
              onChanged: canControl ? setTempo : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SideButton(
                    onPressed: canControl ? _tap : null,
                    top: const Icon(Icons.touch_app_outlined),
                    label: t.tapTempo,
                  ),
                ),
                const SizedBox(width: 12),
                Tooltip(
                  message: playing ? t.stop : t.start,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primaryContainer,
                      foregroundColor: scheme.onPrimaryContainer,
                      minimumSize: const Size(112, 76),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: canControl
                        ? () => state.engine.setPlaying(!playing)
                        : null,
                    child: Icon(
                      playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SideButton(
                    onPressed: canControl
                        ? () => _pickMeter(shownBeats, info.beatUnit)
                        : null,
                    top: Text(
                      '$shownBeats/${info.beatUnit}',
                      style: text.headlineSmall,
                    ),
                    label: t.meter,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final page = ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (info.setlist != null)
          _SetlistBar(state: state, beat: beat, beatsPerBar: beatsPerBar),
        stage,
        const SizedBox(height: 12),
        // Everything set up before playing, one section at a time. Tapping
        // the open one closes it.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (id, icon, label) in panels)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    showCheckmark: false,
                    avatar: Icon(icon, size: 18),
                    label: Text(label),
                    selected: id == shownPanel,
                    onSelected: (on) => setState(() => panel = on ? id : null),
                  ),
                ),
            ],
          ),
        ),
        if (shownPanel != null) ...[
          const SizedBox(height: 12),
          _PanelCard(panel: shownPanel, state: state, bar: playing ? bar : 0),
        ],
      ],
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

class _SetlistBar extends StatelessWidget {
  const _SetlistBar({
    required this.state,
    required this.beat,
    required this.beatsPerBar,
  });

  final AppState state;
  final double beat;
  final int beatsPerBar;

  @override
  Widget build(BuildContext context) {
    final info = state.showInfo;
    final change = info.changeBeat;
    final next = info.next;
    final t = AppLocalizations.of(context);
    final String status;
    if (change != null && change > beat) {
      final when = t.inBars(((change - beat) / beatsPerBar).ceil());
      status = next == null ? t.setlistEnds(when) : t.setlistNextIn(next, when);
    } else {
      status = next == null ? t.lastSong : t.nextSong(next);
    }
    final i = state.setlistIndex;
    final small = Theme.of(context).textTheme.bodySmall;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${info.setlist} · ${info.position}/${info.total}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      status,
                      style: small,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            if (state.canSaveLeaderSetlist)
              IconButton(
                tooltip: t.saveLeaderSetlist,
                onPressed: () {
                  final saved = state.saveLeaderSetlist();
                  if (saved == null) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t.setlistImported(saved.name))),
                  );
                },
                icon: const Icon(Icons.save_alt),
              ),
            // Only whoever runs the setlist moves through it.
            if (state.canControl) ...[
              IconButton(
                tooltip: t.previousSongTooltip,
                onPressed: i > 0 ? () => state.goToSong(i - 1) : null,
                icon: const Icon(Icons.skip_previous),
              ),
              IconButton(
                tooltip: t.nextSongTooltip,
                onPressed: next != null ? () => state.goToSong(i + 1) : null,
                icon: const Icon(Icons.skip_next),
              ),
              IconButton(
                tooltip: t.leaveSetlist,
                onPressed: state.stopSetlist,
                icon: const Icon(Icons.close),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The metronome's sections below the stage.
enum _Panel { click, band, practice }

/// Tap tempo and the meter: an icon or value over a short label.
class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.onPressed,
    required this.top,
    required this.label,
  });

  final VoidCallback? onPressed;
  final Widget top;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 76),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 32, child: Center(child: top)),
          FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1)),
        ],
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.panel,
    required this.state,
    required this.bar,
  });

  final _Panel panel;
  final AppState state;
  final int bar;

  static const _steps = ['1', 'e', '&', 'a'];

  // A long word ("Mitspieler") shrinks a little instead of breaking.
  static Widget _oneLine(String text) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(text, maxLines: 1, softWrap: false),
  );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final help = text.bodySmall!.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    int stepMax({required bool up}) => stepRampMax(
      state.library.rampMax,
      state.library.rampMaxStep,
      up: up,
      tempo: state.engine.tempo(),
    );
    final children = switch (panel) {
      _Panel.click => [
        Text(t.myClickHelp, style: help),
        const SizedBox(height: 16),
        Text(t.subdivision, style: text.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: 1, label: Text(t.no)),
            const ButtonSegment(value: 2, label: Text('2')),
            const ButtonSegment(value: 3, label: Text('3')),
            const ButtonSegment(value: 4, label: Text('4')),
          ],
          selected: {state.library.subdivision},
          onSelectionChanged: (s) => state.setClick(subdivision: s.first),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(t.volume, style: text.titleMedium),
            Expanded(
              child: Slider(
                value: state.library.volume,
                onChanged: (v) => state.setClick(volume: v),
                onChangeEnd: (_) => state.saveLibrary(),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(child: Text(t.sound, style: text.titleMedium)),
            DropdownButton<int>(
              value: state.library.sound,
              items: [
                // In the engine's order (see clickWave in engine.cpp).
                for (final (i, name) in [
                  t.soundBeep,
                  t.soundWood,
                  t.soundDigital,
                ].indexed)
                  DropdownMenuItem(value: i, child: Text(name)),
              ],
              onChanged: (n) => state.setClick(sound: n),
            ),
          ],
        ),
      ],
      _Panel.band => [
        Text(t.shareClick, style: text.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<ShareMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: ShareMode.solo, label: _oneLine(t.modeSolo)),
            ButtonSegment(
              value: ShareMode.leader,
              label: _oneLine(t.modeLeader),
            ),
            ButtonSegment(
              value: ShareMode.follower,
              label: _oneLine(t.modeFollower),
            ),
          ],
          selected: {state.shareMode},
          onSelectionChanged: (s) => state.setShareMode(s.first),
        ),
      ],
      _Panel.practice => [
        Row(
          children: [
            Expanded(child: Text(t.displacedClick, style: text.titleMedium)),
            if (state.displaceBars > 0)
              Text(t.displacedNow(_steps[(bar ~/ state.displaceBars) % 4])),
          ],
        ),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: 0, label: Text(t.no)),
            ButtonSegment(value: 2, label: Text(t.everyBars(2))),
            ButtonSegment(value: 3, label: Text(t.everyBars(3))),
          ],
          selected: {state.displaceBars},
          onSelectionChanged: (s) => state.setDisplacement(s.first),
        ),
        const SizedBox(height: 4),
        Text(t.displacedHelp, style: help),
        const Divider(height: 32),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.gapTrainer),
          subtitle: Text(t.gapTrainerHelp),
          value: state.gapTrainer,
          onChanged: (v) => state.setGapTrainer(enabled: v),
        ),
        if (state.gapTrainer) ...[
          _BarsRow(
            label: t.barsWithClick,
            value: state.gapPlay,
            onChanged: (n) => state.setGapTrainer(play: n),
          ),
          _BarsRow(
            label: t.barsSilent,
            value: state.gapMute,
            onChanged: (n) => state.setGapTrainer(mute: n),
          ),
        ],
        const Divider(height: 32),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.tempoRamp),
          subtitle: Text(t.tempoRampHelp),
          value: state.library.ramp,
          onChanged: (v) => state.setRamp(enabled: v),
        ),
        if (state.library.ramp) ...[
          _BarsRow(
            label: t.rampUpBpm,
            value: state.library.rampBpm,
            onChanged: (n) => state.setRamp(bpm: n),
          ),
          _BarsRow(
            label: t.rampEveryBars,
            value: state.library.rampBars,
            onChanged: (n) => state.setRamp(bars: n),
          ),
          Row(
            children: [
              Expanded(child: Text(t.rampMaxBpm)),
              RepeatIconButton(
                tooltip: t.rampMaxDown,
                onPressed: state.library.rampMax > 0
                    ? () => state.setRamp(max: stepMax(up: false))
                    : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 96,
                child: Text(
                  state.library.rampMax > 0
                      ? '${state.library.rampMax}'
                      : t.rampNoMax,
                  textAlign: TextAlign.center,
                ),
              ),
              RepeatIconButton(
                tooltip: t.rampMaxUp,
                onPressed: state.library.rampMax < 300
                    ? () => state.setRamp(max: stepMax(up: true))
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: Text(t.rampMaxStep)),
              DropdownButton<int>(
                value: state.library.rampMaxStep,
                items: [
                  for (final n in rampMaxSteps)
                    DropdownMenuItem(value: n, child: Text('$n')),
                ],
                onChanged: (n) => state.setRamp(maxStep: n),
              ),
            ],
          ),
        ],
      ],
    };
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _BarsRow extends StatelessWidget {
  const _BarsRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        DropdownButton<int>(
          value: value,
          items: [
            for (var n = 1; n <= 8; n++)
              DropdownMenuItem(value: n, child: Text('$n')),
          ],
          onChanged: (n) => onChanged(n!),
        ),
      ],
    );
  }
}
