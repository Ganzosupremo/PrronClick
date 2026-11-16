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
      beat = lib.lookupFunction<Double Function(), double Function()>(
        'pc_beat',
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
  final double Function() beat;
}
