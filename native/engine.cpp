// SPDX-License-Identifier: GPL-3.0-or-later
#include "prronclick.h"

#include <ableton/Link.hpp>

#include "miniaudio.h"

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cmath>
#include <memory>

namespace {

using std::chrono::microseconds;

constexpr double kPi = 3.14159265358979323846;
constexpr double kClickSeconds = 0.03;
constexpr double kAccentHz = 1600.0;
constexpr double kBeatHz = 1000.0;

struct Engine {
  ableton::Link link{120.0};
  ma_device device{};
  double sampleRate = 48000.0;
  std::atomic<double> quantum{4.0};
  std::atomic<double> extraLatencyMicros{0.0};
  double outputLatencyMicros = 0.0;

  // Audio thread only.
  double lastBeat = -1.0;
  double clickFreq = 0.0;
  long clickSample = 0;
  long clickLength = 0;
};

std::unique_ptr<Engine> g;

void render(ma_device* device, void* output, const void*, ma_uint32 frames) {
  auto& e = *static_cast<Engine*>(device->pUserData);
  auto* out = static_cast<float*>(output);
  const ma_uint32 channels = device->playback.channels;

  const auto state = e.link.captureAudioSessionState();
  const double quantum = e.quantum.load();
  // Time at which the first frame of this buffer reaches the speaker.
  const auto hostTime =
      e.link.clock().micros() +
      microseconds(std::llround(e.outputLatencyMicros + e.extraLatencyMicros.load()));
  const double microsPerFrame = 1e6 / e.sampleRate;

  for (ma_uint32 i = 0; i < frames; ++i) {
    if (state.isPlaying()) {
      const auto t = hostTime + microseconds(std::llround(i * microsPerFrame));
      const double beat = state.beatAtTime(t, quantum);
      if (beat >= 0.0 && std::floor(beat) > std::floor(e.lastBeat)) {
        const bool accent = state.phaseAtTime(t, quantum) < 1.0;
        e.clickFreq = accent ? kAccentHz : kBeatHz;
        e.clickSample = 0;
        e.clickLength = static_cast<long>(kClickSeconds * e.sampleRate);
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
  auto e = std::make_unique<Engine>();
  e->link.enableStartStopSync(true);

  ma_device_config config = ma_device_config_init(ma_device_type_playback);
  config.playback.format = ma_format_f32;
  config.playback.channels = 2;
  config.sampleRate = 0;  // device native rate
  config.performanceProfile = ma_performance_profile_low_latency;
  config.dataCallback = render;
  config.pUserData = e.get();

  if (ma_device_init(nullptr, &config, &e->device) != MA_SUCCESS) return false;
  e->sampleRate = e->device.sampleRate;
  // shortcut: buffer-size estimate of output latency; ignores DAC/driver delay,
  // which is what the user's extra-latency setting covers. Upgrade to the
  // AAudio/AVAudioSession reported latency if clicks drift between devices.
  e->outputLatencyMicros = 1e6 * e->device.playback.internalPeriodSizeInFrames *
                           e->device.playback.internalPeriods /
                           e->device.playback.internalSampleRate;
  if (ma_device_start(&e->device) != MA_SUCCESS) {
    ma_device_uninit(&e->device);
    return false;
  }
  g = std::move(e);
  return true;
}

void pc_shutdown(void) {
  if (!g) return;
  ma_device_uninit(&g->device);
  g.reset();
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
    // Beat 0 lands on the next bar boundary of the shared session.
    state.setIsPlayingAndRequestBeatAtTime(true, now, 0.0, g->quantum.load());
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
  if (g) g->quantum = std::clamp(beats, 1, 16);
}

void pc_set_extra_latency_ms(double ms) {
  if (g) g->extraLatencyMicros = std::max(0.0, ms) * 1000.0;
}

double pc_beat(void) {
  if (!g) return 0.0;
  return g->link.captureAppSessionState().beatAtTime(g->link.clock().micros(),
                                                     g->quantum.load());
}

}  // extern "C"
