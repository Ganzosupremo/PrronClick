// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:material_ui/material_ui.dart';

import 'app_state.dart';
import 'l10n/app_localizations.dart';
import 'setlist.dart';
import 'song.dart';
import 'theme.dart';
import 'transfer.dart';

class SetlistsPage extends StatelessWidget {
  const SetlistsPage({super.key, required this.state, required this.onStarted});

  final AppState state;

  /// Called after a setlist starts, so the app can show the metronome.
  final VoidCallback onStarted;

  Future<void> _create(BuildContext context) async {
    final name = await askName(
      context,
      title: AppLocalizations.of(context).newSetlist,
    );
    if (name == null || !context.mounted) return;
    final setlist = Setlist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
    );
    state.saveSetlist(setlist);
    _open(context, setlist);
  }

  void _open(BuildContext context, Setlist setlist) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SetlistPage(state: state, setlist: setlist, onStarted: onStarted),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        tooltip: t.newSetlist,
        onPressed: () => _create(context),
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final setlists = state.library.setlists;
          if (setlists.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  t.noSetlists,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              for (final s in setlists)
                ListTile(
                  title: Text(s.name),
                  subtitle: Text(_summary(t, s.songsFrom(state.library.songs))),
                  selected: s == state.activeSetlist,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(context, s),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _summary(AppLocalizations t, List<Song> songs) {
    final secs = songs.fold(0, (sum, s) => sum + (s.lengthSeconds ?? 0));
    return [
      t.songCount(songs.length),
      if (secs > 0) formatDuration(secs),
    ].join(' · ');
  }
}

/// Asks for a name; returns null if cancelled.
Future<String?> askName(
  BuildContext context, {
  required String title,
  String initial = '',
  String? label, // default: "Name"
}) => showDialog<String>(
  context: context,
  builder: (_) => _NameDialog(
    title: title,
    initial: initial,
    label: label ?? AppLocalizations.of(context).name,
  ),
);

// Owns its controller: the TextField still uses it while the dialog animates
// out, after showDialog's future has completed.
class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.initial,
    required this.label,
  });

  final String title;
  final String initial;
  final String label;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void submit() {
    final name = controller.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: widget.label),
        onSubmitted: (_) => submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        TextButton(
          onPressed: submit,
          child: Text(AppLocalizations.of(context).save),
        ),
      ],
    );
  }
}

/// One setlist: its songs in order, auto-advance, and starting it.
class SetlistPage extends StatelessWidget {
  const SetlistPage({
    super.key,
    required this.state,
    required this.setlist,
    required this.onStarted,
  });

  final AppState state;
  final Setlist setlist;
  final VoidCallback onStarted;

