// SPDX-License-Identifier: GPL-3.0-or-later
// Voice cues: a voice counts the count-in and names the next section.
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'engine.dart';
import 'song.dart';

/// Languages with voices; any other app language uses English ones.
const voiceLanguages = ['es', 'en'];

/// Engine slot of each cue file: numbers 1-8 (which the engine says in the
/// count-in) in `assets/voices/<language>/counts/`, the rest in `sections/`.
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
  'post_chorus': 22,
  'guitar_solo': 23,
  'bass_solo': 24,
  'drum_solo': 25,
  'acapella': 26,
  'rap': 27,
  'vamp': 28,
  'turnaround': 29,
  'exhortation': 30,
  // Numbered recordings ("Chorus 2" in one word); other numbers are said
  // as the word, then the count.
  'verse_1': 31,
  'verse_2': 32,
  'verse_3': 33,
  'verse_4': 34,
  'verse_5': 35,
  'verse_6': 36,
  'pre_chorus_1': 37,
  'pre_chorus_2': 38,
  'pre_chorus_3': 39,
  'pre_chorus_4': 40,
  'chorus_1': 41,
  'chorus_2': 42,
  'chorus_3': 43,
  'chorus_4': 44,
  'bridge_1': 45,
  'bridge_2': 46,
  'bridge_3': 47,
  'bridge_4': 48,
};

/// The slots to say for [cue] (from [sectionCue]): the word's own numbered
/// recording if there is one, else the word, then the number.
(int, int) cueToSay((int, int) cue) {
  final (slot, n) = cue;
  final word = cueSlots.entries.firstWhere((e) => e.value == slot).key;
  final numbered = cueSlots['${word}_$n'];
  return numbered != null ? (numbered, 0) : cue;
}

// Words a section name may use, in any of the app's languages. Longer names
// come first: "pre coro" and "post coro" also contain "coro", "solo de
// guitarra" contains "solo".
const _sectionWords = [
  ('pre_chorus', ['pre chorus', 'prechorus', 'precoro', 'pre coro']),
  ('pre_chorus', ['pre refrain', 'prerefrain']),
  ('post_chorus', ['post chorus', 'postchorus', 'postcoro', 'post coro']),
  ('guitar_solo', ['guitar solo', 'solo de guitarra', 'gitarrensolo']),
  ('bass_solo', ['bass solo', 'solo de bajo', 'basssolo']),
  ('drum_solo', ['drum solo', 'solo de bateria', 'schlagzeugsolo']),
  ('acapella', ['acapella', 'a capella', 'a cappella', 'acappella']),
  ('rap', ['rap']),
  ('vamp', ['vamp']),
  ('turnaround', ['turnaround']),
  ('exhortation', ['exhortation', 'exhortacion']),
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
      final folder = slot <= 8 ? 'counts' : 'sections';
      final data = await rootBundle.load(
        'assets/voices/$language/$folder/$file.wav',
      );
      bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } on FlutterError {
      // no recording for this cue (there is no "8"): it stays silent
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
