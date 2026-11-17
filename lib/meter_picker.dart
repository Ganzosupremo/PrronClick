// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import 'l10n/app_localizations.dart';
import 'song.dart';

/// Lets the user scroll to any meter; returns (beats, unit), or null if
/// dismissed.
Future<(int, int)?> pickMeter(BuildContext context, int beats, int unit) =>
    showModalBottomSheet<(int, int)>(
      context: context,
      // Its own height, not the default 9/16 of the screen; scrolls if short.
      isScrollControlled: true,
      builder: (_) => _MeterSheet(beats: beats, unit: unit),
    );

class _MeterSheet extends StatefulWidget {
  const _MeterSheet({required this.beats, required this.unit});

  final int beats;
  final int unit;

  @override
  State<_MeterSheet> createState() => _MeterSheetState();
}

class _MeterSheetState extends State<_MeterSheet> {
  static final _beats = List.generate(16, (i) => i + 1);

  late int beats = widget.beats;
  late int unit = widget.unit;
  late final _beatsWheel = FixedExtentScrollController(
    initialItem: _beats.indexOf(beats),
  );
  late final _unitWheel = FixedExtentScrollController(
    initialItem: beatUnits.indexOf(unit),
  );

  @override
  void dispose() {
    _beatsWheel.dispose();
    _unitWheel.dispose();
    super.dispose();
  }

  Widget _wheel(
    String label,
    List<int> values,
    FixedExtentScrollController controller,
    ValueChanged<int> onChanged,
  ) {
    final theme = Theme.of(context);
    return Semantics(
      label: label,
      child: SizedBox(
        width: 96,
        height: 176,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Marks the selected row.
            Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: theme.colorScheme.outline),
                ),
              ),
            ),
            ListWheelScrollView.useDelegate(
              controller: controller,
              itemExtent: 48,
              physics: const FixedExtentScrollPhysics(),
              overAndUnderCenterOpacity: 0.35,
              onSelectedItemChanged: (i) =>
                  setState(() => onChanged(values[i])),
              childDelegate: ListWheelChildListDelegate(
                children: [
                  for (final v in values)
                    Center(
                      child: Text('$v', style: theme.textTheme.headlineMedium),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.meter, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            // The wheels also follow a mouse drag (desktop).
            ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: PointerDeviceKind.values.toSet(),
                scrollbars: false,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _wheel(t.beatsPerBar, _beats, _beatsWheel, (v) {
                    beats = v;
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '/',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  _wheel(t.beatUnit, beatUnits, _unitWheel, (v) {
                    unit = v;
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.meterHelp,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(context, (beats, unit)),
              child: Text(t.useMeter('$beats/$unit')),
            ),
          ],
        ),
      ),
    );
  }
}
