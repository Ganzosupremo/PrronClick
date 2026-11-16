// Checks scheduled song changes in the engine: at beat 8 switch from
// 120 BPM 4/4 to 60 BPM 3/4 (first bar silent) without a jump in the beat,
// then stop at the end of the next two bars.
//   dart --packages=.dart_tool/package_config.json tool/setlist_smoke.dart <path to engine lib>
import 'dart:io';

import 'package:prronclick/engine.dart';

void main(List<String> args) async {
  final e = Engine(args[0]);
  if (!e.init()) throw 'audio init failed';
  e.setTempo(120);
  e.setBeatsPerBar(4);
  e.setCountIn(1);
  e.setPlaying(true);
  final firstCount = e.countUntil(); // one bar of 4/4 from beat 0
  e.scheduleSong(8, 60, 3, 1);

  // (seconds, beat) samples around the change.
  final samples = <(double, double)>[];
  final clock = Stopwatch()..start();
  while (e.beat() < 11) {
    samples.add((clock.elapsedMicroseconds / 1e6, e.beat()));
    await Future.delayed(const Duration(milliseconds: 20));
  }
  final failures = <String>[];
  void check(bool ok, String what) => ok ? null : failures.add(what);
  check((e.tempo() - 60).abs() < 0.01, 'tempo ${e.tempo()} != 60');
  check(e.beatsPerBar() == 3, 'meter ${e.beatsPerBar()} != 3');
  check(e.barOrigin() == 8, 'origin ${e.barOrigin()} != 8');
  check(e.muteUntil() == 11, 'pause ends at ${e.muteUntil()}, not 11');
  check(firstCount == 4, 'first count-in ends at $firstCount, not 4');
  check(e.countUntil() == 14, 'count-in ends at ${e.countUntil()}, not 14');

  // Fit a line on each side and find where each reaches beat 8: the same
  // moment if the beat did not jump.
  double crossAt(Iterable<(double, double)> pts) {
    final p = pts.toList();
    final n = p.length;
    final mx = p.map((x) => x.$1).reduce((a, b) => a + b) / n;
    final my = p.map((x) => x.$2).reduce((a, b) => a + b) / n;
    var sxy = 0.0, sxx = 0.0;
    for (final (x, y) in p) {
      sxy += (x - mx) * (y - my);
      sxx += (x - mx) * (x - mx);
    }
    final slope = sxy / sxx;
    return mx + (8 - my) / slope;
  }

  final before = crossAt(samples.where((s) => s.$2 > 2 && s.$2 < 7.8));
  final after = crossAt(samples.where((s) => s.$2 > 8.2));
  final jumpMs = (after - before) * 1000;
  check(jumpMs.abs() < 5, 'beat jumped ${jumpMs.toStringAsFixed(1)} ms');

  e.scheduleSong(14, 0, 3, 0); // last song ends after two bars of 3/4
  while (e.isPlaying() && clock.elapsed.inSeconds < 15) {
    await Future.delayed(const Duration(milliseconds: 20));
  }
  final stopBeat = e.beat();
  check(!e.isPlaying(), 'did not stop');
  stdout.writeln(
    'change jump ${jumpMs.toStringAsFixed(2)} ms, stopped near beat '
    '${stopBeat.toStringAsFixed(2)}',
  );
  e.shutdown();
  if (failures.isNotEmpty) {
    stdout.writeln('FAIL: ${failures.join('; ')}');
    exitCode = 1;
  }
}
