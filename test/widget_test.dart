// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prronclick/lyrics_view.dart';
import 'package:prronclick/song.dart';
import 'package:prronclick/songs_page.dart';

void main() {
  testWidgets('song editor: scroll the meter wheels, fill the new fields', (
    tester,
  ) async {
    Song? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => saved = await Navigator.of(
              context,
            ).push<Song>(MaterialPageRoute(builder: (_) => const SongEditor())),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre'),
      'Vals',
    );
    await tester.tap(find.text('4/4'));
    await tester.pumpAndSettle();

    // Two rows down on each wheel: 4 -> 6 beats, 4 -> 16 (2, 4, 8, 16).
    final wheels = find.byType(ListWheelScrollView);
    await tester.drag(wheels.first, const Offset(0, -96));
    await tester.drag(wheels.last, const Offset(0, -96));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar 6/16'));
    await tester.pumpAndSettle();
    expect(find.text('6/16'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tonalidad (opcional)'),
      'Am',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect((saved!.name, saved!.meter, saved!.key), ('Vals', '6/16', 'Am'));
    expect((saved!.note, saved!.lyrics), (null, null));
  });

  testWidgets('lyrics: chords above, comments, sections; no raw directives', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LyricsView(
            text:
                '{comment: Entra la batería}\n{soc}\n[Am]Hola [E7]mundo\n'
                'reason to {comment: Break}\n'
                'p[E]raise\n'
                '{eoc}\n{x_cosa: 1}',
          ),
        ),
      ),
    );
    expect(find.text('Entra la batería'), findsOneWidget);
    expect(find.text('Coro'), findsOneWidget);
    // Each chord sits right above the syllable it was written before.
    Offset at(String text) => tester.getTopLeft(find.text(text));
    expect(at('Am').dx, at('Hola\u00A0').dx);
    expect(at('Am').dy, lessThan(at('Hola\u00A0').dy));
    expect(at('E7').dx, at('mundo').dx);
    expect(at('E').dx, at('raise').dx); // "p[E]raise": inside the word
    expect(at('raise').dx, tester.getTopRight(find.text('p')).dx);
    expect(at('p').dy, at('raise').dy);
    expect(
      find.textContaining('reason to  Break', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('{', findRichText: true), findsNothing);
  });
}
