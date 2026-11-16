// SPDX-License-Identifier: GPL-3.0-or-later
#include "prronclick.h"

#include <ableton/Link.hpp>

#include "miniaudio.h"
#include "rules.hpp"

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cmath>
#include <memory>
#include <mutex>

#if defined(__ANDROID__)
#include <dlfcn.h>
#include <time.h>
#endif

namespace {

using std::chrono::microseconds;

constexpr double kPi = 3.14159265358979323846;
constexpr double kClickSeconds = 0.03;
constexpr double kAccentHz = 1600.0;
constexpr double kBeatHz = 1000.0;
// Link's own bar/phase is unused: peers' beat numbers differ by an integer, so
// bars come from our origin (shared by the leader) and Link only aligns beats.
constexpr double kQuantum = 1.0;

// Bar settings plus a change scheduled at a future beat, so every peer switches
// meter on the same downbeat.
struct BarConfig {
  pc::Rules rules;
  bool hasPending = false;
  int pendingBeatsPerBar = 4;
  double pendingOrigin = 0.0;
  // Setlists: the pending change is a new song, so the tempo changes (or the
  // music stops, if pendingBpm <= 0) on the same beat. Leader only: followers
  // get the tempo through Link.
  bool pendingSong = false;
  double pendingBpm = 0.0;
  unsigned songChangeId = 0;  // bumped per schedule so it is applied once

  void applyPendingAt(double beat) {
    if (hasPending && beat >= pendingOrigin) {
      rules.beatsPerBar = pendingBeatsPerBar;
      rules.origin = pendingOrigin;
      hasPending = false;
    }
  }
};

struct Engine {
  ableton::Link link{120.0};
  ma_device device{};
  double sampleRate = 48000.0;
  std::mutex configMutex;
  BarConfig config;  // guarded by configMutex
  std::atomic<double> extraLatencyMicros{0.0};
  std::atomic<double> outputLatencyMicros{0.0};

  // Audio thread only.
  BarConfig audioConfig;
  unsigned appliedSongChangeId = 0;
  double lastBeat = -1.0;
  double clickFreq = 0.0;
  long clickSample = 0;
  long clickLength = 0;
};

// Raw pointer on purpose: a static destructor would tear down the audio and Link
// threads while the DLL unloads, which deadlocks and leaves the process running
// after its window closes. Without pc_shutdown the OS reclaims it on exit.
Engine* g = nullptr;

#if defined(__ANDROID__)
// AAudio is loaded at runtime (miniaudio does the same) so the app still runs
// where it is missing; we then keep the buffer-size estimate.
using GetTimestampFn = int32_t (*)(void*, clockid_t, int64_t*, int64_t*);
using GetFramesWrittenFn = int64_t (*)(void*);
GetTimestampFn aaudioGetTimestamp = nullptr;
GetFramesWrittenFn aaudioGetFramesWritten = nullptr;

int64_t nowNanos(clockid_t clock) {
  timespec ts{};
  clock_gettime(clock, &ts);
  return ts.tv_sec * 1000000000LL + ts.tv_nsec;
}

// Measures how long until the first frame of the buffer being rendered now is
// heard, from the time the DAC presented a known frame. Returns false if AAudio
// cannot tell yet (e.g. right after start).
bool measuredLatencyMicros(Engine& e, double& out) {
  if (!aaudioGetTimestamp || e.device.pContext->backend != ma_backend_aaudio) return false;
  void* stream = e.device.aaudio.pStreamPlayback;
  int64_t framePos = 0, timeNs = 0;
  if (!stream || aaudioGetTimestamp(stream, CLOCK_MONOTONIC, &framePos, &timeNs) != 0) {
    return false;
  }
  const int64_t nextFrame = aaudioGetFramesWritten(stream);
  const double presentNs = timeNs + (nextFrame - framePos) * 1e9 / e.device.playback.internalSampleRate;
  out = (presentNs - nowNanos(CLOCK_MONOTONIC)) / 1000.0;
  return out > 0.0 && out < 500000.0;
}
#endif

void render(ma_device* device, void* output, const void*, ma_uint32 frames) {
  auto& e = *static_cast<Engine*>(device->pUserData);
  auto* out = static_cast<float*>(output);
  const ma_uint32 channels = device->playback.channels;

#if defined(__ANDROID__)
  double measured = 0.0;
  if (measuredLatencyMicros(e, measured)) {
    // Smooth timestamp jitter so clicks don't wobble.
    const double prev = e.outputLatencyMicros.load();
    e.outputLatencyMicros = prev + 0.05 * (measured - prev);
  }
#endif

  auto state = e.link.captureAudioSessionState();
  // Time at which the first frame of this buffer reaches the speaker.
  const auto hostTime =
      e.link.clock().micros() +
      microseconds(std::llround(e.outputLatencyMicros + e.extraLatencyMicros.load()));

  // Never block the audio thread: if the UI holds the lock, keep last buffer's copy.
  if (e.configMutex.try_lock()) {
    if (state.isPlaying()) e.config.applyPendingAt(state.beatAtTime(hostTime, kQuantum));
    e.audioConfig = e.config;
    e.configMutex.unlock();
  }
  auto& cfg = e.audioConfig;
  const double microsPerFrame = 1e6 / e.sampleRate;

  // A song change due within this buffer: pivot the shared timeline on its
  // first beat. Beats rendered so far stay put; the rest follow the new tempo.
  if (state.isPlaying() && cfg.hasPending && cfg.pendingSong &&
      cfg.songChangeId != e.appliedSongChangeId) {
    const auto bufferEnd = hostTime + microseconds(std::llround(frames * microsPerFrame));
    if (state.beatAtTime(bufferEnd, kQuantum) >= cfg.pendingOrigin) {
      const auto at = state.timeAtBeat(cfg.pendingOrigin, kQuantum);
      if (cfg.pendingBpm > 0.0) {
        state.setTempo(cfg.pendingBpm, at);
      } else {
        state.setIsPlaying(false, at);
      }
      e.link.commitAudioSessionState(state);
      e.appliedSongChangeId = cfg.songChangeId;
    }
  }

  for (ma_uint32 i = 0; i < frames; ++i) {
    if (state.isPlaying()) {
      const auto t = hostTime + microseconds(std::llround(i * microsPerFrame));
      const double beat = state.beatAtTime(t, kQuantum);
      cfg.applyPendingAt(beat);
      if (beat >= 0.0 && pc::crosses(cfg.rules, e.lastBeat, beat)) {
        const double coord = std::floor(pc::clickCoord(cfg.rules, beat));
        if (!pc::isMuted(cfg.rules, coord)) {
          e.clickFreq = pc::isAccent(cfg.rules, coord) ? kAccentHz : kBeatHz;
          e.clickSample = 0;
          e.clickLength = static_cast<long>(kClickSeconds * e.sampleRate);
        }
      }
      e.lastBeat = beat;
    } else {
      e.lastBeat = -1.0;
    }

    float sample = 0.0f;
    if (e.clickSample < e.clickLength) {
      const double t = e.clickSample / e.sampleRate;
      sample = static_cast<float>(0.6 * std::sin(2.0 * kPi * e.clickFreq * t) *
                                  std::exp(-t * 150.0));
      ++e.clickSample;
    }
    for (ma_uint32 c = 0; c < channels; ++c) {
      out[i * channels + c] = sample;
    }
  }
}

}  // namespace

