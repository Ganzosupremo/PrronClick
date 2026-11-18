// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;

import 'engine.dart';
import 'song.dart';

/// What the band sees about the music: the song and, inside a setlist, where
/// it stands. [changeBeat] is in the beats of whoever holds the object.
class ShowInfo {
  const ShowInfo({
    this.song,
    this.author,
    this.key,
    this.note,
    this.beatUnit = 4,
    this.accents,
    this.transpose = 0,
    this.section,
    this.nextSection,
    this.sectionChange,
    this.setlist,
    this.position = 0,
    this.total = 0,
    this.next,
    this.changeBeat,
  });

  final String? song;
  final String? author; // the song's author
  final String? key; // the song's musical key
  final String? note; // the song's one-line note for the band
  final int beatUnit; // the meter's lower number (notation only)
  final List<int>? accents; // the song's own; null = automatic
  final int
  transpose; // semitones the chords are shown moved ([key] already is)
  final String? section; // the song's section playing now
  final String? nextSection; // the one scheduled, once it is
  final double? sectionChange; // the beat where it starts
  final String? setlist; // null = no setlist running
  final int position; // 1-based
  final int total;
  final String? next; // next song's name; null = last song
  final double? changeBeat; // when the next song (or the end) starts

  Map<String, Object?> toJson() => {
    'song': ?song,
    'author': ?author,
    'key': ?key,
    'note': ?note,
    if (beatUnit != 4) 'unit': beatUnit,
    'accents': ?accents,
    if (transpose != 0) 'transpose': transpose,
    'section': ?section,
    if (nextSection != null)
      'nextSection': {'name': nextSection, 'at': sectionChange},
    if (setlist != null)
      'setlist': {
        'name': setlist,
        'pos': position,
        'total': total,
        'next': ?next,
        'change': ?changeBeat,
      },
  };

