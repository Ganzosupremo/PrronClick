import 'package:flutter_test/flutter_test.dart';
import 'package:prronclick/cues.dart';

void main() {
  (int, int)? cue(String file, [int n = 0]) => (cueSlots[file]!, n);

  test('section names in each language find their cue', () {
    expect(sectionCue('Coro'), cue('chorus'));
    expect(sectionCue('Chorus'), cue('chorus'));
    expect(sectionCue('Refrain'), cue('chorus'));
    expect(sectionCue('Estribillo'), cue('chorus'));
    expect(sectionCue('Verso 2'), cue('verse', 2));
    expect(sectionCue('verse2'), cue('verse', 2));
    expect(sectionCue('Strophe 3'), cue('verse', 3));
    expect(sectionCue('Introducción'), cue('intro'));
    expect(sectionCue('Brücke'), cue('bridge'));
    expect(sectionCue('PUENTE'), cue('bridge'));
    expect(sectionCue('Final'), cue('ending'));
    expect(sectionCue('Solo de guitarra'), cue('guitar_solo'));
    expect(sectionCue('Solo'), cue('solo'));
    expect(sectionCue('Post-coro'), cue('post_chorus'));
    expect(sectionCue('Exhortación'), cue('exhortation'));
    expect(sectionCue('Vamp 2'), cue('vamp', 2));
  });

  test('a numbered recording is said in one go, else word then number', () {
    expect(cueToSay(sectionCue('Coro 2')!), cue('chorus_2'));
    expect(cueToSay(sectionCue('Verso 6')!), cue('verse_6'));
    expect(cueToSay(sectionCue('Puente 5')!), cue('bridge', 5));
    expect(cueToSay(sectionCue('Vamp 2')!), cue('vamp', 2));
    expect(cueToSay(sectionCue('Coro')!), cue('chorus'));
  });

  test('every slot fits the engine and is used once', () {
    expect(cueSlots.values.toSet().length, cueSlots.length);
    expect(cueSlots.values.every((s) => s >= 1 && s <= 63), isTrue);
  });

  test('pre-chorus is not heard as chorus', () {
    expect(sectionCue('Pre-coro'), cue('pre_chorus'));
    expect(sectionCue('Precoro 2'), cue('pre_chorus', 2));
    expect(sectionCue('Pre-Chorus'), cue('pre_chorus'));
    expect(sectionCue('Pre-Refrain'), cue('pre_chorus'));
  });

  test('numbers only up to eight; unknown names say nothing', () {
    expect(sectionCue('Verso 12'), cue('verse'));
    expect(sectionCue('Groove'), isNull);
    expect(sectionCue('Corona'), isNull); // a word, not "coro"
    expect(sectionCue(''), isNull);
  });

  test('an Outro, Final or Coda ends the song; a Tag or Verso does not', () {
    for (final name in [
      'Outro',
      'Final',
      'Coda',
      'Ending',
      'Schluss',
      'Ende',
    ]) {
      expect(endsSong(name), isTrue, reason: name);
    }
    for (final name in ['Tag', 'Verso', 'Coro final?', 'Groove']) {
      expect(endsSong(name), name == 'Coro final?', reason: name);
    }
  });
}
