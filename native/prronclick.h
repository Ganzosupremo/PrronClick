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

// Local only: Link does not share the bar length between peers.
PC_API void pc_set_beats_per_bar(int beats);

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
