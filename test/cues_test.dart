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
    expect(sectionCue('Solo de guitarra'), cue('solo'));
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
