// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'setlist.dart';
import 'song.dart';

/// Everything the app saves: settings, songs and setlists.
class Library {
  Library({
    this.practiceTools = false,
    this.extraLatencyMs = 0,
    this.displaceBars = 0,
    this.gapTrainer = false,
    this.gapPlay = 4,
    this.gapMute = 2,
    this.countInBars = 0,
    List<Song>? songs,
    List<Setlist>? setlists,
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
      countInBars: switch (settings['countInBars']) {
        final int n when n >= 0 && n <= 2 => n,
        _ => 0,
      },
      songs: [
        for (final s in (json['songs'] as List?) ?? const []) ?Song.fromJson(s),
      ],
      setlists: [
        for (final s in (json['setlists'] as List?) ?? const [])
          ?Setlist.fromJson(s),
      ],
    );
  }

  bool practiceTools;
  double extraLatencyMs;
  int displaceBars; // 0, 2 or 3
  bool gapTrainer;
  int gapPlay;
  int gapMute;
  int countInBars; // 0, 1 or 2
  final List<Song> songs;
  final List<Setlist> setlists;

  /// Adds an imported song. If we already have it (same id, else same name)
  /// ours takes its content and keeps its id, which setlists refer to.
  /// Returns the song now in the library.
  Song mergeSong(Song song) {
    final old =
        songs.where((s) => s.id == song.id).firstOrNull ??
        songs.where((s) => fold(s.name) == fold(song.name)).firstOrNull;
    if (old == null) {
      songs.add(song);
      return song;
    }
    return old..copyFrom(song);
  }

  /// A setlist as a file for another device: the setlist and its songs.
  Map<String, Object?> exportSetlist(Setlist setlist) => {
    'prronclick': 'setlist',
    'setlist': setlist.toJson(),
    'songs': [for (final s in setlist.songsFrom(songs).toSet()) s.toJson()],
  };

  /// Reads [exportSetlist]'s output: merges its songs, then adds the setlist
  /// or updates ours with the same id. Returns null if [json] is not one.
  Setlist? importSetlist(Object? json) {
    if (json is! Map || json['prronclick'] != 'setlist') return null;
    final incoming = Setlist.fromJson(json['setlist']);
    if (incoming == null) return null;
    final ids = <String, String>{}; // id in the file -> id here
    final list = json['songs'];
    for (final j in list is List ? list : const []) {
      final song = Song.fromJson(j);
      if (song != null) ids[song.id] = mergeSong(song).id;
    }
    final songIds = [for (final id in incoming.songIds) ?ids[id]];
    final old = setlists.where((s) => s.id == incoming.id).firstOrNull;
    if (old == null) {
      incoming.songIds
        ..clear()
        ..addAll(songIds);
      setlists.add(incoming);
      return incoming;
    }
    return old
      ..name = incoming.name
      ..songIds.clear()
      ..songIds.addAll(songIds)
      ..autoAdvance = incoming.autoAdvance
      ..pauseBars = incoming.pauseBars
      ..countInBars = incoming.countInBars;
  }

  Map<String, Object?> toJson() => {
    'version': 1,
    'settings': {
      'practiceTools': practiceTools,
      'extraLatencyMs': extraLatencyMs,
      'displaceBars': displaceBars,
      'gapTrainer': gapTrainer,
      'gapPlay': gapPlay,
      'gapMute': gapMute,
      'countInBars': countInBars,
    },
    'songs': [for (final s in songs) s.toJson()],
    'setlists': [for (final s in setlists) s.toJson()],
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
