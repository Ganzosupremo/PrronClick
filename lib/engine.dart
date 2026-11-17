// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:ffi';
import 'dart:io';

/// Bindings to the native engine in `native/prronclick.h`.
class Engine {
  Engine([String? libraryPath]) : this._(_open(libraryPath));

  Engine._(DynamicLibrary lib)
    : init = lib.lookupFunction<Bool Function(), bool Function()>('pc_init'),
      shutdown = lib.lookupFunction<Void Function(), void Function()>(
        'pc_shutdown',
      ),
      setLinkEnabled = lib
          .lookupFunction<Void Function(Bool), void Function(bool)>(
            'pc_set_link_enabled',
          ),
      setLinkPort = lib.lookupFunction<Void Function(Int), void Function(int)>(
        'pc_set_link_port',
      ),
      setAccents = lib
          .lookupFunction<
            Void Function(UnsignedInt, Int, Bool),
            void Function(int, int, bool)
          >('pc_set_accents'),
      loadCue = lib
          .lookupFunction<
            Bool Function(Int, Pointer<Void>, Size),
            bool Function(int, Pointer<Void>, int)
          >('pc_load_cue'),
      setVoiceCount = lib
          .lookupFunction<Void Function(Bool), void Function(bool)>(
            'pc_set_voice_count',
          ),
      scheduleCue = lib
          .lookupFunction<
            Void Function(Double, Int, Int),
            void Function(double, int, int)
          >('pc_schedule_cue'),
      clearCues = lib.lookupFunction<Void Function(), void Function()>(
        'pc_clear_cues',
      ),
      numPeers = lib.lookupFunction<Int Function(), int Function()>(
        'pc_num_peers',
      ),
      setPlaying = lib.lookupFunction<Void Function(Bool), void Function(bool)>(
        'pc_set_playing',
      ),
      isPlaying = lib.lookupFunction<Bool Function(), bool Function()>(
        'pc_is_playing',
      ),
      setTempo = lib
          .lookupFunction<Void Function(Double), void Function(double)>(
            'pc_set_tempo',
          ),
      tempo = lib.lookupFunction<Double Function(), double Function()>(
        'pc_tempo',
      ),
      setBeatsPerBar = lib
          .lookupFunction<Void Function(Int), void Function(int)>(
            'pc_set_beats_per_bar',
          ),
      setBeatUnit = lib.lookupFunction<Void Function(Int), void Function(int)>(
        'pc_set_beat_unit',
      ),
      scheduleSection = lib
          .lookupFunction<
            Void Function(Double, Double, Int),
            void Function(double, double, int)
          >('pc_schedule_section'),
      setSubdivision = lib
          .lookupFunction<Void Function(Int), void Function(int)>(
            'pc_set_subdivision',
          ),
      setVolume = lib
          .lookupFunction<Void Function(Double), void Function(double)>(
            'pc_set_volume',
          ),
      setSound = lib.lookupFunction<Void Function(Int), void Function(int)>(
        'pc_set_sound',
      ),
      setExtraLatencyMs = lib
          .lookupFunction<Void Function(Double), void Function(double)>(
            'pc_set_extra_latency_ms',
          ),
      outputLatencyMs = lib
          .lookupFunction<Double Function(), double Function()>(
            'pc_output_latency_ms',
          ),
      beat = lib.lookupFunction<Double Function(), double Function()>(
        'pc_beat',
      ),
      calibrationStart = lib.lookupFunction<Bool Function(), bool Function()>(
        'pc_calibration_start',
      ),
      calibrationFinish = lib
          .lookupFunction<Double Function(), double Function()>(
            'pc_calibration_finish',
          ),
      setBar = lib
          .lookupFunction<
            Void Function(
              Int,
              Double,
              Double,
              Double,
              Int,
              Double,
              Double,
              Double,
            ),
            void Function(
              int,
              double,
              double,
              double,
              int,
              double,
              double,
              double,
            )
          >('pc_set_bar'),
      countUntil = lib.lookupFunction<Double Function(), double Function()>(
        'pc_count_until',
      ),
      pendingCountBeats = lib
          .lookupFunction<Double Function(), double Function()>(
            'pc_pending_count_beats',
          ),
      setCountIn = lib.lookupFunction<Void Function(Int), void Function(int)>(
        'pc_set_count_in',
      ),
      muteUntil = lib.lookupFunction<Double Function(), double Function()>(
        'pc_mute_until',
      ),
      pendingMuteBeats = lib
          .lookupFunction<Double Function(), double Function()>(
            'pc_pending_mute_beats',
          ),
      beatsPerBar = lib.lookupFunction<Int Function(), int Function()>(
        'pc_beats_per_bar',
      ),
      barOrigin = lib.lookupFunction<Double Function(), double Function()>(
        'pc_bar_origin',
      ),
      pendingBeatsPerBar = lib.lookupFunction<Int Function(), int Function()>(
        'pc_pending_beats_per_bar',
      ),
      pendingOrigin = lib.lookupFunction<Double Function(), double Function()>(
        'pc_pending_origin',
      ),
      setDisplacement = lib
          .lookupFunction<Void Function(Int), void Function(int)>(
            'pc_set_displacement',
          ),
      scheduleSong = lib
          .lookupFunction<
            Void Function(Double, Double, Int, Int),
            void Function(double, double, int, int)
          >('pc_schedule_song'),
      setGapTrainer = lib
          .lookupFunction<Void Function(Int, Int), void Function(int, int)>(
            'pc_set_gap_trainer',
          );

