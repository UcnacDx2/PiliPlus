import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'controller.dart';

// Enum to represent the different focus areas in the TV player UI.
enum FocusArea {
  none,
  top,
  progress,
  bottom,
}

class TvPlayerController extends PlPlayerController {
  TvPlayerController() : super();

  // Focus nodes for the main UI areas.
  final FocusNode focusNodeA = FocusNode(); // Top controls
  final FocusNode focusNodeB = FocusNode(); // Progress bar
  final FocusNode focusNodeC = FocusNode(); // Bottom controls

  // Tracks the currently active focus area.
  final Rx<FocusArea> currentFocusArea = FocusArea.none.obs;

  // Method to handle key events when the controls are hidden (blind operation).
  KeyEventResult handleKeyEventWhenHidden(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.select: // OK/Enter button
        showControlsAndFocus(FocusArea.progress);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp: // D-pad Up
        showControlsAndFocus(FocusArea.top);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown: // D-pad Down
        showControlsAndFocus(FocusArea.bottom);
        return KeyEventResult.handled;
      // Add other blind key event handling here if needed.
    }
    return KeyEventResult.ignored;
  }

  // Method to show the controls and set focus to a specific area.
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
        // Do nothing or remove focus
        break;
    }

    // Reuse the existing auto-hide timer logic from the parent controller.
    // The timer logic is handled by the view, which observes `showControls`.
  }

  // Handles the back key event.
  KeyEventResult handleBackKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (showControls.value) {
      showControls.value = false;
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Future<void> dispose() async {
    focusNodeA.dispose();
    focusNodeB.dispose();
    focusNodeC.dispose();
    await super.dispose();
  }
}
