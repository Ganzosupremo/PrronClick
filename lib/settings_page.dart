// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:material_ui/material_ui.dart';

import 'app_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final lib = state.library;
          final small = Theme.of(context).textTheme.bodySmall;
          return ListView(
            children: [
              SwitchListTile(
                title: const Text('Herramientas de práctica'),
                subtitle: const Text(
                  'Muestra el click desplazado y el entrenador de tempo en el '
                  'panel de Herramientas.',
                ),
                value: lib.practiceTools,
                onChanged: state.setPracticeTools,
              ),
              ListTile(
                title: const Text('Cuenta de entrada'),
                subtitle: const Text(
                  'Compases de click en otro tono antes de cada canción. Como '
                  'Seguidor suena la cuenta del líder.',
                ),
                trailing: DropdownButton<int>(
                  value: lib.countInBars,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('No')),
                    DropdownMenuItem(value: 1, child: Text('1 compás')),
                    DropdownMenuItem(value: 2, child: Text('2 compases')),
                  ],
                  onChanged: (n) => state.setCountIn(n!),
                ),
              ),
              SwitchListTile(
                title: const Text('Flash de pantalla'),
                subtitle: const Text(
                  'El metrónomo parpadea con cada pulso. Por encima de 180 '
                  'BPM, solo en el primer pulso del compás.',
                ),
                value: lib.flash,
                onChanged: (v) => state.setFlash(beats: v),
              ),
              SwitchListTile(
                title: const Text('Flash en la cuenta de entrada'),
                subtitle: const Text(
                  'Si parpadea durante la cuenta, esté o no encendido el '
                  'flash de cada pulso.',
                ),
                value: lib.flashCountIn,
                onChanged: (v) => state.setFlash(countIn: v),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ajuste de latencia: ${lib.extraLatencyMs.round()} ms',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Súbelo si tu click suena tarde respecto a los demás '
                      '(p. ej. con auriculares Bluetooth), o calíbralo '
                      'abajo.',
                      style: small,
                    ),
                    Text(
                      'Latencia de salida ya compensada: '
                      '${state.engine.outputLatencyMs().toStringAsFixed(1)} ms',
                      style: small,
                    ),
                  ],
                ),
              ),
              Slider(
                min: -100,
                max: 400,
                divisions: 100,
                value: lib.extraLatencyMs.clamp(-100, 400),
                label: '${lib.extraLatencyMs.round()} ms',
                onChanged: state.setExtraLatency,
                onChangeEnd: (_) => state.saveLibrary(),
              ),
              _CalibrateTile(state: state),
            ],
          );
        },
      ),
    );
  }
}

class _CalibrateTile extends StatefulWidget {
  const _CalibrateTile({required this.state});

  final AppState state;

  @override
  State<_CalibrateTile> createState() => _CalibrateTileState();
}

class _CalibrateTileState extends State<_CalibrateTile> {
  bool running = false;

  Future<void> _run() async {
    setState(() => running = true);
    final (result, error) = await widget.state.calibrate();
    if (!mounted) return;
    setState(() => running = false);
    final String text;
    if (result == null) {
      text = error!;
    } else if (result.$1.abs() < 3) {
      text = 'Ya estabas alineado con el líder.';
    } else {
      final (late, applied) = result;
      final heard =
          'Sonabas ${late.abs().round()} ms ${late > 0 ? 'tarde' : 'antes'}.';
      text = (late - applied).abs() < 1
          ? '$heard Ajuste corregido.'
          : '$heard El ajuste llegó a su límite '
                '(${widget.state.library.extraLatencyMs.round()} ms); revisa '
                'la salida de audio de este dispositivo.';
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.mic_none),
      title: const Text('Calibrar con el líder'),
      subtitle: Text(
        running
            ? 'Escuchando… no toques nada durante 8 segundos.'
            : 'Con este dispositivo como Seguidor y el líder sonando cerca, '
                  'el micrófono escucha los dos clicks y ajusta la latencia. '
                  'Mejor sin otros seguidores sonando y a un tempo moderado.',
      ),
      trailing: running
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
          : null,
      onTap: running ? null : _run,
    );
  }
}