  /// Parses a leader's message, shifting its beat by [k] into ours. Strings
  /// are capped: they come from the network.
  static ShowInfo fromMessage(Map<Object?, Object?> m, int k) {
    String? text(Object? v) =>
        v is String ? (v.length > 80 ? v.substring(0, 80) : v) : null;
    final s = m['setlist'];
    final song = text(m['song']), key = text(m['key']), note = text(m['note']);
    final author = text(m['author']);
    final unit = beatUnits.contains(m['unit']) ? m['unit'] as int : 4;
    final accents = parseAccents(m['accents']);
    final transpose = switch (m['transpose']) {
      final int n when n.abs() <= 11 => n,
      _ => 0,
    };
    final ns = m['nextSection'];
    final nextSection = ns is Map ? text(ns['name']) : null;
    final at = ns is Map ? ns['at'] : null;
    final sectionChange = nextSection != null && at is num
        ? at.toDouble() + k
        : null;
    if (s is! Map) {
      return ShowInfo(
        song: song,
        author: author,
        key: key,
        note: note,
        beatUnit: unit,
        accents: accents,
        transpose: transpose,
        section: text(m['section']),
        nextSection: nextSection,
        sectionChange: sectionChange,
      );
    }
    final pos = s['pos'], total = s['total'], change = s['change'];
    return ShowInfo(
      song: song,
      author: author,
      key: key,
      note: note,
      beatUnit: unit,
      accents: accents,
      transpose: transpose,
      section: text(m['section']),
      nextSection: nextSection,
      sectionChange: sectionChange,
      setlist: text(s['name']),
      position: pos is int ? pos : 0,
      total: total is int ? total : 0,
      next: text(s['next']),
      changeBeat: change is num ? change.toDouble() + k : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ShowInfo &&
      other.song == song &&
      other.author == author &&
      other.key == key &&
      other.note == note &&
      other.beatUnit == beatUnit &&
      sameAccents(other.accents, accents) &&
      other.transpose == transpose &&
      other.section == section &&
      other.nextSection == nextSection &&
      other.sectionChange == sectionChange &&
      other.setlist == setlist &&
      other.position == position &&
      other.total == total &&
      other.next == next &&
      other.changeBeat == changeBeat;

  @override
  int get hashCode => Object.hash(
    song,
    author,
    key,
    note,
    beatUnit,
    accentBits(accents ?? const []),
    transpose,
    section,
    nextSection,
    sectionChange,
    setlist,
    position,
    total,
    next,
    changeBeat,
  );
}

/// Link's own discovery port, shared with Ableton Live and every Link app.
const standardLinkPort = 20808;

/// The port a band with this session code meets on: Link's own without a
/// code, else one of 500 even ports from 21000 (the odd one above each is
/// for our bar broadcast). Case and outer spaces do not count.
int sessionPort(String code) {
  final c = code.trim().toLowerCase();
  if (c.isEmpty) return standardLinkPort;
  var hash = 0x811c9dc5; // FNV-1a: the same on every device
  for (final byte in utf8.encode(c)) {
    hash = ((hash ^ byte) * 0x01000193) & 0xFFFFFFFF;
  }
  return 21000 + 2 * (hash % 500);
}

/// Shares what Link does not: where bars start and when to start playing.
///
/// Link keeps tempo and beat phase in sync, but each peer numbers beats
/// differently (off by a whole number k). The leader broadcasts its beat and
/// bar origin; each follower works out k and shifts the origin by it.
///
/// The leader also hands out its setlist with the songs' lyrics, too big for
/// a datagram: each message names its version, and a follower that has not
/// got that one fetches it over TCP from the same port.
class ShareChannel {
  ShareChannel._(
    this.engine,
    this.socket,
    this.port, {
    this.info,
    this.onInfo,
    this.songs,
    this.onSongs,
  });

  /// UDP port of the broadcast: the one above Link's (see [sessionPort]).
  final int port;
  static const _interval = Duration(milliseconds: 300);
  // Changes (start, new meter or song) go out at once: a follower started by
  // Link must not keep stale bars until the next periodic message.
  static const _poll = Duration(milliseconds: 20);

  final Engine engine;
  final RawDatagramSocket socket;
  Timer? _timer;

  /// Leader: what to tell followers about the song and setlist.
  final ShowInfo Function()? info;

  /// Follower: called with what the leader says about the song and setlist.
  final void Function(ShowInfo)? onInfo;

  /// Leader: the setlist and songs to hand out, as JSON.
  final String Function()? songs;
  ServerSocket? _server;
  String? _payload;
  final _payloadAge = Stopwatch();

  /// Follower: called with the leader's setlist and songs (still unchecked).
  final void Function(Object? json)? onSongs;
  int? _songsVersion;
  bool _fetching = false;
  Stopwatch? _sinceFetch;
  static const _maxSongBytes = 4 << 20;

  // Follower: recent k values (median rejects a packet delayed past a beat).
  final _ks = <int>[];
  bool? _leaderPlaying;

  static Future<ShareChannel> leader(
    Engine engine, {
    required int port,
    ShowInfo Function()? info,
    String Function()? songs,
  }) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)
      ..broadcastEnabled = true;
    final channel = ShareChannel._(
      engine,
      socket,
      port,
      info: info,
      songs: songs,
    );
    if (songs != null) {
      try {
        channel._server = await ServerSocket.bind(
          InternetAddress.anyIPv4,
          port,
        );
        channel._server!.listen((client) async {
          try {
            client.add(utf8.encode(channel._songsPayload()));
            await client.close();
          } on SocketException {
            client.destroy();
          }
        });
      } on SocketException catch (e) {
        // The click is still shared; only the lyrics are not.
        debugPrint('setlist sharing unavailable: $e');
      }
    }
    final sinceSent = Stopwatch()..start();
    String? lastState;
    channel._timer = Timer.periodic(_poll, (_) {
      final e = channel.engine;
      final state =
          '${e.isPlaying()} ${e.beatsPerBar()} ${e.barOrigin()} '
          '${e.pendingBeatsPerBar()} ${e.pendingOrigin()} ${e.muteUntil()} '
          '${e.countUntil()} '
          '${info?.call().toJson()}';
      if (state == lastState && sinceSent.elapsed < _interval) return;
      lastState = state;
      sinceSent.reset();
      channel._send();
    });
    return channel;
  }