  void _start(BuildContext context, int index) {
    if (!state.canControl) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).followerNoTempo)),
      );
      return;
    }
    state.startSetlist(setlist, index);
    Navigator.of(context).pop();
    onStarted();
  }

  Future<void> _rename(BuildContext context) async {
    final name = await askName(
      context,
      title: AppLocalizations.of(context).renameSetlist,
      initial: setlist.name,
    );
    if (name == null) return;
    setlist.name = name;
    state.saveSetlist(setlist);
  }

  Future<void> _delete(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.deleteQuestion(setlist.name)),
        content: Text(t.setlistDeleteKeepsSongs),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    state.deleteSetlist(setlist);
    Navigator.of(context).pop();
  }

  Future<void> _addSongs(BuildContext context) async {
    final songs = state.library.songs;
    if (songs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).createSongsFirst)),
      );
      return;
    }
    final picked = await showDialog<List<Song>>(
      context: context,
      builder: (_) => _SongPicker(songs: songs),
    );
    if (picked == null || picked.isEmpty) return;
    setlist.songIds.addAll(picked.map((s) => s.id));
    state.saveSetlist(setlist);
  }

  void _move(int from, int to) {
    final ids = setlist.songIds;
    ids.insert(to, ids.removeAt(from));
    state.saveSetlist(setlist);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final t = AppLocalizations.of(context);
        // Ids of deleted songs are already removed, so positions match.
        final songs = setlist.songsFrom(state.library.songs);
        return Scaffold(
          appBar: AppBar(
            title: PageTitle(setlist.name),
            actions: [
              IconButton(
                tooltip: t.exportSetlist,
                icon: const Icon(Icons.ios_share),
                onPressed: () => exportSetlist(context, state, setlist),
              ),
              IconButton(
                tooltip: t.rename,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _rename(context),
              ),
              IconButton(
                tooltip: t.deleteSetlist,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(context),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: null,
            onPressed: songs.isEmpty ? null : () => _start(context, 0),
            icon: const Icon(Icons.play_arrow),
            label: Text(t.start),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              SwitchListTile(
                title: Text(t.autoAdvance),
                subtitle: Text(t.autoAdvanceHelp),
                value: setlist.autoAdvance,
                onChanged: (v) {
                  setlist.autoAdvance = v;
                  state.saveSetlist(setlist);
                },
              ),
              ListTile(
                enabled: setlist.autoAdvance,
                title: Text(t.pauseBetween),
                subtitle: Text(t.pauseBetweenHelp),
                trailing: DropdownButton<int>(
                  value: setlist.pauseBars,
                  items: [
                    for (final n in const [0, 1, 2, 4, 8])
                      DropdownMenuItem(
                        value: n,
                        child: Text(n == 0 ? t.no : t.bars(n)),
                      ),
                  ],
                  onChanged: setlist.autoAdvance
                      ? (n) {
                          setlist.pauseBars = n!;
                          state.saveSetlist(setlist);
                        }
                      : null,
                ),
              ),
              ListTile(
                title: Text(t.countIn),
                subtitle: Text(t.setlistCountInHelp),
                trailing: DropdownButton<int>(
                  // -1 = no own value: follow the app setting.
                  value: setlist.countInBars ?? -1,
                  items: [
                    DropdownMenuItem(
                      value: -1,
                      child: Text(
                        t.countInFromSettings(state.library.countInBars),
                      ),
                    ),
                    DropdownMenuItem(value: 0, child: Text(t.no)),
                    DropdownMenuItem(value: 1, child: Text(t.bars(1))),
                    DropdownMenuItem(value: 2, child: Text(t.bars(2))),
                  ],
                  onChanged: (n) {
                    setlist.countInBars = n == -1 ? null : n;
                    state.saveSetlist(setlist);
                  },
                ),
              ),
              const Divider(),
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorderItem: _move,
                children: [
                  for (final (i, song) in songs.indexed)
                    ListTile(
                      key: ValueKey('$i-${song.id}'),
                      leading: ReorderableDragStartListener(
                        index: i,
                        child: const Icon(Icons.drag_handle),
                      ),
                      title: Text('${i + 1}. ${song.name}'),
                      subtitle: Text(
                        [
                          ?song.author,
                          song.lengthSeconds == null && setlist.autoAdvance
                              ? t.noDurationManual(song.summary)
                              : song.summary,
                        ].join('\n'),
                      ),
                      onTap: () => _start(context, i),
                      trailing: IconButton(
                        tooltip: t.removeFromSetlist,
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          setlist.songIds.removeAt(i);
                          state.saveSetlist(setlist);
                        },
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: () => _addSongs(context),
                  icon: const Icon(Icons.playlist_add),
                  label: Text(t.addSongs),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Multi-select of songs, returned in the order they were ticked.
class _SongPicker extends StatefulWidget {
  const _SongPicker({required this.songs});

  final List<Song> songs;

  @override
  State<_SongPicker> createState() => _SongPickerState();
}

class _SongPickerState extends State<_SongPicker> {
  final picked = <Song>[];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(t.addSongs),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final song in widget.songs)
              CheckboxListTile(
                title: Text(song.name),
                subtitle: Text([?song.author, song.summary].join('\n')),
                value: picked.contains(song),
                onChanged: (on) => setState(
                  () => on! ? picked.add(song) : picked.remove(song),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, picked),
          child: Text(picked.isEmpty ? t.add : t.addCount(picked.length)),
        ),
      ],
    );
  }
}
