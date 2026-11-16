// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'engine.dart';
import 'library.dart';
import 'share.dart';

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
  ShareChannel? _channel;

  // Practice tools: per session, not saved.
  int displaceBars = 0;
  bool gapTrainer = false;
  int gapPlay = 4;
  int gapMute = 2;

  bool get canControl => shareMode != ShareMode.follower;

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

  void setDisplacement(int bars) {
    displaceBars = bars;
    engine.setDisplacement(bars);
    notifyListeners();
  }

  void setGapTrainer({bool? enabled, int? play, int? mute}) {
    gapTrainer = enabled ?? gapTrainer;
    gapPlay = play ?? gapPlay;
    gapMute = mute ?? gapMute;
    engine.setGapTrainer(gapTrainer ? gapPlay : 0, gapTrainer ? gapMute : 0);
    notifyListeners();
  }

  void setPracticeTools(bool enabled) {
    library.practiceTools = enabled;
    // Hidden tools must not keep changing the click.
    if (!enabled) {
      setDisplacement(0);
      setGapTrainer(enabled: false);
    }
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
