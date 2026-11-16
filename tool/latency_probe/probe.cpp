// SPDX-License-Identifier: GPL-3.0-or-later
// Dev tool: joins the Link session, records the default microphone and writes
//   <out>.f32  mono float samples
//   <out>.csv  sampleIndex,beat   (Link beat, quantum 1, at that sample's
//              capture time, not corrected for input latency)
// so clicks recorded from several devices can be placed on the shared beat grid.
// usage: latency_probe <seconds> <out-prefix>
#include <ableton/Link.hpp>

#include "miniaudio.h"

#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

struct Probe {
  ableton::Link link{120.0};
  std::mutex m;
  std::vector<float> samples;
  std::vector<std::pair<size_t, double>> marks;  // sampleIndex, beat
  double sampleRate = 48000.0;
};

static void capture(ma_device* d, void*, const void* in, ma_uint32 frames) {
  auto& p = *static_cast<Probe*>(d->pUserData);
  // First frame of this buffer was captured ~one buffer ago.
  const auto t = p.link.clock().micros() -
                 std::chrono::microseconds(static_cast<long long>(frames * 1e6 / p.sampleRate));
  const double beat = p.link.captureAudioSessionState().beatAtTime(t, 1.0);
  std::lock_guard<std::mutex> lock(p.m);
  p.marks.emplace_back(p.samples.size(), beat);
  const auto* f = static_cast<const float*>(in);
  p.samples.insert(p.samples.end(), f, f + frames);
}

int main(int argc, char** argv) {
  if (argc < 3) {
    std::fprintf(stderr, "usage: latency_probe <seconds> <out-prefix>\n");
    return 2;
  }
  Probe p;
  p.link.enable(true);
  p.link.enableStartStopSync(true);

  ma_device_config c = ma_device_config_init(ma_device_type_capture);
  c.capture.format = ma_format_f32;
  c.capture.channels = 1;
  c.sampleRate = 48000;
  c.performanceProfile = ma_performance_profile_low_latency;
  c.noFixedSizedCallback = MA_TRUE;
  c.dataCallback = capture;
  c.pUserData = &p;
  ma_device dev;
  if (ma_device_init(nullptr, &c, &dev) != MA_SUCCESS || ma_device_start(&dev) != MA_SUCCESS) {
    std::fprintf(stderr, "capture device failed\n");
    return 1;
  }
  p.sampleRate = dev.sampleRate;
  std::this_thread::sleep_for(std::chrono::seconds(std::atoi(argv[1])));
  ma_device_uninit(&dev);

  const std::string out = argv[2];
  FILE* f = std::fopen((out + ".f32").c_str(), "wb");
  std::fwrite(p.samples.data(), sizeof(float), p.samples.size(), f);
  std::fclose(f);
  f = std::fopen((out + ".csv").c_str(), "w");
  std::fprintf(f, "# sampleRate=%.0f peers=%zu tempo=%.3f\n", p.sampleRate, p.link.numPeers(),
               p.link.captureAppSessionState().tempo());
  for (auto& [i, b] : p.marks) std::fprintf(f, "%zu,%.6f\n", i, b);
  std::fclose(f);
  std::printf("wrote %zu samples, peers=%zu\n", p.samples.size(), p.link.numPeers());
}
