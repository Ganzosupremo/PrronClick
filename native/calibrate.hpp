// SPDX-License-Identifier: GPL-3.0-or-later
// Latency calibration analysis. A follower records its mic while the leader
// clicks at 1000/1600 Hz and the follower clicks the same beats at kOwnHz.
// Both reach the same mic, so input latency cancels: the gap between the two
// onsets is how late (positive) this device sounds against the leader.
#pragma once

#include <algorithm>
#include <cmath>
#include <vector>

namespace pc {

constexpr double kOwnHz = 2400.0;  // between 1000/1600 Hz and their harmonics
constexpr double kOwnAttack = 0.003;
constexpr double kOwnOnsetBiasMs = 1.2;  // measured by calibrate_test

// Our calibration click. A sharp attack spreads energy into the leader's
// bands, so it fades in over 3 ms; kOwnOnsetBias is what that costs.
inline double ownClick(double t) {
  const double fade = t < kOwnAttack ? 0.5 - 0.5 * std::cos(3.14159265358979323846 * t / kOwnAttack) : 1.0;
  return 0.6 * fade * std::sin(2.0 * 3.14159265358979323846 * kOwnHz * t) * std::exp(-t * 150.0);
}

// Four cascaded band-pass biquads (RBJ, 0 dB peak): steep enough that our
// click does not leak into the leader's bands and the other way round.
class BandPass {
 public:
  BandPass(double hz, double bandwidthHz, double rate) {
    const double w = 2.0 * 3.14159265358979323846 * hz / rate;
    const double alpha = std::sin(w) * bandwidthHz / (2.0 * hz);
    const double a0 = 1.0 + alpha;
    b0 = alpha / a0;
    a1 = -2.0 * std::cos(w) / a0;
    a2 = (1.0 - alpha) / a0;
  }
  double operator()(double x) {
    for (auto& st : s) x = stage(st, x);
    return x;
  }

 private:
  struct State { double x1 = 0, x2 = 0, y1 = 0, y2 = 0; };
  double stage(State& st, double x) {
    const double y = b0 * x - b0 * st.x2 - a1 * st.y1 - a2 * st.y2;
    st.x2 = st.x1; st.x1 = x; st.y2 = st.y1; st.y1 = y;
    return y;
  }
  double b0, a1, a2;
  State s[4];
};

// Level of the loudest of these bands over time. Same bandwidth for every
// band so their rise times, and so their onset bias, match.
inline std::vector<float> envelope(const std::vector<float>& x, double rate,
                                   std::vector<double> hz) {
  constexpr double kBandwidth = 300.0;
  std::vector<BandPass> filters;
  for (double f : hz) filters.emplace_back(f, kBandwidth, rate);
  std::vector<float> env(x.size());
  const double k = 1.0 - std::exp(-1.0 / (0.0005 * rate));  // 0.5 ms smoothing
  double e = 0.0;
  for (size_t i = 0; i < x.size(); ++i) {
    double v = 0.0;
    for (auto& f : filters) v = std::max(v, std::abs(f(x[i])));
    e += k * (v - e);
    env[i] = static_cast<float>(e);
  }
  return env;
}

// Onset times (seconds) where the envelope rises through 30% of its loud level.
inline std::vector<double> onsets(const std::vector<float>& env, double rate) {
  if (env.empty()) return {};
  std::vector<float> sorted = env;
  const size_t p99 = sorted.size() * 99 / 100;
  std::nth_element(sorted.begin(), sorted.begin() + p99, sorted.end());
  const size_t p50 = sorted.size() / 2;
  std::nth_element(sorted.begin(), sorted.begin() + p50, sorted.begin() + p99);
  const double loud = sorted[p99], floor = sorted[p50];
  if (loud < 4.0 * floor || loud <= 0.0) return {};  // nothing clearly above noise
  const double threshold = floor + 0.3 * (loud - floor);
  const auto refractory = static_cast<size_t>(0.15 * rate);  // skip echoes
  std::vector<double> out;
  for (size_t i = 1; i < env.size(); ++i) {
    if (env[i - 1] < threshold && env[i] >= threshold) {
      out.push_back(i / rate);
      i += refractory;
    }
  }
  return out;
}

// Most pairs (80%) must sit this close to the median, else there is no one
// steady offset (leader's click displaced, another follower playing, noise).
constexpr double kMaxSpreadMs = 5.0;

struct Calibration {
  double lateMs = NAN;  // NAN = not enough clicks heard, or no steady offset
  int pairs = 0;
};

// shortcut: pairs each own click with the nearest leader click, so errors over
// half a beat (250 ms at 120 BPM) alias; calibrate at a moderate tempo.
inline Calibration analyze(const std::vector<float>& x, double rate) {
  const auto leaderEnv = envelope(x, rate, {1000.0, 1600.0});
  auto ownEnv = envelope(x, rate, {kOwnHz});
  // The leader's sharp attack leaks into our band (7-24% on a phone speaker),
  // and our tone may reach the mic quieter than that, so take the leak out.
  // The attack reaches our band ~2 ms before the leader's own band rises:
  // subtract the leader's level from the next 3 ms. Left in, a leak would also
  // hide (refractory) a click of ours up to 150 ms after it.
  constexpr float kLeak = 0.3f;
  const auto ahead = static_cast<size_t>(0.003 * rate);
  for (size_t i = 0; i < ownEnv.size(); ++i) {
    const auto end = leaderEnv.begin() + std::min(i + ahead, leaderEnv.size());
    const float leak = kLeak * *std::max_element(leaderEnv.begin() + i, end);
    ownEnv[i] = std::max(0.0f, ownEnv[i] - leak);
  }
  const auto own = onsets(ownEnv, rate);
  const auto leader = onsets(leaderEnv, rate);
  Calibration c;
  if (own.size() < 6 || leader.size() < 6) return c;
  std::vector<double> gaps;
  for (size_t i = 1; i < leader.size(); ++i) gaps.push_back(leader[i] - leader[i - 1]);
  std::nth_element(gaps.begin(), gaps.begin() + gaps.size() / 2, gaps.end());
  const double period = gaps[gaps.size() / 2];
  std::vector<double> d;
  for (double t : own) {
    const auto it = std::lower_bound(leader.begin(), leader.end(), t);
    double best = 1e9;
    if (it != leader.end()) best = *it - t;
    if (it != leader.begin() && t - *(it - 1) < std::abs(best)) best = *(it - 1) - t;
    if (std::abs(best) < period / 2) d.push_back(-best);  // own - leader
  }
  if (d.size() < 6) return c;
  std::nth_element(d.begin(), d.begin() + d.size() / 2, d.end());
  const double median = d[d.size() / 2];
  const auto steady = std::count_if(d.begin(), d.end(), [&](double v) {
    return std::abs(v - median) * 1000.0 <= kMaxSpreadMs;
  });
  c.pairs = static_cast<int>(d.size());
  if (steady < 0.8 * d.size()) return c;
  c.lateMs = median * 1000.0 - kOwnOnsetBiasMs;
  return c;
}

}  // namespace pc
