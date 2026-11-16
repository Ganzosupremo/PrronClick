// Smoke check, acting as the leader: join the Link session, wait for a peer
// (another instance of this script, or the app in follower mode), then set
// the tempo and start, and check beats advance at that tempo.
//   dart --packages=.dart_tool/package_config.json tool/link_smoke.dart <path to engine lib> [seconds]
import 'dart:io';

import 'package:prronclick/engine.dart';

void main(List<String> args) async {
  final e = Engine(args[0]);
  final seconds = args.length > 1 ? int.parse(args[1]) : 2;
  if (!e.init()) throw 'audio init failed';
  e.setLinkEnabled(true);
  for (var i = 0; i < 50 && e.numPeers() == 0; i++) {
    await Future.delayed(const Duration(milliseconds: 100));
  }
  e.setTempo(150);
  e.setPlaying(true);
  await Future.delayed(const Duration(milliseconds: 500));
  final b0 = e.beat();
  final t0 = DateTime.now();
  await Future.delayed(Duration(seconds: seconds));
  final b1 = e.beat();
  final secs = DateTime.now().difference(t0).inMicroseconds / 1e6;
  final rate = (b1 - b0) / secs * 60;
  stdout.writeln(
    'tempo=${e.tempo()} playing=${e.isPlaying()} peers=${e.numPeers()} '
    'measuredBpm=${rate.toStringAsFixed(2)}',
  );
  if ((rate - 150).abs() >= 1) exitCode = 1;
  e.setPlaying(false);
  e.shutdown();
}
