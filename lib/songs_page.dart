// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:material_ui/material_ui.dart';

import 'app_state.dart';
import 'song.dart';

class SongsPage extends StatefulWidget {
  const SongsPage({super.key, required this.state, required this.onLoaded});

  final AppState state;

  /// Called after a song is loaded, so the app can show the metronome.
  final VoidCallback onLoaded;

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  final search = TextEditingController();
  int? meter; // filter; null = all

  AppState get state => widget.state;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _edit(BuildContext context, [Song? song]) async {
    final saved = await Navigator.of(context).push<Song>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SongEditor(song: song),
      ),
    );
    if (saved != null) state.saveSong(saved);
  }

  Future<void> _delete(BuildContext context, Song song) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Borrar "${song.name}"?'),
        content: const Text('No se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok == true) state.deleteSong(song);
  }

  void _load(BuildContext context, Song song) {
    if (!state.canControl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Como seguidor, el tempo lo pone el líder.'),
        ),
      );
      return;
    }
    state.loadSong(song);
    widget.onLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        tooltip: 'Nueva canción',
        onPressed: () => _edit(context),
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final songs = state.library.songs;
          if (songs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Aún no hay canciones. Toca + para crear una con su tempo, '
                  'compás y duración.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            );
          }
          final shown = filterSongs(songs, search.text, meter);
          final filtering = shown.length != songs.length;
          final meters = {for (final s in songs) s.beatsPerBar}.toList()
            ..sort();
          Widget tile(Song song, int index) => ListTile(
            key: ValueKey(song.id),
            // Dragging only makes sense on the full list.
            leading: filtering
                ? null
                : ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle),
                  ),
            title: Text(song.name),
            subtitle: Text(song.summary),
            selected: song == state.currentSong,
            onTap: () => _load(context, song),
            trailing: PopupMenuButton<String>(
              tooltip: 'Opciones',
              onSelected: (action) => action == 'edit'
                  ? _edit(context, song)
                  : _delete(context, song),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Borrar')),
              ],
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SearchBar(
                  controller: search,
                  hintText: 'Buscar canción',
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (search.text.isNotEmpty)
                      IconButton(
                        tooltip: 'Borrar búsqueda',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(search.clear),
                      ),
                  ],
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (meters.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      for (final m in meters)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text('$m/4'),
                            selected: meter == m,
                            onSelected: (on) =>
                                setState(() => meter = on ? m : null),
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: shown.isEmpty
                    ? Center(
                        child: Text(
                          'Ninguna canción coincide.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      )
                    : filtering
                    ? ListView(
                        padding: const EdgeInsets.only(bottom: 88),
                        children: [
                          for (final (i, song) in shown.indexed) tile(song, i),
                        ],
                      )
                    : ReorderableListView(
                        buildDefaultDragHandles: false,
                        padding: const EdgeInsets.only(bottom: 88),
                        onReorderItem: state.moveSong,
                        children: [
                          for (final (i, song) in shown.indexed) tile(song, i),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Creates a song, or edits [song] in place. Pops the saved song.
class SongEditor extends StatefulWidget {
  const SongEditor({super.key, this.song});

  final Song? song;

  @override
  State<SongEditor> createState() => _SongEditorState();
}

class _SongEditorState extends State<SongEditor> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.song?.name);
  late final bpm = TextEditingController(
    text: (widget.song?.bpm ?? 120).round().toString(),
  );
  late final duration = TextEditingController(
    text: switch (widget.song?.durationSeconds) {
      final d? => formatDuration(d),
      null => '',
    },
  );
  late int beatsPerBar = widget.song?.beatsPerBar ?? 4;

  @override
  void dispose() {
    name.dispose();
    bpm.dispose();
    duration.dispose();
    super.dispose();
  }

  void _save() {
    if (!form.currentState!.validate()) return;
    final song =
        widget.song ??
        Song(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: '',
          bpm: 120,
          beatsPerBar: 4,
        );
    song
      ..name = name.text.trim()
      ..bpm = double.parse(bpm.text)
      ..beatsPerBar = beatsPerBar
      ..durationSeconds = parseDuration(duration.text);
    Navigator.pop(context, song);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.song == null ? 'Nueva canción' : 'Editar canción'),
        actions: [TextButton(onPressed: _save, child: const Text('Guardar'))],
      ),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: name,
              autofocus: widget.song == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Ponle un nombre' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: bpm,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tempo (BPM)'),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n < 20 || n > 300 ? 'Entre 20 y 300' : null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: beatsPerBar,
              decoration: const InputDecoration(labelText: 'Compás'),
              items: [
                for (var n = 1; n <= 12; n++)
                  DropdownMenuItem(value: n, child: Text('$n/4')),
              ],
              onChanged: (n) => beatsPerBar = n!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: duration,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Duración (opcional)',
                hintText: '3:30',
                helperMaxLines: 2,
                helperText:
                    'Minutos:segundos. En un setlist, al acabar pasa '
                    'a la siguiente.',
              ),
              validator: (v) {
                try {
                  parseDuration(v ?? '');
                  return null;
                } on FormatException {
                  return 'Usa minutos:segundos, p. ej. 3:30';
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
