// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math';

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'app_state.dart';
import 'l10n/app_localizations.dart';
import 'practice.dart';

/// "12 s", "25 min", "1 h 5 min".
String practiceTime(AppLocalizations t, int seconds) {
  if (seconds < 60) return t.durationS(seconds);
  final minutes = (seconds / 60).round();
  return minutes < 60
      ? t.durationM(minutes)
      : t.durationHm(minutes ~/ 60, minutes % 60);
}

String toolName(AppLocalizations t, PracticeTool tool) => switch (tool) {
  PracticeTool.ramp => t.tempoRamp,
  PracticeTool.gap => t.gapTrainer,
  PracticeTool.displace => t.displacedClick,
};

/// How much was practised in a day, week or month; tapping a day of the
/// chart narrows everything below it to that day.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.state});

  final AppState state;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  HistoryRange _range = HistoryRange.week;
  Period? _period; // null = the one holding [_anchor]
  DateTime? _anchor; // a time inside the period to show; null = now
  DateTime? _day; // a day picked on the chart
  int? _bar; // the bar picked, for its caption

  int _firstWeekday(BuildContext context) =>
      // MaterialLocalizations counts from Sunday = 0.
      (MaterialLocalizations.of(context).firstDayOfWeekIndex + 6) % 7 + 1;

  void _setRange(HistoryRange range, Period shown) => setState(() {
    // Keep looking at the same time: the picked day, else today if it is in
    // the period shown, else the period's start.
    final now = DateTime.now();
    _anchor =
        _day ??
        (!now.isBefore(shown.from) && now.isBefore(shown.to)
            ? now
            : shown.from);
    _range = range;
    _period = null;
    _day = null;
    _bar = null;
  });

  void _move(int steps, Period period) => setState(() {
    _period = shiftPeriod(_range, period, steps);
    _day = null;
    _bar = null;
  });

  Future<void> _clear() async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.historyClear),
        content: Text(t.historyClearAsk),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );
    if (ok == true) widget.state.clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final history = widget.state.library.history;
        return Scaffold(
          appBar: AppBar(
            title: Text(t.history),
            actions: [
              if (history.isNotEmpty)
                IconButton(
                  tooltip: t.historyClear,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _clear,
                ),
            ],
          ),
          body: history.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(t.historyEmpty, textAlign: TextAlign.center),
                  ),
                )
              : _body(context, history),
        );
      },
    );
  }

  Widget _body(BuildContext context, List<Practice> history) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final period =
        _period ??
        periodOf(_range, _anchor ?? now, firstWeekday: _firstWeekday(context));
    final inPeriod = entriesIn(history, period);
    final day = _day;
    final entries = day == null
        ? inPeriod
        : entriesIn(history, (from: day, to: addDays(day, 1)));
    final summary = PracticeSummary(entries);
    final isLatest = !period.to.isBefore(addDays(dayOf(now), 1));

    final title = switch (_range) {
      HistoryRange.day => DateFormat.yMMMEd(locale).format(period.from),
      HistoryRange.week =>
        '${DateFormat.MMMd(locale).format(period.from)} – '
            '${DateFormat.yMMMd(locale).format(addDays(period.to, -1))}',
      HistoryRange.month => DateFormat.yMMMM(locale).format(period.from),
    };

    // Against the period before, while the whole period is shown.
    String? change;
    if (day == null) {
      final before = PracticeSummary(
        entriesIn(history, shiftPeriod(_range, period, -1)),
      ).seconds;
      if (before > 0) {
        final pct = ((summary.seconds - before) * 100 / before).round();
        final text = '${pct > 0 ? '+' : ''}$pct %';
        change = switch (_range) {
          HistoryRange.day => t.historyVsPrevDay(text),
          HistoryRange.week => t.historyVsPrevWeek(text),
          HistoryRange.month => t.historyVsPrevMonth(text),
        };
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<HistoryRange>(
          segments: [
            ButtonSegment(
              value: HistoryRange.day,
              label: Text(t.historyRangeDay),
            ),
            ButtonSegment(
              value: HistoryRange.week,
              label: Text(t.historyRangeWeek),
            ),
            ButtonSegment(
              value: HistoryRange.month,
              label: Text(t.historyRangeMonth),
            ),
          ],
          selected: {_range},
          showSelectedIcon: false,
          onSelectionChanged: (s) => _setRange(s.single, period),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              tooltip: t.historyPrevious,
              onPressed: () => _move(-1, period),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: t.historyNext,
              onPressed: isLatest ? null : () => _move(1, period),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        if (day != null)
          Align(
            child: InputChip(
              label: Text(DateFormat.MMMEd(locale).format(day)),
              onDeleted: () => setState(() {
                _day = null;
                _bar = null;
              }),
              deleteButtonTooltipMessage: t.historyWholePeriod,
            ),
          ),
        const SizedBox(height: 8),
        _Figures(
          tiles: [
            (t.historyTime, practiceTime(t, summary.seconds), change),
            (t.historySessionsLabel, '${summary.sessions}', null),
            if (_range == HistoryRange.day || day != null)
              (t.historyLongest, practiceTime(t, summary.longest), null)
            else
              (t.historyDaysLabel, '${summary.days}', null),
            (t.historyStreak, t.historyStreakDays(streak(history, now)), null),
          ],
        ),
        const SizedBox(height: 16),
        _BarChart(
          range: _range,
          period: period,
          seconds: buckets(inPeriod, _range, period),
          picked: _bar,
          onPick: (i) => setState(() {
            if (_range == HistoryRange.day) {
              _bar = _bar == i ? null : i;
              return;
            }
            final picked = addDays(period.from, i);
            _day = _day == picked ? null : picked;
            _bar = _day == null ? null : i;
          }),
        ),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(t.historyNothing, textAlign: TextAlign.center),
          )
        else ...[
          _Songs(state: widget.state, entries: entries, total: summary.seconds),
          const SizedBox(height: 16),
          _Tools(summary: summary),
          const SizedBox(height: 16),
          _Sessions(
            entries: entries,
            showDate: day == null && _range != HistoryRange.day,
          ),
        ],
      ],
    );
  }
}

