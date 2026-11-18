// SPDX-License-Identifier: GPL-3.0-or-later
// Pure click rules: everything is a function of the Link beat, so every peer
// that shares the bar origin hears the same pattern without extra messages.
#pragma once

#include <cmath>

namespace pc {

struct Rules {
  int beatsPerBar = 4;
  int beatUnit = 4;      // the meter's lower number; only groups the accents
  double origin = 0.0;   // beat where bar 0 starts
  int displaceBars = 0;  // 0 = off; else shift a 16th every N bars
  int gapPlay = 0;       // tempo trainer: bars with click...
  int gapMute = 0;       // ...then bars of silence; 0 = off
  double muteUntil = 0;  // silent from origin up to this beat (setlist pause)
  double countUntil = 0; // count-in: after the pause, another pitch up to here
  int subdivision = 1;   // softer clicks per beat on this device; 1 = none
  // The song's own accents: 2 bits per beat (see accentLevel), used only in
  // bars of exactly accentCount beats; 0 = the automatic pattern.
  unsigned accentBits = 0;
  int accentCount = 0;
};

enum Accent { kStrong = 0, kMedium = 1, kNormal = 2, kSilent = 3 };

inline long floorDiv(double x) { return static_cast<long>(std::floor(x)); }
inline long mod(long a, long n) { return ((a % n) + n) % n; }

inline long barAt(const Rules& r, double beat) {
  return floorDiv((beat - r.origin) / r.beatsPerBar);
}

// Shifts time so the click lands on 1, e, &, a, 1… as bars go by: a click fires
// whenever this coordinate crosses an integer.
inline double clickCoord(const Rules& r, double beat) {
  if (r.displaceBars <= 0) return beat;
  const long step = mod(floorDiv(static_cast<double>(barAt(r, beat)) / r.displaceBars), 4);
  return beat - step * 0.25;
}

inline bool isCount(const Rules& r, double coord) {
  return coord >= r.origin && coord >= r.muteUntil && coord < r.countUntil;
}

inline bool isMuted(const Rules& r, double coord) {
  if (coord >= r.origin && coord < r.muteUntil) return true;
  if (isCount(r, coord)) return false;  // the tempo trainer never eats the count-in
  if (r.gapPlay <= 0 || r.gapMute <= 0) return false;
  return mod(barAt(r, coord), r.gapPlay + r.gapMute) >= r.gapPlay;
}

inline bool isAccent(const Rules& r, double coord) {
  return mod(floorDiv(coord - r.origin), r.beatsPerBar) == 0;
}

// Compound meters (6/8, 9/8, 12/8) are felt in threes: a lighter accent starts
// each group after the first. Same rule as accentGroup in lib/song.dart.
inline bool isSubAccent(const Rules& r, double coord) {
  if (r.beatUnit != 8 || r.beatsPerBar <= 3 || r.beatsPerBar % 3 != 0) return false;
  const long inBar = mod(floorDiv(coord - r.origin), r.beatsPerBar);
  return inBar != 0 && inBar % 3 == 0;
}

// How the beat at coord sounds. The count-in always counts plainly.
inline int accentLevel(const Rules& r, double coord) {
  const bool own = r.accentCount == r.beatsPerBar && !isCount(r, coord);
  if (!own) return isAccent(r, coord) ? kStrong : isSubAccent(r, coord) ? kMedium : kNormal;
  const long inBar = mod(floorDiv(coord - r.origin), r.beatsPerBar);
  return static_cast<int>((r.accentBits >> (2 * inBar)) & 3u);
}

// Nothing sounds at coord, its subdivisions included: a silent bar, or a
// beat the song marks silent.
inline bool isSilent(const Rules& r, double coord) {
  return isMuted(r, coord) || accentLevel(r, coord) == kSilent;
}

inline bool crosses(const Rules& r, double prev, double beat) {
  return std::floor(clickCoord(r, beat)) > std::floor(clickCoord(r, prev));
}

// A subdivision click: the coordinate crosses a fraction of a beat, not a beat.
inline bool crossesDivision(const Rules& r, double prev, double beat) {
  if (r.subdivision <= 1) return false;
  const double a = clickCoord(r, prev), b = clickCoord(r, beat);
  return std::floor(b) == std::floor(a) &&
         std::floor(b * r.subdivision) > std::floor(a * r.subdivision);
}

// The first beat click after `beat` that sounds (subdivisions never count),
// or only bar starts if `downbeatOnly`: where it falls and its accentLevel.
// Clicks land on a 16th grid (displacement moves them by quarters of a beat).
// false if none within 16 beats.
inline bool nextFelt(const Rules& r, double beat, bool downbeatOnly, double* at, int* level) {
  const double first = std::floor(beat * 4) / 4 + 0.25;
  for (int i = 0; i < 64; ++i) {
    const double b = first + i * 0.25;
    if (!crosses(r, b - 0.125, b)) continue;
    const double coord = std::floor(clickCoord(r, b));
    if (isSilent(r, coord) || (downbeatOnly && !isAccent(r, coord))) continue;
    *at = b;
    *level = accentLevel(r, coord);
    return true;
  }
  return false;
}

// The last beat click at or before `beat` that sounds: nextFelt backwards.
inline bool prevFelt(const Rules& r, double beat, bool downbeatOnly, double* at, int* level) {
  const double last = std::floor(beat * 4) / 4;
  for (int i = 0; i < 64; ++i) {
    const double b = last - i * 0.25;
    if (!crosses(r, b - 0.125, b)) continue;
    const double coord = std::floor(clickCoord(r, b));
    if (isSilent(r, coord) || (downbeatOnly && !isAccent(r, coord))) continue;
    *at = b;
    *level = accentLevel(r, coord);
    return true;
  }
  return false;
}

}  // namespace pc
