// SPDX-License-Identifier: GPL-3.0-or-later
// Runs the real engine (it clicks out loud for a few seconds) through a song
// with sections inside a setlist, then the tempo ramp:
//   flutter test tool/sections_smoke_test.dart
// Needs the Windows debug build's engine DLL; skipped without it.
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:prronclick/app_state.dart';
import 'package:prronclick/engine.dart';
import 'package:prronclick/library.dart';
import 'package:prronclick/setlist.dart';
import 'package:prronclick/song.dart';

const dll = 'build/windows/x64/runner/Debug/prronclick_engine.dll';

Future<void> until(bool Function() done, String what) async {
  final clock = Stopwatch()..start();
  while (!done()) {
    if (clock.elapsed > const Duration(seconds: 6)) fail('never: $what');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  test('sections, then the next song, then the ramp', () async {
    final dir = await Directory.systemTemp.createTemp('prronclick_smoke');
    final a = Song(
      id: 'a',
      name: 'A',
      bpm: 240,
      beatsPerBar: 2,
      sections: [
        Section(name: 'X', bars: 2),
        Section(name: 'Y', bars: 2, bpm: 300, beatsPerBar: 3, beatUnit: 8),
      ],
    );
    final b = Song(id: 'b', name: 'B', bpm: 200, beatsPerBar: 2);
    final set = Setlist(id: 's', name: 'S', songIds: ['a', 'b']);
    final library = Library(songs: [a, b], setlists: [set], volume: 0.2);
    final state = AppState.using(
      Engine(dll),
      LibraryStore(File('${dir.path}/library.json')),
      library,
    );
    addTearDown(() async {
      state.close();
      await dir.delete(recursive: true);
    });
    final e = state.engine;
    expect(state.audioOk, isTrue);
    expect(a.lengthSeconds, 2); // 4 beats at 240 + 6 at 300

    // Voice cues: the engine decodes a real WAV; a bad file is refused.
    final wav = File('assets/voices/en/chorus.wav');
    if (wav.existsSync()) {
      final bytes = wav.readAsBytesSync();
      final native = malloc<Uint8>(bytes.length);
      native.asTypedList(bytes.length).setAll(0, bytes);
      expect(e.loadCue(13, native.cast(), bytes.length), isTrue);
      expect(e.loadCue(13, native.cast(), 10), isFalse);
      malloc.free(native);
    }
    state.setVoice(count: true, sections: true);

    state.startSetlist(set);
    expect((e.tempo(), e.beatsPerBar(), state.sectionIndex), (240, 2, 0));
    e.setPlaying(true);

    await until(() => state.showInfo.nextSection == 'Y', 'Y scheduled');
    expect(state.showInfo.section, 'X');
    expect(state.showInfo.sectionChange, 4); // two bars of 2 beats
    expect(state.showInfo.changeBeat, isNull); // not a song change

    await until(() => state.sectionIndex == 1, 'section Y playing');
    expect((e.tempo().round(), e.beatsPerBar(), state.beatUnit), (300, 3, 8));
    expect(e.barOrigin(), 4);
    expect(state.currentSong, a);

    await until(() => state.currentSong == b, 'song B playing');
    expect(e.barOrigin(), 10); // two bars of 3 beats after beat 4
    expect((e.tempo().round(), e.beatsPerBar(), state.beatUnit), (200, 2, 4));
    expect((state.sectionIndex, state.showInfo.section), (0, null));

    // Ramp: +5 BPM every bar of B (2 beats at 200 = 0.6 s), back on stop.
    state.setPracticeTools(true);
    state.setRamp(enabled: true, bpm: 5, bars: 1);
    await until(() => e.tempo().round() >= 210, 'two ramp steps');
    expect(e.tempo().round() % 5, 0);
    e.setPlaying(false);
    await until(() => e.tempo().round() == 200, 'tempo back after stopping');

    // Stopped in the middle of a song with sections: it starts over.
    state.goToSong(0);
    e.setPlaying(true);
    await until(() => state.sectionIndex == 1, 'section Y again');
    e.setPlaying(false);
    await until(() => state.sectionIndex == 0, 'back to section X');
    expect((e.tempo().round(), e.beatsPerBar()), (240, 2));

    // Tapping beats on the metronome: the loaded song keeps its accents.
    state.cycleAccent(1, 2);
    expect(state.accents, [accentStrong, accentStrong]);
    expect(state.currentSong!.accents, [accentStrong, accentStrong]);
    state.cycleAccent(1, 2); // medium
    state.cycleAccent(1, 2); // silent
    state.cycleAccent(1, 2); // normal again: the automatic pattern
    expect((state.accents, state.currentSong!.accents), (null, null));
    // The library is saved in the background: let it finish before cleanup.
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }, skip: File(dll).existsSync() ? false : 'no engine at $dll');
}
