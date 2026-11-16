// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:prronclick/share.dart';

Map<Object?, Object?> wire(Map<String, Object?> m) =>
    jsonDecode(jsonEncode(m)) as Map<Object?, Object?>;

void main() {
  test('setlist info survives the wire, beat shifted by k', () {
    const info = ShowInfo(
      song: 'Dos',
      setlist: 'Bolo',
      position: 2,
      total: 3,
      next: 'Tres',
      changeBeat: 40,
    );
    final got = ShowInfo.fromMessage(wire(info.toJson()), -7);
    expect(got.song, 'Dos');
    expect(got.setlist, 'Bolo');
    expect((got.position, got.total, got.next), (2, 3, 'Tres'));
    expect(got.changeBeat, 33);
  });

  test('key, note and beat unit reach followers', () {
    const info = ShowInfo(song: 'Dos', key: 'Am', note: 'Sola', beatUnit: 8);
    expect(ShowInfo.fromMessage(wire(info.toJson()), 0), info);
    const inSet = ShowInfo(song: 'Dos', key: 'Am', beatUnit: 8, setlist: 'B');
    expect(ShowInfo.fromMessage(wire(inSet.toJson()), 0), inSet);
    // An older leader says nothing; junk falls back to x/4.
    expect(ShowInfo.fromMessage(wire({'song': 'Uno'}), 0).beatUnit, 4);
    expect(ShowInfo.fromMessage(wire({'unit': 5, 'key': 3}), 0).beatUnit, 4);
  });

  test('no setlist, last song, and junk from the network', () {
    expect(ShowInfo.fromMessage(wire({'song': 'Uno'}), 0).setlist, isNull);
    final last = ShowInfo.fromMessage(
      wire(const ShowInfo(setlist: 'B', position: 3, total: 3).toJson()),
      0,
    );
    expect((last.next, last.changeBeat), (null, null));
    final junk = ShowInfo.fromMessage({
      'song': 5,
      'setlist': {'name': 'x' * 500, 'pos': 'a', 'change': '1'},
    }, 0);
    expect(junk.song, isNull);
    expect(junk.setlist!.length, 80);
    expect((junk.position, junk.changeBeat), (0, null));
  });
}
