// SPDX-License-Identifier: GPL-3.0-or-later
// Import and export through the system's file dialogs: songs as ChordPro
// text, setlists as JSON.
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import 'app_state.dart';
import 'chordpro.dart';
import 'setlist.dart';

const _maxBytes = 1 << 20; // nobody's lyrics are over 1 MB

// Taken before the file dialog opens: the page may be gone when it closes.
void Function(String) _sayOn(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  return (text) => messenger.showSnackBar(SnackBar(content: Text(text)));
}

String _baseName(String file) => file.replaceFirst(RegExp(r'\.[^.]+$'), '');

Future<void> importSongs(BuildContext context, AppState state) async {
  final say = _sayOn(context);
  try {
    // Any type: Android has no file type for .cho and would grey them out.
    final files = await FilePicker.pickFiles(dialogTitle: 'Importar canciones');
    var count = 0, skipped = 0;
    for (final file in files) {
      final bytes = await file.readAsBytes();
      final songs = bytes.length > _maxBytes
          ? const <Never>[]
          : parseChordPro(
              decodeText(bytes),
              fallbackName: _baseName(file.name),
            );
      songs.isEmpty ? skipped++ : count += state.importSongs(songs);
    }
    if (files.isEmpty) return;
    say(
      [
        count == 1 ? '1 canción importada.' : '$count canciones importadas.',
        if (skipped > 0) '$skipped archivo(s) sin canciones.',
      ].join(' '),
    );
  } on Exception catch (e) {
    debugPrint('import songs: $e');
    say('No se pudo leer el archivo.');
  }
}

Future<void> _save(
  BuildContext context,
  String fileName,
  String text, {
  String mimeType = 'application/octet-stream',
}) async {
  final say = _sayOn(context);
  try {
    final saved = await FilePicker.saveFile(
      fileName: fileName,
      bytes: utf8.encode(text),
      mimeType: mimeType,
    );
    if (saved != null) say('Guardado: $fileName');
  } on Exception catch (e) {
    debugPrint('export: $e');
    say('No se pudo guardar el archivo.');
  }
}

/// All songs in one ChordPro file.
Future<void> exportSongs(BuildContext context, AppState state) =>
    _save(context, 'canciones.cho', toChordPro(state.library.songs));

Future<void> importSetlist(BuildContext context, AppState state) async {
  final say = _sayOn(context);
  try {
    final file = await FilePicker.pickFile(dialogTitle: 'Importar setlist');
    if (file == null) return;
    final bytes = await file.readAsBytes();
    Setlist? setlist;
    if (bytes.length <= _maxBytes) {
      try {
        setlist = state.importSetlist(jsonDecode(decodeText(bytes)));
      } on FormatException {
        // not JSON: reported below
      }
    }
    say(
      setlist == null
          ? 'Ese archivo no es un setlist de PrronClick.'
          : 'Setlist "${setlist.name}" importado.',
    );
  } on Exception catch (e) {
    debugPrint('import setlist: $e');
    say('No se pudo leer el archivo.');
  }
}

/// The setlist and its songs (with lyrics) in one JSON file.
Future<void> exportSetlist(
  BuildContext context,
  AppState state,
  Setlist setlist,
) => _save(
  context,
  // Without the characters Windows refuses in file names.
  '${setlist.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.json',
  const JsonEncoder.withIndent(' ')
      .convert(state.library.exportSetlist(setlist)),
  mimeType: 'application/json',
);
