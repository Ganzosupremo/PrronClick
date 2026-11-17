// SPDX-License-Identifier: GPL-3.0-or-later
#include "prronclick.h"

#include <ableton/Link.hpp>

#include "calibrate.hpp"
#include "miniaudio.h"
#include "rules.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cmath>
#include <memory>
#include <mutex>
#include <vector>

#if defined(__ANDROID__)
#include <dlfcn.h>
#include <time.h>
#endif

#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif
#if TARGET_OS_IPHONE
// Built from ios/Runner/NativeEngine.mm, i.e. as Objective-C++.
#import <AVFoundation/AVFoundation.h>
#endif

namespace {

using std::chrono::microseconds;

constexpr double kPi = 3.14159265358979323846;
constexpr double kClickSeconds = 0.03;
constexpr double kAccentHz = 1600.0;
constexpr double kSubAccentHz = 1300.0;  // start of a group of three in 6/8
constexpr double kBeatHz = 1000.0;
// Count-in: the same two-pitch pattern, lower. Kept away from calibration's
// 2400 Hz band.
constexpr double kCountAccentHz = 1200.0;
constexpr double kCountSubAccentHz = 975.0;
constexpr double kCountHz = 750.0;
// Subdivisions: lower and half as loud, so the beat stays on top.
constexpr double kDivisionHz = 800.0;
constexpr double kCountDivisionHz = 600.0;
constexpr double kDivisionGain = 0.5;
// Link's own bar/phase is unused: peers' beat numbers differ by an integer, so
// bars come from our origin (shared by the leader) and Link only aligns beats.
constexpr double kQuantum = 1.0;

// Voice cues: decoded samples by slot (1-8 are the spoken counts). Replaced
// whole when one is loaded, so the audio thread never sees a half-written one.
constexpr int kCueSlots = 64;
using CueBank = std::array<std::vector<float>, kCueSlots>;

// A cue to say on a beat: slot, then slot2 right after (e.g. "verse", "two").
struct CueEvent {
  double beat = 0.0;
  int slot = 0;
  int slot2 = 0;
};
constexpr int kMaxCues = 8;

// Bar settings plus a change scheduled at a future beat, so every peer switches
// meter on the same downbeat.
struct BarConfig {
  pc::Rules rules;
  bool hasPending = false;
  int pendingBeatsPerBar = 4;
  double pendingOrigin = 0.0;
  double pendingMuteBeats = 0.0;  // silent beats from the new origin (pause)
  double pendingCountBeats = 0.0;  // count-in beats after that pause
  int countBars = 0;  // count-in for songs this device starts (setting)
  // Setlists: the pending change is a new song, so the tempo changes (or the
  // music stops, if pendingBpm <= 0) on the same beat. Leader only: followers
  // get the tempo through Link.
  bool pendingSong = false;
  double pendingBpm = 0.0;
  unsigned songChangeId = 0;  // bumped per schedule so it is applied once
  // Accents for the pending change (the next song's); else they stay.
  bool pendingHasAccents = false;
  unsigned pendingAccentBits = 0;
  int pendingAccentCount = 0;
  // shortcut: the audio thread may drop the last reference to an old bank and
  // free it there; banks only change when the language does.
  std::shared_ptr<const CueBank> cues;
  bool voiceCount = false;  // say "1, 2, 3, 4" in the count-in
  std::array<CueEvent, kMaxCues> cueEvents{};
  int cueCount = 0;

