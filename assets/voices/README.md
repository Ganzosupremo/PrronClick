# Voice cues

One folder per language (`es`, `en`, `de`), one short audio file per cue,
named as in `cueSlots` in `lib/cues.dart`: `1.wav` … `8.wav` for the count-in,
then `intro`, `verse`, `pre_chorus`, `chorus`, `bridge`, `instrumental`,
`solo`, `interlude`, `outro`, `ending`, `breakdown` and `tag`.

The WAVs here now are **placeholders** made by
`tool/make_placeholder_voices.ps1` with the Windows voices. Their license does
not allow shipping them, so git ignores them. Before a release, replace them
with recordings we may distribute (ours, or under a license compatible with
GPL-3.0) and remove the `.gitignore` line.

Without the files the app still works: the voice settings are just disabled.
