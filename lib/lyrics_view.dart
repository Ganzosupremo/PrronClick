// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:material_ui/material_ui.dart';

import 'chordpro.dart';
import 'l10n/app_localizations.dart';

/// Shows a song's ChordPro body: lyrics with their chords above them, comments
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

  static String? _section(AppLocalizations t, String directive) =>
      switch (directive) {
        'start_of_chorus' || 'soc' => t.chorus,
        'start_of_verse' || 'sov' => t.verse,
        'start_of_bridge' || 'sob' => t.bridge,
        _ => null,
      };
  static const _comments = {'comment', 'c', 'comment_italic', 'ci', 'cb'};
  // Inside a line of lyrics: a [chord], or a comment written after the words
  // (ChordPro wants directives on their own line, people do not).
  static final _inline = RegExp(
    r'\[([^\]]*)\]|\{\s*(?:comment|comment_italic|c|ci|cb)\s*:\s*([^}]*?)\s*\}',
    caseSensitive: false,
  );

  static final _word = RegExp(r'\S*\s*');

  /// One line of lyrics, each chord above the syllable it is written before.
  /// The line wraps between words; a word split by a chord stays together.
  Widget _lyricLine(
    String line,
    TextStyle plain,
    TextStyle chord,
    TextStyle comment,
  ) {
    final matches = _inline.allMatches(line).toList();
    // No chords: a single text wraps better than pieces.
    if (matches.every((m) => m.group(2) != null)) {
      var at = 0;
      final spans = <TextSpan>[];
      for (final m in matches) {
        spans.add(TextSpan(text: line.substring(at, m.start)));
        spans.add(TextSpan(text: ' ${m.group(2)} ', style: comment));
        at = m.end;
      }
      spans.add(TextSpan(text: line.substring(at)));
      return Text.rich(TextSpan(children: spans), style: plain);
    }

    final words = <Widget>[]; // what the line may wrap between
    var word = <Widget>[];
    void endWord() {
      if (word.isEmpty) return;
      words.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: word,
        ),
      );
      word = [];
    }

    // A piece of lyrics with the chord that sounds on it, if any. Spaces are
    // non-breaking so the ones at a piece's edge keep their width.
    void piece(String? chordName, String text, [TextStyle? style]) {
      final lyric = Text(text.replaceAll(' ', '\u00A0'), style: style ?? plain);
      word.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // The gap keeps a chord off the next one over a short syllable.
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(chordName ?? '', style: chord),
            ),
            lyric,
          ],
        ),
      );
      if (text.isEmpty || text.endsWith(' ')) endWord();
    }

    String? pending; // a chord waiting for the lyrics it goes over
    void lyrics(String text) {
      for (final m in _word.allMatches(text)) {
        final part = m.group(0)!;
        if (part.isEmpty) continue;
        piece(pending, part);
        pending = null;
      }
    }

    var at = 0;
    for (final m in matches) {
      lyrics(line.substring(at, m.start));
      at = m.end;
      // A chord with no lyrics under it (two in a row, or at the end).
      if (pending != null) piece(pending, '');
      pending = null;
      if (m.group(2) case final note?) {
        endWord();
        piece(null, ' $note ', comment);
        endWord();
      } else {
        pending = m.group(1);
      }
    }
    lyrics(line.substring(at));
    if (pending != null) piece(pending, '');
    endWord();
    return Wrap(crossAxisAlignment: WrapCrossAlignment.end, children: words);
  }

  List<Widget> _build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final plain = theme.textTheme.bodyLarge!;
    final chord = plain.copyWith(
      color: scheme.primary,
      fontWeight: FontWeight.bold,
    );
    final comment = plain.copyWith(
      color: scheme.onTertiaryContainer,
      backgroundColor: scheme.tertiaryContainer,
    );
    final out = <Widget>[];
    for (final line in widget.text.split('\n')) {
      final d = directive.firstMatch(line);
      if (d == null) {
        out.add(_lyricLine(line, plain, chord, comment));
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
      } else if (_section(t, name) case final section?) {
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