/// Headline numbers, two to a row.
class _Figures extends StatelessWidget {
  const _Figures({required this.tiles});

  final List<(String label, String value, String? note)> tiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget tile((String, String, String?) f) => Expanded(
      child: Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(f.$1, style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(f.$2, style: theme.textTheme.titleLarge),
              if (f.$3 case final note?)
                Text(note, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                tile(tiles[i]),
                if (i + 1 < tiles.length)
                  tile(tiles[i + 1])
                else
                  const Spacer(),
              ],
            ),
          ),
      ],
    );
  }
}

/// Time per hour (a day) or per day (a week or month). Tapping a bar shows
/// its value; in a week or month it also picks that day.
class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.range,
    required this.period,
    required this.seconds,
    required this.picked,
    required this.onPick,
  });

  final HistoryRange range;
  final Period period;
  final List<int> seconds;
  final int? picked;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final top = seconds.fold(0, max);
    final today = dayOf(DateTime.now());
    final small = theme.textTheme.bodySmall!;
    final pick = picked;

    String label(int i) => switch (range) {
      HistoryRange.day => '$i',
      HistoryRange.week => DateFormat.E(locale).format(addDays(period.from, i)),
      HistoryRange.month => '${i + 1}',
    };
    // Which bars get an axis label: every 6 hours, every day of a week,
    // every 7th day of a month.
    bool labelled(int i) => switch (range) {
      HistoryRange.day => i % 6 == 0,
      HistoryRange.week => true,
      HistoryRange.month => i % 7 == 0,
    };
    String name(int i) => switch (range) {
      HistoryRange.day => '$i:00–${i + 1}:00',
      _ => DateFormat.MMMEd(locale).format(addDays(period.from, i)),
    };

    final caption = pick == null
        ? (range == HistoryRange.day ? t.historyTapHour : t.historyTapDay)
        : '${name(pick)}: ${practiceTime(t, seconds[pick])}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(caption, style: small)),
            if (top > 0) Text(t.historyMax(practiceTime(t, top)), style: small),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < seconds.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    label: '${name(i)}: ${practiceTime(t, seconds[i])}',
                    child: GestureDetector(
                      // The whole column is the target, not only the bar.
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onPick(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: top == 0 || seconds[i] == 0
                                ? 0
                                : max(3.0, 110 * seconds[i] / top),
                            margin: EdgeInsets.symmetric(
                              horizontal: seconds.length > 7 ? 1 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: pick == null || pick == i
                                  ? scheme.primary
                                  : scheme.primary.withValues(alpha: 0.35),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                          Divider(height: 1, color: scheme.outlineVariant),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 16,
                            child: labelled(i)
                                ? OverflowBox(
                                    maxWidth: 48,
                                    child: Text(
                                      label(i),
                                      style: small.copyWith(
                                        fontWeight:
                                            range != HistoryRange.day &&
                                                addDays(period.from, i) == today
                                            ? FontWeight.bold
                                            : null,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A row with a name, a value and a bar for its share of the whole.
class _ShareRow extends StatelessWidget {
  const _ShareRow({
    required this.title,
    required this.value,
    required this.share,
    this.detail,
    this.onTap,
  });

  final String title;
  final String value;
  final double share; // 0..1
  final String? detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, overflow: TextOverflow.ellipsis)),
                Text(value),
                if (onTap != null)
                  Icon(Icons.chevron_right, size: 20, color: scheme.outline),
              ],
            ),
            if (detail case final d?) Text(d, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: share,
                minHeight: 6,
                color: scheme.primary,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Songs extends StatelessWidget {
  const _Songs({
    required this.state,
    required this.entries,
    required this.total,
  });

  final AppState state;
  final List<Practice> entries;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.historySongs, style: theme.textTheme.titleMedium),
        for (final s in practiceBySong(entries))
          _ShareRow(
            title: s.song ?? t.historyNoSong,
            value: practiceTime(t, s.seconds),
            share: total == 0 ? 0 : s.seconds / total,
            detail: [
              t.historyTimes(s.times),
              s.firstBpm == s.lastBpm && s.lastBpm == s.bestBpm
                  ? t.historyBpm(s.lastBpm)
                  : t.historyTempo(s.firstBpm, s.lastBpm, s.bestBpm),
            ].join(' · '),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SongProgressPage(state: state, songKey: s.key),
              ),
            ),
          ),
      ],
    );
  }
}

