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
                      '(p. ej. con auriculares Bluetooth).',
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
                min: 0,
                max: 400,
                divisions: 80,
                value: lib.extraLatencyMs.clamp(0, 400),
                label: '${lib.extraLatencyMs.round()} ms',
                onChanged: state.setExtraLatency,
                onChangeEnd: (_) => state.saveLibrary(),
              ),
            ],
          );
        },
      ),
    );
  }
}
