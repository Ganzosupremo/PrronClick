// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prronclick/app_state.dart';
import 'package:prronclick/engine.dart';
import 'package:prronclick/l10n/app_localizations.dart';
import 'package:prronclick/library.dart';
import 'package:prronclick/main.dart';
import 'package:prronclick/song.dart';

/// The native engine's stand-in: keeps tempo, meter and play; the rest does
/// nothing.
class FakeEngine implements Engine {
  bool playing = false;
  double bpm = 120;
  int bpb = 4;
  int cuesCleared = 0;

  @override
  bool Function() get init =>
      () => true;
  @override
  bool Function() get isPlaying =>
      () => playing;
  @override
  void Function(bool) get setPlaying =>
      (on) => playing = on;
  @override
  double Function() get tempo =>
      () => bpm;
  @override
  void Function(double) get setTempo =>
      (b) => bpm = b;
  @override
  int Function() get beatsPerBar =>
      () => bpb;
  @override
  void Function(int) get setBeatsPerBar =>
      (b) => bpb = b;
  @override
  void Function() get clearCues =>
      () => cuesCleared++;
  @override
  int Function() get numPeers =>
      () => 0;
  @override
  int Function() get pendingBeatsPerBar =>
      () => 0;
  @override
  bool Function(int, Pointer<Void>, int) get loadCue =>
      (_, _, _) => false;
  @override
  bool Function() get silentNow =>
      () => false;
  @override
  ({double at, bool downbeat, bool count})? lastFelt(bool downbeatOnly) => null;

  // Every other getter is a do-nothing function (up to setBar's 8 arguments)
  // or, for the values read back, 0.
  @override
  dynamic noSuchMethod(Invocation i) => switch (i.memberName) {
    #beat ||
    #barOrigin ||
    #muteUntil ||
    #countUntil ||
    #pendingOrigin ||
    #pendingMuteBeats ||
    #pendingCountBeats ||
    #outputLatencyMs => () => 0.0,
    _ => ([a, b, c, d, e, f, g, h]) {},
  };
}

void main() {
  testWidgets('the X clears the loaded song from the metronome', (
    tester,
  ) async {
    final engine = FakeEngine();
    final song = Song(id: 's1', name: 'Vals', bpm: 90, beatsPerBar: 3);
    final state = AppState.using(
      engine,
      LibraryStore(File('${Directory.systemTemp.path}/prronclick_test.json')),
      Library()..songs.add(song),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: HomePage(state: state),
      ),
    );
    // The metronome polls the engine every frame: pump, never settle.
    Future<void> settle() async {
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    await tester.tap(find.text('Canciones'));
    await settle();
    await tester.tap(find.text('Vals'));
    await settle();
    expect(state.currentSong, song);
    expect(engine.bpm, 90);
    final close = find.byTooltip('Quitar canción y setlist');
    expect(close, findsOneWidget);

    engine.setPlaying(true);
    await tester.tap(close);
    await settle();
    expect(close, findsNothing);
    expect(state.currentSong, isNull);
    expect(state.activeSetlist, isNull);
    expect(state.showInfo.song, isNull);
    expect(engine.playing, isFalse);
    expect(engine.cuesCleared, greaterThan(0));
    expect(find.text('Vals'), findsNothing); // gone from the metronome

    await tester.pumpWidget(const SizedBox());
    state.close();
  });
}