  void applyPendingAt(double beat) {
    if (hasPending && beat >= pendingOrigin) {
      rules.beatsPerBar = pendingBeatsPerBar;
      rules.origin = pendingOrigin;
      rules.muteUntil = pendingOrigin + pendingMuteBeats;
      rules.countUntil = rules.muteUntil + pendingCountBeats;
      if (pendingHasAccents) {
        rules.accentBits = pendingAccentBits;
        rules.accentCount = pendingAccentCount;
      }
      hasPending = false;
      pendingHasAccents = false;
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
  std::atomic<double> volume{1.0};
  std::atomic<int> sound{0};  // timbre, see clickWave

  // Latency calibration: while on, every beat plays pc::ownClick and the mic
  // is recorded into `recording` (allocated up front: the capture callback
  // must not allocate).
  std::atomic<bool> calibrating{false};
  ma_device capture{};
  bool captureOpen = false;
  std::vector<float> recording;
  std::atomic<size_t> recorded{0};

  // Audio thread only.
  BarConfig audioConfig;
  unsigned appliedSongChangeId = 0;
  double lastBeat = -1.0;
  double clickFreq = 0.0;
  long clickSample = 0;
  long clickLength = 0;
  bool clickOwn = false;
  double clickGain = 1.0;
  int clickSound = 0;
  std::shared_ptr<const CueBank> voiceBank;  // keeps the playing sample alive
  int voiceSlot = 0;  // 0 = silent
  int voiceNext = 0;  // said right after
  size_t voicePos = 0;
};

// Starts saying `slot` (then `next`), cutting off whatever was being said.
void say(Engine& e, const BarConfig& cfg, int slot, int next) {
  if (!cfg.cues || slot <= 0 || slot >= kCueSlots || (*cfg.cues)[slot].empty()) return;
  e.voiceBank = cfg.cues;
  e.voiceSlot = slot;
  e.voiceNext = next;
  e.voicePos = 0;
}

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

// Context for every device we open. nullptr (miniaudio's default) everywhere
// but iOS, where both devices must share one audio session: a capture device
// on its own switches the session to Record and silences our click while
// calibrating.
ma_context* audioContext() {
#if TARGET_OS_IPHONE
  static ma_context context;
  static const bool ok = [] {
    ma_context_config c = ma_context_config_init();
    c.coreaudio.sessionCategory = ma_ios_session_category_play_and_record;
    // Speaker, not the earpiece; Bluetooth headphones; other apps keep playing.
    c.coreaudio.sessionCategoryOptions = ma_ios_session_category_option_default_to_speaker |
                                         ma_ios_session_category_option_allow_bluetooth_a2dp |
                                         ma_ios_session_category_option_mix_with_others;
    return ma_context_init(nullptr, 0, &c, &context) == MA_SUCCESS;
  }();
  return ok ? &context : nullptr;
#else
  return nullptr;
#endif
}

#if TARGET_OS_IPHONE
// The session knows the current route (speaker, cable, Bluetooth); the buffer
// size alone misses the DAC and Bluetooth delay.
// shortcut: refreshed on init and on play only, so a route change while
// playing waits for the next start; upgrade to a route-change observer if
// that bites.
void refreshOutputLatency(Engine& e) {
  AVAudioSession* s = [AVAudioSession sharedInstance];
  e.outputLatencyMicros = 1e6 * (s.outputLatency + s.IOBufferDuration);
}
#endif

// One click, t seconds in. Every timbre keeps the pitch: a follower's
// calibration listens for the leader at 1000/1600 Hz.
double clickWave(int sound, double hz, double t) {
  const double s = std::sin(2.0 * kPi * hz * t);
  switch (sound) {
    case 1:  // wood: gone in a few ms
      return s * std::exp(-t * 600.0);
    case 2:  // digital: a square wave
      return (s >= 0.0 ? 0.5 : -0.5) * std::exp(-t * 250.0);
    default:  // beep
      return s * std::exp(-t * 150.0);
  }
}

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
  const double volume = e.volume;

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
      if (e.calibrating) {
        // Plain beats, no practice rules: the leader's clicks are the reference.
        if (beat >= 0.0 && std::floor(beat) != std::floor(e.lastBeat)) {
          e.clickOwn = true;
          e.clickSample = 0;
          e.clickLength = static_cast<long>(kClickSeconds * e.sampleRate);
        }
      } else if (const bool onBeat = beat >= 0.0 && pc::crosses(cfg.rules, e.lastBeat, beat);
                 onBeat || (beat >= 0.0 && pc::crossesDivision(cfg.rules, e.lastBeat, beat))) {
        const double coord = std::floor(pc::clickCoord(cfg.rules, beat));
        if (pc::isSilent(cfg.rules, coord)) {
          // silent bar or silent beat, with its subdivisions
        } else if (!onBeat) {
          e.clickOwn = false;
          e.clickFreq = pc::isCount(cfg.rules, coord) ? kCountDivisionHz : kDivisionHz;
          e.clickGain = kDivisionGain;
          e.clickSound = e.sound;
          e.clickSample = 0;
          e.clickLength = static_cast<long>(kClickSeconds * e.sampleRate);
        } else {
          if (cfg.voiceCount && pc::isCount(cfg.rules, coord)) {
            const long n = pc::mod(pc::floorDiv(coord - cfg.rules.origin), cfg.rules.beatsPerBar) + 1;
            if (n <= 8) say(e, cfg, static_cast<int>(n), 0);
          }
          e.clickOwn = false;
          e.clickGain = 1.0;
          e.clickSound = e.sound;
          // 0 = accent, 1 = lighter accent, 2 = plain beat (silent: above).
          const int kind = pc::accentLevel(cfg.rules, coord);
          static constexpr double kSong[] = {kAccentHz, kSubAccentHz, kBeatHz};
          static constexpr double kCount[] = {kCountAccentHz, kCountSubAccentHz, kCountHz};
          e.clickFreq = (pc::isCount(cfg.rules, coord) ? kCount : kSong)[kind];
          e.clickSample = 0;
          e.clickLength = static_cast<long>(kClickSeconds * e.sampleRate);
        }
      }
      if (!e.calibrating && beat >= 0.0) {
        for (int c = 0; c < cfg.cueCount; ++c) {
          const auto& cue = cfg.cueEvents[c];
          if (e.lastBeat < cue.beat && beat >= cue.beat) say(e, cfg, cue.slot, cue.slot2);
        }
      }
      e.lastBeat = beat;
    } else {
      e.lastBeat = -1.0;
      e.voiceSlot = 0;  // stopping cuts the voice off
    }

