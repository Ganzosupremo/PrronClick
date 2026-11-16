// SPDX-License-Identifier: GPL-3.0-or-later
// Songs as ChordPro text (https://www.chordpro.org), the format other
// musicians' apps read and write.
import 'dart:convert';

import 'song.dart';

/// A line that is only a directive: {name} or {name: value}.
final directive = RegExp(r'^\s*\{\s*([A-Za-z_]+)\s*(?::\s*(.*?))?\s*\}\s*$');

/// Reads the songs in [text] ({new_song} separates them). Title, key, tempo,
/// time, duration and "{meta: nota ...}" fill the song's fields; every other
/// line is kept as its lyrics. A file with no directives is one song named
/// [fallbackName]. Songs get fresh ids.
List<Song> parseChordPro(String text, {String fallbackName = 'Sin título'}) {
  final songs = <Song>[];
  final stamp = DateTime.now().microsecondsSinceEpoch;
  late Song song;
  late List<String> body;
  var named = false;

  void start() {
    song = Song(
      id: '$stamp-${songs.length}',
      name: songs.isEmpty ? fallbackName : '$fallbackName ${songs.length + 1}',
      bpm: 120,
      beatsPerBar: 4,
    );
    body = [];
    named = false;
  }

  void finish() {
    while (body.isNotEmpty && body.first.trim().isEmpty) {
      body.removeAt(0);
    }
    while (body.isNotEmpty && body.last.trim().isEmpty) {
      body.removeLast();
    }
    if (body.isNotEmpty) song.lyrics = body.join('\n');
    // Skip the nothing between two {new_song} or after the last one.
    if (named || body.isNotEmpty) songs.add(song);
  }

  start();
  // A byte-order mark would hide the first directive.
  for (final line in LineSplitter.split(text.replaceFirst('﻿', ''))) {
    final d = directive.firstMatch(line);
    final value = d?.group(2) ?? '';
    switch (d?.group(1)?.toLowerCase()) {
      case 'new_song' || 'ns':
        finish();
        start();
      case 'title' || 't' when value.isNotEmpty:
        song.name = value;
        named = true;
      case 'key' when value.isNotEmpty:
        song.key = value;
      case 'tempo' when double.tryParse(value) != null:
        song.bpm = double.parse(value).clamp(20, 300);
      case 'time':
        final m = RegExp(r'^(\d+)\s*/\s*(\d+)$').firstMatch(value);
        if (m == null) {
          body.add(line);
        } else {
          final unit = int.parse(m.group(2)!);
          song.beatsPerBar = int.parse(m.group(1)!).clamp(1, 16);
          song.beatUnit = beatUnits.contains(unit) ? unit : 4;
        }
      case 'duration':
        // ChordPro: "m:ss" or plain seconds.
        try {
          song.durationSeconds = value.contains(':')
              ? parseDuration(value)
              : int.parse(value);
        } on FormatException {
          body.add(line);
        }
      case 'meta' when RegExp(r'^not[ae]\s+\S').hasMatch(value):
        song.note = value.substring(4).trim();
      default:
        body.add(line);
    }
  }
  finish();
  return songs;
}

/// Writes [songs] so [parseChordPro] reads the same songs back.
String toChordPro(Iterable<Song> songs) => [
  for (final s in songs)
    [
      '{title: ${s.name}}',
      if (s.key != null) '{key: ${s.key}}',
      '{tempo: ${s.bpm.round()}}',
      '{time: ${s.meter}}',
      if (s.durationSeconds case final d?) '{duration: ${formatDuration(d)}}',
      if (s.note != null) '{meta: nota ${s.note}}',
      if (s.lyrics != null) '\n${s.lyrics}',
    ].join('\n'),
].join('\n\n{new_song}\n');
