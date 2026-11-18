// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import 'accent_circles.dart';
import 'app_state.dart';
import 'l10n/app_localizations.dart';
import 'lyrics_view.dart';
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

    // Screen flash: bright on the beat, gone a third of a beat later. Above
    // 180 BPM only the bar's first beat flashes: more than three flashes a
    // second can trigger seizures.
    final lib = state.library;
    final first = currentBeat == 0;
    final intoBeat = (beat - origin) - (beat - origin).floorToDouble();
    final flashing =
        currentBeat >= 0 &&
        beat >= origin &&
        !paused &&
        !muted &&
        (counting ? lib.flashCountIn : lib.flash) &&
        (first || tempo <= 180);
    final flash = flashing
        ? (1 - intoBeat * 3).clamp(0.0, 1.0) * (first ? 0.5 : 0.3)
        : 0.0;

    final page = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.showInfo.setlist != null)
          _SetlistBar(state: state, beat: beat, beatsPerBar: beatsPerBar),
        if (state.shareMode != ShareMode.solo)
          Center(
            child: Chip(
              avatar: const Icon(Icons.link, size: 18),
              label: Text(switch (state.shareMode) {
                ShareMode.leader => t.leaderPeers(peers),
                ShareMode.follower =>
                  peers == 0 ? t.searchingLeader : t.followingLeader,
                ShareMode.solo => '',
              }),
            ),
          ),
        SizedBox(
          height: 24,
          child: state.showInfo.song == null
              ? null
              : Text(
                  state.showInfo.song!,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
        ),
        if (aboutSong.isNotEmpty)
          Text(
            aboutSong,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: scheme.tertiary),
          ),
        if (comingUp != null)
          Text(
            comingUp,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        // The count-in always counts plainly (see accentLevel in rules.hpp).
        AccentCircles(
          levels: !counting && accents?.length == beatsPerBar
              ? accents!
              : defaultAccents(beatsPerBar, info.beatUnit),
          current: currentBeat,
          onTap: canControl ? (i) => state.cycleAccent(i, beatsPerBar) : null,
        ),
        SizedBox(
          height: 24,
          child: muted || paused || counting
              ? Text(
                  paused
                      ? t.statusPause
                      : counting
                      ? t.countIn
                      : t.statusSilence,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.outline),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RepeatIconButton(
              filledTonal: true,
              tooltip: t.tempoDown,
              onPressed: canControl ? () => setTempo(tempo - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 160,
              child: Text(
                tempo.round().toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge,
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
        const Text('BPM', textAlign: TextAlign.center),
        Slider(
          min: 20,
          max: 300,
          value: tempo.clamp(20, 300),
          label: tempo.round().toString(),
          onChanged: canControl ? setTempo : null,
        ),
        Center(
          child: OutlinedButton.icon(
            onPressed: canControl ? _tap : null,
            icon: const Icon(Icons.touch_app_outlined),
            label: Text(t.tapTempo),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: FloatingActionButton.large(
            heroTag:
                null, // every tab has a FAB in the same route: no shared tag
            tooltip: playing ? t.stop : t.start,
            onPressed: canControl
                ? () => state.engine.setPlaying(!playing)
                : null,
            child: Icon(playing ? Icons.stop : Icons.play_arrow),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Text(t.meter)),
            OutlinedButton(
              onPressed: canControl
                  ? () => _pickMeter(shownBeats, info.beatUnit)
                  : null,
              child: Text('$shownBeats/${info.beatUnit}'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ToolsPanel(state: state, bar: playing ? bar : 0),
        if (lyrics != null)
          // Keyed: lines above come and go ("Next: ..."), and without a key
          // the list would rebuild the card closed.
          Card.outlined(
            key: const ValueKey('lyrics'),
            child: ExpansionTile(
              key: const PageStorageKey('lyrics'),
              leading: const Icon(Icons.lyrics_outlined),
              title: Text(t.lyrics),
              shape: const Border(),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(t.transpose)),
                    IconButton(
                      tooltip: t.transposeDown,
                      onPressed: canControl && info.transpose > -11
                          ? () => state.setTranspose(info.transpose - 1)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    SizedBox(
                      width: 72,
                      child: Text(
                        [
                          info.transpose > 0
                              ? '+${info.transpose}'
                              : '${info.transpose}',
                          ?info.key,
                        ].join(' · '),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      tooltip: t.transposeUp,
                      onPressed: canControl && info.transpose < 11
                          ? () => state.setTranspose(info.transpose + 1)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                LyricsView(
                  text: lyrics,
                  transpose: info.transpose,
                  section: playing ? info.section : null,
                ),
              ],
            ),
          ),
      ],
    );
    return Stack(
      children: [
        page,
        if (flash > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: (first ? scheme.primary : scheme.tertiary).withValues(
                  alpha: flash,
                ),
              ),
            ),
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

class _ToolsPanel extends StatelessWidget {
  const _ToolsPanel({required this.state, required this.bar});

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
    int stepMax({required bool up}) => stepRampMax(
      state.library.rampMax,
      state.library.rampMaxStep,
      up: up,
      tempo: state.engine.tempo(),
    );
    return Card.outlined(
      child: ExpansionTile(
        leading: const Icon(Icons.handyman_outlined),
        title: Text(t.tools),
        shape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.shareClick),
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
          const Divider(height: 32),
          Text(t.myClick),
          Text(t.myClickHelp, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(t.subdivision),
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
              Text(t.volume),
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
              Expanded(child: Text(t.sound)),
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
          if (state.library.practiceTools) ...[
            const Divider(height: 32),
            Row(
              children: [
                Expanded(child: Text(t.displacedClick)),
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
            Text(t.displacedHelp, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
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
        ],
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
