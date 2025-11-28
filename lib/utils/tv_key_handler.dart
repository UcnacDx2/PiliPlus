import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'tv_focus_manager.dart';

class TvKeyHandler {
  final TvFocusManager focusManager = TvFocusManager();
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
    87: LogicalKeyboardKey.mediaTrackNext,
    88: LogicalKeyboardKey.mediaTrackPrevious,
    89: LogicalKeyboardKey.mediaRewind,
    90: LogicalKeyboardKey.mediaFastForward,
    126: LogicalKeyboardKey.mediaPlay,
    127: LogicalKeyboardKey.mediaPause,

    // Other
    4: LogicalKeyboardKey.backspace,
    82: LogicalKeyboardKey.contextMenu,
    111: LogicalKeyboardKey.escape,
  };

  final FocusNode _focusNode = FocusNode();
  FocusNode get focusNode => _focusNode;

  void handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.data is RawKeyEventDataAndroid) {
        final keyCode = (event.data as RawKeyEventDataAndroid).keyCode;
        final logicalKey = androidToLogicalKey[keyCode];
        if (logicalKey != null) {
          if (logicalKey == LogicalKeyboardKey.arrowUp) {
            focusManager.moveFocus(AxisDirection.up);
          } else if (logicalKey == LogicalKeyboardKey.arrowDown) {
            focusManager.moveFocus(AxisDirection.down);
          } else if (logicalKey == LogicalKeyboardKey.arrowLeft) {
            focusManager.moveFocus(AxisDirection.left);
          } else if (logicalKey == LogicalKeyboardKey.arrowRight) {
            focusManager.moveFocus(AxisDirection.right);
          } else if (logicalKey == LogicalKeyboardKey.backspace) {
            Get.back();
          }
        }
      }
    }
  }

  void dispose() {
    _focusNode.dispose();
  }
}
