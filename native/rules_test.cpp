// SPDX-License-Identifier: GPL-3.0-or-later
// Feeds the rules a simulated sample stream and checks where clicks land.
#include "rules.hpp"

#include <cstdio>
#include <cstdlib>
#include <vector>

using namespace pc;

struct Click {
  double beat;
  bool accent;
};

static std::vector<Click> run(const Rules& r, double from, double to) {
  std::vector<Click> clicks;
  const double step = 1.0 / 4800;  // ~100 samples per 10 ms at 120 BPM / 48 kHz
  double prev = from - step;
  for (double b = from; b < to; b += step) {
    if (crosses(r, prev, b)) {
      const double coord = std::floor(clickCoord(r, b));
      if (!isMuted(r, coord)) clicks.push_back({b, isAccent(r, coord)});
    }
    prev = b;
  }
  return clicks;
}

static int failures = 0;
#define CHECK(cond)                                                \
  do {                                                             \
    if (!(cond)) {                                                 \
      std::printf("FAIL line %d: %s\n", __LINE__, #cond);          \
      ++failures;                                                  \
    }                                                              \
  } while (0)

static bool near(double a, double b) { return std::fabs(a - b) < 0.001; }

int main() {
  {  // Plain 4/4: one click per beat, accent on 0, 4, 8.
    const auto c = run(Rules{}, 0, 12);
    CHECK(c.size() == 12);
    for (size_t i = 0; i < c.size(); ++i) {
      CHECK(near(c[i].beat, i));
      CHECK(c[i].accent == (i % 4 == 0));
    }
  }
  {  // Displace every 2 bars of 4/4: offsets 0, .25, .5, .75, then 0 again.
    Rules r;
    r.displaceBars = 2;
    const auto c = run(r, 0, 40);
    const double offsets[] = {0, 0.25, 0.5, 0.75, 0};
    for (int group = 0; group < 5; ++group) {
      for (int k = 0; k < 8; ++k) {
        const double want = group * 8 + k + offsets[group];
        bool found = false;
        for (const auto& x : c) found |= near(x.beat, want);
        CHECK(found);
      }
    }
    // No doubled or missing clicks at the shifts: 8 per 2-bar group, last
    // group cut where its shifted clicks run past beat 40.
    CHECK(c.size() == 40);
    for (size_t i = 1; i < c.size(); ++i) CHECK(c[i].beat - c[i - 1].beat > 0.2);
    for (const auto& x : c) {
      const double coord = x.beat - offsets[static_cast<int>(x.beat) / 8 % 5];
      CHECK(x.accent == (static_cast<long>(std::lround(coord)) % 4 == 0));
    }
  }
  {  // Gap trainer 4 on / 2 off: bars 4-5 silent, bar 6 plays again.
    Rules r;
    r.gapPlay = 4;
    r.gapMute = 2;
    const auto c = run(r, 0, 28);
    CHECK(c.size() == 20);
    for (const auto& x : c) CHECK(x.beat < 16 || x.beat >= 24);
  }
  {  // Bar origin and odd meter: 3/4 starting at beat 5.
    Rules r;
    r.beatsPerBar = 3;
    r.origin = 5;
    const auto c = run(r, 5, 11);
    CHECK(c.size() == 6);
    CHECK(c[0].accent && !c[1].accent && !c[2].accent && c[3].accent);
  }
  {  // Pause: two silent bars from the origin, then clicks again.
    Rules r;
    r.origin = 8;
    r.muteUntil = 16;
    const auto c = run(r, 8, 24);
    CHECK(c.size() == 8);
    CHECK(near(c[0].beat, 16) && c[0].accent);
  }
  {  // Count-in: one bar after a one-bar pause, even where the trainer mutes.
    Rules r;
    r.origin = 8;
    r.muteUntil = 12;
    r.countUntil = 16;
    r.gapPlay = 1;
    r.gapMute = 3;
    const auto c = run(r, 8, 24);
    CHECK(c.size() == 4);  // bar 0 paused, bar 1 counted, bars 2-3 trainer-muted
    CHECK(near(c[0].beat, 12) && near(c[3].beat, 15));
    CHECK(!isCount(r, 11) && isCount(r, 12) && isCount(r, 15) && !isCount(r, 16));
  }
  {  // Negative beats (count-in before origin) still work.
    Rules r;
    CHECK(barAt(r, -0.5) == -1);
    CHECK(isAccent(r, -4));
  }
  std::printf(failures ? "%d failure(s)\n" : "all rules tests passed\n", failures);
  return failures ? EXIT_FAILURE : EXIT_SUCCESS;
}
