// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:material_ui/material_ui.dart';

import 'app_state.dart';
import 'l10n/app_localizations.dart';
import 'setlists_page.dart';
import 'transfer.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.state});

  final AppState state;

  /// Each language under its own name, so anyone can find theirs.
  static const _languages = {'es': 'Español', 'en': 'English', 'de': 'Deutsch'};

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final lib = state.library;
          final small = Theme.of(context).textTheme.bodySmall;
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(t.language),
                trailing: DropdownButton<String>(
                  value: lib.language,
                  items: [
                    DropdownMenuItem(value: '', child: Text(t.languageSystem)),
                    for (final MapEntry(:key, :value) in _languages.entries)
                      DropdownMenuItem(value: key, child: Text(value)),
                  ],
                  onChanged: (code) => state.setLanguage(code!),
                ),
              ),
              const Divider(),
              SwitchListTile(
                title: Text(t.practiceTools),
                subtitle: Text(t.practiceToolsHelp),
                value: lib.practiceTools,
                onChanged: state.setPracticeTools,
              ),
              ListTile(
                title: Text(t.countIn),
                subtitle: Text(t.countInHelp),
                trailing: DropdownButton<int>(
                  value: lib.countInBars,
                  items: [
                    DropdownMenuItem(value: 0, child: Text(t.no)),
                    DropdownMenuItem(value: 1, child: Text(t.bars(1))),
                    DropdownMenuItem(value: 2, child: Text(t.bars(2))),
                  ],
                  onChanged: (n) => state.setCountIn(n!),
                ),
              ),
              SwitchListTile(
                title: Text(t.flash),
                subtitle: Text(t.flashHelp),
                value: lib.flash,
                onChanged: (v) => state.setFlash(beats: v),
              ),
              SwitchListTile(
                title: Text(t.flashCountIn),
                subtitle: Text(t.flashCountInHelp),
                value: lib.flashCountIn,
                onChanged: (v) => state.setFlash(countIn: v),
              ),
              SwitchListTile(
                title: Text(t.voiceCount),
                subtitle: Text(
                  state.voices == 0 ? t.voicesMissing : t.voiceCountHelp,
                ),
                value: lib.voiceCount,
                onChanged: state.voices == 0
                    ? null
                    : (v) => state.setVoice(count: v),
              ),
              SwitchListTile(
                title: Text(t.voiceSections),
                subtitle: Text(
                  state.voices == 0 ? t.voicesMissing : t.voiceSectionsHelp,
                ),
                value: lib.voiceSections,
                onChanged: state.voices == 0
                    ? null
                    : (v) => state.setVoice(sections: v),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.save_outlined),
                title: Text(t.backupSave),
                subtitle: Text(t.backupSaveHelp),
                onTap: () => saveBackup(context, state),
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: Text(t.backupRestore),
                subtitle: Text(t.backupRestoreHelp),
                onTap: () => restoreBackup(context, state),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: Text(
                  lib.sessionCode.isEmpty
                      ? t.sessionCode
                      : t.sessionCodeIs(lib.sessionCode),
                ),
                subtitle: Text(
                  lib.sessionCode.isEmpty
                      ? t.sessionCodeOffHelp
                      : t.sessionCodeOnHelp,
                ),
                trailing: lib.sessionCode.isEmpty
                    ? null
                    : IconButton(
                        tooltip: t.sessionCodeReset,
                        icon: const Icon(Icons.restart_alt),
                        onPressed: () => state.setSessionCode(''),
                      ),
                onTap: () async {
                  final code = await askName(
                    context,
                    title: t.sessionCode,
                    initial: lib.sessionCode,
                    label: t.sessionCodeLabel,
                  );
                  if (code != null) await state.setSessionCode(code);
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.latencyAdjust(lib.extraLatencyMs.round())),
                    const SizedBox(height: 4),
                    Text(t.latencyHelp, style: small),
                    Text(
                      t.latencyCompensated(
                        state.engine.outputLatencyMs().toStringAsFixed(1),
                      ),
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
    final t = AppLocalizations.of(context);
    final String text;
    if (result == null) {
      text = switch (error!) {
        CalibrationError.notFollowing => t.calibrateNotFollowing,
        CalibrationError.noPermission => t.calibrateNoPermission,
        CalibrationError.micFailed => t.calibrateMicFailed,
        CalibrationError.notHeard => t.calibrateNotHeard,
      };
    } else if (result.$1.abs() < 3) {
      text = t.calibrateAligned;
    } else {
      final (late, applied) = result;
      final ms = late.abs().round();
      final heard = late > 0 ? t.calibrateLate(ms) : t.calibrateEarly(ms);
      text = (late - applied).abs() < 1
          ? '$heard ${t.calibrateFixed}'
          : '$heard '
                '${t.calibrateLimit(widget.state.library.extraLatencyMs.round())}';
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListTile(
      leading: const Icon(Icons.mic_none),
      title: Text(t.calibrate),
      subtitle: Text(running ? t.calibrateListening : t.calibrateHelp),
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
