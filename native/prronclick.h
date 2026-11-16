// PrronClick native engine: Ableton Link + click audio output.
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <stdbool.h>

#if defined(_WIN32)
#define PC_API __declspec(dllexport)
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
// scheduled change, counted from nextOrigin.
PC_API void pc_set_bar(int beatsPerBar, double origin, double muteUntil, int nextBeatsPerBar,
                       double nextOrigin, double nextMuteBeats);
PC_API int pc_beats_per_bar(void);
PC_API double pc_bar_origin(void);
PC_API int pc_pending_beats_per_bar(void);  // 0 = none
PC_API double pc_pending_origin(void);
PC_API double pc_mute_until(void);
PC_API double pc_pending_mute_beats(void);

// Setlists (leader or solo): at `beat`, switch to a new song: tempo and meter
// change on that downbeat, and its first pauseBars bars are silent.
// bpm <= 0 stops playback there instead (last song).
// Replaces any pending change; a later meter change replaces this one.
PC_API void pc_schedule_song(double beat, double bpm, int beatsPerBar, int pauseBars);

// Practice tools, local to this device; 0 turns each off.
// Shift the click a 16th note every barsPerStep bars: 1, e, &, a, 1...
PC_API void pc_set_displacement(int barsPerStep);
// Click for playBars, then silence for muteBars, repeating.
PC_API void pc_set_gap_trainer(int playBars, int muteBars);

// Extra output latency to compensate (e.g. Bluetooth headphones), in ms.
PC_API void pc_set_extra_latency_ms(double ms);

// Output latency the engine compensates for (measured on Android, estimated
// elsewhere), excluding the extra latency setting, in ms.
PC_API double pc_output_latency_ms(void);

// Current beat position on the session timeline (for the UI).
PC_API double pc_beat(void);

#ifdef __cplusplus
}
#endif
