import 'package:PiliPlus/pages/common/common_intro_controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlayerFocus extends StatelessWidget {
  const PlayerFocus({
    super.key,
    required this.child,
    required this.plPlayerController,
    required this.onSendDanmaku,
    required this.canPlay,
    required this.onSkipSegment,
    required this.introController,
  });

  final Widget child;
  final PlPlayerController plPlayerController;
  final VoidCallback onSendDanmaku;
  final bool Function() canPlay;
  final VoidCallback onSkipSegment;
  final CommonIntroController introController;

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

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      // Don't handle key up events to avoid double actions.
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;

    // Layer 1: Controls are hidden. D-pad events should wake them up.
    if (!plPlayerController.showControls.value) {
      if (key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.enter) {
        plPlayerController.showControls.value = true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (key == LogicalKeyboardKey.arrowUp) {
            plPlayerController.mainControlsFocusNode.requestFocus();
          } else if (key == LogicalKeyboardKey.arrowDown) {
            plPlayerController.secondaryControlsFocusNode.requestFocus();
          } else {
            plPlayerController.progressFocusNode.requestFocus();
          }
        });

        return KeyEventResult.handled;
      }
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

    if (key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.mediaPlayPause) {
      plPlayerController.togglePlay();
      return KeyEventResult.handled;
    }

    // Restore other hotkeys
    if (key == LogicalKeyboardKey.keyD) {
      onSendDanmaku.call();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyS) {
      onSkipSegment();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      plPlayerController.setVolume((plPlayerController.volume.value + 0.05).clamp(0.0, 1.0));
      return KeyEventResult.handled;
    }

     if (key == LogicalKeyboardKey.arrowDown) {
      plPlayerController.setVolume((plPlayerController.volume.value - 0.05).clamp(0.0, 1.0));
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}
