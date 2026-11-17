// SPDX-License-Identifier: GPL-3.0-or-later
// Voice cues: a voice counts the count-in and names the next section.
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'engine.dart';
import 'song.dart';

/// Engine slot of each cue file, `assets/voices/<language>/<file>.wav`. Slots
/// 1-8 are the numbers, which the engine says in the count-in.
const cueSlots = {
  '1': 1,
  '2': 2,
  '3': 3,
  '4': 4,
  '5': 5,
  '6': 6,
  '7': 7,
  '8': 8,
  'intro': 10,
  'verse': 11,
  'pre_chorus': 12,
  'chorus': 13,
  'bridge': 14,
  'instrumental': 15,
  'solo': 16,
  'interlude': 17,
  'outro': 18,
  'ending': 19,
  'breakdown': 20,
  'tag': 21,
};

// Words a section name may use, in any of the app's languages. Pre-chorus
// comes before chorus: "pre coro" also contains "coro".
const _sectionWords = [
  ('pre_chorus', ['pre chorus', 'prechorus', 'precoro', 'pre coro']),
  ('pre_chorus', ['pre refrain', 'prerefrain']),
  ('intro', ['intro', 'introduccion', 'einleitung']),
  ('verse', ['verse', 'verso', 'estrofa', 'strophe']),
  ('chorus', ['chorus', 'coro', 'estribillo', 'refrain']),
  ('bridge', ['bridge', 'puente', 'brucke']),
  ('instrumental', ['instrumental']),
  ('solo', ['solo']),
  ('interlude', ['interlude', 'interludio', 'zwischenspiel']),
  ('outro', ['outro', 'coda']),
  ('ending', ['ending', 'final', 'ende', 'schluss']),
  ('breakdown', ['breakdown', 'break']),
  ('tag', ['tag']),
];

/// What to say before a section called [name]: its word's slot and a number
/// slot ("Verso 2" -> verse, 2; 0 = no number), or null if no cue fits.
(int, int)? sectionCue(String name) {
  final words = fold(name).replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  for (final (file, keys) in _sectionWords) {
    for (final key in keys) {
      if (RegExp('(^| )$key(\$| |[0-9])').hasMatch(words)) {
        final n = int.tryParse(RegExp(r'\d+').firstMatch(words)?[0] ?? '');
        return (cueSlots[file]!, n != null && n >= 1 && n <= 8 ? n : 0);
      }
    }
  }
  return null;
}

/// Whether a section called [name] ends the song: an ending word anywhere
/// in it ("Outro", "Coda", "Coro final").
bool endsSong(String name) {
  final words = fold(name).replaceAll(RegExp(r'[^a-z0-9]+'), ' ').split(' ');
  return _sectionWords.any(
    (entry) =>
        (entry.$1 == 'outro' || entry.$1 == 'ending') &&
        entry.$2.any(words.contains),
  );
}

/// Loads [language]'s cues into the engine; returns how many it found.
/// Slots without a file are cleared, so no other language's voice remains.
Future<int> loadCues(Engine engine, String language) async {
  var found = 0;
  for (final MapEntry(key: file, value: slot) in cueSlots.entries) {
    Uint8List? bytes;
    try {
      final data = await rootBundle.load('assets/voices/$language/$file.wav');
      bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } on FlutterError {
      // not in this build: placeholder voices are not committed
    }
    if (bytes == null) {
      engine.loadCue(slot, nullptr, 0);
      continue;
    }
    final native = malloc<Uint8>(bytes.length);
    try {
      native.asTypedList(bytes.length).setAll(0, bytes);
      if (engine.loadCue(slot, native.cast(), bytes.length)) found++;
    } finally {
      malloc.free(native);
    }
  }
  return found;
}
