import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prronclick/library.dart';
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
}
