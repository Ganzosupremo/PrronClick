// SPDX-License-Identifier: GPL-3.0-or-later
// Practice history: one entry each time the click plays a song, and the
// figures the history page shows from them.
import 'dart:math';

import 'song.dart';

/// Practice tools an entry can have used (see [Practice.tools]).
enum PracticeTool { ramp, gap, displace }

/// The click played [song] (null = no song loaded) for [seconds] from
/// [start], reaching [bpm] at most, with [tools] on at some point.
class Practice {
  Practice({
    required this.start,
    required this.seconds,
    this.song,
    required this.bpm,
    Set<PracticeTool>? tools,
  }) : tools = tools ?? {};

  /// Null for an entry that is not one (e.g. a hand-edited file).
  static Practice? fromJson(Object? json) {
    if (json is! Map) return null;
    final t = json['t'], s = json['s'], bpm = json['bpm'], song = json['song'];
    if (t is! int || s is! int || s <= 0 || bpm is! int) return null;
    final tools = json['tools'];
    return Practice(
      start: DateTime.fromMillisecondsSinceEpoch(t * 1000),
      seconds: s,
      song: song is String ? song : null,
      bpm: bpm.clamp(20, 300),
      tools: {
        for (final name in tools is List ? tools : const [])
          ?PracticeTool.values.where((tool) => tool.name == name).firstOrNull,
      },
    );
  }

  final DateTime start;
  int seconds;
  final String? song;
  int bpm;
  final Set<PracticeTool> tools;

  DateTime get day => dayOf(start);

  Map<String, Object?> toJson() => {
    't': start.millisecondsSinceEpoch ~/ 1000,
    's': seconds,
    'song': ?song,
    'bpm': bpm,
    if (tools.isNotEmpty) 'tools': [for (final tool in tools) tool.name],
  };
}

/// The tempo ramp's next step: [up] BPM more, stopping at [max] (0 = up to
/// 300). A tempo already above [max] stays where it is.
double rampedTempo(double tempo, int up, int max) {
  final top = max > 0 ? max.toDouble() : 300.0;
  return tempo >= top ? tempo : min(tempo + up, top);
}

/// The ramp's top after pressing + ([up]) or − with buttons of [step] BPM;
/// 0 = no limit. From no limit, + starts at the first step above [tempo];
/// going under 20 is no limit again.
int stepRampMax(int max, int step, {required bool up, required double tempo}) {
  if (max == 0) {
    return up ? min(((tempo / step).floor() + 1) * step, 300) : 0;
  }
  final next = up ? max + step : max - step;
  return next < 20 ? 0 : min(next, 300);
}

/// Steps the ramp's top tempo buttons can take.
const rampMaxSteps = [1, 2, 5, 10];

/// Shorter than this is a tempo check, not practice.
const minPracticeSeconds = 10;

/// Oldest entries go beyond this: years of daily practice.
const maxPracticeEntries = 5000;

DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// [day] moved [days] calendar days (not 24 h: daylight-saving days are 23
/// or 25 h long).
DateTime addDays(DateTime day, int days) =>
    DateTime(day.year, day.month, day.day + days);

enum HistoryRange { day, week, month }

/// A stretch of calendar time: [from] inclusive, [to] exclusive.
typedef Period = ({DateTime from, DateTime to});

/// The [range] that holds [t]. Weeks start on [firstWeekday] (1 = Monday,
/// 7 = Sunday, as [DateTime.weekday]).
Period periodOf(HistoryRange range, DateTime t, {int firstWeekday = 1}) {
  final day = dayOf(t);
  switch (range) {
    case HistoryRange.day:
      return (from: day, to: addDays(day, 1));
    case HistoryRange.week:
      final from = addDays(day, -((day.weekday - firstWeekday) % 7));
      return (from: from, to: addDays(from, 7));
    case HistoryRange.month:
      return (
        from: DateTime(day.year, day.month),
        to: DateTime(day.year, day.month + 1),
      );
  }
}

