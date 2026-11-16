// SPDX-License-Identifier: GPL-3.0-or-later

/// Note values a meter can count in: the 4 of 3/4, the 8 of 6/8.
const beatUnits = [2, 4, 8, 16];

/// Compound meters (6/8, 9/8, 12/8) are felt in threes: beats per group, or
/// 0 for no grouping. Same rule as isSubAccent in native/rules.hpp.
int accentGroup(int beats, int unit) =>
    unit == 8 && beats > 3 && beats % 3 == 0 ? 3 : 0;

/// A stretch of a song with its own length and, if set, tempo and meter.
class Section {
  Section({
    required this.name,
    required this.bars,
    this.bpm,
    this.beatsPerBar,
    this.beatUnit,
  });

  /// Returns null for an entry that is not a usable section.
  static Section? fromJson(Object? json) {
    if (json is! Map) return null;
    final name = json['name'], bars = json['bars'], bpm = json['bpm'];
    final bpb = json['beatsPerBar'], unit = json['beatUnit'];
    if (name is! String || bars is! int || bars < 1) return null;
    return Section(
      name: name,
      bars: bars.clamp(1, 999),
      bpm: bpm is num ? bpm.toDouble().clamp(20, 300) : null,
      beatsPerBar: bpb is int ? bpb.clamp(1, 16) : null,
      beatUnit: bpb is int && beatUnits.contains(unit) ? unit as int : null,
    );
  }

  String name;
  int bars;
  double? bpm; // null = the song's
  int? beatsPerBar; // null = the song's meter
  int? beatUnit; // with beatsPerBar; null = x/4

  Map<String, Object?> toJson() => {
    'name': name,
    'bars': bars,
    'bpm': ?bpm,
    'beatsPerBar': ?beatsPerBar,
    if (beatsPerBar != null) 'beatUnit': beatUnit ?? 4,
  };
}

class Song {
  Song({
    required this.id,
    required this.name,
    required this.bpm,
    required this.beatsPerBar,
    this.beatUnit = 4,
    this.durationSeconds,
    this.key,
    this.note,
    this.lyrics,
    List<Section>? sections,
  }) : sections = sections ?? [];

  /// Returns null for an entry that is not a usable song (e.g. hand-edited).
  static Song? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'], name = json['name'], bpm = json['bpm'];
    final bpb = json['beatsPerBar'], duration = json['durationSeconds'];
    final unit = json['beatUnit'];
    String? text(Object? v) => v is String && v.trim().isNotEmpty ? v : null;
    if (id is! String || name is! String || bpm is! num || bpb is! int) {
      return null;
    }
    return Song(
      id: id,
      name: name,
      bpm: bpm.toDouble().clamp(20, 300),
      beatsPerBar: bpb.clamp(1, 16),
      beatUnit: beatUnits.contains(unit) ? unit as int : 4,
      durationSeconds: duration is int && duration > 0 ? duration : null,
      key: text(json['key']),
      note: text(json['note']),
      lyrics: text(json['lyrics']),
      sections: [
        if (json['sections'] case final List list)
          for (final s in list) ?Section.fromJson(s),
      ],
    );
  }

  final String id; // setlists refer to songs by id
  String name;
  double bpm;
  int beatsPerBar;

  /// The meter's lower number. Notation only: the click is one per beat and
  /// the tempo counts those beats, whatever note they are written as.
  int beatUnit;
  int? durationSeconds; // null = no set length
  String? key; // musical key, e.g. "Am"
  String? note; // one line for the band, e.g. "drums start alone"
  String? lyrics; // ChordPro body: lyrics with [chords] and {comment: ...}

  /// Played in order, each for its bars; empty = one stretch, the whole song.
  List<Section> sections;

  String get meter => '$beatsPerBar/$beatUnit';

  // Tempo and meter of section [i]: its own, or the song's.
  double bpmAt(int i) => sections.elementAtOrNull(i)?.bpm ?? bpm;
  int beatsAt(int i) => sections.elementAtOrNull(i)?.beatsPerBar ?? beatsPerBar;
  int unitAt(int i) {
    final s = sections.elementAtOrNull(i);
    return s?.beatsPerBar == null ? beatUnit : s!.beatUnit ?? 4;
  }

  /// How long the song lasts: what its sections add up to, else the
  /// duration typed in. Null = no set length.
  int? get lengthSeconds {
    if (sections.isEmpty) return durationSeconds;
    var seconds = 0.0;
    for (final (i, s) in sections.indexed) {
      seconds += s.bars * beatsAt(i) * 60 / bpmAt(i);
    }
    return seconds.round();
  }

  /// Takes everything but the id from [other] (an imported copy).
  void copyFrom(Song other) {
    name = other.name;
    bpm = other.bpm;
    beatsPerBar = other.beatsPerBar;
    beatUnit = other.beatUnit;
    durationSeconds = other.durationSeconds;
    key = other.key;
    note = other.note;
    lyrics = other.lyrics;
    sections = [for (final s in other.sections) Section.fromJson(s.toJson())!];
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'bpm': bpm,
    'beatsPerBar': beatsPerBar,
    if (beatUnit != 4) 'beatUnit': beatUnit,
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
    'key': ?key,
    'note': ?note,
    'lyrics': ?lyrics,
    if (sections.isNotEmpty) 'sections': [for (final s in sections) s.toJson()],
  };

  String get summary {
    final d = lengthSeconds;
    return [
      '${bpm.round()} BPM',
      meter,
      if (d != null) formatDuration(d),
      ?key,
    ].join(' · ');
  }
}

const _accents = {
  'á': 'a',
  'é': 'e',
  'í': 'i',
  'ó': 'o',
  'ú': 'u',
  'ü': 'u',
  'ñ': 'n',
};

/// Lowercase without Spanish accents, so "cancion" finds "Canción".
String fold(String s) =>
    s.toLowerCase().split('').map((c) => _accents[c] ?? c).join();

/// Songs whose name has every word of [query] and, if set, that [meter]
/// ("3/4").
List<Song> filterSongs(List<Song> songs, String query, String? meter) {
  final words = fold(query).split(' ').where((w) => w.isNotEmpty).toList();
  return [
    for (final s in songs)
      if ((meter == null || s.meter == meter) &&
          words.every(fold(s.name).contains))
        s,
  ];
}

/// Tap tempo: adds a tap at [now] (ms) to [taps] and returns the BPM of the
/// last few, or null until there are two. A gap over 3 s (20 BPM) starts over.
double? tapBpm(List<int> taps, int now) {
  if (taps.isNotEmpty && now - taps.last > 3000) taps.clear();
  taps.add(now);
  if (taps.length > 5) taps.removeAt(0);
  if (taps.length < 2 || now == taps.first) return null;
  return (60000 * (taps.length - 1) / (now - taps.first)).clamp(20, 300);
}

String formatDuration(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// Parses "m:ss" or plain minutes ("3"). Empty means no duration.
/// Throws [FormatException] on anything else.
int? parseDuration(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  final parts = t.split(':');
  if (parts.length > 2) throw const FormatException();
  final minutes = int.parse(parts[0]);
  final seconds = parts.length == 2 ? int.parse(parts[1]) : 0;
  if (minutes < 0 || seconds < 0 || seconds > 59) throw const FormatException();
  final total = minutes * 60 + seconds;
  if (total == 0) throw const FormatException();
  return total;
}
