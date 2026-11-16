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
    final beatsPerBar = state.beatsPerBar;
    final currentBeat = playing && beat >= 0 ? beat.floor() % beatsPerBar : -1;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
        const SizedBox(height: 24),
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
        const SizedBox(height: 32),
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
              value: beatsPerBar,
              items: [
                for (final n in [2, 3, 4, 5, 6, 7])
                  DropdownMenuItem(value: n, child: Text('$n/4')),
              ],
              onChanged: (n) => state.setBeatsPerBar(n!),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ToolsPanel(state: state),
      ],
    );
  }
}

class _ToolsPanel extends StatelessWidget {
  const _ToolsPanel({required this.state});

  final AppState state;

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
            const Text('Herramientas de práctica'),
            const SizedBox(height: 4),
            // shortcut: placeholder until phase 2 adds them to the engine.
            Text(
              'Click desplazado y entrenador de tempo: llegan en la próxima fase.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
