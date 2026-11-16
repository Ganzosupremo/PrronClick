// SPDX-License-Identifier: GPL-3.0-or-later

class Song {
  Song({
    required this.id,
    required this.name,
    required this.bpm,
    required this.beatsPerBar,
    this.durationSeconds,
  });

  /// Returns null for an entry that is not a usable song (e.g. hand-edited).
  static Song? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'], name = json['name'], bpm = json['bpm'];
    final bpb = json['beatsPerBar'], duration = json['durationSeconds'];
    if (id is! String || name is! String || bpm is! num || bpb is! int) {
      return null;
    }
    return Song(
      id: id,
      name: name,
      bpm: bpm.toDouble().clamp(20, 300),
      beatsPerBar: bpb.clamp(1, 16),
      durationSeconds: duration is int && duration > 0 ? duration : null,
    );
  }

  final String id; // setlists refer to songs by id
  String name;
  double bpm;
  int beatsPerBar;
  int? durationSeconds; // null = no set length

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'bpm': bpm,
    'beatsPerBar': beatsPerBar,
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
  };

  String get summary {
    final d = durationSeconds;
    return [
      '${bpm.round()} BPM',
      '$beatsPerBar/4',
      if (d != null) formatDuration(d),
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

/// Songs whose name has every word of [query] and, if set, that [meter].
List<Song> filterSongs(List<Song> songs, String query, int? meter) {
  final words = fold(query).split(' ').where((w) => w.isNotEmpty).toList();
  return [
    for (final s in songs)
      if ((meter == null || s.beatsPerBar == meter) &&
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
