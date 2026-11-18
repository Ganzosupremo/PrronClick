import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prronclick/library.dart';
import 'package:prronclick/practice.dart';

Practice at(DateTime start, int seconds, {String? song, int bpm = 100}) =>
    Practice(start: start, seconds: seconds, song: song, bpm: bpm);

void main() {
  test('entries survive the library file; junk is skipped', () async {
    final dir = await Directory.systemTemp.createTemp('prronclick_practice');
    addTearDown(() => dir.delete(recursive: true));
    final store = LibraryStore(File('${dir.path}/library.json'));
    final when = DateTime(2026, 11, 17, 21, 30);
    await store.save(
      Library(
        history: [
          at(when, 95, song: 'Praise', bpm: 127),
          at(when, 40),
        ],
      ),
    );
    final back = (await store.load()).history;
    expect(back.length, 2);
    expect(
      (back[0].start, back[0].seconds, back[0].song, back[0].bpm),
      (when, 95, 'Praise', 127),
    );
    expect(back[1].song, isNull);

    final json = jsonDecode(
      await File('${dir.path}/library.json').readAsString(),
    );
    (json as Map)['history'] = [
      {'t': 1, 's': -5, 'bpm': 100}, // no time
      {'t': 'x', 's': 5, 'bpm': 100},
      {'t': 1, 's': 5, 'bpm': 999}, // tempo clamped
      'nonsense',
    ];
    await File('${dir.path}/library.json').writeAsString(jsonEncode(json));
    final kept = (await store.load()).history;
    expect(kept.single.bpm, 300);
  });

  test('periods: a day, a week from its first weekday, a month', () {
    final t = DateTime(2026, 11, 18, 21); // a Wednesday
    expect(periodOf(HistoryRange.day, t), (
      from: DateTime(2026, 11, 18),
      to: DateTime(2026, 11, 19),
    ));
    expect(periodOf(HistoryRange.week, t), (
      from: DateTime(2026, 11, 16),
      to: DateTime(2026, 11, 23),
    ));
    expect(
      periodOf(HistoryRange.week, t, firstWeekday: 7).from,
      DateTime(2026, 11, 15),
    ); // weeks from Sunday
    final month = periodOf(HistoryRange.month, t);
    expect(month, (from: DateTime(2026, 11), to: DateTime(2026, 12)));
    // Moving by whole months, across a year end.
    expect(shiftPeriod(HistoryRange.month, month, 2).from, DateTime(2027, 1));
    expect(
      shiftPeriod(HistoryRange.week, periodOf(HistoryRange.week, t), -1).from,
      DateTime(2026, 11, 9),
    );
  });

  test('bars: hours of a day, days of a week or month', () {
    final entries = [
      at(DateTime(2026, 11, 16, 8, 30), 60), // Monday
      at(DateTime(2026, 11, 18, 21), 30),
      at(DateTime(2026, 11, 18, 21, 40), 15),
      at(DateTime(2026, 11, 22, 23, 59), 10), // Sunday, the week's last
    ];
    final week = periodOf(HistoryRange.week, DateTime(2026, 11, 18));
    expect(buckets(entriesIn(entries, week), HistoryRange.week, week), [
      60,
      0,
      45,
      0,
      0,
      0,
      10,
    ]);
    final day = periodOf(HistoryRange.day, DateTime(2026, 11, 18));
    final hours = buckets(entriesIn(entries, day), HistoryRange.day, day);
    expect((hours.length, hours[21], hours[8]), (24, 45, 0));
    final month = periodOf(HistoryRange.month, DateTime(2026, 2, 3));
    expect(buckets(const [], HistoryRange.month, month).length, 28);
  });

  test('across a daylight-saving change the days still line up', () {
    // Europe moves clocks on the last Sunday of October (the 25th in 2026).
    final week = periodOf(HistoryRange.week, DateTime(2026, 10, 25, 12));
    expect(week.to, DateTime(2026, 10, 26));
    final entries = [
      at(DateTime(2026, 10, 24, 12), 60),
      at(DateTime(2026, 10, 25, 23, 30), 30),
    ];
    expect(
      buckets(entriesIn(entries, week), HistoryRange.week, week).sublist(5),
      [60, 30],
    );
  });

  test('a streak counts days in a row; today not yet does not break it', () {
    final history = [
      at(DateTime(2026, 11, 15, 20), 60),
      at(DateTime(2026, 11, 16, 20), 60),
      at(DateTime(2026, 11, 17, 9), 60),
      at(DateTime(2026, 11, 17, 21), 60),
    ];
    expect(streak(history, DateTime(2026, 11, 17, 22)), 3);
    expect(streak(history, DateTime(2026, 11, 18, 8)), 3); // not over yet
    expect(streak(history, DateTime(2026, 11, 19, 8)), 0); // missed a day
    expect(streak(const [], DateTime(2026, 11, 19)), 0);
  });

  test('summary: time, sessions, days, longest and time with each tool', () {
    final s = PracticeSummary([
      at(DateTime(2026, 11, 16, 8), 300)..tools.add(PracticeTool.ramp),
      at(DateTime(2026, 11, 16, 9), 120)
        ..tools.addAll([PracticeTool.gap, PracticeTool.ramp]),
      at(DateTime(2026, 11, 18, 9), 60),
    ]);
    expect((s.seconds, s.sessions, s.days, s.longest), (480, 3, 2, 300));
    expect(s.toolSeconds[PracticeTool.ramp], 420);
    expect(s.toolSeconds[PracticeTool.gap], 120);
    expect(s.toolSeconds[PracticeTool.displace], 0);
    expect(s.plainSeconds, 60);
  });

  test('tools survive the file; unknown ones are dropped', () {
    final p = at(DateTime(2026, 11, 18), 60)
      ..tools.addAll([PracticeTool.gap, PracticeTool.displace]);
    final back = Practice.fromJson(jsonDecode(jsonEncode(p.toJson())))!;
    expect(back.tools, {PracticeTool.gap, PracticeTool.displace});
    final junk = Practice.fromJson({
      ...p.toJson(),
      'tools': ['laser', 3],
    })!;
    expect(junk.tools, isEmpty);
  });

  test('per song: time, times, tempo first, latest and best', () {
    final songs = practiceBySong([
      at(DateTime(2026, 11, 10), 600, song: 'Praise', bpm: 110),
      at(DateTime(2026, 11, 12), 60, song: 'Coro', bpm: 90),
      at(DateTime(2026, 11, 15), 300, song: 'praise', bpm: 127),
      at(DateTime(2026, 11, 16), 300, song: 'Praise', bpm: 120),
      at(DateTime(2026, 11, 17), 30, bpm: 80),
    ]);
    // Most practised first.
    expect([for (final s in songs) s.song], ['Praise', 'Coro', null]);
    final praise = songs.first;
    expect((praise.seconds, praise.times, praise.key), (1200, 3, 'praise'));
    expect((praise.firstBpm, praise.lastBpm, praise.bestBpm), (110, 120, 127));
  });
}
