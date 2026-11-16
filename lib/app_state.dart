// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'engine.dart';
import 'library.dart';

enum ShareMode { solo, leader, follower }

/// App-wide state shared by every tab. The engine's live values (tempo, beat,
/// peers) are not mirrored here: the metronome page polls them every frame.
class AppState extends ChangeNotifier {
  AppState._(this.engine, this.store, this.library) : audioOk = engine.init() {
    engine.setExtraLatencyMs(library.extraLatencyMs);
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
  int beatsPerBar = 4;

  bool get canControl => shareMode != ShareMode.follower;

  void setShareMode(ShareMode mode) {
    engine.setLinkEnabled(mode != ShareMode.solo);
    shareMode = mode;
    notifyListeners();
  }

  void setBeatsPerBar(int beats) {
    engine.setBeatsPerBar(beats);
    beatsPerBar = beats;
    notifyListeners();
  }

  void setPracticeTools(bool enabled) {
    library.practiceTools = enabled;
    notifyListeners();
    store.save(library);
  }

  /// Applies live while dragging; call [saveLibrary] when the drag ends.
  void setExtraLatency(double ms) {
    engine.setExtraLatencyMs(ms);
    library.extraLatencyMs = ms;
    notifyListeners();
  }

  void saveLibrary() => store.save(library);
}
