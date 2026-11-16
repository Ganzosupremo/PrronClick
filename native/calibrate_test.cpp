// SPDX-License-Identifier: GPL-3.0-or-later
// Synthetic mic recordings: the analysis must find how late our clicks are.
#include "calibrate.hpp"

#include <cstdio>
#include <cstdlib>
#include <random>

namespace {

int failures = 0;

// Same click shape as the engine: 30 ms decaying sine.
// Leader: same click as the engine, 30 ms decaying sine. hz = 0: ours.
void click(std::vector<float>& x, double rate, double at, double hz, double gain) {
  const auto start = static_cast<size_t>(at * rate);
  for (size_t i = 0; i < static_cast<size_t>(0.03 * rate) && start + i < x.size(); ++i) {
    const double t = i / rate;
    x[start + i] += static_cast<float>(
        hz == 0 ? gain / 0.6 * pc::ownClick(t)
                : gain * std::sin(2 * 3.14159265358979 * hz * t) * std::exp(-t * 150));
  }
}

void check(const char* name, double lateMs, double leaderGain, double ownGain, double bpm,
           double expect, double tolerance) {
  const double rate = 48000, beat = 60.0 / bpm;
  std::vector<float> x(static_cast<size_t>(8 * rate));
  std::mt19937 rng(1);
  std::normal_distribution<float> noise(0.0f, 0.01f);
  for (auto& s : x) s = noise(rng);
  for (int b = 0; (b + 1) * beat < 7.5; ++b) {
    const double t = 0.2 + b * beat;
    const double hz = b % 4 == 0 ? 1600.0 : 1000.0;
    click(x, rate, t, hz, leaderGain);
    click(x, rate, t + 0.02, hz, leaderGain * 0.3);  // room echo
    click(x, rate, t + lateMs / 1000.0, 0, ownGain);
  }
  const auto c = pc::analyze(x, rate);
  const bool ok = std::isnan(expect) ? std::isnan(c.lateMs)
                                     : std::abs(c.lateMs - expect) <= tolerance;
  std::printf("%s %s: %.2f ms (%d pairs)\n", ok ? "ok  " : "FAIL", name, c.lateMs, c.pairs);
  if (!ok) ++failures;
}

}  // namespace

int main() {
  check("aligned", 0, 0.3, 0.6, 120, 0, 1.0);
  check("late 37 ms", 37, 0.3, 0.6, 120, 37, 1.0);
  check("early 25 ms", -25, 0.3, 0.6, 120, -25, 1.0);
  check("late 170 ms (PC)", 170, 0.2, 0.8, 100, 170, 1.0);
  check("quiet leader", 60, 0.05, 0.8, 120, 60, 2.0);
  check("no leader", 30, 0.0, 0.6, 120, NAN, 0);
  return failures ? EXIT_FAILURE : EXIT_SUCCESS;
}
