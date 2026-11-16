import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prronclick/library.dart';

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
          {'name': 'Intro'},
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
    expect(lib.songs, [
      {'name': 'Intro'},
    ]);
    expect(File('${store.file.path}.tmp').existsSync(), isFalse);
  });

  test('corrupt file is kept aside and defaults load', () async {
    await store.file.writeAsString('{not json');
    final lib = await store.load();
    expect(lib.extraLatencyMs, 0);
    expect(File('${store.file.path}.corrupt').existsSync(), isTrue);
  });
}
