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

  test("the song's accents reach followers; junk is ignored", () {
    const info = ShowInfo(song: 'Dos', accents: [2, 0, 3]);
    expect(ShowInfo.fromMessage(wire(info.toJson()), 0), info);
    expect(info == const ShowInfo(song: 'Dos', accents: [2, 0, 1]), isFalse);
    for (final junk in [
      [4, 0],
      'x',
      List.filled(17, 0),
      <int>[],
    ]) {
      expect(ShowInfo.fromMessage(wire({'accents': junk}), 0).accents, isNull);
    }
  });

  test('the section playing and the next one reach followers', () {
    const info = ShowInfo(
      song: 'Dos',
      section: 'Verso',
      nextSection: 'Coro',
      sectionChange: 16,
    );
    final got = ShowInfo.fromMessage(wire(info.toJson()), 3);
    expect(
      (got.section, got.nextSection, got.sectionChange),
      ('Verso', 'Coro', 19),
    );
    const inSet = ShowInfo(section: 'Verso', setlist: 'B', changeBeat: 40);
    expect(ShowInfo.fromMessage(wire(inSet.toJson()), 0), inSet);
    final junk = ShowInfo.fromMessage(
      wire({
        'section': 4,
        'nextSection': {'name': 'Coro', 'at': 'x'},
      }),
      0,
    );
    expect(
      (junk.section, junk.nextSection, junk.sectionChange),
      (null, 'Coro', null),
    );
  });

  test('session codes: no code is standard Link, a code is its own port', () {
    expect(sessionPort(''), 20808);
    expect(sessionPort('   '), 20808);
    final azul = sessionPort('azul');
    expect(sessionPort(' AZUL '), azul); // typed a little differently
    expect(sessionPort('roja'), isNot(azul));
    for (final code in ['azul', 'roja', 'ñandú 🎸', 'x' * 40]) {
      final port = sessionPort(code);
      expect(port, inInclusiveRange(21000, 21998));
      expect(port.isEven, isTrue); // the odd one above is the bar broadcast
    }
    expect(azul, 21510); // must never change: old and new apps have to meet
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