    float sample = 0.0f;
    if (e.clickSample < e.clickLength) {
      const double t = e.clickSample / e.sampleRate;
      sample = static_cast<float>(
          e.clickOwn ? pc::ownClick(t)
                     : 0.6 * e.clickGain * volume * clickWave(e.clickSound, e.clickFreq, t));
      ++e.clickSample;
    }
    if (e.voiceSlot > 0) {
      const auto& voice = (*e.voiceBank)[e.voiceSlot];
      sample += static_cast<float>(volume) * voice[e.voicePos];
      if (++e.voicePos >= voice.size()) {
        e.voicePos = 0;
        e.voiceSlot = e.voiceNext > 0 && e.voiceNext < kCueSlots && !(*e.voiceBank)[e.voiceNext].empty()
                          ? e.voiceNext : 0;
        e.voiceNext = 0;
      }
    }
    sample = std::clamp(sample, -1.0f, 1.0f);
    for (ma_uint32 c = 0; c < channels; ++c) {
      out[i * channels + c] = sample;
    }
  }
}

void record(ma_device* device, void*, const void* input, ma_uint32 frames) {
  auto& e = *static_cast<Engine*>(device->pUserData);
  const size_t at = e.recorded.load();
  const size_t n = std::min<size_t>(frames, e.recording.size() - at);
  std::copy_n(static_cast<const float*>(input), n, e.recording.begin() + at);
  e.recorded = at + n;
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

  if (ma_device_init(audioContext(), &config, &e->device) != MA_SUCCESS) return false;
  e->sampleRate = e->device.sampleRate;
  // shortcut: buffer-size estimate of output latency; ignores mixer/DAC delay.
  // Android replaces it with the AAudio-measured latency once audio runs;
  // iOS asks its audio session below; Windows still needs its measured
  // latency (WASAPI clock) if clicks land late against other devices.
  e->outputLatencyMicros = 1e6 * e->device.playback.internalPeriodSizeInFrames *
                           e->device.playback.internalPeriods /
                           e->device.playback.internalSampleRate;
  if (ma_device_start(&e->device) != MA_SUCCESS) {
    ma_device_uninit(&e->device);
    return false;
  }
#if TARGET_OS_IPHONE
  refreshOutputLatency(*e);
#endif
  g = e.release();
  return true;
}

