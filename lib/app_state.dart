// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:io';
import 'dart:math';

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
  /// [load] is the app's way in; tests bring their own engine and store.
  AppState.using(this.engine, this.store, this.library)
    : audioOk = engine.init() {
    engine.setExtraLatencyMs(library.extraLatencyMs);
    engine.setLinkPort(sessionPort(library.sessionCode));
    _applyCountIn();
    _applyPractice();
    _applyClick();
    // Sections, setlists and the tempo ramp all watch the beat go by.
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
    // Playing can start or stop from many places (button, Link, the leader, a
    // setlist's end), so poll it instead of hooking each one.
    if (Platform.isAndroid) {
      Timer.periodic(const Duration(milliseconds: 500), (_) => _keepAlive());
      _background.setMethodCallHandler((call) async {
        if (call.method == 'stop') await stopFromNotification();
      });
    }
  }

  static const _background = MethodChannel('prronclick/background');
  late final Timer _ticker;

  /// Stops the timers and the engine (tests; the app lives until it exits).
  void close() {
    _ticker.cancel();
    engine.shutdown();
  }

  bool _alive = false;

  /// The notification's Parar. A follower cannot stop the band (Link would
  /// stop everyone), so it leaves the session first and stops alone.
  Future<void> stopFromNotification() async {
    if (shareMode == ShareMode.follower) await setShareMode(ShareMode.solo);
    engine.setPlaying(false);
  }

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
    return AppState.using(Engine(), store, await store.load());
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

  /// The meter's lower number. Notation, except that the engine groups the
  /// accents of 6/8, 9/8 and 12/8 by it.
  int get beatUnit => _beatUnit;
  int _beatUnit = 4;
  set beatUnit(int unit) {
    _beatUnit = unit;
    engine.setBeatUnit(unit);
  }

  /// The song whose lyrics to show: ours, or as a follower our own copy of
  /// the leader's song, found by name (lyrics are too big to broadcast).
  Song? get shownSong =>
      shareMode == ShareMode.follower ? _followedSong : currentSong;
  Song? _followedSong;

  void _findFollowedSong() {
    final name = leaderInfo.song;
    _followedSong = name == null
        ? null
        : library.songs.where((s) => fold(s.name) == fold(name)).firstOrNull;
  }

  /// Follower: what the leader announces.
  ShowInfo leaderInfo = const ShowInfo();

  /// The song and setlist to show: ours, or the leader's when following.
  ShowInfo get showInfo {
    if (shareMode == ShareMode.follower) return leaderInfo;
    final setlist = activeSetlist;
    final song = currentSong;
    final sections = song?.sections ?? const <Section>[];
    final next = _changeBeat == null ? null : _changeSection;
    final songs = setlistSongs, i = setlistIndex;
    return ShowInfo(
      song: song?.name,
      key: song?.key,
      note: song?.note,
      beatUnit: beatUnit,
      section: sections.elementAtOrNull(sectionIndex)?.name,
      nextSection: next == null ? null : sections.elementAtOrNull(next)?.name,
      sectionChange: next == null ? null : _changeBeat,
      setlist: setlist?.name,
      position: setlist == null ? 0 : i + 1,
      total: setlist == null ? 0 : songs.length,
      next: i + 1 < songs.length ? songs[i + 1].name : null,
      // A section change is not the next song.
      changeBeat: next == null ? _changeBeat : null,
    );
  }

  void saveSong(Song song) {
    if (!library.songs.contains(song)) library.songs.add(song);
    // Its sections may have changed under us: start it over.
    if (song == currentSong && canControl) {
      _forgetChange();
      _load(song);
    }
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
    _forgetChange();
    _load(song);
  }

  /// Meter picked by hand. In a setlist the song keeps its end, rounded up to
  /// a whole bar of the new meter.
  void setMeter(int beats, int unit) {
    beatUnit = unit;
    notifyListeners();
    engine.setBeatsPerBar(beats);
    if (_changeBeat != null && engine.isPlaying()) {
      _resumeEnd = _changeBeat;
      _changeBeat = null;
      _changeSection = null;
    }
  }

  /// Sets tempo and meter from the song (its first section). While playing,
  /// the meter switches on the next downbeat.
  void _load(Song song) {
    sectionIndex = 0;
    engine.setTempo(song.bpmAt(0));
    engine.setBeatsPerBar(song.beatsAt(0));
    beatUnit = song.unitAt(0);
    currentSong = song;
    notifyListeners();
  }

  /// Adds songs read from a file; returns how many.
  int importSongs(List<Song> songs) {
    songs.forEach(library.mergeSong);
    _libraryChanged();
    return songs.length;
  }

  /// Adds or updates a setlist read from a file; null if it is not one.
  Setlist? importSetlist(Object? json) {
    final setlist = library.importSetlist(json);
    if (setlist == null) return null;
    // Its songs or order may have changed under a running setlist.
    if (activeSetlist != null) stopSetlist();
    _libraryChanged();
    return setlist;
  }

  void _libraryChanged() {
    _findFollowedSong();
    notifyListeners();
    store.save(library);
  }

  // ---- Setlists ----

  void saveSetlist(Setlist setlist) {
    if (!library.setlists.contains(setlist)) library.setlists.add(setlist);
    _applyCountIn(); // the running setlist's count-in may have been edited
    _libraryChanged();
  }

  void deleteSetlist(Setlist setlist) {
    library.setlists.remove(setlist);
    if (activeSetlist == setlist) stopSetlist();
    _libraryChanged();
  }

  Setlist? activeSetlist;
  int setlistIndex = 0;

  /// Which of the current song's sections is playing.
  int sectionIndex = 0;

  /// Beat where the next song, section or the end is scheduled; null if none
  /// yet.
  double? get changeBeat => _changeBeat;
  double? _changeBeat;
  int _changeIndex = 0; // the song it brings...
  int? _changeSection; // ...or, if set, the section of the current song
  double? _resumeEnd; // end to keep after a manual meter change

  void _forgetChange() {
    _changeBeat = null;
    _changeSection = null;
    _resumeEnd = null;
  }

  List<Song> get setlistSongs =>
      activeSetlist?.songsFrom(library.songs) ?? const [];

  void startSetlist(Setlist setlist, [int index = 0]) {
    final songs = setlist.songsFrom(library.songs);
    if (index >= songs.length) return;
    activeSetlist = setlist;
    setlistIndex = index;
    _forgetChange();
    _applyCountIn();
    _load(songs[index]);
  }

  void stopSetlist() {
    activeSetlist = null;
    _forgetChange();
    _applyCountIn();
    notifyListeners();
  }

  /// Jumps to song [index]: now if stopped, else on the next downbeat.
  void goToSong(int index) {
    if (index < 0 || index >= setlistSongs.length) return;
    _forgetChange();
    if (!engine.isPlaying()) {
      setlistIndex = index;
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
      engine.scheduleSong(beat, song.bpmAt(0), song.beatsAt(0), pauseBars);
    } else {
      engine.scheduleSong(beat, 0, engine.beatsPerBar(), 0); // end of setlist
    }
    _changeBeat = beat;
    _changeIndex = index;
    _changeSection = null;
  }

  /// Where the stretch playing now (song or section) began: after its pause
  /// and count-in, if any.
  double _stretchStart() =>
      [engine.barOrigin(), engine.muteUntil(), engine.countUntil()].reduce(max);

  void _tick() {
    _rampTick();
    final song = currentSong;
    if (song == null || !canControl) return;
    final setlist = activeSetlist;
    final sections = song.sections;
    if (setlist == null && sections.isEmpty) return;
    if (!engine.isPlaying()) {
      // Stopped by the user or at the end; playing again restarts this song.
      _forgetChange();
      if (sectionIndex != 0) _load(song);
      return;
    }
    final beat = engine.beat();
    final change = _changeBeat;
    if (change != null) {
      if (beat < change) return;
      _changeBeat = null;
      if (_changeSection case final section?) {
        _changeSection = null;
        sectionIndex = section;
        beatUnit = song.unitAt(section);
      } else {
        final songs = setlistSongs;
        setlistIndex = _changeIndex;
        sectionIndex = 0;
        if (setlistIndex < songs.length) {
          currentSong = songs[setlistIndex];
          beatUnit = currentSong!.unitAt(0);
        }
      }
      notifyListeners();
      return;
    }
    // Wait until the stretch's first downbeat sets the bar origin.
    if (engine.pendingBeatsPerBar() > 0) return;
    final lastSection = sectionIndex + 1 >= sections.length;
    final advance =
        setlist != null &&
        setlist.autoAdvance &&
        setlistIndex < setlistSongs.length;
    if (lastSection && !advance) return; // nothing follows: keep playing
    final bars = sections.isEmpty
        ? songBars(song)
        : sections[min(sectionIndex, sections.length - 1)].bars;
    if (bars == null) return; // no duration: the user moves on
    final origin = engine.barOrigin(), bpb = engine.beatsPerBar();
    var end = _stretchStart() + bars * bpb;
    if (_resumeEnd case final kept?) {
      end = origin + ((kept - origin) / bpb).ceil() * bpb;
      _resumeEnd = null;
    }
    // Already past the end (auto-advance turned on late): change soon instead
    // of pivoting the tempo in the past.
    if (end <= beat + 0.5) end = _nextDownbeat();
    if (lastSection) {
      _schedule(setlistIndex + 1, end, pauseBars: setlist!.pauseBars);
    } else {
      final next = sectionIndex + 1;
      engine.scheduleSection(end, song.bpmAt(next), song.beatsAt(next));
      _changeBeat = end;
      _changeSection = next;
    }
    notifyListeners();
  }

  // ---- Tempo ramp ----

  double? _rampStart; // start of the stretch being ramped
  double? _rampBase; // its tempo before the ramp, to go back to
  int _rampStep = 0;

  /// Practice tool: every rampBars bars the tempo goes up rampBpm. A new song
  /// or section starts over from its own tempo; stopping goes back to it.
  // shortcut: the step lands up to one tick (100 ms) after the downbeat, not
  // on it; schedule it in the engine if that is ever heard.
  void _rampTick() {
    final on = library.practiceTools && library.ramp && canControl;
    if (!on || !engine.isPlaying()) {
      if (_rampBase case final base? when canControl) engine.setTempo(base);
      _rampBase = _rampStart = null;
      return;
    }
    final start = _stretchStart();
    final bars = ((engine.beat() - start) / engine.beatsPerBar()).floor();
    if (bars < 0) return; // still in the pause or count-in
    final step = bars ~/ library.rampBars;
    if (start != _rampStart) {
      _rampStart = start;
      _rampBase = engine.tempo();
      _rampStep = step;
    } else if (step > _rampStep) {
      final up = library.rampBpm * (step - _rampStep);
      engine.setTempo((engine.tempo() + up).clamp(20, 300));
      _rampStep = step;
    }
  }

  // ---- Sharing ----

  Future<void> setShareMode(ShareMode mode) async {
    engine.setLinkEnabled(mode != ShareMode.solo);
    shareMode = mode;
    leaderInfo = const ShowInfo();
    _followedSong = null;
    engine.setBeatUnit(beatUnit); // back to ours after following a leader
    if (mode == ShareMode.follower && activeSetlist != null) stopSetlist();
    notifyListeners();
    _channel?.close();
    _channel = null;
    try {
      final channel = switch (mode) {
        ShareMode.solo => null,
        ShareMode.leader => await ShareChannel.leader(
          engine,
          port: sessionPort(library.sessionCode) + 1,
          info: () => showInfo,
        ),
        ShareMode.follower => await ShareChannel.follower(
          engine,
          port: sessionPort(library.sessionCode) + 1,
          onInfo: (info) {
            if (info == leaderInfo) return;
            leaderInfo = info;
            engine.setBeatUnit(info.beatUnit);
            _findFollowedSong();
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

  /// Moves this device to the band with [code] (empty = standard Link).
  /// Link opens its sockets when enabled, so sharing goes off and on again.
  Future<void> setSessionCode(String code) async {
    library.sessionCode = code.trim();
    store.save(library);
    notifyListeners();
    final mode = shareMode;
    engine.setLinkEnabled(false);
    engine.setLinkPort(sessionPort(library.sessionCode));
    if (mode == ShareMode.solo) return;
    // Link closes the old sockets on its own thread: give it a moment, or
    // off-then-on is seen as no change and it stays on the old port.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (shareMode == mode) await setShareMode(mode);
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

  /// A running setlist's own count-in wins over the app setting.
  void _applyCountIn() =>
      engine.setCountIn(activeSetlist?.countInBars ?? library.countInBars);

  /// Applies to the next song started (play or a setlist change).
  void setCountIn(int bars) {
    library.countInBars = bars;
    _applyCountIn();
    notifyListeners();
    store.save(library);
  }

  void setRamp({bool? enabled, int? bpm, int? bars}) {
    library.ramp = enabled ?? library.ramp;
    library.rampBpm = bpm ?? library.rampBpm;
    library.rampBars = bars ?? library.rampBars;
    _rampStart = null; // count the bars again with the new numbers
    notifyListeners();
    store.save(library);
  }

  void _applyClick() {
    engine.setSubdivision(library.subdivision);
    engine.setVolume(library.volume);
    engine.setSound(library.sound);
  }

  /// This device's click. The volume applies live while dragging; call
  /// [saveLibrary] when the drag ends.
  void setClick({int? subdivision, double? volume, int? sound}) {
    library.subdivision = subdivision ?? library.subdivision;
    library.volume = volume ?? library.volume;
    library.sound = sound ?? library.sound;
    _applyClick();
    notifyListeners();
    if (volume == null) store.save(library);
  }

  void setFlash({bool? beats, bool? countIn}) {
    library.flash = beats ?? library.flash;
    library.flashCountIn = countIn ?? library.flashCountIn;
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