  static Future<ShareChannel> follower(
    Engine engine, {
    required int port,
    void Function(ShowInfo)? onInfo,
    void Function(Object? json)? onSongs,
  }) async {
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      port,
      reuseAddress: true,
    );
    final channel = ShareChannel._(
      engine,
      socket,
      port,
      onInfo: onInfo,
      onSongs: onSongs,
    );
    socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = socket.receive();
      if (datagram != null) {
        channel.onMessage(datagram.data, from: datagram.address);
      }
    });
    return channel;
  }

  void close() {
    _timer?.cancel();
    socket.close();
    _server?.close();
  }

  // Built at most once a second: messages go out up to every 20 ms.
  String _songsPayload() {
    if (_payload == null || _payloadAge.elapsed > const Duration(seconds: 1)) {
      _payload = songs!();
      _payloadAge
        ..reset()
        ..start();
    }
    return _payload!;
  }

  /// Follower: gets version [version] of the setlist from the leader at
  /// [from], unless we have it, are getting it, or just failed to.
  Future<void> _fetchSongs(int version, InternetAddress from) async {
    if (version == _songsVersion || _fetching) return;
    if (_sinceFetch case final s? when s.elapsed < const Duration(seconds: 2)) {
      return;
    }
    _fetching = true;
    _sinceFetch = Stopwatch()..start();
    try {
      final client = await Socket.connect(
        from,
        port,
        timeout: const Duration(seconds: 2),
      );
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in client.timeout(const Duration(seconds: 5))) {
        bytes.add(chunk);
        if (bytes.length > _maxSongBytes) {
          client.destroy();
          throw const FormatException('setlist too big');
        }
      }
      final json = jsonDecode(utf8.decode(bytes.takeBytes()));
      _songsVersion = version;
      onSongs?.call(json);
    } on Exception catch (e) {
      debugPrint('could not get the leader\'s setlist: $e');
    } finally {
      _fetching = false;
    }
  }

  void _send() {
    final next = engine.pendingBeatsPerBar();
    final message = {
      'v': 1,
      'beat': engine.beat(),
      'playing': engine.isPlaying(),
      'bpb': engine.beatsPerBar(),
      'origin': engine.barOrigin(),
      'mute': engine.muteUntil(),
      'count': engine.countUntil(),
      if (next > 0)
        'next': {
          'bpb': next,
          'origin': engine.pendingOrigin(),
          'mute': engine.pendingMuteBeats(),
          'count': engine.pendingCountBeats(),
        },
      ...?info?.call().toJson(),
      if (songs != null && _server != null) 'songs': _songsPayload().hashCode,
    };
    // shortcut: limited broadcast goes out one interface only; send per
    // interface (subnet broadcast) if a multi-homed leader is not heard.
    socket.send(
      utf8.encode(jsonEncode(message)),
      InternetAddress('255.255.255.255'),
      port,
    );
  }

  /// Applies one leader message, sent from [from]. Anything malformed is
  /// ignored: it comes from whoever is on the network.
  void onMessage(List<int> bytes, {InternetAddress? from}) {
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
    if (m['songs'] case final int version when from != null) {
      _fetchSongs(version, from);
    }
    final mute = m['mute'] is num ? m['mute'] as num : origin;
    // A leader without count-in (older app) sends none: origin means no count.
    final count = m['count'] is num ? m['count'] as num : origin;
    var nextBpb = 0;
    num nextOrigin = 0, nextMute = 0, nextCount = 0;
    final next = m['next'];
    if (next is Map && next['bpb'] is int && next['origin'] is num) {
      nextBpb = next['bpb'] as int;
      nextOrigin = next['origin'] as num;
      if (next['mute'] case final num n) nextMute = n;
      if (next['count'] case final num n) nextCount = n;
    }
    // Without a Link connection our beats are unrelated to the leader's.
    if (engine.numPeers() == 0) return;

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
    onInfo?.call(ShowInfo.fromMessage(m, k));

    engine.setBar(
      bpb,
      origin.toDouble() + k,
      mute.toDouble() + k,
      count.toDouble() + k,
      nextBpb,
      nextOrigin.toDouble() + k,
      nextMute.toDouble(),
      nextCount.toDouble(),
    );
  }
}