void pc_shutdown(void) {
  if (!g) return;
  pc_calibration_finish();
  ma_device_uninit(&g->device);
  delete g;
  g = nullptr;
}

void pc_set_link_enabled(bool enabled) {
  if (g) g->link.enable(enabled);
}

// pc::linkPort only exists in native/link_patch's copy of Link's header: if
// this does not compile, that directory is not first in the include path.
void pc_set_link_port(int port) {
  pc::linkPort = static_cast<unsigned short>(std::clamp(port, 1024, 65535));
}

int pc_num_peers(void) {
  return g ? static_cast<int>(g->link.numPeers()) : 0;
}

void pc_set_playing(bool playing) {
  if (!g) return;
  auto state = g->link.captureAppSessionState();
  const auto now = g->link.clock().micros();
  if (playing) {
#if TARGET_OS_IPHONE
    refreshOutputLatency(*g);
#endif
    // Beat 0 lands on the next shared beat; the bar starts there.
    state.setIsPlayingAndRequestBeatAtTime(true, now, 0.0, kQuantum);
    std::lock_guard<std::mutex> lock(g->configMutex);
    g->config.rules.origin = 0.0;
    g->config.rules.muteUntil = 0.0;
    g->config.rules.countUntil = g->config.countBars * g->config.rules.beatsPerBar;
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
    c.rules.muteUntil = 0.0;
    c.rules.countUntil = 0.0;
    c.hasPending = false;
    return;
  }
  // Mid-song: switch on the next downbeat (after any change already due).
  c.applyPendingAt(beat);
  const pc::Rules& r = c.rules;
  c.pendingOrigin = r.origin + (pc::barAt(r, beat) + 1) * r.beatsPerBar;
  c.pendingBeatsPerBar = beats;
  c.pendingMuteBeats = 0.0;
  c.pendingCountBeats = 0.0;
  c.hasPending = true;
  c.pendingSong = false;
  c.pendingHasAccents = false;
}

// A tempo and meter change on `beat`; a new song adds its pause and count-in.
static void schedule(double beat, double bpm, int beatsPerBar, int pauseBars, bool newSong) {
  if (!g) return;
  std::lock_guard<std::mutex> lock(g->configMutex);
  auto& c = g->config;
  c.hasPending = true;
  c.pendingOrigin = beat;
  c.pendingBeatsPerBar = std::clamp(beatsPerBar, 1, 16);
  c.pendingMuteBeats = std::max(0, pauseBars) * c.pendingBeatsPerBar;
  c.pendingCountBeats = newSong && bpm > 0.0 ? c.countBars * c.pendingBeatsPerBar : 0.0;
  c.pendingSong = true;
  c.pendingBpm = bpm > 0.0 ? std::clamp(bpm, 20.0, 300.0) : 0.0;
  c.pendingHasAccents = false;
  ++c.songChangeId;
}

void pc_schedule_song(double beat, double bpm, int beatsPerBar, int pauseBars) {
  schedule(beat, bpm, beatsPerBar, pauseBars, true);
}

void pc_schedule_section(double beat, double bpm, int beatsPerBar) {
  if (bpm > 0.0) schedule(beat, bpm, beatsPerBar, 0, false);
}

