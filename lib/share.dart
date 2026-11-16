// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'engine.dart';

/// Shares what Link does not: where bars start and when to start playing.
///
/// Link keeps tempo and beat phase in sync, but each peer numbers beats
/// differently (off by a whole number k). The leader broadcasts its beat and
/// bar origin; each follower works out k and shifts the origin by it.
class ShareChannel {
  ShareChannel._(this.engine, this.socket, {this.songName, this.onSongName});

  static const port = 20809;
  static const _interval = Duration(milliseconds: 300);

  final Engine engine;
  final RawDatagramSocket socket;
  Timer? _timer;

  /// Leader: name of the song being played, if any.
  final String? Function()? songName;

  /// Follower: called with the leader's song name (null = none).
  final void Function(String?)? onSongName;

  // Follower: recent k values (median rejects a packet delayed past a beat).
  final _ks = <int>[];
  bool? _leaderPlaying;

  static Future<ShareChannel> leader(
    Engine engine, {
    String? Function()? songName,
  }) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)
      ..broadcastEnabled = true;
    final channel = ShareChannel._(engine, socket, songName: songName);
    channel._timer = Timer.periodic(_interval, (_) => channel._send());
    return channel;
  }

  static Future<ShareChannel> follower(
    Engine engine, {
    void Function(String?)? onSongName,
  }) async {
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      port,
      reuseAddress: true,
    );
    final channel = ShareChannel._(engine, socket, onSongName: onSongName);
    socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = socket.receive();
      if (datagram != null) channel.onMessage(datagram.data);
    });
    return channel;
  }

  void close() {
    _timer?.cancel();
    socket.close();
  }

  void _send() {
    final next = engine.pendingBeatsPerBar();
    final song = songName?.call();
    final message = {
      'v': 1,
      'beat': engine.beat(),
      'playing': engine.isPlaying(),
      'bpb': engine.beatsPerBar(),
      'origin': engine.barOrigin(),
      if (next > 0) 'next': {'bpb': next, 'origin': engine.pendingOrigin()},
      'song': ?song,
    };
    // shortcut: limited broadcast goes out one interface only; send per
    // interface (subnet broadcast) if a multi-homed leader is not heard.
    socket.send(
      utf8.encode(jsonEncode(message)),
      InternetAddress('255.255.255.255'),
      port,
    );
  }

  /// Applies one leader message. Anything malformed is ignored: it comes from
  /// whoever is on the network.
  void onMessage(List<int> bytes) {
    final Object? m;
    try {
      m = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      return;
    }
    if (m is! Map || m['v'] != 1) return;
    final beat = m['beat'], playing = m['playing'];
    final bpb = m['bpb'], origin = m['origin'];
    if (beat is! num || playing is! bool || bpb is! int || origin is! num) {
      return;
    }
    var nextBpb = 0;
    num nextOrigin = 0;
    final next = m['next'];
    if (next is Map && next['bpb'] is int && next['origin'] is num) {
      nextBpb = next['bpb'] as int;
      nextOrigin = next['origin'] as num;
    }
    // Without a Link connection our beats are unrelated to the leader's.
    if (engine.numPeers() == 0) return;
    final song = m['song'];
    onSongName?.call(song is String ? song : null);

    // Starting re-numbers our beats, and so does the leader starting: old k
    // values no longer apply.
    if (playing && !engine.isPlaying()) {
      engine.setPlaying(true);
      _ks.clear();
    }
    if (playing != _leaderPlaying) {
      _ks.clear();
      _leaderPlaying = playing;
    }
    // The packet is a little late, so our beat is a little ahead: floor works.
    _ks.add((engine.beat() - beat + 0.05).floor());
    if (_ks.length > 5) _ks.removeAt(0);
    final k = ([..._ks]..sort())[_ks.length ~/ 2];

    engine.setBar(
      bpb,
      origin.toDouble() + k,
      nextBpb,
      nextOrigin.toDouble() + k,
    );
  }
}
