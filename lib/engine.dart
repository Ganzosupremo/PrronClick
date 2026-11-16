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
            Void Function(Int, Double, Double, Int, Double, Double),
            void Function(int, double, double, int, double, double)
          >('pc_set_bar'),
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
  final void Function(bool) setPlaying;
  final bool Function() isPlaying;
  final void Function(double) setTempo;
  final double Function() tempo;
  final void Function(int) setBeatsPerBar;
  final void Function(double) setExtraLatencyMs;
  final double Function() outputLatencyMs;
  final double Function() beat;

  /// Follower calibration: records the mic and swaps our click for a higher
  /// tone. finish returns how many ms late we sound (NaN = not heard).
  final bool Function() calibrationStart;
  final double Function() calibrationFinish;

  /// (beatsPerBar, origin, muteUntil, nextBeatsPerBar or 0, nextOrigin,
  /// nextMuteBeats)
  final void Function(int, double, double, int, double, double) setBar;
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
}
