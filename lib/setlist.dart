// SPDX-License-Identifier: GPL-3.0-or-later
import 'song.dart';

class Setlist {
  Setlist({
    required this.id,
    required this.name,
    List<String>? songIds,
    this.autoAdvance = true,
    this.pauseBars = 0,
  }) : songIds = songIds ?? [];

  /// Returns null for an entry that is not a usable setlist.
  static Setlist? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'], name = json['name'], ids = json['songIds'];
    if (id is! String || name is! String) return null;
    return Setlist(
      id: id,
      name: name,
      songIds: [
        if (ids is List)
          for (final s in ids)
            if (s is String) s,
      ],
      autoAdvance: json['autoAdvance'] != false,
      pauseBars: switch (json['pauseBars']) {
        final int n when n >= 0 && n <= 16 => n,
        _ => 0,
      },
    );
  }

  final String id;
  String name;
  final List<String> songIds; // a song may appear more than once
  bool autoAdvance;

  /// Silent bars before each song that follows another automatically.
  int pauseBars;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'songIds': songIds,
    'autoAdvance': autoAdvance,
    'pauseBars': pauseBars,
  };

  /// The setlist's songs, skipping ids whose song no longer exists.
  List<Song> songsFrom(List<Song> library) {
    final byId = {for (final s in library) s.id: s};
    return [for (final id in songIds) ?byId[id]];
  }
}

/// Whole bars a song lasts at its tempo (at least one), or null if it has no
/// duration.
int? songBars(Song song) {
  final seconds = song.durationSeconds;
  if (seconds == null) return null;
  final bars = (seconds * song.bpm / 60 / song.beatsPerBar).round();
  return bars < 1 ? 1 : bars;
}
