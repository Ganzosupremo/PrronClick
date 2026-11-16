// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'engine.dart';
import 'library.dart';
import 'share.dart';
import 'song.dart';

enum ShareMode { solo, leader, follower }

/// App-wide state shared by every tab. The engine's live values (tempo, beat,
/// peers) are not mirrored here: the metronome page polls them every frame.
class AppState extends ChangeNotifier {
  AppState._(this.engine, this.store, this.library) : audioOk = engine.init() {
    engine.setExtraLatencyMs(library.extraLatencyMs);
    _applyPractice();
  }

  static Future<AppState> load() async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    final store = LibraryStore(File('${dir.path}/library.json'));
    return AppState._(Engine(), store, await store.load());
  }

  final Engine engine;
  final LibraryStore store;
  final Library library;
  final bool audioOk;

  ShareMode shareMode = ShareMode.solo;
  ShareChannel? _channel;

  int get displaceBars => library.displaceBars;
  bool get gapTrainer => library.gapTrainer;
  int get gapPlay => library.gapPlay;
  int get gapMute => library.gapMute;

  bool get canControl => shareMode != ShareMode.follower;

  /// Last song loaded into the metronome (shown above the tempo).
  Song? currentSong;

  void saveSong(Song song) {
    if (!library.songs.contains(song)) library.songs.add(song);
    _libraryChanged();
  }

  void deleteSong(Song song) {
    library.songs.remove(song);
    if (currentSong == song) currentSong = null;
    _libraryChanged();
  }

  /// Sets tempo and meter from the song. While playing, the meter switches on
  /// the next downbeat.
  void loadSong(Song song) {
    engine.setTempo(song.bpm);
    engine.setBeatsPerBar(song.beatsPerBar);
    currentSong = song;
    notifyListeners();
  }

  void _libraryChanged() {
    notifyListeners();
    store.save(library);
  }

  Future<void> setShareMode(ShareMode mode) async {
    engine.setLinkEnabled(mode != ShareMode.solo);
    shareMode = mode;
    notifyListeners();
    _channel?.close();
    _channel = null;
    try {
      final channel = switch (mode) {
        ShareMode.solo => null,
        ShareMode.leader => await ShareChannel.leader(engine),
        ShareMode.follower => await ShareChannel.follower(engine),
      };
      // The user may have switched again while the socket was opening.
      if (shareMode == mode) {
        _channel = channel;
      } else {
        channel?.close();
      }
    } on SocketException catch (e) {
      // Link still syncs the beat; only bar alignment is lost.
      debugPrint('share channel unavailable: $e');
    }
  }

  // Hidden tools must not change the click, but keep their settings.
  void _applyPractice() {
    final on = library.practiceTools;
    engine.setDisplacement(on ? displaceBars : 0);
    final gap = on && gapTrainer;
    engine.setGapTrainer(gap ? gapPlay : 0, gap ? gapMute : 0);
  }

  void setDisplacement(int bars) {
    library.displaceBars = bars;
    _practiceChanged();
  }

  void setGapTrainer({bool? enabled, int? play, int? mute}) {
    library.gapTrainer = enabled ?? gapTrainer;
    library.gapPlay = play ?? gapPlay;
    library.gapMute = mute ?? gapMute;
    _practiceChanged();
  }

  void _practiceChanged() {
    _applyPractice();
    notifyListeners();
    store.save(library);
  }

  void setPracticeTools(bool enabled) {
    library.practiceTools = enabled;
    _practiceChanged();
  }

  /// Applies live while dragging; call [saveLibrary] when the drag ends.
  void setExtraLatency(double ms) {
    engine.setExtraLatencyMs(ms);
    library.extraLatencyMs = ms;
    notifyListeners();
  }

  void saveLibrary() => store.save(library);
}