extern "C" {

bool pc_init(void) {
  if (g) return true;
#if defined(__ANDROID__)
  if (void* aaudio = dlopen("libaaudio.so", RTLD_NOW)) {
    aaudioGetTimestamp =
        reinterpret_cast<GetTimestampFn>(dlsym(aaudio, "AAudioStream_getTimestamp"));
    aaudioGetFramesWritten =
        reinterpret_cast<GetFramesWrittenFn>(dlsym(aaudio, "AAudioStream_getFramesWritten"));
    if (!aaudioGetFramesWritten) aaudioGetTimestamp = nullptr;
  }
#endif
  auto e = std::make_unique<Engine>();
  e->link.enableStartStopSync(true);

  ma_device_config config = ma_device_config_init(ma_device_type_playback);
  config.playback.format = ma_format_f32;
  config.playback.channels = 2;
  config.sampleRate = 0;  // device native rate
  config.performanceProfile = ma_performance_profile_low_latency;
  config.dataCallback = render;
#if defined(__ANDROID__)
  // Our callback must run straight from the backend's, so frames written by
  // AAudio line up with the buffer being rendered.
  config.noFixedSizedCallback = MA_TRUE;
#endif
  config.pUserData = e.get();

  if (ma_device_init(nullptr, &config, &e->device) != MA_SUCCESS) return false;
  e->sampleRate = e->device.sampleRate;
  // shortcut: buffer-size estimate of output latency; ignores mixer/DAC delay.
  // Android replaces it with the AAudio-measured latency once audio runs;
  // Windows and iOS still need their measured latency (WASAPI clock /
  // AVAudioSession.outputLatency) if clicks land late against other devices.
  e->outputLatencyMicros = 1e6 * e->device.playback.internalPeriodSizeInFrames *
                           e->device.playback.internalPeriods /
                           e->device.playback.internalSampleRate;
  if (ma_device_start(&e->device) != MA_SUCCESS) {
    ma_device_uninit(&e->device);
    return false;
  }
  g = e.release();
  return true;
}

void pc_shutdown(void) {
  if (!g) return;
  ma_device_uninit(&g->device);
  delete g;
  g = nullptr;
}

void pc_set_link_enabled(bool enabled) {
  if (g) g->link.enable(enabled);
}

int pc_num_peers(void) {
  return g ? static_cast<int>(g->link.numPeers()) : 0;
}

void pc_set_playing(bool playing) {
  if (!g) return;
  auto state = g->link.captureAppSessionState();
  const auto now = g->link.clock().micros();
  if (playing) {
    // Beat 0 lands on the next shared beat; the bar starts there.
    state.setIsPlayingAndRequestBeatAtTime(true, now, 0.0, kQuantum);
    std::lock_guard<std::mutex> lock(g->configMutex);
    g->config.rules.origin = 0.0;
    g->config.hasPending = false;
  } else {
    state.setIsPlaying(false, now);
  }
  g->link.commitAppSessionState(state);
}

bool pc_is_playing(void) {
  return g && g->link.captureAppSessionState().isPlaying();
}

void pc_set_tempo(double bpm) {
  if (!g) return;
  auto state = g->link.captureAppSessionState();
  state.setTempo(std::clamp(bpm, 20.0, 300.0), g->link.clock().micros());
  g->link.commitAppSessionState(state);
}

double pc_tempo(void) {
  return g ? g->link.captureAppSessionState().tempo() : 120.0;
}

void pc_set_beats_per_bar(int beats) {
  if (!g) return;
  beats = std::clamp(beats, 1, 16);
  const auto state = g->link.captureAppSessionState();
  const double beat = state.beatAtTime(g->link.clock().micros(), kQuantum);
  std::lock_guard<std::mutex> lock(g->configMutex);
  auto& c = g->config;
  if (!state.isPlaying()) {
    c.rules.beatsPerBar = beats;
    c.hasPending = false;
    return;
  }
  // Mid-song: switch on the next downbeat (after any change already due).
  c.applyPendingAt(beat);
  const pc::Rules& r = c.rules;
  c.pendingOrigin = r.origin + (pc::barAt(r, beat) + 1) * r.beatsPerBar;
  c.pendingBeatsPerBar = beats;
  c.hasPending = true;
  c.pendingSong = false;
}

void pc_schedule_song(double beat, double bpm, int beatsPerBar) {
  if (!g) return;
  std::lock_guard<std::mutex> lock(g->configMutex);
  auto& c = g->config;
  c.hasPending = true;
  c.pendingOrigin = beat;
  c.pendingBeatsPerBar = std::clamp(beatsPerBar, 1, 16);
  c.pendingSong = true;
  c.pendingBpm = bpm > 0.0 ? std::clamp(bpm, 20.0, 300.0) : 0.0;
  ++c.songChangeId;
}

void pc_set_bar(int beatsPerBar, double origin, int nextBeatsPerBar, double nextOrigin) {
  if (!g) return;
  std::lock_guard<std::mutex> lock(g->configMutex);
  auto& c = g->config;
  c.rules.beatsPerBar = std::clamp(beatsPerBar, 1, 16);
  c.rules.origin = origin;
  c.hasPending = nextBeatsPerBar > 0;
  c.pendingSong = false;
  c.pendingBeatsPerBar = std::clamp(nextBeatsPerBar, 1, 16);
  c.pendingOrigin = nextOrigin;
}

// Reads the bar settings, applying a due pending change so the UI agrees with
// what is heard.
static BarConfig currentConfig() {
  const auto state = g->link.captureAppSessionState();
  const double beat = state.beatAtTime(g->link.clock().micros(), kQuantum);
  std::lock_guard<std::mutex> lock(g->configMutex);
  if (state.isPlaying()) g->config.applyPendingAt(beat);
  return g->config;
}

int pc_beats_per_bar(void) { return g ? currentConfig().rules.beatsPerBar : 4; }
double pc_bar_origin(void) { return g ? currentConfig().rules.origin : 0.0; }

int pc_pending_beats_per_bar(void) {
  if (!g) return 0;
  const auto c = currentConfig();
  return c.hasPending ? c.pendingBeatsPerBar : 0;
}

double pc_pending_origin(void) { return g ? currentConfig().pendingOrigin : 0.0; }

void pc_set_displacement(int barsPerStep) {
  if (!g) return;
  std::lock_guard<std::mutex> lock(g->configMutex);
  g->config.rules.displaceBars = std::max(0, barsPerStep);
}

void pc_set_gap_trainer(int playBars, int muteBars) {
  if (!g) return;
  std::lock_guard<std::mutex> lock(g->configMutex);
  g->config.rules.gapPlay = std::max(0, playBars);
  g->config.rules.gapMute = std::max(0, muteBars);
}

void pc_set_extra_latency_ms(double ms) {
  if (g) g->extraLatencyMicros = std::max(0.0, ms) * 1000.0;
}

double pc_output_latency_ms(void) {
  return g ? g->outputLatencyMicros.load() / 1000.0 : 0.0;
}

double pc_beat(void) {
  if (!g) return 0.0;
  return g->link.captureAppSessionState().beatAtTime(g->link.clock().micros(), kQuantum);
}

}  // extern "C"