  static DynamicLibrary _open(String? path) {
    final name =
        path ??
        (Platform.isAndroid
            ? 'libprronclick_engine.so'
            : Platform.isWindows
            ? 'prronclick_engine.dll'
            : null);
    // iOS: linked into the app binary.
    return name == null ? DynamicLibrary.process() : DynamicLibrary.open(name);
  }

  final bool Function() init;
  final void Function() shutdown;
  final void Function(bool) setLinkEnabled;
  final int Function() numPeers;

  /// The port Link finds peers on; applies the next time Link is enabled.
  final void Function(int) setLinkPort;

  /// The song's accents, 2 bits a beat (see pc_set_accents); with [next],
  /// from the scheduled change on.
  final void Function(int bits, int count, bool next) setAccents;

  /// Voice cues (see pc_load_cue and the ones after it in prronclick.h).
  final bool Function(int slot, Pointer<Void> data, int size) loadCue;
  final void Function(bool on) setVoiceCount;
  final void Function(double beat, int slot, int slot2) scheduleCue;
  final void Function() clearCues;
  final void Function(bool) setPlaying;
  final bool Function() isPlaying;
  final void Function(double) setTempo;
  final double Function() tempo;
  final void Function(int) setBeatsPerBar;

  /// The meter's lower number: only groups the accents (threes in 6/8).
  final void Function(int) setBeatUnit;
  final void Function(double) setExtraLatencyMs;
  final double Function() outputLatencyMs;
  final double Function() beat;

  /// Follower calibration: records the mic and swaps our click for a higher
  /// tone. finish returns how many ms late we sound (NaN = not heard).
  final bool Function() calibrationStart;
  final double Function() calibrationFinish;

  /// (beatsPerBar, origin, muteUntil, countUntil, nextBeatsPerBar or 0,
  /// nextOrigin, nextMuteBeats, nextCountBeats)
  final void Function(int, double, double, double, int, double, double, double)
  setBar;

  /// Count-in: beats after the pause up to this one sound at another pitch.
  final double Function() countUntil;
  final double Function() pendingCountBeats;

  /// Count-in bars before each song we start; 0 = none.
  final void Function(int) setCountIn;
  final double Function() muteUntil;
  final double Function() pendingMuteBeats;
  final int Function() beatsPerBar;
  final double Function() barOrigin;
  final int Function() pendingBeatsPerBar;
  final double Function() pendingOrigin;
  final void Function(int) setDisplacement;
  final void Function(int, int) setGapTrainer;

  /// (beat, bpm or 0 to stop there, beatsPerBar, pauseBars)
  final void Function(double, double, int, int) scheduleSong;

  /// (beat, bpm, beatsPerBar): the same change inside a song, with no pause
  /// or count-in.
  final void Function(double, double, int) scheduleSection;

  /// This device's click: softer clicks inside each beat (1 = none), volume
  /// 0..1 and timbre (0 beep, 1 wood, 2 digital).
  final void Function(int) setSubdivision;
  final void Function(double) setVolume;
  final void Function(int) setSound;
}
