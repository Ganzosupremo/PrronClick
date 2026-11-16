// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'engine.dart';
import 'library.dart';
import 'setlist.dart';
import 'share.dart';
import 'song.dart';

enum ShareMode { solo, leader, follower }

/// App-wide state shared by every tab. The engine's live values (tempo, beat,
/// peers) are not mirrored here: the metronome page polls them every frame.
class AppState extends ChangeNotifier {
  AppState._(this.engine, this.store, this.library) : audioOk = engine.init() {
    engine.setExtraLatencyMs(library.extraLatencyMs);
    _applyPractice();
    // Playing can start or stop from many places (button, Link, the leader, a
    // setlist's end), so poll it instead of hooking each one.
    if (Platform.isAndroid) {
      Timer.periodic(const Duration(milliseconds: 500), (_) => _keepAlive());
    }
  }

  static const _background = MethodChannel('prronclick/background');
  bool _alive = false;

  /// Android: a foreground service keeps the click going with the screen off
  /// while it plays, or while shared (a follower must hear the leader start).
  Future<void> _keepAlive() async {
    final want = engine.isPlaying() || shareMode != ShareMode.solo;
    if (want == _alive) return;
    _alive = want;
    // Refused from the background (Android 12+): retry on the next tick.
    if (await _background.invokeMethod<bool>('keepAlive', want) != true) {
      _alive = !want;
    }
  }

