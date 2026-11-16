// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:material_ui/material_ui.dart';
import 'package:flutter/scheduler.dart';

import 'engine.dart';

void main() => runApp(const PrronClickApp());

class PrronClickApp extends StatelessWidget {
  const PrronClickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PrronClick',
      themeMode: ThemeMode.system,
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        brightness: Brightness.dark,
      ),
      home: const MetronomePage(),
    );
  }
}

enum Mode { solo, leader, follower }

class MetronomePage extends StatefulWidget {
  const MetronomePage({super.key});

  @override
  State<MetronomePage> createState() => _MetronomePageState();
}

class _MetronomePageState extends State<MetronomePage>
    with SingleTickerProviderStateMixin {
  final engine = Engine();
  late final Ticker ticker;
  bool audioOk = false;

  Mode mode = Mode.solo;
  int beatsPerBar = 4;
  double extraLatencyMs = 0;

  // Polled from the engine every frame.
  double tempo = 120;
  bool playing = false;
  int peers = 0;
  double beat = 0;

  bool get canControl => mode != Mode.follower;

  @override
  void initState() {
    super.initState();
    audioOk = engine.init();
    ticker = createTicker((_) {
      if (!audioOk) return;
      setState(() {
        tempo = engine.tempo();
        playing = engine.isPlaying();
        peers = engine.numPeers();
        beat = engine.beat();
      });
    })..start();
  }

  @override
  void dispose() {
    ticker.dispose();
    engine.shutdown();
    super.dispose();
  }

  void setMode(Mode m) {
    engine.setLinkEnabled(m != Mode.solo);
    setState(() => mode = m);
  }

  void setTempo(double bpm) => engine.setTempo(bpm.roundToDouble());

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!audioOk) {
      return const Scaffold(
        body: Center(child: Text('No se pudo abrir la salida de audio.')),
      );
    }
    final currentBeat = playing && beat >= 0 ? beat.floor() % beatsPerBar : -1;

    return Scaffold(
      appBar: AppBar(title: const Text('PrronClick')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<Mode>(
              segments: const [
                ButtonSegment(value: Mode.solo, label: Text('Solo')),
                ButtonSegment(value: Mode.leader, label: Text('Líder')),
                ButtonSegment(value: Mode.follower, label: Text('Seguidor')),
              ],
              selected: {mode},
              onSelectionChanged: (s) => setMode(s.first),
            ),
            const SizedBox(height: 8),
            Text(switch (mode) {
              Mode.solo => 'Sin conexión',
              Mode.leader => 'Líder · $peers conectado(s)',
              Mode.follower =>
                peers == 0 ? 'Buscando líder…' : 'Siguiendo al líder',
            }, textAlign: TextAlign.center),
            const SizedBox(height: 32),
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
                    ? () => engine.setPlaying(!playing)
                    : null,
                child: Icon(playing ? Icons.stop : Icons.play_arrow),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                const Expanded(child: Text('Compás')),
                DropdownButton<int>(
                  value: beatsPerBar,
                  items: [
                    for (final n in [2, 3, 4, 5, 6, 7])
                      DropdownMenuItem(value: n, child: Text('$n/4')),
                  ],
                  onChanged: (n) {
                    engine.setBeatsPerBar(n!);
                    setState(() => beatsPerBar = n);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Ajuste de latencia: ${extraLatencyMs.round()} ms'),
            const Text(
              'Súbelo si tu click suena tarde respecto a los demás (p. ej. con auriculares Bluetooth).',
              style: TextStyle(fontSize: 12),
            ),
            Slider(
              min: 0,
              max: 400,
              divisions: 80,
              value: extraLatencyMs,
              onChanged: (v) {
                engine.setExtraLatencyMs(v);
                setState(() => extraLatencyMs = v);
              },
            ),
          ],
        ),
      ),
    );
  }
}
