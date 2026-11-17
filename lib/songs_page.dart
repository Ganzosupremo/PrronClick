// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:material_ui/material_ui.dart';

import 'app_state.dart';
import 'l10n/app_localizations.dart';
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
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.deleteQuestion(song.name)),
        content: Text(t.cannotUndo),
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
    if (ok == true) state.deleteSong(song);
  }

  void _load(BuildContext context, Song song) {
    if (!state.canControl) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).followerNoTempo)),
      );
      return;
    }
    state.loadSong(song);
    widget.onLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        tooltip: t.newSong,
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
                  t.noSongs,
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
              tooltip: t.options,
              onSelected: (action) => action == 'edit'
                  ? _edit(context, song)
                  : _delete(context, song),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(t.edit)),
                PopupMenuItem(value: 'delete', child: Text(t.delete)),
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
                  hintText: t.searchSong,
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (search.text.isNotEmpty)
                      IconButton(
                        tooltip: t.clearSearch,
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
                          t.noMatch,
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

  static String _describe(AppLocalizations t, Section s) => [
    t.bars(s.bars),
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
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.song == null ? t.newSong : t.editSong),
        actions: [TextButton(onPressed: _save, child: Text(t.save))],
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
              decoration: InputDecoration(labelText: t.name),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? t.nameRequired : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: bpm,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: t.tempoBpm),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n < 20 || n > 300
                    ? t.between20and300
                    : null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text(t.meter)),
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
              decoration: InputDecoration(
                labelText: t.durationOptional,
                hintText: '3:30',
                helperMaxLines: 2,
                helperText: t.durationHelp,
              ),
              validator: (v) {
                try {
                  parseDuration(v ?? '');
                  return null;
                } on FormatException {
                  return t.durationInvalid;
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text(t.sectionsOptional)),
                TextButton.icon(
                  onPressed: _editSection,
                  icon: const Icon(Icons.add),
                  label: Text(t.add),
                ),
              ],
            ),
            Text(t.sectionsHelp, style: Theme.of(context).textTheme.bodySmall),
            for (final (i, s) in sections.indexed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.name),
                subtitle: Text(_describe(t, s)),
                onTap: () => _editSection(i),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: t.moveUp,
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: i == 0
                          ? null
                          : () => setState(
                              () =>
                                  sections.insert(i - 1, sections.removeAt(i)),
                            ),
                    ),
                    IconButton(
                      tooltip: t.removeSection,
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => sections.removeAt(i)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: key,
              decoration: InputDecoration(
                labelText: t.keyOptional,
                hintText: 'Am',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: note,
              maxLength: 80, // what the leader's broadcast carries
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: t.noteOptional,
                hintText: t.noteHint,
                helperText: t.noteHelp,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: lyrics,
              minLines: 6,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: t.lyricsOptional,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
                helperMaxLines: 3,
                helperText: t.lyricsHelp('{comment: ${t.lyricsHelpCue}}'),
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
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.section == null ? t.newSection : t.editSection),
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
                decoration: InputDecoration(
                  labelText: t.name,
                  hintText: t.sectionNameHint,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? t.nameRequired : null,
              ),
              TextFormField(
                controller: bars,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: t.barsLabel),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return n == null || n < 1 || n > 999
                      ? t.between1and999
                      : null;
                },
              ),
              TextFormField(
                controller: bpm,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t.tempoOptional,
                  helperText: t.tempoOptionalHelp,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v);
                  return n == null || n < 20 || n > 300
                      ? t.between20and300
                      : null;
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text(t.meter)),
                  if (beats != null)
                    IconButton(
                      tooltip: t.useSongMeter,
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => beats = unit = null),
                    ),
                  OutlinedButton(
                    onPressed: _pickMeter,
                    child: Text(
                      beats == null ? t.songMeter : '$beats/${unit ?? 4}',
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
          child: Text(t.cancel),
        ),
        TextButton(onPressed: _save, child: Text(t.save)),
      ],
    );
  }
}
