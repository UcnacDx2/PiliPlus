import 'dart:io';

import 'package:PiliPlus/pages/common/common_intro_controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlayerFocus extends StatelessWidget {
  const PlayerFocus({
    required this.child,
    required this.plPlayerController,
    required this.introController,
    required this.onSendDanmaku,
    required this.canPlay,
    required this.onSkipSegment,
    this.onShowMenu,
    super.key,
  });

  final Widget child;
  final PlPlayerController plPlayerController;
  final CommonIntroController introController;
  final VoidCallback onSendDanmaku;
  final bool Function() canPlay;
  final VoidCallback onSkipSegment;
  final VoidCallback? onShowMenu;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }

        final bool shift = HardwareKeyboard.instance.logicalKeysPressed
            .contains(LogicalKeyboardKey.shiftLeft);

        final Duration seekDuration = Duration(
          seconds: shift ? 3 : 5,
        );

        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          if (!canPlay()) return KeyEventResult.handled;
          plPlayerController.onForward(seekDuration);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          if (!canPlay()) return KeyEventResult.handled;
          plPlayerController.onBackward(seekDuration);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          plPlayerController.setVolume(
            (plPlayerController.volume.value + 0.05).clamp(0, 1),
          );
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          plPlayerController.setVolume(
            (plPlayerController.volume.value - 0.05).clamp(0, 1),
          );
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.space) {
          if (!canPlay()) return KeyEventResult.handled;
          plPlayerController.onDoubleTapCenter();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyJ) {
          if (!canPlay()) return KeyEventResult.handled;
          plPlayerController.onBackward(const Duration(seconds: 10));
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
          if (!canPlay()) return KeyEventResult.handled;
          plPlayerController.onForward(const Duration(seconds: 10));
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyK) {
          if (!canPlay()) return KeyEventResult.handled;
          plPlayerController.onDoubleTapCenter();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
          onSendDanmaku();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
          onSkipSegment();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyN) {
          introController.nextPlay();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyP) {
          if (shift) {
            introController.prevPlay();
          }
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
          onShowMenu?.call();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.period) {
          if (shift) {
            final double speed = plPlayerController.playbackSpeed;
            if (speed < 8) {
              plPlayerController.setPlaybackSpeed(
                (speed + 0.25).clamp(0.25, 8),
              );
            }
          }
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.comma) {
          if (shift) {
            final double speed = plPlayerController.playbackSpeed;
            if (speed > 0.25) {
              plPlayerController.setPlaybackSpeed(
                (speed - 0.25).clamp(0.25, 8),
              );
            }
          }
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.slash) {
          if (shift) {
            plPlayerController.setDefaultSpeed();
          }
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyF ||
            event.logicalKey == LogicalKeyboardKey.f11) {
          plPlayerController.triggerFullScreen(
            status: !plPlayerController.isFullScreen.value,
          );
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          if (plPlayerController.isFullScreen.value) {
            plPlayerController.triggerFullScreen(status: false);
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}
