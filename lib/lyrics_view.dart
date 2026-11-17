// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'chordpro.dart';
import 'cues.dart';
import 'l10n/app_localizations.dart';
import 'song.dart';

/// Shows a song's ChordPro body: lyrics with their chords above them, comments
/// and section names set apart. Other directives are not shown. The chords
/// show [transpose] semitones moved. While [section] is set, its part of the
/// lyrics is tinted, and when it changes the page scrolls to that heading.
class LyricsView extends StatefulWidget {
  const LyricsView({
    super.key,
    required this.text,
    this.transpose = 0,
    this.section,
  });

  final String text;
  final int transpose;
  final String? section; // the song's section playing; null = stopped

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  // Parsed once per text: the metronome page rebuilds on every frame. Block
  // 0 is what comes before the first heading; heading i starts block i + 1.
  List<List<Widget>>? _blocks;

  // The headings auto-scroll can go to, and the one it went to last.
  final _headings = <(String, GlobalKey)>[];
  int _at = -1;
  bool _lit = false; // the section playing has a heading: tint it

  @override
  void initState() {
    super.initState();
    // Opened while playing: go to the section playing now, once the tile
    // has finished opening (before that the page cannot scroll that far).
    // A section change meanwhile has already gone where it should.
    _opening = Timer(const Duration(milliseconds: 300), () {
      if (_at == -1 && widget.section != null) _follow(widget.section!);
    });
  }

  Timer? _opening;

  @override
  void dispose() {
    _opening?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(LyricsView old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text || widget.section == null) {
      _at = -1; // playing again starts from the top
      _lit = false;
    }
    if (old.text != widget.text || old.transpose != widget.transpose) {
      _blocks = null;
    }
    // The same section again ("Coro", "Coro"): stay where we are.
    final section = widget.section;
    if (section != null &&
        (old.section == null || _plain(section) != _plain(old.section!))) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _follow(section));
    }
  }

  static String _plain(String s) =>
      fold(s).replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  /// Scrolls to the heading of [section]: the next one with its name after
  /// the last we went to ("Coro" twice in a song), else the first. Names
  /// match exactly, else as the same kind ("Refrain" is "Chorus"), else
  /// without the number ("Chorus 2" goes to the only "Chorus").
  void _follow(String section) {
    if (!mounted) return;
    final cue = sectionCue(section);
    List<int> where(bool Function(String name) same) => [
      for (final (i, (name, _)) in _headings.indexed)
        if (same(name)) i,
    ];
    var hits = where((name) => _plain(name) == _plain(section));
    if (hits.isEmpty && cue != null) {
      hits = where((name) => sectionCue(name) == cue);
      if (hits.isEmpty) hits = where((name) => sectionCue(name)?.$1 == cue.$1);
    }
    setState(() => _lit = hits.isNotEmpty);
    if (hits.isEmpty) return;
    _at = hits.firstWhere((i) => i > _at, orElse: () => hits.first);
    // Collapsed lyrics are not built: nothing to scroll to.
    final target = _headings[_at].$2.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      alignment: 0.1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _blocks = null; // theme colours may have changed
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
        pending = transposeChord(m.group(1)!, widget.transpose);
      }
    }
    lyrics(line.substring(at));
    if (pending != null) piece(pending, '');
    endWord();
    return Wrap(crossAxisAlignment: WrapCrossAlignment.end, children: words);
  }

  List<List<Widget>> _build(BuildContext context) {
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
    final blocks = [<Widget>[]];
    _headings.clear();
    void heading(String name, Widget child) {
      final key = GlobalKey();
      _headings.add((name, key));
      blocks.add([KeyedSubtree(key: key, child: child)]);
    }

    for (final line in widget.text.split('\n')) {
      final d = directive.firstMatch(line);
      if (d == null) {
        blocks.last.add(_lyricLine(line, plain, chord, comment));
        continue;
      }
      final name = d.group(1)!.toLowerCase(), value = d.group(2) ?? '';
      if (_comments.contains(name) && value.isNotEmpty) {
        final note = Container(
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
        );
        // People often name sections in comments: {c: Coro}. Others ("x2")
        // stay inside their section.
        if (sectionCue(value) != null) {
          heading(value, note);
        } else {
          blocks.last.add(note);
        }
      } else if (_section(t, name) case final section?) {
        final name = value.isEmpty ? section : value;
        heading(
          name,
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              name,
              style: theme.textTheme.labelLarge!.copyWith(
                color: scheme.outline,
              ),
            ),
          ),
        );
      }
    }
    return blocks;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final blocks = _blocks ??= _build(context);
    final lit = _lit ? _at + 1 : -1;
    // Every block keeps the same padding, so the tint moving shifts nothing.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, block) in blocks.indexed)
          if (block.isNotEmpty)
            Container(
              key: i == lit ? const ValueKey('section playing') : null,
              padding: const EdgeInsets.fromLTRB(8, 0, 4, 4),
              decoration: BoxDecoration(
                color: i == lit ? scheme.primary.withValues(alpha: 0.08) : null,
                border: Border(
                  left: BorderSide(
                    color: i == lit ? scheme.primary : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: block,
              ),
            ),
      ],
    );
  }
}
