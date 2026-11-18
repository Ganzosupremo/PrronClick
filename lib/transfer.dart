// SPDX-License-Identifier: GPL-3.0-or-later
// Import and export through the system's file dialogs: songs as ChordPro
// text, setlists as JSON.
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import 'app_state.dart';
import 'chordpro.dart';
import 'l10n/app_localizations.dart';
import 'library.dart';
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
  final t = AppLocalizations.of(context);
  try {
    // Any type: Android has no file type for .cho and would grey them out.
    final files = await FilePicker.pickFiles(dialogTitle: t.importSongs);
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
        t.songsImported(count),
        if (skipped > 0) t.filesWithoutSongs(skipped),
      ].join(' '),
    );
  } on Exception catch (e) {
    debugPrint('import songs: $e');
    say(t.cannotRead);
  }
}

Future<void> _save(
  BuildContext context,
  String fileName,
  String text, {
  String mimeType = 'application/octet-stream',
}) async {
  final say = _sayOn(context);
  final t = AppLocalizations.of(context);
  try {
    final saved = await FilePicker.saveFile(
      fileName: fileName,
      bytes: utf8.encode(text),
      mimeType: mimeType,
    );
    if (saved != null) say(t.savedFile(fileName));
  } on Exception catch (e) {
    debugPrint('export: $e');
    say(t.cannotSave);
  }
}

/// All songs in one ChordPro file.
Future<void> exportSongs(BuildContext context, AppState state) => _save(
  context,
  '${AppLocalizations.of(context).songsFileName}.cho',
  toChordPro(state.library.songs),
);

Future<void> importSetlist(BuildContext context, AppState state) async {
  final say = _sayOn(context);
  final t = AppLocalizations.of(context);
  try {
    final file = await FilePicker.pickFile(dialogTitle: t.importSetlist);
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
    say(setlist == null ? t.notASetlist : t.setlistImported(setlist.name));
  } on Exception catch (e) {
    debugPrint('import setlist: $e');
    say(t.cannotRead);
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

// Years of practice history and lyrics, with room to spare.
const _maxBackupBytes = 32 << 20;

/// Everything (songs, setlists, settings, history) in one JSON file.
Future<void> saveBackup(BuildContext context, AppState state) {
  final now = DateTime.now();
  final date = now.toIso8601String().substring(0, 10);
  return _save(
    context,
    'PrronClick-$date.json',
    jsonEncode(backupOf(state.library, now)),
    mimeType: 'application/json',
  );
}

/// Picks a backup and, once confirmed, replaces everything with it. The
/// snack bar offers to undo.
Future<void> restoreBackup(BuildContext context, AppState state) async {
  final say = _sayOn(context);
  final messenger = ScaffoldMessenger.of(context);
  final t = AppLocalizations.of(context);
  Library? restored;
  try {
    final file = await FilePicker.pickFile(dialogTitle: t.backupRestore);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length <= _maxBackupBytes) {
      try {
        restored = libraryFromBackup(jsonDecode(decodeText(bytes)));
      } on FormatException {
        // not JSON: reported below
      }
    }
  } on Exception catch (e) {
    debugPrint('restore backup: $e');
    say(t.cannotRead);
    return;
  }
  if (restored == null) {
    say(t.notABackup);
    return;
  }
  if (!context.mounted) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t.backupRestoreAsk),
      content: Text(
        t.backupRestoreWhat(restored!.songs.length, restored.setlists.length),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(t.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(t.backupReplace),
        ),
      ],
    ),
  );
  if (ok != true) return;
  final old = await state.restoreLibrary(restored);
  messenger.showSnackBar(
    SnackBar(
      content: Text(t.backupRestored),
      duration: const Duration(seconds: 10),
      action: SnackBarAction(
        label: t.undo,
        onPressed: () => state.restoreLibrary(old),
      ),
    ),
  );
}