void pc_set_bar(int beatsPerBar, double origin, double muteUntil, double countUntil,
                int nextBeatsPerBar, double nextOrigin, double nextMuteBeats,
                double nextCountBeats) {
  if (!g) return;
  std::lock_guard<std::mutex> lock(g->configMutex);
  auto& c = g->config;
  c.rules.beatsPerBar = std::clamp(beatsPerBar, 1, 16);
  c.rules.origin = origin;
  c.rules.muteUntil = muteUntil;
  c.rules.countUntil = countUntil;
  c.hasPending = nextBeatsPerBar > 0;
  c.pendingMuteBeats = std::max(0.0, nextMuteBeats);
  c.pendingCountBeats = std::max(0.0, nextCountBeats);
  c.pendingSong = false;
  c.pendingBeatsPerBar = std::clamp(nextBeatsPerBar, 1, 16);
  c.pendingOrigin = nextOrigin;
}

bool pc_load_cue(int slot, const void* data, size_t size) {
  if (!g || slot <= 0 || slot >= kCueSlots) return false;
  std::vector<float> samples;
  if (data != nullptr && size > 0) {
    // Any format miniaudio reads, as mono at the device's rate.
    ma_decoder_config dc =
        ma_decoder_config_init(ma_format_f32, 1, static_cast<ma_uint32>(g->sampleRate));
    ma_decoder decoder;
    if (ma_decoder_init_memory(data, size, &dc, &decoder) != MA_SUCCESS) return false;
    float chunk[4096];
    ma_uint64 read = 0;
    while (ma_decoder_read_pcm_frames(&decoder, chunk, 4096, &read) == MA_SUCCESS && read > 0) {
      samples.insert(samples.end(), chunk, chunk + read);
      if (samples.size() > static_cast<size_t>(g->sampleRate) * 5) break;  // cues are short
    }
    ma_decoder_uninit(&decoder);
  }
  std::lock_guard<std::mutex> lock(g->configMutex);
  auto bank = g->config.cues ? std::make_shared<CueBank>(*g->config.cues)
                             : std::make_shared<CueBank>();
  (*bank)[slot] = std::move(samples);
  g->config.cues = std::move(bank);
  return true;
}

void pc_set_voice_count(bool on) {
  if (!g) return;
  std::lock_guard<std::mutex> lock(g->configMutex);
  g->config.voiceCount = on;
}

void pc_schedule_cue(double beat, int slot, int slot2) {
  if (!g) return;
  std::lock_guard<std::mutex> lock(g->configMutex);
  auto& c = g->config;
  // Replaces a cue on the same beat; else the oldest makes room.
  int at = 0;
  while (at < c.cueCount && std::fabs(c.cueEvents[at].beat - beat) > 1e-6) ++at;
  if (at == kMaxCues) {
    std::move(c.cueEvents.begin() + 1, c.cueEvents.end(), c.cueEvents.begin());
    at = kMaxCues - 1;
  }
  c.cueEvents[at] = {beat, slot, slot2};
  c.cueCount = std::max(c.cueCount, at + 1);
}

void pc_clear_cues(void) {
  if (!g) return;
  std::lock_guard<std::mutex> lock(g->configMutex);
  g->config.cueCount = 0;
}

void pc_set_accents(unsigned bits, int count, bool next) {
  if (!g) return;
  count = std::clamp(count, 0, 16);
  std::lock_guard<std::mutex> lock(g->configMutex);
  auto& c = g->config;
  if (next && c.hasPending) {
    c.pendingHasAccents = true;
    c.pendingAccentBits = bits;
    c.pendingAccentCount = count;
  } else {
    c.rules.accentBits = bits;
    c.rules.accentCount = count;
  }
}

}  // extern "C"