class _Tools extends StatelessWidget {
  const _Tools({required this.summary});

  final PracticeSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final total = summary.seconds;
    double share(int s) => total == 0 ? 0 : s / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.historyTools, style: theme.textTheme.titleMedium),
        for (final MapEntry(key: tool, value: seconds)
            in summary.toolSeconds.entries)
          if (seconds > 0)
            _ShareRow(
              title: toolName(t, tool),
              value: practiceTime(t, seconds),
              share: share(seconds),
            ),
        _ShareRow(
          title: t.historyNoTools,
          value: practiceTime(t, summary.plainSeconds),
          share: share(summary.plainSeconds),
        ),
      ],
    );
  }
}

/// Every session, latest first.
class _Sessions extends StatelessWidget {
  const _Sessions({required this.entries, required this.showDate});

  final List<Practice> entries;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final time = DateFormat.Hm(locale);
    final date = DateFormat.MMMEd(locale);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.historySessionsLabel, style: theme.textTheme.titleMedium),
        for (final p in entries.reversed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: SizedBox(
              width: showDate ? 80 : 48,
              child: Text(
                showDate
                    ? '${date.format(p.start)}\n${time.format(p.start)}'
                    : time.format(p.start),
                style: theme.textTheme.bodySmall,
              ),
            ),
            title: Text(p.song ?? t.historyNoSong),
            subtitle: Text(
              [
                practiceTime(t, p.seconds),
                t.historyBpm(p.bpm),
                for (final tool in p.tools) toolName(t, tool),
              ].join(' · '),
            ),
          ),
      ],
    );
  }
}

/// One song over time: its tempo session by session, and every session.
class SongProgressPage extends StatefulWidget {
  const SongProgressPage({
    super.key,
    required this.state,
    required this.songKey,
  });

  final AppState state;
  final String songKey;

  @override
  State<SongProgressPage> createState() => _SongProgressPageState();
}

