// SPDX-License-Identifier: GPL-3.0-or-later
// Follows the Link session and runs the latency calibration against the
// leader's clicks, printing how late this machine sounds.
// usage: dart run tool/calibrate_smoke.dart <path to prronclick_engine> [extraMs]
import 'dart:io';

import 'package:prronclick/engine.dart';
import 'package:prronclick/share.dart';

Future<void> main(List<String> args) async {
  final e = Engine(args[0]);
  if (!e.init()) throw StateError('audio failed');
  if (args.length > 1) e.setExtraLatencyMs(double.parse(args[1]));
  e.setLinkEnabled(true);
  final share = await ShareChannel.follower(e, port: standardLinkPort + 1);
  for (var i = 0; i < 100 && !(e.numPeers() > 0 && e.isPlaying()); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  stdout.writeln('peers ${e.numPeers()} playing ${e.isPlaying()} '
      'tempo ${e.tempo().toStringAsFixed(1)} '
      'output latency ${e.outputLatencyMs().toStringAsFixed(1)} ms');
  await Future<void>.delayed(const Duration(seconds: 1));
  if (!e.calibrationStart()) throw StateError('mic failed');
  await Future<void>.delayed(const Duration(seconds: 8));
  stdout.writeln('late ${e.calibrationFinish().toStringAsFixed(1)} ms');
  share.close();
  e.shutdown();
}
