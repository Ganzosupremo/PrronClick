// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// An [IconButton] that, held down, keeps pressing itself until let go or
/// disabled (e.g. at the end of its range).
class RepeatIconButton extends StatefulWidget {
  const RepeatIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.filledTonal = false,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool filledTonal; // [IconButton.filledTonal]'s look

  static const every = Duration(milliseconds: 100);

  @override
  State<RepeatIconButton> createState() => _RepeatIconButtonState();
}

class _RepeatIconButtonState extends State<RepeatIconButton> {
  Timer? _timer;

  void _start() {
    widget.onPressed?.call();
    _timer = Timer.periodic(RepeatIconButton.every, (_) {
      // The latest widget: each press rebuilds it, maybe disabled now.
      final press = widget.onPressed;
      if (press == null) return _stop();
      press();
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final button = widget.filledTonal
        ? IconButton.filledTonal(onPressed: widget.onPressed, icon: widget.icon)
        : IconButton(onPressed: widget.onPressed, icon: widget.icon);
    return GestureDetector(
      onLongPressStart: enabled ? (_) => _start() : null,
      onLongPressEnd: (_) => _stop(),
      onLongPressCancel: _stop,
      // A tooltip would take the long press: shown on hover only, and still
      // read out by screen readers.
      child: widget.tooltip == null
          ? button
          : Tooltip(
              message: widget.tooltip,
              triggerMode: TooltipTriggerMode.manual,
              child: button,
            ),
    );
  }
}
