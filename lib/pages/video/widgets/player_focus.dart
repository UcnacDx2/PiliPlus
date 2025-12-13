import 'dart:async';

import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlayerFocus extends StatelessWidget {
  const PlayerFocus({
    super.key,
    required this.child,
    required this.plPlayerController,
  });

  final Widget child;
  final PlPlayerController plPlayerController;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          return _handleGlobalKeys(event);
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }

  KeyEventResult _handleGlobalKeys(KeyDownEvent event) {
    final key = event.logicalKey;

    // Layer 1: Controls are hidden. Handle waking up the controls.
    if (!plPlayerController.showControls.value) {
      if (key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.arrowDown) {

        plPlayerController.controls = true;

        // Delay to allow the UI to build before requesting focus.
        Future.delayed(const Duration(milliseconds: 50), () {
          if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
            plPlayerController.progressFocusNode.requestFocus();
          } else if (key == LogicalKeyboardKey.arrowUp) {
            plPlayerController.mainControlsFocusNode.requestFocus();
          } else if (key == LogicalKeyboardKey.arrowDown) {
            plPlayerController.secondaryControlsFocusNode.requestFocus();
          }
        });

        // This key press was used to show the controls, so we handle it.
        return KeyEventResult.handled;
      }
    }
    // Layer 2: Controls are visible. Handle navigation and actions.
    else {
      // Special handling when the progress bar is focused.
      if (plPlayerController.progressFocusNode.hasFocus) {
        if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
          plPlayerController.onDoubleTapCenter(); // Toggles play/pause
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowLeft) {
          plPlayerController.onBackward(plPlayerController.fastForBackwardDuration);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowRight) {
          plPlayerController.onForward(plPlayerController.fastForBackwardDuration);
          return KeyEventResult.handled;
        }
        // Let Up/Down fall through to allow default focus traversal.
      }
    }

    // Handle global hotkeys regardless of control visibility
    if (key == LogicalKeyboardKey.keyF) {
      plPlayerController.triggerFullScreen();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyM) {
       final isMuted = !plPlayerController.isMuted;
       plPlayerController.videoPlayerController!.setVolume(
         isMuted ? 0 : plPlayerController.volume.value * 100,
       );
       plPlayerController.isMuted = isMuted;
      return KeyEventResult.handled;
    }
     if (key == LogicalKeyboardKey.space) {
        plPlayerController.onDoubleTapCenter();
        return KeyEventResult.handled;
    }


    // If no specific action was taken, let the event be handled by others.
    return KeyEventResult.ignored;
  }
}