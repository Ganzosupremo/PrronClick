// SPDX-License-Identifier: GPL-3.0-or-later

/// Note values a meter can count in: the 4 of 3/4, the 8 of 6/8.
const beatUnits = [2, 4, 8, 16];

/// Compound meters (6/8, 9/8, 12/8) are felt in threes: beats per group, or
/// 0 for no grouping. Same rule as isSubAccent in native/rules.hpp.
int accentGroup(int beats, int unit) =>
    unit == 8 && beats > 3 && beats % 3 == 0 ? 3 : 0;

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
  });

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

  String get meter => '$beatsPerBar/$beatUnit';

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
  };

  String get summary {
    final d = durationSeconds;
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
