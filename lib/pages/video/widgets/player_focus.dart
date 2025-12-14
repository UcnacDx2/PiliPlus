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
          return _handleKeyEvent(event);
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }

  KeyEventResult _handleKeyEvent(KeyDownEvent event) {
    final key = event.logicalKey;

    // Layer 1: Controls are hidden. D-pad events should wake them up.
    if (!plPlayerController.showControls.value) {
      if (key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.enter) {

        plPlayerController.showControls.value = true;

        // Use a post-frame callback to ensure widgets are built before requesting focus.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (key == LogicalKeyboardKey.arrowUp) {
            plPlayerController.mainControlsFocusNode.requestFocus();
          } else if (key == LogicalKeyboardKey.arrowDown) {
            plPlayerController.secondaryControlsFocusNode.requestFocus();
          } else { // select or enter
            plPlayerController.progressFocusNode.requestFocus();
          }
        });

        return KeyEventResult.handled;
      }
    }
    // Layer 2: Controls are visible. Let the Focus widgets with onKey handlers do their job.
    // The global handler should now only care about global hotkeys.
    else {
        // The individual Focus widgets on the control rows and progress bar will handle
        // arrow key navigation and actions. We don't need to do anything here for that.
    }

    // --- Global Hotkeys (work whether controls are visible or not) ---

    if (key == LogicalKeyboardKey.keyF) {
      plPlayerController.triggerFullScreen();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyM) {
       final currentVolume = plPlayerController.volume.value;
       if (currentVolume > 0) {
         plPlayerController.previousVolume = currentVolume;
         plPlayerController.setVolume(0);
       } else {
         plPlayerController.setVolume(plPlayerController.previousVolume);
       }
      return KeyEventResult.handled;
    }

     if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.mediaPlayPause) {
        plPlayerController.togglePlay();
        return KeyEventResult.handled;
    }


    // If no global hotkey was matched, ignore the event.
    return KeyEventResult.ignored;
  }
}
