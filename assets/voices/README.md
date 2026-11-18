# Voice cues

Recorded by Otoniel of [LibreTracks](https://github.com/otonielpv/LibreTracks),
who authorized PrronClick to use them (November 2026).

One folder per language (`es`, `en`); other app languages use the English
voices. In each:

- `counts/`: `1.wav` … `7.wav`, the count-in numbers (there is no 8: an
  eighth beat is silent).
- `sections/`: the section names, some also numbered (`chorus_2.wav`). The
  app uses the ones named in `cueSlots` in `lib/cues.dart`; not `refrain`
  (a "Refrain" is said as "Chorus") nor `next_song`.
- `cues/`: band calls ("Build", "Last time"…). Not used by the app yet, so not
  in the build (see `pubspec.yaml`).

Without the files the app still works: the voice settings are just disabled.
