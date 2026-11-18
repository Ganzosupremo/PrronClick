// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'chordpro.dart';
import 'cues.dart';
import 'engine.dart';
import 'library.dart';
import 'practice.dart';
import 'setlist.dart';
import 'share.dart';
import 'song.dart';

enum ShareMode { solo, leader, follower }

enum CalibrationError { notFollowing, noPermission, micFailed, notHeard }

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
    engine.setVoiceCount(library.voiceCount);
    _loadVoices();
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

  /// The bar's accents (null = automatic): the leader's when following,
  /// else the song's or set by hand.
  List<int>? get accents =>
      shareMode == ShareMode.follower ? leaderInfo.accents : _accents;
  List<int>? _accents;

  void _sendAccents(List<int>? accents, {bool next = false}) => engine
      .setAccents(accentBits(accents ?? const []), accents?.length ?? 0, next);

  /// Tapping beat [index] of a bar of [beats] (see [nextAccent]). The
  /// loaded song keeps it.
  void cycleAccent(int index, int beats) {
    final auto = defaultAccents(beats, beatUnit);
    final levels = [...(_accents?.length == beats ? _accents! : auto)];
    levels[index] = nextAccent(levels[index]);
    _accents = sameAccents(levels, auto) ? null : levels;
    _sendAccents(_accents);
    final song = currentSong;
    if (song != null && song.beatsPerBar == beats) {
      song.accents = _accents;
      _libraryChanged();
    } else {
      notifyListeners();
    }
  }

  /// The song whose lyrics to show: ours, or as a follower the leader's,
  /// found by name among the songs it sent, else in our own library.
  Song? get shownSong =>
      shareMode == ShareMode.follower ? _followedSong : currentSong;
  Song? _followedSong;

  void _findFollowedSong() {
    final name = leaderInfo.song;
    Song? named(List<Song> songs) =>
        songs.where((s) => fold(s.name) == fold(name!)).firstOrNull;
    _followedSong = name == null
        ? null
        : named(_leaderSongs) ?? named(library.songs);
  }

  /// Follower: what the leader sent ([Library.exportSetlist]'s format when a
  /// setlist runs there), and its songs.
  Object? _leaderShared;
  List<Song> _leaderSongs = const [];

  void _leaderSent(Object? json) {
    final list = json is Map ? json['songs'] : null;
    _leaderShared = json;
    _leaderSongs = [
      for (final s in list is List ? list : const []) ?Song.fromJson(s),
    ];
    _findFollowedSong();
    notifyListeners();
  }

  /// Follower: whether the leader's running setlist can be kept.
  bool get canSaveLeaderSetlist =>
      shareMode == ShareMode.follower &&
      leaderInfo.setlist != null &&
      _leaderShared is Map &&
      (_leaderShared as Map)['prronclick'] == 'setlist';

  /// Follower: adds the leader's setlist and its songs to our library (or
  /// updates them, if we kept it before). Null if there is none.
  Setlist? saveLeaderSetlist() =>
      canSaveLeaderSetlist ? importSetlist(_leaderShared) : null;

  /// Leader: the running setlist with its songs, else the song loaded.
  String _sharedSongs() => jsonEncode(switch (activeSetlist) {
    final setlist? => library.exportSetlist(setlist),
    null => {
      'songs': [?currentSong?.toJson()],
    },
  });

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
      key: song?.key == null
          ? null
          : transposeChord(song!.key!, song.transpose),
      note: song?.note,
      beatUnit: beatUnit,
      accents: _accents,
      transpose: song?.transpose ?? 0,
      section: sections.elementAtOrNull(sectionIndex)?.name,
      nextSection: next == null ? null : sections.elementAtOrNull(next)?.name,
      sectionChange: next == null ? null : _changeBeat,
      setlist: setlist?.name,
      position: setlist == null ? 0 : i + 1,
      total: setlist == null ? 0 : songs.length,
      next: i + 1 < songs.length ? songs[i + 1].name : null,
      // A section change is not the next song, nor is the song's end.
      changeBeat: next == null && !_changeStops ? _changeBeat : null,
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
    // While playing, from the downbeat the new meter starts on.
    _accents = song.accents;
    _sendAccents(_accents, next: true);
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
  bool _changeStops = false; // ...or the song's end: the click stops there

  void _forgetChange() {
    _changeBeat = null;
    _changeSection = null;
    _resumeEnd = null;
    _changeStops = false;
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
      _sendAccents(song.accents, next: true);
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
    _cueTick();
    _practiceTick();
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
      } else if (_changeStops) {
        // The engine stops on this beat; stopping loads the song's start.
        _changeStops = false;
      } else {
        final songs = setlistSongs;
        setlistIndex = _changeIndex;
        sectionIndex = 0;
        if (setlistIndex < songs.length) {
          currentSong = songs[setlistIndex];
          beatUnit = currentSong!.unitAt(0);
          _accents = currentSong!.accents; // the engine switched on the beat
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
    // An Outro (or Final, Coda...) last ends the song: the click stops.
    final stops =
        lastSection &&
        !advance &&
        sections.isNotEmpty &&
        endsSong(sections.last.name);
    if (lastSection && !advance && !stops) return; // keep playing
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
    if (stops) {
      engine.scheduleSong(end, 0, bpb, 0);
      _changeBeat = end;
      _changeSection = null;
      _changeStops = true;
    } else if (lastSection) {
      _schedule(setlistIndex + 1, end, pauseBars: setlist!.pauseBars);
    } else {
      final next = sectionIndex + 1;
      engine.scheduleSection(end, song.bpmAt(next), song.beatsAt(next));
      _changeBeat = end;
      _changeSection = next;
    }
    notifyListeners();
  }

  // ---- Practice history ----

  Practice? _practicing; // what is playing now, until it stops or changes

  /// Notes what the click plays: a new entry when it starts or the song
  /// changes, the highest tempo while it plays.
  void _practiceTick() {
    final playing = engine.isPlaying();
    final song = showInfo.song;
    if (_practicing case final p? when !playing || p.song != song) {
      _endPractice();
    }
    if (!playing) return;
    final bpm = engine.tempo().round().clamp(20, 300);
    final p = _practicing ??= Practice(
      start: DateTime.now(),
      seconds: 0,
      song: song,
      bpm: bpm,
    );
    p.bpm = max(p.bpm, bpm);
    // The tools as they apply now (see _applyPractice and _rampTick).
    if (library.practiceTools) {
      if (library.ramp && canControl) p.tools.add(PracticeTool.ramp);
      if (gapTrainer) p.tools.add(PracticeTool.gap);
      if (displaceBars > 0) p.tools.add(PracticeTool.displace);
    }
  }

  void _endPractice() {
    final p = _practicing!;
    _practicing = null;
    p.seconds = DateTime.now().difference(p.start).inSeconds;
    if (p.seconds < minPracticeSeconds) return;
    final history = library.history..add(p);
    if (history.length > maxPracticeEntries) {
      history.removeRange(0, history.length - maxPracticeEntries);
    }
    notifyListeners();
    store.save(library);
  }

  void clearHistory() {
    library.history.clear();
    notifyListeners();
    store.save(library);
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
    _leaderShared = null;
    _leaderSongs = const [];
    engine.setBeatUnit(beatUnit); // back to ours after following a leader
    _sendAccents(_accents);
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
          songs: _sharedSongs,
        ),
        ShareMode.follower => await ShareChannel.follower(
          engine,
          port: sessionPort(library.sessionCode) + 1,
          onInfo: (info) {
            if (info == leaderInfo) return;
            leaderInfo = info;
            engine.setBeatUnit(info.beatUnit);
            // shortcut: applied when heard, so a new song's first beat may
            // keep the old accents; send the next song's ahead if it matters.
            _sendAccents(info.accents);
            _findFollowedSong();
            notifyListeners();
          },
          onSongs: _leaderSent,
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

  /// Shows the loaded song's chords and key [steps] semitones moved.
  void setTranspose(int steps) {
    final song = currentSong;
    if (song == null) return;
    song.transpose = steps.clamp(-11, 11);
    notifyListeners();
    store.save(library);
  }

  /// '' follows the phone's language.
  void setLanguage(String code) {
    library.language = code;
    _loadVoices();
    notifyListeners();
    store.save(library);
  }

  /// How many voice cues the app's language has; 0 = none in this build.
  int voices = 0;

  Future<void> _loadVoices() async {
    final phone = PlatformDispatcher.instance.locale.languageCode;
    final language = library.language.isNotEmpty
        ? library.language
        : languages.contains(phone)
        ? phone
        : 'en';
    voices = await loadCues(engine, language);
    notifyListeners();
  }

  void setVoice({bool? count, bool? sections}) {
    library.voiceCount = count ?? library.voiceCount;
    library.voiceSections = sections ?? library.voiceSections;
    engine.setVoiceCount(library.voiceCount);
    notifyListeners();
    store.save(library);
  }

  double? _cuedBeat;

  /// A bar before a section starts, a voice says its name. Followers too: they
  /// get the leader's next section and its beat.
  void _cueTick() {
    final info = showInfo;
    final name = info.nextSection, change = info.sectionChange;
    final cue = name == null ? null : sectionCue(name);
    if (!library.voiceSections || !engine.isPlaying() || cue == null) {
      if (_cuedBeat != null) engine.clearCues();
      _cuedBeat = null;
      return;
    }
    final at = change! - engine.beatsPerBar();
    if (at == _cuedBeat || at <= engine.beat()) return;
    engine.scheduleCue(at, cue.$1, cue.$2);
    _cuedBeat = at;
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
  /// the setting hit its limit), or why it could not.
  Future<((double, double)?, CalibrationError?)> calibrate() async {
    if (shareMode != ShareMode.follower ||
        engine.numPeers() == 0 ||
        !engine.isPlaying()) {
      return (null, CalibrationError.notFollowing);
    }
    if ((Platform.isAndroid || Platform.isIOS) &&
        await _mic.invokeMethod<bool>('request') != true) {
      return (null, CalibrationError.noPermission);
    }
    if (!engine.calibrationStart()) {
      return (null, CalibrationError.micFailed);
    }
    await Future<void>.delayed(const Duration(seconds: 8));
    final late = engine.calibrationFinish();
    if (late.isNaN) {
      return (null, CalibrationError.notHeard);
    }
    final before = library.extraLatencyMs;
    setExtraLatency((before + late).clamp(-100, 400));
    saveLibrary();
    return ((late, library.extraLatencyMs - before), null);
  }
}
