// SPDX-License-Identifier: GPL-3.0-or-later
// Songs as ChordPro text (https://www.chordpro.org), the format other
// musicians' apps read and write.
import 'dart:convert';
import 'dart:typed_data';

import 'song.dart';

/// A text file's bytes as a string: UTF-16 if it starts with that byte-order
/// mark (Windows editors' "Unicode"), else UTF-8, else Latin-1 (older ones).
String decodeText(Uint8List bytes) {
  if (bytes.length >= 2) {
    final little = bytes[0] == 0xFF && bytes[1] == 0xFE;
    if (little || (bytes[0] == 0xFE && bytes[1] == 0xFF)) {
      final data = ByteData.sublistView(bytes);
      final endian = little ? Endian.little : Endian.big;
      return String.fromCharCodes([
        for (var i = 2; i + 1 < bytes.length; i += 2) data.getUint16(i, endian),
      ]);
    }
  }
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return latin1.decode(bytes);
  }
}

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
    // Accents for another meter mean nothing: back to the automatic ones.
    if (song.accents?.length != song.beatsPerBar) song.accents = null;
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
      case 'transpose' when int.tryParse(value) != null:
        song.transpose = int.parse(value).clamp(-11, 11);
      case 'tempo' when double.tryParse(value) != null:
        song.bpm = double.parse(value).clamp(20, 300);
      case 'time':
        final m = RegExp(r'^(\d{1,3})\s*/\s*(\d{1,3})$').firstMatch(value);
        if (m == null) {
          body.add(line); // not a meter (or absurd numbers): keep the text
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
      case 'meta' when _section(value) != null:
        song.sections.add(_section(value)!);
      case 'meta' when _accents(value) != null:
        song.accents = _accents(value);
      default:
        body.add(line);
    }
  }
  finish();
  return songs;
}

// Accent symbols, one per beat: "acentos > . - x".
const _accentSymbols = ['>', '-', '.', 'x'];

List<int>? _accents(String value) {
  final m = RegExp(
    r'^(?:acentos|accents|akzente)\s+(.+)$',
    caseSensitive: false,
  ).firstMatch(value);
  if (m == null) return null;
  final levels = [
    for (final s in m.group(1)!.trim().split(RegExp(r'\s+')))
      _accentSymbols.indexOf(s.toLowerCase()),
  ];
  return levels.contains(-1) ? null : parseAccents(levels);
}

/// A click section: "seccion Name; bars[; bpm][; beats/unit]" (ChordPro has
/// nothing for these, so they travel as {meta}).
Section? _section(String value) {
  final m = RegExp(
    r'^sec[ct]i[oó]n\s+(.+)$',
    caseSensitive: false,
  ).firstMatch(value);
  final parts = [for (final p in (m?.group(1) ?? '').split(';')) p.trim()];
  final bars = parts.length < 2 ? null : int.tryParse(parts[1]);
  if (parts[0].isEmpty || bars == null || bars < 1) return null;
  final section = Section(name: parts[0], bars: bars.clamp(1, 999));
  for (final p in parts.skip(2)) {
    final meter = RegExp(r'^(\d{1,3})\s*/\s*(\d{1,3})$').firstMatch(p);
    if (meter != null) {
      final unit = int.parse(meter.group(2)!);
      section.beatsPerBar = int.parse(meter.group(1)!).clamp(1, 16);
      section.beatUnit = beatUnits.contains(unit) ? unit : 4;
    } else if (double.tryParse(p) case final bpm?) {
      section.bpm = bpm.clamp(20, 300);
    }
  }
  return section;
}

/// Writes [songs] so [parseChordPro] reads the same songs back.
String toChordPro(Iterable<Song> songs) => [
  for (final s in songs)
    [
      '{title: ${s.name}}',
      if (s.key != null) '{key: ${s.key}}',
      if (s.transpose != 0) '{transpose: ${s.transpose}}',
      '{tempo: ${s.bpm.round()}}',
      '{time: ${s.meter}}',
      if (s.durationSeconds case final d?) '{duration: ${formatDuration(d)}}',
      if (s.note != null) '{meta: nota ${s.note}}',
      if (s.accents case final a?)
        '{meta: acentos ${[for (final l in a) _accentSymbols[l]].join(' ')}}',
      for (final c in s.sections)
        '{meta: seccion ${[c.name.replaceAll(';', ','), c.bars, if (c.bpm case final bpm?) bpm.round(), if (c.beatsPerBar case final beats?) '$beats/${c.beatUnit ?? 4}'].join('; ')}}',
      if (s.lyrics != null) '\n${s.lyrics}',
    ].join('\n'),
].join('\n\n{new_song}\n');

// Chord roots, as letters or as Do-Re-Mi; spelled back with the original's
// sharps or flats, else the ones musicians use most.
const _letters = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
const _syllables = {
  'Do': 0,
  'Re': 2,
  'Mi': 4,
  'Fa': 5,
  'Sol': 7,
  'La': 9,
  'Si': 11,
};
const _sharpNames = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];
const _flatNames = [
  'C',
  'Db',
  'D',
  'Eb',
  'E',
  'F',
  'Gb',
  'G',
  'Ab',
  'A',
  'Bb',
  'B',
];
const _usualNames = [
  'C',
  'C#',
  'D',
  'Eb',
  'E',
  'F',
  'F#',
  'G',
  'Ab',
  'A',
  'Bb',
  'B',
];
final _note = RegExp(r'^(Do|Re|Mi|Fa|Sol|La|Si|[A-G])([#b♯♭]?)');
// What may follow the root: "m7b5", "maj7", "sus4", "add9", "(#9)"...; so
// "[Coda]" or "[Intro]" are left alone.
final _suffix = RegExp(
  r'^(?:maj|min|dim|aug|sus|add|alt|m|M|[0-9#b+\-°ø()^Δ,.])*$',
);

/// [chord] moved [steps] semitones ("Am7/G" +2 -> "Bm7/A"); anything that is
/// not a chord comes back as it was.
String transposeChord(String chord, int steps) {
  if (steps % 12 == 0) return chord;
  String? note(String text) {
    final m = _note.firstMatch(text);
    if (m == null || m.end != text.length) return null;
    final root = m.group(1)!, accidental = m.group(2)!;
    final sharp = accidental == '#' || accidental == '♯';
    final flat = accidental == 'b' || accidental == '♭';
    final pitch =
        (_letters[root] ?? _syllables[root]!) +
        (sharp ? 1 : 0) -
        (flat ? 1 : 0);
    final names = sharp
        ? _sharpNames
        : flat
        ? _flatNames
        : _usualNames;
    final name = names[(pitch + steps) % 12];
    if (_letters.containsKey(root)) return name;
    final latin = _syllables.keys.elementAt('CDEFGAB'.indexOf(name[0]));
    return latin + name.substring(1);
  }

  final m = RegExp(
    r'^(Do|Re|Mi|Fa|Sol|La|Si|[A-G])([#b♯♭]?)(.*?)(?:/([^/]+))?$',
  ).firstMatch(chord.trim());
  if (m == null || !_suffix.hasMatch(m.group(3)!)) return chord;
  final root = note('${m.group(1)}${m.group(2)}')!;
  final bass = m.group(4);
  if (bass == null) return '$root${m.group(3)}';
  final movedBass = note(bass);
  return movedBass == null ? chord : '$root${m.group(3)}/$movedBass';
}
