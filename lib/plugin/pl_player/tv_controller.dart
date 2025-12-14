import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';

enum FocusArea {
  none,
  top,
  progress,
  bottom,
}

class TvPlayerController {
  static TvPlayerController? _instance;
  final PlPlayerController plPlayerController;

  // private constructor
  TvPlayerController._(this.plPlayerController);

  // get instance
  static TvPlayerController getInstance({bool isLive = false}) {
    // create a new instance if one doesn't exist
    _instance ??= TvPlayerController._(PlPlayerController.getInstance(isLive: isLive));
    return _instance!;
  }

  // Focus nodes for different UI areas
  final FocusNode focusNodeA = FocusNode(); // Top area
  final FocusNode focusNodeB = FocusNode(); // Progress bar area
  final FocusNode focusNodeC = FocusNode(); // Bottom area

  // Currently active focus area
  final Rx<FocusArea> currentFocusArea = FocusArea.none.obs;

  // Method to handle key events when controls are hidden
  KeyEventResult handleKeyEventWhenHidden(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.select: // OK/Enter
        plPlayerController.onDoubleTapCenter();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp: // DPAD_UP
        showControlsAndFocus(FocusArea.top);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown: // DPAD_DOWN
        showControlsAndFocus(FocusArea.bottom);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        plPlayerController.onBackward(plPlayerController.fastForBackwardDuration);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        plPlayerController.onForward(plPlayerController.fastForBackwardDuration);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  // Method to show controls and set focus
  void showControlsAndFocus(FocusArea area) {
    plPlayerController.showControls.value = true;
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

  // Back key handling
  KeyEventResult handleBackKey() {
    if (plPlayerController.showControls.value) {
      // Hide the controls
      plPlayerController.showControls.value = false;
      return KeyEventResult.handled;
    } else {
      // Exit the player (let the upper layer handle it)
      return KeyEventResult.ignored;
    }
  }

  // Auto-hide timer
  void startAutoHideTimer() {
    Future.delayed(const Duration(seconds: 5), () {
      if (plPlayerController.showControls.value) {
        // Add a check here to see if any sub-menus are open
        // if (!isAnyMenuOpen()) {
        //   showControls.value = false;
        // }
      }
    });
  }


  void dispose() {
    focusNodeA.dispose();
    focusNodeB.dispose();
    focusNodeC.dispose();
    plPlayerController.dispose();
  }

  void handleFocusChange(FocusArea area) {
    currentFocusArea.value = area;
  }
}
