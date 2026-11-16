// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:material_ui/material_ui.dart';

import 'app_state.dart';
import 'meter_picker.dart';
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
  String? meter; // filter, e.g. "3/4"; null = all

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
          final meters = {for (final s in songs) s.meter}.toList()..sort();
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
                            label: Text(m),
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
  late int beatUnit = widget.song?.beatUnit ?? 4;
  late final key = TextEditingController(text: widget.song?.key);
  late final note = TextEditingController(text: widget.song?.note);
  late final lyrics = TextEditingController(text: widget.song?.lyrics);
  // Copies: nothing changes in the song until it is saved.
  late final sections = [
    for (final s in widget.song?.sections ?? const <Section>[])
      Section.fromJson(s.toJson())!,
  ];

  @override
  void dispose() {
    name.dispose();
    bpm.dispose();
    duration.dispose();
    key.dispose();
    note.dispose();
    lyrics.dispose();
    super.dispose();
  }

  static String? orNull(String text) =>
      text.trim().isEmpty ? null : text.trimRight();

  Future<void> _pickMeter() async {
    final picked = await pickMeter(context, beatsPerBar, beatUnit);
    if (picked == null) return;
    setState(() {
      beatsPerBar = picked.$1;
      beatUnit = picked.$2;
    });
  }

  Future<void> _editSection([int? index]) async {
    final section = await showDialog<Section>(
      context: context,
      builder: (_) =>
          _SectionDialog(section: index == null ? null : sections[index]),
    );
    if (section == null) return;
    setState(() {
      index == null ? sections.add(section) : sections[index] = section;
    });
  }

  static String _describe(Section s) => [
    s.bars == 1 ? '1 compás' : '${s.bars} compases',
    if (s.bpm case final bpm?) '${bpm.round()} BPM',
    if (s.beatsPerBar case final beats?) '$beats/${s.beatUnit ?? 4}',
  ].join(' · ');

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
      ..beatUnit = beatUnit
      ..durationSeconds = parseDuration(duration.text)
      ..key = orNull(key.text)
      ..note = orNull(note.text)
      ..lyrics = orNull(lyrics.text)
      ..sections = sections;
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
            Row(
              children: [
                const Expanded(child: Text('Compás')),
                OutlinedButton(
                  onPressed: _pickMeter,
                  child: Text('$beatsPerBar/$beatUnit'),
                ),
              ],
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
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: Text('Secciones (opcional)')),
                TextButton.icon(
                  onPressed: _editSection,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir'),
                ),
              ],
            ),
            Text(
              'Tramos con sus compases y, si quieres, su tempo y compás. '
              'Suenan en orden y de ellos sale la duración de la canción.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            for (final (i, s) in sections.indexed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.name),
                subtitle: Text(_describe(s)),
                onTap: () => _editSection(i),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Subir',
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: i == 0
                          ? null
                          : () => setState(
                              () =>
                                  sections.insert(i - 1, sections.removeAt(i)),
                            ),
                    ),
                    IconButton(
                      tooltip: 'Quitar sección',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => sections.removeAt(i)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: key,
              decoration: const InputDecoration(
                labelText: 'Tonalidad (opcional)',
                hintText: 'Am',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: note,
              maxLength: 80, // what the leader's broadcast carries
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                hintText: 'Entra la batería sola',
                helperText: 'Se ve en el metrónomo, también en los seguidores.',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: lyrics,
              minLines: 6,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Letra (opcional)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                helperMaxLines: 3,
                helperText:
                    'Formato ChordPro: acordes entre corchetes, [Am], y '
                    'avisos como {comment: Entra toda la banda}.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Creates or edits one section; pops the new [Section].
class _SectionDialog extends StatefulWidget {
  const _SectionDialog({this.section});

  final Section? section;

  @override
  State<_SectionDialog> createState() => _SectionDialogState();
}

class _SectionDialogState extends State<_SectionDialog> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.section?.name);
  late final bars = TextEditingController(text: '${widget.section?.bars ?? 8}');
  late final bpm = TextEditingController(
    text: widget.section?.bpm?.round().toString(),
  );
  late int? beats = widget.section?.beatsPerBar;
  late int? unit = widget.section?.beatUnit;

  @override
  void dispose() {
    name.dispose();
    bars.dispose();
    bpm.dispose();
    super.dispose();
  }

  Future<void> _pickMeter() async {
    final picked = await pickMeter(context, beats ?? 4, unit ?? 4);
    if (picked == null) return;
    setState(() {
      beats = picked.$1;
      unit = picked.$2;
    });
  }

  void _save() {
    if (!form.currentState!.validate()) return;
    Navigator.pop(
      context,
      Section(
        name: name.text.trim(),
        bars: int.parse(bars.text),
        bpm: double.tryParse(bpm.text),
        beatsPerBar: beats,
        beatUnit: beats == null ? null : unit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.section == null ? 'Nueva sección' : 'Editar sección'),
      content: Form(
        key: form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                autofocus: widget.section == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Coro',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ponle un nombre' : null,
              ),
              TextFormField(
                controller: bars,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Compases'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return n == null || n < 1 || n > 999 ? 'Entre 1 y 999' : null;
                },
              ),
              TextFormField(
                controller: bpm,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tempo (opcional)',
                  helperText: 'Vacío: el de la canción.',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v);
                  return n == null || n < 20 || n > 300
                      ? 'Entre 20 y 300'
                      : null;
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(child: Text('Compás')),
                  if (beats != null)
                    IconButton(
                      tooltip: 'Usar el compás de la canción',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => beats = unit = null),
                    ),
                  OutlinedButton(
                    onPressed: _pickMeter,
                    child: Text(
                      beats == null
                          ? 'El de la canción'
                          : '$beats/${unit ?? 4}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}
