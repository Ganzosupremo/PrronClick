// PrronClick native engine: Ableton Link + click audio output.
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <stdbool.h>
#include <stddef.h>

#if defined(_WIN32)
#define PC_API __declspec(dllexport)
#elif defined(__APPLE__)
// iOS links the engine into the app binary; "used" keeps the linker from
// dead-stripping symbols only dart:ffi looks up.
#define PC_API __attribute__((visibility("default"), used))
#else
#define PC_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Creates the Link instance and starts the audio device. Returns false if the
// audio device could not be opened. Safe to call more than once.
PC_API bool pc_init(void);
PC_API void pc_shutdown(void);

// Solo mode = Link disabled; leader/follower = Link enabled.
PC_API void pc_set_link_enabled(bool enabled);
PC_API int pc_num_peers(void);
// UDP port Link finds its peers on (20808 is Link's own, shared with every
// other Link app). Takes effect the next time Link is enabled.
PC_API void pc_set_link_port(int port);

PC_API void pc_set_playing(bool playing);
PC_API bool pc_is_playing(void);

PC_API void pc_set_tempo(double bpm);
PC_API double pc_tempo(void);

// Bars are counted from an origin beat. Link does not share them, so the
// leader broadcasts these values and followers set them with pc_set_bar.
// While playing, a new meter starts on the next downbeat.
PC_API void pc_set_beats_per_bar(int beats);
// nextBeatsPerBar = 0 means no change is scheduled. Beats from origin up to
// muteUntil are silent (a setlist pause); nextMuteBeats is the same for the
// scheduled change, counted from nextOrigin. After the pause, beats up to
// countUntil are a count-in (another pitch); nextCountBeats is its length for
// the scheduled change.
PC_API void pc_set_bar(int beatsPerBar, double origin, double muteUntil, double countUntil,
                       int nextBeatsPerBar, double nextOrigin, double nextMuteBeats,
                       double nextCountBeats);
// The meter's lower number, applied at once. It only adds a lighter accent
// every three beats in 6/8, 9/8 and 12/8: tempo and bars count beats.
PC_API void pc_set_beat_unit(int unit);
// The song's own accents, 2 bits per beat from the first: 0 strong,
// 1 medium, 2 normal, 3 silent. Used in bars of exactly `count` beats; count
// 0 = the automatic pattern. With `next`, they wait for the scheduled change
// (the next song), if there is one.
PC_API void pc_set_accents(unsigned bits, int count, bool next);
// Voice cues. Loads an audio file's bytes (WAV, MP3, FLAC) into slot 1-63;
// slots 1-8 are the counts said in the count-in. Empty data clears it.
PC_API bool pc_load_cue(int slot, const void* data, size_t size);
// Say the count-in's numbers (slots 1-8) on its beats.
PC_API void pc_set_voice_count(bool on);
// Says `slot`, then `slot2` (0 = nothing), when the beat reaches `beat`.
// Up to 8 are kept; one on the same beat replaces the old one.
PC_API void pc_schedule_cue(double beat, int slot, int slot2);
PC_API void pc_clear_cues(void);
PC_API int pc_beats_per_bar(void);
PC_API double pc_bar_origin(void);
PC_API int pc_pending_beats_per_bar(void);  // 0 = none
PC_API double pc_pending_origin(void);
PC_API double pc_mute_until(void);
PC_API double pc_pending_mute_beats(void);
PC_API double pc_count_until(void);
PC_API double pc_pending_count_beats(void);
// Count-in bars before each song this device starts (play, or a setlist
// change); 0 = none. Followers get the leader's through pc_set_bar.
PC_API void pc_set_count_in(int bars);

// Setlists (leader or solo): at `beat`, switch to a new song: tempo and meter
// change on that downbeat, and its first pauseBars bars are silent.
// bpm <= 0 stops playback there instead (last song).
// Replaces any pending change; a later meter change replaces this one.
PC_API void pc_schedule_song(double beat, double bpm, int beatsPerBar, int pauseBars);

// The same change inside a song (a new section): no pause, no count-in.
PC_API void pc_schedule_section(double beat, double bpm, int beatsPerBar);

// This device's click, not shared: softer clicks inside each beat (1 = none,
// up to 4), volume 0..1, and timbre (0 beep, 1 wood, 2 digital).
PC_API void pc_set_subdivision(int clicksPerBeat);
PC_API void pc_set_volume(double volume);
PC_API void pc_set_sound(int sound);

// Practice tools, local to this device; 0 turns each off.
// Shift the click a 16th note every barsPerStep bars: 1, e, &, a, 1...
PC_API void pc_set_displacement(int barsPerStep);
// Click for playBars, then silence for muteBars, repeating.
PC_API void pc_set_gap_trainer(int playBars, int muteBars);

// Extra output latency to compensate (e.g. Bluetooth headphones), in ms.
// Negative if the device reports more latency than it has.
PC_API void pc_set_extra_latency_ms(double ms);

// Latency calibration for a follower while the leader plays: records the mic
// and swaps our click for a higher tone on every beat. Records up to 15 s.
// start returns false if the mic cannot be opened.
PC_API bool pc_calibration_start(void);
// Stops and returns how many ms late our clicks sound against the leader's
// (add it to the extra latency), or NaN if both were not heard clearly.
PC_API double pc_calibration_finish(void);

// Output latency the engine compensates for (measured on Android, estimated
// elsewhere), excluding the extra latency setting, in ms.
PC_API double pc_output_latency_ms(void);

// Current beat position on the session timeline (for the UI).
PC_API double pc_beat(void);

// Whether the click is muted where it is now (a pause or the gap trainer's
// silent bars), by the same rules the audio uses.
PC_API bool pc_silent_now(void);

// Vibration: microseconds until the next beat whose click sounds (only bar
// starts if downbeat_only), and its accent in *level (0 strong, 1 medium,
// 2 plain). -1 if stopped, calibrating or none in the next 16 beats.
PC_API long long pc_next_felt_beat(bool downbeat_only, int* level);

// Screen flash: the beat of the last click that sounded (only bar starts if
// downbeat_only); *flags = accent level | 4 if the bar's first | 8 if count-in.
// NaN if stopped, calibrating or none in the last 16 beats.
PC_API double pc_last_felt_beat(bool downbeat_only, int* flags);

#ifdef __cplusplus
}
#endif
