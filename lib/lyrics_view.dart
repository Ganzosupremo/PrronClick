// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:material_ui/material_ui.dart';

import 'chordpro.dart';

/// Shows a song's ChordPro body: lyrics with their chords in colour, comments
/// and section names set apart. Other directives are not shown.
class LyricsView extends StatefulWidget {
  const LyricsView({super.key, required this.text});

  final String text;

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  // Parsed once per text: the metronome page rebuilds on every frame.
  List<Widget>? _lines;

  @override
  void didUpdateWidget(LyricsView old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _lines = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lines = null; // theme colours may have changed
  }

  static const _sections = {
    'start_of_chorus': 'Coro',
    'soc': 'Coro',
    'start_of_verse': 'Verso',
    'sov': 'Verso',
    'start_of_bridge': 'Puente',
    'sob': 'Puente',
  };
  static const _comments = {'comment', 'c', 'comment_italic', 'ci', 'cb'};
  static final _chord = RegExp(r'\[([^\]]*)\]');

  List<Widget> _build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final plain = theme.textTheme.bodyLarge!;
    final chord = TextStyle(color: scheme.primary, fontWeight: FontWeight.bold);
    final out = <Widget>[];
    for (final line in widget.text.split('\n')) {
      final d = directive.firstMatch(line);
      if (d == null) {
        var at = 0;
        final spans = <TextSpan>[];
        for (final m in _chord.allMatches(line)) {
          spans.add(TextSpan(text: line.substring(at, m.start)));
          spans.add(TextSpan(text: '${m.group(1)} ', style: chord));
          at = m.end;
        }
        spans.add(TextSpan(text: line.substring(at)));
        out.add(Text.rich(TextSpan(children: spans), style: plain));
        continue;
      }
      final name = d.group(1)!.toLowerCase(), value = d.group(2) ?? '';
      if (_comments.contains(name) && value.isNotEmpty) {
        out.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: plain.copyWith(color: scheme.onTertiaryContainer),
            ),
          ),
        );
      } else if (_sections[name] case final section?) {
        out.add(
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              value.isEmpty ? section : value,
              style: theme.textTheme.labelLarge!.copyWith(
                color: scheme.outline,
              ),
            ),
          ),
        );
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _lines ??= _build(context),
    );
  }
}
