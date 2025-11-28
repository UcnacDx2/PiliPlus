import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class TvKeyHandler {
  static const Map<int, LogicalKeyboardKey> androidToLogicalKey = {
    // D-Pad
    19: LogicalKeyboardKey.arrowUp,
    20: LogicalKeyboardKey.arrowDown,
    21: LogicalKeyboardKey.arrowLeft,
    22: LogicalKeyboardKey.arrowRight,
    23: LogicalKeyboardKey.select,

    // Media
    85: LogicalKeyboardKey.mediaPlayPause,
    86: LogicalKeyboardKey.mediaStop,
    87: LogicalKeyboardKey.mediaNext,
    88: LogicalKeyboardKey.mediaPrevious,
    89: LogicalKeyboardKey.mediaRewind,
    90: LogicalKeyboardKey.mediaFastForward,
    126: LogicalKeyboardKey.mediaPlay,
    127: LogicalKeyboardKey.mediaPause,

    // Other
    4: LogicalKeyboardKey.back,
    82: LogicalKeyboardKey.menu,
    111: LogicalKeyboardKey.escape,
  };

  final FocusNode _focusNode = FocusNode();
  FocusNode get focusNode => _focusNode;

  KeyEventResult handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.data is RawKeyEventDataAndroid) {
        final keyCode = (event.data as RawKeyEventDataAndroid).keyCode;
        final logicalKey = androidToLogicalKey[keyCode];
        if (logicalKey != null) {
          final context = _focusNode.context;
          if (context != null) {
            if (logicalKey == LogicalKeyboardKey.arrowUp) {
              Focus.of(context).focusInDirection(TraversalDirection.up);
              return KeyEventResult.handled;
            } else if (logicalKey == LogicalKeyboardKey.arrowDown) {
              Focus.of(context).focusInDirection(TraversalDirection.down);
              return KeyEventResult.handled;
            } else if (logicalKey == LogicalKeyboardKey.arrowLeft) {
              Focus.of(context).focusInDirection(TraversalDirection.left);
              return KeyEventResult.handled;
            } else if (logicalKey == LogicalKeyboardKey.arrowRight) {
              Focus.of(context).focusInDirection(TraversalDirection.right);
              return KeyEventResult.handled;
            }
          }
          if (logicalKey == LogicalKeyboardKey.select) {
            // Simulate a tap on the focused widget
            return KeyEventResult.handled;
          } else if (logicalKey == LogicalKeyboardKey.back) {
            Get.back();
            return KeyEventResult.handled;
          }
        }
      }
    }
    return KeyEventResult.ignored;
  }

  void dispose() {
    _focusNode.dispose();
  }
}