class _SongProgressPageState extends State<SongProgressPage> {
  int? _picked; // the session picked on the chart

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final song = practiceBySong(widget.state.library.history)
            .where((s) => s.key == widget.songKey)
            .firstOrNull;
        if (song == null) {
          return Scaffold(appBar: AppBar(), body: const SizedBox());
        }
        final sessions = song.sessions;
        final i = _picked;
        final picked = i == null || i >= sessions.length ? null : sessions[i];
        final small = theme.textTheme.bodySmall!;
        final date = DateFormat.MMMd(locale);
        final gain = song.lastBpm - song.firstBpm;
        return Scaffold(
          appBar: AppBar(title: Text(song.song ?? t.historyNoSong)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Figures(
                tiles: [
                  (t.historyTime, practiceTime(t, song.seconds), null),
                  (t.historySessionsLabel, '${song.times}', null),
                  (t.historyBestBpm, t.historyBpm(song.bestBpm), null),
                  (
                    t.historyTempoChange,
                    '${gain > 0 ? '+' : ''}$gain BPM',
                    '${song.firstBpm} → ${song.lastBpm} BPM',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                t.historyTempoPerSession,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                picked == null
                    ? t.historyTapPoint
                    : '${DateFormat.MMMEd(locale).format(picked.start)} '
                          '${DateFormat.Hm(locale).format(picked.start)} · '
                          '${t.historyBpm(picked.bpm)} · '
                          '${practiceTime(t, picked.seconds)}',
                style: small,
              ),
              const SizedBox(height: 8),
              _TempoChart(
                bpms: [for (final s in sessions) s.bpm],
                picked: picked == null ? null : i,
                onPick: (i) => setState(() => _picked = i),
              ),
              Row(
                children: [
                  const SizedBox(width: 40),
                  Text(date.format(sessions.first.start), style: small),
                  const Spacer(),
                  Text(date.format(sessions.last.start), style: small),
                ],
              ),
              const SizedBox(height: 16),
              _Sessions(entries: sessions, showDate: true),
            ],
          ),
        );
      },
    );
  }
}

/// The tempo of each session, in order, as a line. Touching it picks the
/// nearest session.
class _TempoChart extends StatelessWidget {
  const _TempoChart({
    required this.bpms,
    required this.picked,
    required this.onPick,
  });

  final List<int> bpms;
  final int? picked;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final small = theme.textTheme.bodySmall!;
    final low = bpms.reduce(min), high = bpms.reduce(max);
    // A little room above and below, never a flat zero-height range.
    final bottom = max(20, low - 5), top = max(high + 5, bottom + 10);
    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$top', style: small),
                Text('$bottom', style: small),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                void pick(Offset at) {
                  if (bpms.length == 1) return onPick(0);
                  final i = (at.dx / box.maxWidth * (bpms.length - 1)).round();
                  onPick(i.clamp(0, bpms.length - 1));
                }

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => pick(d.localPosition),
                  onHorizontalDragUpdate: (d) => pick(d.localPosition),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _TempoPainter(
                      bpms: bpms,
                      bottom: bottom.toDouble(),
                      top: top.toDouble(),
                      picked: picked,
                      line: scheme.primary,
                      grid: scheme.outlineVariant,
                      surface: scheme.surface,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TempoPainter extends CustomPainter {
  _TempoPainter({
    required this.bpms,
    required this.bottom,
    required this.top,
    required this.picked,
    required this.line,
    required this.grid,
    required this.surface,
  });

  final List<int> bpms;
  final double bottom, top;
  final int? picked;
  final Color line, grid, surface;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 8.0; // markers at the edges stay whole
    final w = size.width - 2 * pad, h = size.height - 2 * pad;
    Offset at(int i) => Offset(
      pad + (bpms.length == 1 ? w / 2 : w * i / (bpms.length - 1)),
      pad + h * (1 - (bpms[i] - bottom) / (top - bottom)),
    );
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final y in [pad, pad + h]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < bpms.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    // Markers while they fit; with many sessions only the picked one.
    final dots = bpms.length <= 30;
    for (var i = 0; i < bpms.length; i++) {
      if (!dots && i != picked) continue;
      final r = i == picked ? 6.0 : 4.0;
      canvas.drawCircle(at(i), r + 2, Paint()..color = surface);
      canvas.drawCircle(at(i), r, Paint()..color = line);
    }
  }

  @override
  bool shouldRepaint(_TempoPainter old) =>
      old.bpms != bpms || old.picked != picked || old.line != line;
}
