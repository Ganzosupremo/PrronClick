import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prronclick/library.dart';
import 'package:prronclick/setlist.dart';
import 'package:prronclick/song.dart';

void main() {
  late Directory dir;
  late LibraryStore store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('prronclick_test');
    store = LibraryStore(File('${dir.path}/library.json'));
  });
  tearDown(() => dir.delete(recursive: true));

  test('missing file loads defaults', () async {
    final lib = await store.load();
    expect(lib.practiceTools, isFalse);
    expect(lib.extraLatencyMs, 0);
  });

  test('save then load round-trips, overwriting the previous file', () async {
    await store.save(Library(extraLatencyMs: 10));
    await store.save(
      Library(
        practiceTools: true,
        extraLatencyMs: 170,
        displaceBars: 3,
        gapTrainer: true,
        gapPlay: 6,
        gapMute: 1,
        songs: [
          Song(
            id: 'a',
            name: 'Intro',
            bpm: 96,
            beatsPerBar: 3,
            durationSeconds: 210,
          ),
        ],
      ),
    );
    final lib = await store.load();
    expect(lib.practiceTools, isTrue);
    expect(lib.extraLatencyMs, 170);
    expect(lib.displaceBars, 3);
    expect(lib.gapTrainer, isTrue);
    expect(lib.gapPlay, 6);
    expect(lib.gapMute, 1);
    expect(lib.songs.single.toJson(), {
      'id': 'a',
      'name': 'Intro',
      'bpm': 96.0,
      'beatsPerBar': 3,
      'durationSeconds': 210,
    });
    expect(File('${store.file.path}.tmp').existsSync(), isFalse);
  });

  test('corrupt file is kept aside and defaults load', () async {
    await store.file.writeAsString('{not json');
    final lib = await store.load();
    expect(lib.extraLatencyMs, 0);
    expect(File('${store.file.path}.corrupt').existsSync(), isTrue);
  });

  test('unusable song entries are skipped', () async {
    await store.file.writeAsString(
      '{"songs":[{"name":"no id"},'
      '{"id":"b","name":"Ok","bpm":500,"beatsPerBar":4}]}',
    );
    final lib = await store.load();
    expect(lib.songs.single.name, 'Ok');
    expect(lib.songs.single.bpm, 300);
  });

  test('durations parse as m:ss or minutes', () {
    expect(parseDuration(''), isNull);
    expect(parseDuration('3:05'), 185);
    expect(parseDuration('4'), 240);
    for (final bad in ['1:60', 'abc', '1:', '0:00', '1:2:3']) {
      expect(() => parseDuration(bad), throwsFormatException, reason: bad);
    }
    expect(formatDuration(185), '3:05');
  });

  test('tap tempo averages recent taps and starts over after a gap', () {
    final taps = <int>[];
    expect(tapBpm(taps, 0), isNull);
    expect(tapBpm(taps, 500), 120);
    expect(tapBpm(taps, 1000), 120);
    expect(tapBpm(taps, 5000), isNull); // 4 s later: a new count
    expect(tapBpm(taps, 5750), 80);
    expect(tapBpm([0], 10), 300); // clamped
  });

  test('song search ignores case and accents; meter filter', () {
    Song song(String name, int bpb) =>
        Song(id: name, name: name, bpm: 100, beatsPerBar: bpb);
    final songs = [
      song('Canción Triste', 4),
      song('Vals', 3),
      song('Otra canción', 3),
    ];
    List<String> names(String q, [int? m]) => [
      for (final s in filterSongs(songs, q, m)) s.name,
    ];
    expect(names('CANCION'), ['Canción Triste', 'Otra canción']);
    expect(names('cancion otra'), ['Otra canción']);
    expect(names('', 3), ['Vals', 'Otra canción']);
    expect(names('triste', 3), isEmpty);
    expect(names('  '), hasLength(3));
  });

  test('setlists round-trip and skip deleted songs', () async {
    final a = Song(id: 'a', name: 'A', bpm: 120, beatsPerBar: 4);
    final b = Song(id: 'b', name: 'B', bpm: 90, beatsPerBar: 3);
    await store.save(
      Library(
        songs: [a, b],
        setlists: [
          Setlist(
            id: 's',
            name: 'Gig',
            songIds: ['b', 'x', 'a', 'b'],
            pauseBars: 2,
            countInBars: 0,
          ),
          Setlist(id: 't', name: 'Otro'),
        ],
      ),
    );
    final lib = await store.load();
    final set = lib.setlists.first;
    expect(set.countInBars, 0); // an explicit "none", not the app setting
    expect(lib.setlists.last.countInBars, isNull);
    expect(set.name, 'Gig');
    expect(set.autoAdvance, isTrue);
    expect(set.pauseBars, 2);
    expect([for (final s in set.songsFrom(lib.songs)) s.id], ['b', 'a', 'b']);
  });

  test('song length in bars', () {
    Song song(int? secs, double bpm, int bpb) => Song(
      id: '',
      name: '',
      bpm: bpm,
      beatsPerBar: bpb,
      durationSeconds: secs,
    );
    expect(songBars(song(null, 120, 4)), isNull);
    expect(songBars(song(60, 120, 4)), 30); // 120 beats
    expect(songBars(song(200, 84, 3)), 93); // 280 beats / 3 = 93.3
    expect(songBars(song(1, 60, 4)), 1);
  });
}
