// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import 'app_state.dart';

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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canControl = state.canControl;
    final currentBeat = playing && beat >= 0
        ? (beat - origin).floor() % beatsPerBar
        : -1;
    final bar = ((beat - origin) / beatsPerBar).floor();
    final muted =
        playing &&
        state.library.practiceTools &&
        state.gapTrainer &&
        bar % (state.gapPlay + state.gapMute) >= state.gapPlay;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.activeSetlist != null)
          _SetlistBar(state: state, beat: beat, beatsPerBar: beatsPerBar),
        if (state.shareMode != ShareMode.solo)
          Center(
            child: Chip(
              avatar: const Icon(Icons.link, size: 18),
              label: Text(switch (state.shareMode) {
                ShareMode.leader => 'Líder · $peers conectado(s)',
                ShareMode.follower =>
                  peers == 0 ? 'Buscando líder…' : 'Siguiendo al líder',
                ShareMode.solo => '',
              }),
            ),
          ),
        SizedBox(
          height: 24,
          child: state.songName == null
              ? null
              : Text(
                  state.songName!,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < beatsPerBar; i++)
              Padding(
                padding: const EdgeInsets.all(6),
                child: CircleAvatar(
                  radius: i == 0 ? 18 : 14,
                  backgroundColor: i == currentBeat
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                ),
              ),
          ],
        ),
        SizedBox(
          height: 24,
          child: muted
              ? Text(
                  'Silencio',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.outline),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              tooltip: 'Bajar tempo',
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
            IconButton.filledTonal(
              tooltip: 'Subir tempo',
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
        const SizedBox(height: 16),
        Center(
          child: FloatingActionButton.large(
            tooltip: playing ? 'Parar' : 'Empezar',
            onPressed: canControl
                ? () => state.engine.setPlaying(!playing)
                : null,
            child: Icon(playing ? Icons.stop : Icons.play_arrow),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(child: Text('Compás')),
            DropdownButton<int>(
              // Show the meter the user picked even before its downbeat comes.
              value: pendingBeatsPerBar > 0 ? pendingBeatsPerBar : beatsPerBar,
              // Songs and the leader may use meters outside the short list.
              items: [
                for (final n in {
                  2,
                  3,
                  4,
                  5,
                  6,
                  7,
                  beatsPerBar,
                  if (pendingBeatsPerBar > 0) pendingBeatsPerBar,
                }.toList()..sort())
                  DropdownMenuItem(value: n, child: Text('$n/4')),
              ],
              onChanged: canControl
                  ? (n) => state.engine.setBeatsPerBar(n!)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ToolsPanel(state: state, bar: playing ? bar : 0),
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
    final songs = state.setlistSongs;
    final i = state.setlistIndex;
    final change = state.changeBeat;
    final next = i + 1 < songs.length ? songs[i + 1].name : null;
    final String status;
    if (change != null) {
      final bars = ((change - beat) / beatsPerBar).ceil();
      final when = bars <= 1 ? 'en el próximo compás' : 'en $bars compases';
      status = next == null ? 'Termina $when' : 'Sigue "$next" $when';
    } else {
      status = next == null ? 'Última canción' : 'Siguiente: $next';
    }
    final small = Theme.of(context).textTheme.bodySmall;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${state.activeSetlist!.name} · ${i + 1}/${songs.length}',
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
            IconButton(
              tooltip: 'Canción anterior',
              onPressed: i > 0 ? () => state.goToSong(i - 1) : null,
              icon: const Icon(Icons.skip_previous),
            ),
            IconButton(
              tooltip: 'Canción siguiente',
              onPressed: next != null ? () => state.goToSong(i + 1) : null,
              icon: const Icon(Icons.skip_next),
            ),
            IconButton(
              tooltip: 'Salir del setlist',
              onPressed: state.stopSetlist,
              icon: const Icon(Icons.close),
            ),
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

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: ExpansionTile(
        leading: const Icon(Icons.handyman_outlined),
        title: const Text('Herramientas'),
        shape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Compartir click'),
          const SizedBox(height: 8),
          SegmentedButton<ShareMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ShareMode.solo, label: Text('Solo')),
              ButtonSegment(value: ShareMode.leader, label: Text('Líder')),
              ButtonSegment(value: ShareMode.follower, label: Text('Seguidor')),
            ],
            selected: {state.shareMode},
            onSelectionChanged: (s) => state.setShareMode(s.first),
          ),
          if (state.library.practiceTools) ...[
            const Divider(height: 32),
            Row(
              children: [
                const Expanded(child: Text('Click desplazado')),
                if (state.displaceBars > 0)
                  Text('Ahora en: ${_steps[(bar ~/ state.displaceBars) % 4]}'),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 0, label: Text('No')),
                ButtonSegment(value: 2, label: Text('Cada 2')),
                ButtonSegment(value: 3, label: Text('Cada 3')),
              ],
              selected: {state.displaceBars},
              onSelectionChanged: (s) => state.setDisplacement(s.first),
            ),
            Text(
              'Se mueve una semicorchea cada 2 o 3 compases: 1, e, &, a.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Entrenador de tempo'),
              subtitle: const Text(
                'El click suena unos compases y luego se calla.',
              ),
              value: state.gapTrainer,
              onChanged: (v) => state.setGapTrainer(enabled: v),
            ),
            if (state.gapTrainer) ...[
              _BarsRow(
                label: 'Compases con click',
                value: state.gapPlay,
                onChanged: (n) => state.setGapTrainer(play: n),
              ),
              _BarsRow(
                label: 'Compases en silencio',
                value: state.gapMute,
                onChanged: (n) => state.setGapTrainer(mute: n),
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
