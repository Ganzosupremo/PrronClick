// SPDX-License-Identifier: GPL-3.0-or-later
// Checks that session codes keep bands apart. Run two at once on one PC:
//   dart --packages=.dart_tool/package_config.json tool/session_smoke.dart <engine lib> <code> [<code> ...]
// Each joins Link with its first code, prints how many peers it sees each
// second for 8 s, then moves to the next code, and so on.
import 'dart:io';

import 'package:prronclick/engine.dart';
import 'package:prronclick/share.dart';

Future<void> main(List<String> args) async {
  final e = Engine(args[0]);
  if (!e.init()) throw 'audio init failed';
  for (final code in args.skip(1)) {
    // The same steps as AppState.setSessionCode.
    e.setLinkEnabled(false);
    e.setLinkPort(sessionPort(code));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    e.setLinkEnabled(true);
    // One figure a second: peers take a moment to find each other.
    final seen = <int>[];
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      seen.add(e.numPeers());
    }
    stdout.writeln('code "$code" port ${sessionPort(code)}: peers $seen');
  }
  e.shutdown();
}
