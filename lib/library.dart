// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

/// Everything the app saves: settings now, songs and setlists in later phases.
class Library {
  Library({
    this.practiceTools = false,
    this.extraLatencyMs = 0,
    List<Object?>? songs,
    List<Object?>? setlists,
  }) : songs = songs ?? [],
       setlists = setlists ?? [];

  factory Library.fromJson(Map<String, Object?> json) {
    final settings = (json['settings'] as Map?) ?? const {};
    return Library(
      practiceTools: settings['practiceTools'] == true,
      extraLatencyMs: (settings['extraLatencyMs'] as num?)?.toDouble() ?? 0,
      songs: (json['songs'] as List?)?.toList(),
      setlists: (json['setlists'] as List?)?.toList(),
    );
  }

  bool practiceTools;
  double extraLatencyMs;
  // Kept as raw JSON until phases 3 and 4 give them a model.
  final List<Object?> songs;
  final List<Object?> setlists;

  Map<String, Object?> toJson() => {
    'version': 1,
    'settings': {
      'practiceTools': practiceTools,
      'extraLatencyMs': extraLatencyMs,
    },
    'songs': songs,
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
