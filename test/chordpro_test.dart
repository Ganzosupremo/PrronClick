// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:prronclick/chordpro.dart';
import 'package:prronclick/library.dart';
import 'package:prronclick/setlist.dart';
import 'package:prronclick/song.dart';

const bikina = '''
{title: La Bikina}
{key: Am}
{tempo: 96}
{time: 6/8}
{duration: 3:40}
{meta: nota Entra la batería sola}

{comment: Intro - 4 compases}
{start_of_verse}
[Am]Solitaria camina la bi[E7]kina
{end_of_verse}
''';

void main() {
  test('reads a song: fields from directives, the rest is lyrics', () {
    final s = parseChordPro(bikina).single;
    expect((s.name, s.key, s.bpm, s.meter), ('La Bikina', 'Am', 96, '6/8'));
    expect((s.durationSeconds, s.note), (220, 'Entra la batería sola'));
    expect(s.lyrics, startsWith('{comment: Intro'));
    expect(s.lyrics, endsWith('{end_of_verse}'));
    expect(s.lyrics, contains('[Am]Solitaria'));
  });

  test('writes what it reads, several songs per file', () {
    final other = Song(id: 'x', name: 'Vals', bpm: 140, beatsPerBar: 3);
    final first = parseChordPro(bikina).single;
    final back = parseChordPro(toChordPro([first, other]));
    expect(back, hasLength(2));
    expect(back[0].toJson()..remove('id'), first.toJson()..remove('id'));
    expect(back[1].toJson()..remove('id'), other.toJson()..remove('id'));
    expect(back[0].id, isNot(back[1].id));
  });

  test('lenient: plain text, odd values, seconds, empty file', () {
    final plain = parseChordPro('﻿Hola\r\nmundo\n', fallbackName: 'Mi');
    expect((plain.single.name, plain.single.lyrics), ('Mi', 'Hola\nmundo'));
    expect((plain.single.bpm, plain.single.meter), (120, '4/4'));

    final odd = parseChordPro(
      '{t: X}\n{tempo: 999}\n{time: 7/5}\n{duration: 90}\n{meta: artist Yo}\n'
      '{time: rápido}',
    ).single;
    expect((odd.bpm, odd.meter, odd.durationSeconds), (300, '7/4', 90));
    expect(odd.note, isNull);
    // What it does not understand stays in the text instead of vanishing.
    expect(odd.lyrics, '{meta: artist Yo}\n{time: rápido}');

    expect(parseChordPro('  \n\n'), isEmpty);
    expect(
      parseChordPro('{t: A}\n{new_song}\n{new_song}\n{t: B}'),
      hasLength(2),
    );
  });

  test('importing a song again updates ours and keeps its id', () {
    final ours = Song(id: 'mine', name: 'La bikina', bpm: 80, beatsPerBar: 4);
    final lib = Library(songs: [ours]);
    final merged = lib.mergeSong(parseChordPro(bikina).single);
    expect(lib.songs.single, same(ours));
    expect((merged.id, merged.bpm, merged.key), ('mine', 96, 'Am'));
  });

  test('a setlist travels with its songs and maps onto ours by name', () {
    final a = Song(id: 'a', name: 'Uno', bpm: 100, beatsPerBar: 4, key: 'G');
    final b = Song(id: 'b', name: 'Dos', bpm: 90, beatsPerBar: 7, beatUnit: 8);
    final theirs = Library(
      songs: [a, b],
      setlists: [
        Setlist(id: 's', name: 'Bolo', songIds: ['b', 'a', 'b'], pauseBars: 1),
      ],
    );
    final file = theirs.exportSetlist(theirs.setlists.single);

    final mine = Library(
      songs: [Song(id: 'z', name: 'uno', bpm: 50, beatsPerBar: 3)],
    );
    final got = mine.importSetlist(file)!;
    expect(got.songIds, ['b', 'z', 'b']); // "Uno" is our "uno"
    expect(got.pauseBars, 1);
    expect(
      [for (final s in mine.songs) (s.id, s.bpm, s.meter)],
      [('z', 100.0, '4/4'), ('b', 90.0, '7/8')],
    );

    // Again, after they changed it: ours is updated, not duplicated.
    theirs.setlists.single
      ..name = 'Bolo 2'
      ..songIds.removeLast();
    final again = mine.importSetlist(theirs.exportSetlist(theirs.setlists[0]));
    expect(again, same(got));
    expect(got.name, 'Bolo 2');
    expect(got.songIds, ['b', 'z']);
    expect(mine.setlists, hasLength(1));

    expect(mine.importSetlist({'songs': []}), isNull);
    expect(mine.importSetlist('hola'), isNull);
  });
}
