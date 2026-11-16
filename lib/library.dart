// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'song.dart';

/// Everything the app saves: settings now, songs and setlists in later phases.
class Library {
  Library({
    this.practiceTools = false,
    this.extraLatencyMs = 0,
    this.displaceBars = 0,
    this.gapTrainer = false,
    this.gapPlay = 4,
    this.gapMute = 2,
    List<Song>? songs,
    List<Object?>? setlists,
  }) : songs = songs ?? [],
       setlists = setlists ?? [];

  factory Library.fromJson(Map<String, Object?> json) {
    final settings = (json['settings'] as Map?) ?? const {};
    // Out-of-range bar counts (hand-edited file) fall back to the defaults.
    int bars(Object? v, int fallback) =>
        v is int && v >= 1 && v <= 8 ? v : fallback;
    final displace = settings['displaceBars'];
    return Library(
      practiceTools: settings['practiceTools'] == true,
      extraLatencyMs: (settings['extraLatencyMs'] as num?)?.toDouble() ?? 0,
      displaceBars: displace == 2 || displace == 3 ? displace as int : 0,
      gapTrainer: settings['gapTrainer'] == true,
      gapPlay: bars(settings['gapPlay'], 4),
      gapMute: bars(settings['gapMute'], 2),
      songs: [
        for (final s in (json['songs'] as List?) ?? const []) ?Song.fromJson(s),
      ],
      setlists: (json['setlists'] as List?)?.toList(),
    );
  }

  bool practiceTools;
  double extraLatencyMs;
  int displaceBars; // 0, 2 or 3
  bool gapTrainer;
  int gapPlay;
  int gapMute;
  final List<Song> songs;
  // Kept as raw JSON until phase 4 gives them a model.
  final List<Object?> setlists;

  Map<String, Object?> toJson() => {
    'version': 1,
    'settings': {
      'practiceTools': practiceTools,
      'extraLatencyMs': extraLatencyMs,
      'displaceBars': displaceBars,
      'gapTrainer': gapTrainer,
      'gapPlay': gapPlay,
      'gapMute': gapMute,
    },
    'songs': [for (final s in songs) s.toJson()],
    'setlists': setlists,
  };
}

/// Saves the library as one JSON file, written atomically.
class LibraryStore {
  LibraryStore(this.file);

  final File file;
  Future<void> _pending = Future.value();

  Future<Library> load() async {
    if (!await file.exists()) return Library();
    try {
      final json = jsonDecode(await file.readAsString());
      return Library.fromJson((json as Map).cast<String, Object?>());
    } on Object {
      // Never lose a damaged file: keep it aside and start fresh.
      await file.rename('${file.path}.corrupt');
      return Library();
    }
  }

  /// Saves are queued so two quick saves never interleave.
  Future<void> save(Library library) {
    final text = jsonEncode(library.toJson());
    return _pending = _pending.then((_) async {
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(text, flush: true);
      await tmp.rename(file.path);
    });
  }
}
