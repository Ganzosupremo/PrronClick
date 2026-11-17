// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prronclick/chordpro.dart';
import 'package:prronclick/lyrics_view.dart';
import 'package:prronclick/share.dart';
import 'package:prronclick/song.dart';

import 'widget_test.dart' show app;

void main() {
  test('chords move by semitones, keeping how they were written', () {
    expect(transposeChord('G', 2), 'A');
    expect(transposeChord('Am7/G', 2), 'Bm7/A');
    expect(transposeChord('F#m', 1), 'Gm');
    expect(transposeChord('F#', 1), 'G');
    expect(transposeChord('C#', 1), 'D');
    expect(transposeChord('Bb', 2), 'C');
    expect(transposeChord('Eb', 1), 'E');
    expect(transposeChord('Db', 1), 'D');
    expect(transposeChord('C', 1), 'C#'); // the usual names: C#, Eb, F#, Ab, Bb
    expect(transposeChord('D', 1), 'Eb');
    expect(transposeChord('Cmaj7', -1), 'Bmaj7');
    expect(transposeChord('Cmaj7', -1 + 12), 'Bmaj7');
    expect(transposeChord('Dsus4', -2), 'Csus4');
    expect(transposeChord('E7(#9)', 5), 'A7(#9)');
    expect(transposeChord('C', 12), 'C');
  });

  test('Do-Re-Mi chords stay Do-Re-Mi', () {
    expect(transposeChord('Sol', 2), 'La');
    expect(transposeChord('Lam', 3), 'Dom');
    expect(transposeChord('Rem7/Do', 2), 'Mim7/Re');
    expect(transposeChord('Fa#', -1), 'Fa');
    expect(transposeChord('Sib', 2), 'Do');
  });

  test('what is not a chord is left alone', () {
    for (final s in ['Coda', 'Intro', 'N.C.', 'x2', '', 'Groove', 'G/x']) {
      expect(transposeChord(s, 3), s);
    }
  });

  test('the transposition is kept in the library, ChordPro and the wire', () {
    final song = Song(id: 'a', name: 'A', bpm: 100, beatsPerBar: 4)
      ..transpose = -3;
    expect(Song.fromJson(jsonDecode(jsonEncode(song.toJson())))!.transpose, -3);
    expect(Song.fromJson({...song.toJson(), 'transpose': 40})!.transpose, 0);
    expect(parseChordPro(toChordPro([song])).single.transpose, -3);

    const info = ShowInfo(song: 'A', key: 'F', transpose: 2);
    final wire = jsonDecode(jsonEncode(info.toJson())) as Map;
    expect(ShowInfo.fromMessage(wire, 0), info);
    expect(ShowInfo.fromMessage({'transpose': 'x'}, 0).transpose, 0);
  });

  testWidgets('lyrics show moved chords and scroll to the section playing', (
    tester,
  ) async {
    final text = [
      '{start_of_verse: Verso 1}',
      for (var i = 0; i < 40; i++) '[G]linea $i',
      '{c: Coro}',
      '[C]el coro',
      '{start_of_verse: Verso 2}',
      for (var i = 0; i < 40; i++) 'otra $i',
      '{soc}',
      'coro otra vez',
    ].join('\n');
    Widget page(String section) => app(
      Scaffold(
        body: ListView(
          children: [LyricsView(text: text, transpose: 2, section: section)],
        ),
      ),
    );
    await tester.pumpWidget(page('Verso 1'));
    expect(find.text('A'), findsWidgets);
    expect(find.text('G'), findsNothing);

    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    await tester.pumpWidget(page('Coro'));
    await tester.pumpAndSettle();
    final atChorus = scroll.position.pixels;
    expect(atChorus, greaterThan(0));
    expect(find.text('D'), findsOneWidget); // C + 2, on screen

    await tester.pumpWidget(page('Verso 2'));
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, greaterThan(atChorus));
    // "Chorus" again: the second chorus heading ({soc}), not the first.
    final atVerse2 = scroll.position.pixels;
    await tester.pumpWidget(page('Chorus'));
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, greaterThanOrEqualTo(atVerse2));
  });

  testWidgets('the section playing is tinted; the same one again stays', (
    tester,
  ) async {
    final text = [
      '{c: Coro}',
      'primer coro',
      '{c: x2}', // a note, not a section: still the first chorus
      'sigue el coro',
      '{c: Verso}',
      for (var i = 0; i < 40; i++) 'linea $i',
      '{c: Coro}',
      'segundo coro',
    ].join('\n');
    Widget page(String? section) => app(
      Scaffold(
        body: ListView(
          children: [LyricsView(text: text, section: section)],
        ),
      ),
    );
    final lit = find.byKey(const ValueKey('section playing'));
    Finder inLit(String s) => find.descendant(of: lit, matching: find.text(s));

    await tester.pumpWidget(page(null));
    await tester.pumpWidget(page('Coro'));
    await tester.pumpAndSettle();
    expect(inLit('primer coro'), findsOneWidget);
    expect(inLit('sigue el coro'), findsOneWidget);

    // Coro, Coro: no move to the second chorus.
    await tester.pumpWidget(page('coro'));
    await tester.pumpAndSettle();
    expect(inLit('primer coro'), findsOneWidget);

    await tester.pumpWidget(page('Verso'));
    await tester.pumpAndSettle();
    expect(inLit('linea 0'), findsOneWidget);
    await tester.pumpWidget(page('Coro'));
    await tester.pumpAndSettle();
    expect(inLit('segundo coro'), findsOneWidget);

    // A section with no heading, or stopped: nothing tinted.
    await tester.pumpWidget(page('Solo'));
    await tester.pumpAndSettle();
    expect(lit, findsNothing);
    await tester.pumpWidget(page(null));
    await tester.pumpAndSettle();
    expect(lit, findsNothing);
  });

  testWidgets('lyrics opened mid-song go to the section playing', (
    tester,
  ) async {
    final text = [
      for (var i = 0; i < 40; i++) 'linea $i',
      '{c: Puente}',
      'el puente',
    ].join('\n');
    await tester.pumpWidget(
      app(
        Scaffold(
          body: ListView(
            children: [LyricsView(text: text, section: 'Bridge')],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('el puente').hitTestable(), findsOneWidget);
  });

  testWidgets('the lyrics card stays open when a line above it goes away', (
    tester,
  ) async {
    Widget page(bool comingUp) => app(
      Scaffold(
        body: ListView(
          children: [
            if (comingUp) const Text('Next: Coro'),
            const Text('127'),
            const Card.outlined(
              key: ValueKey('lyrics'),
              child: ExpansionTile(
                key: PageStorageKey('lyrics'),
                title: Text('Letra'),
                children: [Text('la letra')],
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(page(true));
    await tester.tap(find.text('Letra'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(page(false));
    await tester.pumpAndSettle();
    expect(find.text('la letra'), findsOneWidget);
  });
}
