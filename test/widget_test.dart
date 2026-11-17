// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prronclick/l10n/app_localizations.dart';
import 'package:prronclick/lyrics_view.dart';
import 'package:prronclick/song.dart';
import 'package:prronclick/songs_page.dart';

/// The app's texts in Spanish, which these tests look for.
Widget app(Widget home, {Locale locale = const Locale('es')}) => MaterialApp(
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  home: home,
);

void main() {
  testWidgets('song editor: scroll the meter wheels, fill the new fields', (
    tester,
  ) async {
    Song? saved;
    await tester.pumpWidget(
      app(
        Builder(
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
    // An accent set in 4/4 is dropped when the meter changes.
    await tester.tap(find.bySemanticsLabel('Pulso 2: Normal'));
    await tester.pump();
    expect(find.bySemanticsLabel('Pulso 2: Fuerte'), findsOneWidget);
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
    // Strong -> medium -> silent.
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.bySemanticsLabel(RegExp('^Pulso 1:')));
      await tester.pump();
    }
    expect(find.bySemanticsLabel('Pulso 1: Mudo'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tonalidad (opcional)'),
      'Am',
    );
    // A section with its own tempo, keeping the song's meter.
    await tester.tap(find.text('Añadir'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre').last,
      'Coro',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Compases'),
      '12',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tempo (opcional)'),
      '90',
    );
    await tester.tap(find.text('Guardar').last);
    await tester.pumpAndSettle();
    expect(find.text('12 compases · 90 BPM'), findsOneWidget);

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect((saved!.name, saved!.meter, saved!.key), ('Vals', '6/16', 'Am'));
    expect(saved!.accents, [3, 2, 2, 2, 2, 2]);
    final section = saved!.sections.single;
    expect((section.name, section.bars, section.bpm), ('Coro', 12, 90));
    expect((section.beatsPerBar, saved!.unitAt(0)), (null, 16));
    expect((saved!.note, saved!.lyrics), (null, null));
  });

  testWidgets('lyrics: chords above, comments, sections; no raw directives', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const Scaffold(
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

  testWidgets('English and German texts', (tester) async {
    for (final (code, chorus, add) in [
      ('en', 'Chorus', 'Add'),
      ('de', 'Refrain', 'Hinzufügen'),
    ]) {
      await tester.pumpWidget(
        app(
          const Scaffold(body: LyricsView(text: '{soc}\nla')),
          locale: Locale(code),
        ),
      );
      expect(find.text(chorus), findsOneWidget);
      await tester.pumpWidget(app(const SongEditor(), locale: Locale(code)));
      expect(find.text(add), findsOneWidget);
    }
  });
}
