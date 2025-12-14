import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

enum FocusArea {
  none,
  top,
  progress,
  bottom,
}

class TvPlayerController extends PlPlayerController {
  final FocusNode focusNodeA = FocusNode(); // Top area
  final FocusNode focusNodeB = FocusNode(); // Progress bar area
  final FocusNode focusNodeC = FocusNode(); // Bottom area

  final Rx<FocusArea> currentFocusArea = FocusArea.none.obs;

  static TvPlayerController? _instance;

  TvPlayerController();

  factory TvPlayerController.getInstance({bool isLive = false}) {
    _instance ??= TvPlayerController();
    _instance!
      ..isLive = isLive
      ..playerCount += 1;
    return _instance!;
  }

  void showControlsAndFocus(FocusArea area) {
    showControls.value = true;
    currentFocusArea.value = area;

    switch (area) {
      case FocusArea.top:
        focusNodeA.requestFocus();
        break;
      case FocusArea.progress:
        focusNodeB.requestFocus();
        break;
      case FocusArea.bottom:
        focusNodeC.requestFocus();
        break;
      case FocusArea.none:
        break;
    }
    startAutoHideTimer();
  }

  KeyEventResult handleKeyEventWhenHidden(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.select: // OK/Enter
        showControlsAndFocus(FocusArea.progress);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp: // DPAD_UP
        showControlsAndFocus(FocusArea.top);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown: // DPAD_DOWN
        showControlsAndFocus(FocusArea.bottom);
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult handleBackKey() {
    if (showControls.value) {
      showControls.value = false;
      return KeyEventResult.handled;
    } else {
      return KeyEventResult.ignored;
    }
  }

  void startAutoHideTimer() {
    timer?.cancel();
    timer = Timer(showControlDuration, () {
      showControls.value = false;
    });
  }
}