  static Future<AppState> load() async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    final store = LibraryStore(File('${dir.path}/library.json'));
    return AppState._(Engine(), store, await store.load());
  }

  final Engine engine;
  final LibraryStore store;
  final Library library;
  final bool audioOk;

  ShareMode shareMode = ShareMode.solo;
  ShareChannel? _channel;

  int get displaceBars => library.displaceBars;
  bool get gapTrainer => library.gapTrainer;
  int get gapPlay => library.gapPlay;
  int get gapMute => library.gapMute;

  bool get canControl => shareMode != ShareMode.follower;

  /// Last song loaded into the metronome (shown above the tempo).
  Song? currentSong;

  /// Follower: what the leader announces.
  ShowInfo leaderInfo = const ShowInfo();

  /// The song and setlist to show: ours, or the leader's when following.
  ShowInfo get showInfo {
    if (shareMode == ShareMode.follower) return leaderInfo;
    final setlist = activeSetlist;
    if (setlist == null) return ShowInfo(song: currentSong?.name);
    final songs = setlistSongs, i = setlistIndex;
    return ShowInfo(
      song: currentSong?.name,
      setlist: setlist.name,
      position: i + 1,
      total: songs.length,
      next: i + 1 < songs.length ? songs[i + 1].name : null,
      changeBeat: _changeBeat,
    );
  }

  void saveSong(Song song) {
    if (!library.songs.contains(song)) library.songs.add(song);
    _libraryChanged();
  }

  /// Moves the song at [from] so it ends up at index [to].
  void moveSong(int from, int to) {
    final songs = library.songs;
    songs.insert(to, songs.removeAt(from));
    _libraryChanged();
  }

  void deleteSong(Song song) {
    library.songs.remove(song);
    for (final s in library.setlists) {
      s.songIds.removeWhere((id) => id == song.id);
    }
    if (currentSong == song) currentSong = null;
    // Positions in the running setlist may have shifted.
    if (activeSetlist != null) stopSetlist();
    _libraryChanged();
  }

  /// Loads a single song, leaving any running setlist.
  void loadSong(Song song) {
    if (activeSetlist != null) stopSetlist();
    _load(song);
  }

  /// Meter picked by hand. In a setlist the song keeps its end, rounded up to
  /// a whole bar of the new meter.
  void setBeatsPerBar(int beats) {
    engine.setBeatsPerBar(beats);
    if (activeSetlist != null && _changeBeat != null && engine.isPlaying()) {
      _resumeEnd = _changeBeat;
      _changeBeat = null;
    }
  }

  /// Sets tempo and meter from the song. While playing, the meter switches on
  /// the next downbeat.
  void _load(Song song) {
    engine.setTempo(song.bpm);
    engine.setBeatsPerBar(song.beatsPerBar);
    currentSong = song;
    notifyListeners();
  }

  void _libraryChanged() {
    notifyListeners();
    store.save(library);
  }

  // ---- Setlists ----

  void saveSetlist(Setlist setlist) {
    if (!library.setlists.contains(setlist)) library.setlists.add(setlist);
    _libraryChanged();
  }

  void deleteSetlist(Setlist setlist) {
    library.setlists.remove(setlist);
    if (activeSetlist == setlist) stopSetlist();
    _libraryChanged();
  }

  Setlist? activeSetlist;
  int setlistIndex = 0;

  /// Beat where the next song (or the end) is scheduled; null if none yet.
  double? get changeBeat => _changeBeat;
  double? _changeBeat;
  int _changeIndex = 0;
  double? _resumeEnd; // song end to keep after a manual meter change
  Timer? _setlistTimer;

  List<Song> get setlistSongs =>
      activeSetlist?.songsFrom(library.songs) ?? const [];

  void startSetlist(Setlist setlist, [int index = 0]) {
    final songs = setlist.songsFrom(library.songs);
    if (index >= songs.length) return;
    activeSetlist = setlist;
    setlistIndex = index;
    _changeBeat = null;
    _resumeEnd = null;
    _load(songs[index]);
    _setlistTimer ??= Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _setlistTick(),
    );
  }

  void stopSetlist() {
    activeSetlist = null;
    _changeBeat = null;
    _resumeEnd = null;
    _setlistTimer?.cancel();
    _setlistTimer = null;
    notifyListeners();
  }

  /// Jumps to song [index]: now if stopped, else on the next downbeat.
  void goToSong(int index) {
    if (index < 0 || index >= setlistSongs.length) return;
    _resumeEnd = null;
    if (!engine.isPlaying()) {
      setlistIndex = index;
      _changeBeat = null;
      _load(setlistSongs[index]);
      return;
    }
    _schedule(index, _nextDownbeat());
    notifyListeners();
  }

  double _nextDownbeat() {
    final origin = engine.barOrigin(), bpb = engine.beatsPerBar();
    return origin + (((engine.beat() - origin) / bpb).floor() + 1) * bpb;
  }

  void _schedule(int index, double beat, {int pauseBars = 0}) {
    final songs = setlistSongs;
    if (index < songs.length) {
      final song = songs[index];
      engine.scheduleSong(beat, song.bpm, song.beatsPerBar, pauseBars);
    } else {
      engine.scheduleSong(beat, 0, engine.beatsPerBar(), 0); // end of setlist
    }
    _changeBeat = beat;
    _changeIndex = index;
  }

  void _setlistTick() {
    final setlist = activeSetlist;
    if (setlist == null || !canControl) return;
    if (!engine.isPlaying()) {
      // Stopped by the user or at the end; playing again restarts this song.
      _changeBeat = null;
      _resumeEnd = null;
      return;
    }
    final songs = setlistSongs;
    final beat = engine.beat();
    final change = _changeBeat;
    if (change != null) {
      if (beat >= change) {
        _changeBeat = null;
        setlistIndex = _changeIndex;
        if (setlistIndex < songs.length) currentSong = songs[setlistIndex];
        notifyListeners();
      }
      return;
    }
    // Wait until the song's first downbeat sets the bar origin.
    if (!setlist.autoAdvance || engine.pendingBeatsPerBar() > 0) return;
    if (setlistIndex >= songs.length) return;
    final bars = songBars(songs[setlistIndex]);
    if (bars == null) return; // no duration: the user moves on
    final origin = engine.barOrigin(), bpb = engine.beatsPerBar();
    // A song reached automatically starts after its pause.
    final start = engine.muteUntil() > origin ? engine.muteUntil() : origin;
    var end = start + bars * bpb;
    if (_resumeEnd case final kept?) {
      end = origin + ((kept - origin) / bpb).ceil() * bpb;
      _resumeEnd = null;
    }
    // Already past the end (auto-advance turned on late): change soon instead
    // of pivoting the tempo in the past.
    if (end <= beat + 0.5) end = _nextDownbeat();
    _schedule(setlistIndex + 1, end, pauseBars: setlist.pauseBars);
    notifyListeners();
  }

  // ---- Sharing ----

  Future<void> setShareMode(ShareMode mode) async {
    engine.setLinkEnabled(mode != ShareMode.solo);
    shareMode = mode;
    leaderInfo = const ShowInfo();
    if (mode == ShareMode.follower && activeSetlist != null) stopSetlist();
    notifyListeners();
    _channel?.close();
    _channel = null;
    try {
      final channel = switch (mode) {
        ShareMode.solo => null,
        ShareMode.leader => await ShareChannel.leader(
          engine,
          info: () => showInfo,
        ),
        ShareMode.follower => await ShareChannel.follower(
          engine,
          onInfo: (info) {
            if (info == leaderInfo) return;
            leaderInfo = info;
            notifyListeners();
          },
        ),
      };
      // The user may have switched again while the socket was opening.
      if (shareMode == mode) {
        _channel = channel;
      } else {
        channel?.close();
      }
    } on SocketException catch (e) {
      // Link still syncs the beat; only bar alignment is lost.
      debugPrint('share channel unavailable: $e');
    }
  }

  // ---- Practice tools and settings ----

  // Hidden tools must not change the click, but keep their settings.
  void _applyPractice() {
    final on = library.practiceTools;
    engine.setDisplacement(on ? displaceBars : 0);
    final gap = on && gapTrainer;
    engine.setGapTrainer(gap ? gapPlay : 0, gap ? gapMute : 0);
  }

  void setDisplacement(int bars) {
    library.displaceBars = bars;
    _practiceChanged();
  }

  void setGapTrainer({bool? enabled, int? play, int? mute}) {
    library.gapTrainer = enabled ?? gapTrainer;
    library.gapPlay = play ?? gapPlay;
    library.gapMute = mute ?? gapMute;
    _practiceChanged();
  }

  void _practiceChanged() {
    _applyPractice();
    notifyListeners();
    store.save(library);
  }

  void setPracticeTools(bool enabled) {
    library.practiceTools = enabled;
    _practiceChanged();
  }

  /// Applies live while dragging; call [saveLibrary] when the drag ends.
  void setExtraLatency(double ms) {
    engine.setExtraLatencyMs(ms);
    library.extraLatencyMs = ms;
    notifyListeners();
  }

  void saveLibrary() => store.save(library);

  static const _mic = MethodChannel('prronclick/mic');

  /// Lines our clicks up with the leader's by ear: records 8 s while the
  /// leader plays, then adds the measured lateness to the latency setting.
  /// Returns how late we were and the correction actually applied (less if
  /// the setting hit its limit), or an error message.
  Future<((double, double)?, String?)> calibrate() async {
    if (shareMode != ShareMode.follower ||
        engine.numPeers() == 0 ||
        !engine.isPlaying()) {
      return (null, 'Ponte como Seguidor con el líder sonando.');
    }
    if ((Platform.isAndroid || Platform.isIOS) &&
        await _mic.invokeMethod<bool>('request') != true) {
      return (null, 'Hace falta permiso para usar el micrófono.');
    }
    if (!engine.calibrationStart()) {
      return (null, 'No se pudo abrir el micrófono.');
    }
    await Future<void>.delayed(const Duration(seconds: 8));
    final late = engine.calibrationFinish();
    if (late.isNaN) {
      return (
        null,
        'No se oyeron bien los dos clicks. Acerca el dispositivo al líder, '
            'sube el volumen, deja sonar solo al líder (sin click desplazado) '
            'y prueba otra vez.',
      );
    }
    final before = library.extraLatencyMs;
    setExtraLatency((before + late).clamp(-100, 400));
    saveLibrary();
    return ((late, library.extraLatencyMs - before), null);
  }
}