// Reads the bar settings, applying a due pending change so the UI agrees with
// what is heard.
static BarConfig currentConfig() {
  const auto state = g->link.captureAppSessionState();
  const double beat = state.beatAtTime(g->link.clock().micros(), kQuantum);
  std::lock_guard<std::mutex> lock(g->configMutex);
  if (state.isPlaying()) g->config.applyPendingAt(beat);
  return g->config;
}

extern "C" {

int pc_beats_per_bar(void) { return g ? currentConfig().rules.beatsPerBar : 4; }
double pc_bar_origin(void) { return g ? currentConfig().rules.origin : 0.0; }

int pc_pending_beats_per_bar(void) {
  if (!g) return 0;
  const auto c = currentConfig();
  return c.hasPending ? c.pendingBeatsPerBar : 0;
}

double pc_mute_until(void) { return g ? currentConfig().rules.muteUntil : 0.0; }
double pc_pending_mute_beats(void) { return g ? currentConfig().pendingMuteBeats : 0.0; }
double pc_count_until(void) { return g ? currentConfig().rules.countUntil : 0.0; }
double pc_pending_count_beats(void) { return g ? currentConfig().pendingCountBeats : 0.0; }

void pc_set_count_in(int bars) {
  if (!g) return;
  std::lock_guard<std::mutex> lock(g->configMutex);
  g->config.countBars = std::clamp(bars, 0, 4);
}

double pc_pending_origin(void) { return g ? currentConfig().pendingOrigin : 0.0; }

void pc_set_beat_unit(int unit) {
  if (!g) return;
  std::lock_guard<std::mutex> lock(g->configMutex);
  g->config.rules.beatUnit = unit;
}

void pc_set_subdivision(int clicksPerBeat) {
  if (!g) return;
  std::lock_guard<std::mutex> lock(g->configMutex);
  g->config.rules.subdivision = std::clamp(clicksPerBeat, 1, 4);
}

void pc_set_volume(double volume) {
  if (g) g->volume = std::clamp(volume, 0.0, 1.0);
}

void pc_set_sound(int sound) {
  if (g) g->sound = sound;
}

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
  if (g) g->extraLatencyMicros = std::clamp(ms, -200.0, 1000.0) * 1000.0;
}

bool pc_calibration_start(void) {
  if (!g || g->captureOpen) return false;
  ma_device_config c = ma_device_config_init(ma_device_type_capture);
  c.capture.format = ma_format_f32;
  c.capture.channels = 1;
  c.sampleRate = 48000;
  c.dataCallback = record;
  c.pUserData = g;
  // No noise suppression or gain control: they eat or reshape clicks.
  c.aaudio.inputPreset = ma_aaudio_input_preset_unprocessed;
  if (ma_device_init(audioContext(), &c, &g->capture) != MA_SUCCESS) {
    c.aaudio.inputPreset = ma_aaudio_input_preset_default;  // not on every phone
    if (ma_device_init(audioContext(), &c, &g->capture) != MA_SUCCESS) return false;
  }
  g->recording.assign(static_cast<size_t>(15 * g->capture.sampleRate), 0.0f);
  g->recorded = 0;
  if (ma_device_start(&g->capture) != MA_SUCCESS) {
    ma_device_uninit(&g->capture);
    return false;
  }
  g->captureOpen = true;
  g->calibrating = true;
  return true;
}

double pc_calibration_finish(void) {
  if (!g || !g->captureOpen) return NAN;
  g->calibrating = false;
  const double rate = g->capture.sampleRate;
  ma_device_uninit(&g->capture);  // stops the callback before we read
  g->captureOpen = false;
  g->recording.resize(g->recorded.load());
  const auto result = pc::analyze(g->recording, rate);
  g->recording = {};
  return result.lateMs;
}

double pc_output_latency_ms(void) {
  return g ? g->outputLatencyMicros.load() / 1000.0 : 0.0;
}

double pc_beat(void) {
  if (!g) return 0.0;
  return g->link.captureAppSessionState().beatAtTime(g->link.clock().micros(), kQuantum);
}

}  // extern "C"
