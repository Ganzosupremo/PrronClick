// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'practice.dart';
import 'setlist.dart';
import 'song.dart';

/// How many click timbres the engine has (see clickWave in native/engine.cpp).
const clickSoundCount = 3;

/// The app's languages; '' = the phone's.
const languages = ['es', 'en', 'de'];

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
    this.subdivision = 1,
    this.volume = 1,
    this.sound = 0,
    this.flash = false,
    this.flashCountIn = false,
    this.vibrate = false,
    this.vibrateDownbeat = false,
    this.voiceCount = false,
    this.voiceSections = false,
    this.ramp = false,
    this.rampBpm = 5,
    this.rampBars = 4,
    this.rampMax = 0,
    this.rampMaxStep = 5,
    this.sessionCode = '',
    this.language = '',
    List<Song>? songs,
    List<Setlist>? setlists,
    List<Practice>? history,
  }) : songs = songs ?? [],
       setlists = setlists ?? [],
       history = history ?? [];

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
      subdivision: switch (settings['subdivision']) {
        final int n when n >= 1 && n <= 4 => n,
        _ => 1,
      },
      volume: switch (settings['volume']) {
        final num v when v >= 0 && v <= 1 => v.toDouble(),
        _ => 1,
      },
      sound: switch (settings['sound']) {
        final int n when n >= 0 && n < clickSoundCount => n,
        _ => 0,
      },
      flash: settings['flash'] == true,
      flashCountIn: settings['flashCountIn'] == true,
      vibrate: settings['vibrate'] == true,
      vibrateDownbeat: settings['vibrateDownbeat'] == true,
      voiceCount: settings['voiceCount'] == true,
      voiceSections: settings['voiceSections'] == true,
      ramp: settings['ramp'] == true,
      rampBpm: bars(settings['rampBpm'], 5),
      rampBars: bars(settings['rampBars'], 4),
      rampMax: switch (settings['rampMax']) {
        final int n when n >= 20 && n <= 300 => n,
        _ => 0,
      },
      rampMaxStep: switch (settings['rampMaxStep']) {
        final int n when rampMaxSteps.contains(n) => n,
        _ => 5,
      },
      sessionCode: switch (settings['sessionCode']) {
        final String s when s.length <= 40 => s.trim(),
        _ => '',
      },
      language: switch (settings['language']) {
        final String code when languages.contains(code) => code,
        _ => '',
      },
      songs: [
        for (final s in (json['songs'] as List?) ?? const []) ?Song.fromJson(s),
      ],
      setlists: [
        for (final s in (json['setlists'] as List?) ?? const [])
          ?Setlist.fromJson(s),
      ],
      history: [
        for (final p in (json['history'] as List?) ?? const [])
          ?Practice.fromJson(p),
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

  // This device's click (not shared with the band).
  int subdivision; // clicks per beat, 1 = none
  double volume; // 0..1
  int sound; // index into the engine's timbres

  bool flash; // the screen flashes on each beat
  bool flashCountIn; // ...and during the count-in
  bool vibrate; // the phone vibrates on each beat that sounds
  bool vibrateDownbeat; // ...only on the bar's first

  bool voiceCount; // a voice counts the count-in
  bool voiceSections; // ...and names the next section a bar ahead

  // Tempo ramp (practice tool): +rampBpm every rampBars bars.
  bool ramp;
  int rampBpm;
  int rampBars;
  int rampMax; // the ramp stops at this tempo; 0 = no limit (300)
  int rampMaxStep; // BPM per press of its − and + buttons

  /// Only devices with the same code share a click. Empty = standard Link,
  /// which Ableton Live and other Link apps also join.
  String sessionCode;

  /// '' = the phone's language, else one of [languages].
  String language;
  final List<Song> songs;
  final List<Setlist> setlists;

  /// When the click played what, oldest first (see [Practice]).
  final List<Practice> history;

  /// Puts [p] in the history once (it is saved again as it grows), keeping
  /// the newest [maxPracticeEntries].
  void keepPractice(Practice p) {
    if (!history.contains(p)) history.add(p);
    if (history.length > maxPracticeEntries) {
      history.removeRange(0, history.length - maxPracticeEntries);
    }
  }

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
      'subdivision': subdivision,
      'volume': volume,
      'sound': sound,
      'flash': flash,
      'flashCountIn': flashCountIn,
      'vibrate': vibrate,
      'vibrateDownbeat': vibrateDownbeat,
      'voiceCount': voiceCount,
      'voiceSections': voiceSections,
      'ramp': ramp,
      'rampBpm': rampBpm,
      'rampBars': rampBars,
      'rampMax': rampMax,
      'rampMaxStep': rampMaxStep,
      'sessionCode': sessionCode,
      'language': language,
    },
    'songs': [for (final s in songs) s.toJson()],
    'setlists': [for (final s in setlists) s.toJson()],
    'history': [for (final p in history) p.toJson()],
  };
}

/// Everything in one file, to move to another device or keep safe.
Map<String, Object?> backupOf(Library library, DateTime when) => {
  'prronclick': 'backup',
  'saved': when.toIso8601String(),
  'library': library.toJson(),
};

/// The library in a [backupOf] file; null if [json] is not one.
Library? libraryFromBackup(Object? json) {
  if (json is! Map || json['prronclick'] != 'backup') return null;
  final library = json['library'];
  if (library is! Map) return null;
  try {
    return Library.fromJson(library.cast<String, Object?>());
  } on Object {
    return null; // a field of the wrong type: not a file we wrote
  }
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
      // Dated: a second damaged file must not replace the first.
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      await file.rename('${file.path}.corrupt-$stamp');
      return Library();
    }
  }

  /// Saves are queued so two quick saves never interleave. A failed one does
  /// not stop the ones after it (it is reported to the caller only).
  Future<void> save(Library library) {
    final text = jsonEncode(library.toJson());
    return _pending = _pending.catchError((_) {}).then((_) async {
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(text, flush: true);
      await tmp.rename(file.path);
    });
  }
}