/// The period [steps] before (negative) or after [period], of the same kind.
Period shiftPeriod(HistoryRange range, Period period, int steps) =>
    switch (range) {
      HistoryRange.day => (
        from: addDays(period.from, steps),
        to: addDays(period.to, steps),
      ),
      HistoryRange.week => (
        from: addDays(period.from, 7 * steps),
        to: addDays(period.to, 7 * steps),
      ),
      HistoryRange.month => (
        from: DateTime(period.from.year, period.from.month + steps),
        to: DateTime(period.from.year, period.from.month + steps + 1),
      ),
    };

/// The entries that started within [period], oldest first.
List<Practice> entriesIn(List<Practice> history, Period period) => [
  for (final p in history)
    if (!p.start.isBefore(period.from) && p.start.isBefore(period.to)) p,
]..sort((a, b) => a.start.compareTo(b.start));

/// Seconds in each bar of the [range]'s chart: hours of a day, else days.
List<int> buckets(List<Practice> entries, HistoryRange range, Period period) {
  final days = DateTime.utc(period.to.year, period.to.month, period.to.day)
      .difference(
        DateTime.utc(period.from.year, period.from.month, period.from.day),
      )
      .inDays;
  final out = List.filled(range == HistoryRange.day ? 24 : days, 0);
  for (final p in entries) {
    final i = range == HistoryRange.day
        ? p.start.hour
        : DateTime.utc(p.start.year, p.start.month, p.start.day)
              .difference(
                DateTime.utc(
                  period.from.year,
                  period.from.month,
                  period.from.day,
                ),
              )
              .inDays;
    if (i >= 0 && i < out.length) out[i] += p.seconds;
  }
  return out;
}

/// Days in a row with practice, up to today; a day not practised yet does
/// not break it until it is over.
int streak(List<Practice> history, DateTime now) {
  final days = {for (final p in history) p.day};
  var day = dayOf(now);
  if (!days.contains(day)) day = addDays(day, -1);
  var n = 0;
  while (days.contains(day)) {
    n++;
    day = addDays(day, -1);
  }
  return n;
}

/// What a set of entries adds up to.
class PracticeSummary {
  PracticeSummary(List<Practice> entries)
    : seconds = entries.fold(0, (sum, p) => sum + p.seconds),
      sessions = entries.length,
      days = {for (final p in entries) p.day}.length,
      longest = entries.fold(0, (m, p) => max(m, p.seconds)),
      toolSeconds = {
        for (final tool in PracticeTool.values)
          tool: entries
              .where((p) => p.tools.contains(tool))
              .fold(0, (sum, p) => sum + p.seconds),
      },
      plainSeconds = entries
          .where((p) => p.tools.isEmpty)
          .fold(0, (sum, p) => sum + p.seconds);

  final int seconds;
  final int sessions;
  final int days; // days with practice
  final int longest; // the longest session, in seconds

  /// Time with each tool on (an entry with two counts for both).
  final Map<PracticeTool, int> toolSeconds;
  final int plainSeconds; // with no tool
}

/// One song's practice: how long, how often, and its tempo then and now.
class SongPractice {
  SongPractice(this.song, this.key);

  final String? song;
  final String key; // [songKey]: what entries of this song share
  final sessions = <Practice>[]; // oldest first
  int seconds = 0;
  int bestBpm = 0;

  int get times => sessions.length;
  int get firstBpm => sessions.first.bpm;
  int get lastBpm => sessions.last.bpm;
  DateTime get lastTime => sessions.last.start;
}

/// Songs are told apart by name, as they are renamed rarely; '' = no song.
String songKey(String? song) => song == null ? '' : fold(song);

/// Per song, most practised first.
List<SongPractice> practiceBySong(List<Practice> history) {
  final bySong = <String, SongPractice>{};
  for (final p in [...history]..sort((a, b) => a.start.compareTo(b.start))) {
    final key = songKey(p.song);
    bySong.putIfAbsent(key, () => SongPractice(p.song, key))
      ..sessions.add(p)
      ..seconds += p.seconds
      ..bestBpm = max(bySong[key]?.bestBpm ?? 0, p.bpm);
  }
  return bySong.values.toList()..sort((a, b) => b.seconds.compareTo(a.seconds));
}
