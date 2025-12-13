import 'dart:async';
import 'dart:math' as math;

import 'package:PiliPlus/pages/common/common_intro_controller.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show KeyDownEvent, KeyUpEvent, LogicalKeyboardKey, HardwareKeyboard;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class PlayerFocus extends StatelessWidget {
  const PlayerFocus({
    super.key,
    required this.child,
    required this.plPlayerController,
    this.introController,
    required this.onSendDanmaku,
    this.canPlay,
    this.onSkipSegment,
    this.onShowMenu,
  });

  final Widget child;
  final PlPlayerController plPlayerController;
  final CommonIntroController? introController;
  final VoidCallback onSendDanmaku;
  final VoidCallback? onShowMenu;
  final bool Function()? canPlay;
  final bool Function()? onSkipSegment;

  static bool _shouldHandle(LogicalKeyboardKey logicalKey) {
    return logicalKey == LogicalKeyboardKey.tab ||
        logicalKey == LogicalKeyboardKey.arrowLeft ||
        logicalKey == LogicalKeyboardKey.arrowRight ||
        logicalKey == LogicalKeyboardKey.arrowUp ||
        logicalKey == LogicalKeyboardKey.arrowDown;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        final handled = _handleKey(event);
        if (handled || _shouldHandle(event.logicalKey)) {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }

  bool get isFullScreen => plPlayerController.isFullScreen.value;
  bool get hasPlayer => plPlayerController.videoPlayerController != null;

  bool _handleKey(KeyEvent event) {
    final key = event.logicalKey;

    if (event is KeyDownEvent) {
      // Controls are hidden
      if (!plPlayerController.showControls.value) {
        if (key == LogicalKeyboardKey.arrowUp) {
          plPlayerController.controls = true;
          plPlayerController.mainControlsFocusNode.requestFocus();
          plPlayerController.currentFocus = FocusState.main;
          return true;
        }
        if (key == LogicalKeyboardKey.arrowDown) {
          plPlayerController.controls = true;
          plPlayerController.secondaryControlsFocusNode.requestFocus();
          plPlayerController.currentFocus = FocusState.secondary;
          return true;
        }
        if (key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.select) {
          plPlayerController.controls = true;
          plPlayerController.progressFocusNode.requestFocus();
          plPlayerController.currentFocus = FocusState.progress;
          return true;
        }
      } else {
        // Controls are visible
        if (key == LogicalKeyboardKey.arrowUp) {
          if (plPlayerController.currentFocus == FocusState.progress) {
            plPlayerController.mainControlsFocusNode.requestFocus();
            plPlayerController.currentFocus = FocusState.main;
          } else if (plPlayerController.currentFocus ==
              FocusState.secondary) {
            plPlayerController.progressFocusNode.requestFocus();
            plPlayerController.currentFocus = FocusState.progress;
          }
          return true;
        }
        if (key == LogicalKeyboardKey.arrowDown) {
          if (plPlayerController.currentFocus == FocusState.main) {
            plPlayerController.progressFocusNode.requestFocus();
            plPlayerController.currentFocus = FocusState.progress;
          } else if (plPlayerController.currentFocus ==
              FocusState.progress) {
            plPlayerController.secondaryControlsFocusNode.requestFocus();
            plPlayerController.currentFocus = FocusState.secondary;
          }
          return true;
        }
        if (key == LogicalKeyboardKey.arrowLeft) {
          if (plPlayerController.progressFocusNode.hasFocus) {
            if (hasPlayer) {
              plPlayerController
                  .onBackward(plPlayerController.fastForBackwardDuration);
            }
            return true;
          }
        }
        if (key == LogicalKeyboardKey.arrowRight) {
          if (plPlayerController.progressFocusNode.hasFocus) {
            if (hasPlayer) {
              plPlayerController
                  .onForward(plPlayerController.fastForBackwardDuration);
            }
            return true;
          }
        }
        if (key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.select) {
          if (plPlayerController.progressFocusNode.hasFocus) {
            plPlayerController.onDoubleTapCenter();
            return true;
          }
        }
      }
    }

    final isKeyQ = key == LogicalKeyboardKey.keyQ;
    if (isKeyQ || key == LogicalKeyboardKey.keyR) {
      if (HardwareKeyboard.instance.isMetaPressed) {
        return true;
      }
      if (!plPlayerController.isLive) {
        if (event is KeyDownEvent) {
          introController!.onStartTriple();
        } else if (event is KeyUpEvent) {
          introController!.onCancelTriple(isKeyQ);
        }
      }
      return true;
    }

    if (key == LogicalKeyboardKey.arrowRight) {
      if (!plPlayerController.isLive) {
        if (event is KeyDownEvent) {
          if (hasPlayer && !plPlayerController.longPressStatus.value) {
            plPlayerController
              ..cancelLongPressTimer()
              ..longPressTimer ??= Timer(
                const Duration(milliseconds: 200),
                () => plPlayerController
                  ..cancelLongPressTimer()
                  ..setLongPressStatus(true),
              );
          }
        } else if (event is KeyUpEvent) {
          plPlayerController.cancelLongPressTimer();
          if (hasPlayer) {
            if (plPlayerController.longPressStatus.value) {
              plPlayerController.setLongPressStatus(false);
            } else {
              plPlayerController.onForward(
                plPlayerController.fastForBackwardDuration,
              );
            }
          }
        }
      }
      return true;
    }

    if (event is KeyDownEvent) {
      final isDigit1 = key == LogicalKeyboardKey.digit1;
      if (isDigit1 || key == LogicalKeyboardKey.digit2) {
        if (HardwareKeyboard.instance.isShiftPressed && hasPlayer) {
          final speed = isDigit1 ? 1.0 : 2.0;
          if (speed != plPlayerController.playbackSpeed) {
            plPlayerController.setPlaybackSpeed(speed);
          }
          SmartDialog.showToast('${speed}x播放');
        }
        return true;
      }

      switch (key) {
        case LogicalKeyboardKey.space:
          if (plPlayerController.isLive || canPlay!()) {
            if (hasPlayer) {
              plPlayerController.onDoubleTapCenter();
            }
          }
          return true;

        case LogicalKeyboardKey.keyF:
          final isFullScreen = this.isFullScreen;
          if (isFullScreen && plPlayerController.controlsLock.value) {
            plPlayerController
              ..controlsLock.value = false
              ..showControls.value = false;
          }
          plPlayerController.triggerFullScreen(
            status: !isFullScreen,
            inAppFullScreen: HardwareKeyboard.instance.isShiftPressed,
          );
          return true;

        case LogicalKeyboardKey.keyD:
          final newVal = !plPlayerController.enableShowDanmaku.value;
          plPlayerController.enableShowDanmaku.value = newVal;
          if (!plPlayerController.tempPlayerConf) {
            GStorage.setting.put(
              plPlayerController.isLive
                  ? SettingBoxKey.enableShowLiveDanmaku
                  : SettingBoxKey.enableShowDanmaku,
              newVal,
            );
          }
          return true;

        case LogicalKeyboardKey.keyP:
          if (Utils.isDesktop && hasPlayer && !isFullScreen) {
            plPlayerController
              ..toggleDesktopPip()
              ..controlsLock.value = false
              ..showControls.value = false;
          }
          return true;

        case LogicalKeyboardKey.keyM:
          if (hasPlayer) {
            final isMuted = !plPlayerController.isMuted;
            plPlayerController.videoPlayerController!.setVolume(
              isMuted ? 0 : plPlayerController.volume.value * 100,
            );
            plPlayerController.isMuted = isMuted;
            SmartDialog.showToast('${isMuted ? '' : '取消'}静音');
          }
          return true;

        case LogicalKeyboardKey.keyS:
          if (hasPlayer && isFullScreen) {
            plPlayerController.takeScreenshot();
          }
          return true;

        case LogicalKeyboardKey.keyL:
          if (isFullScreen || plPlayerController.isDesktopPip) {
            plPlayerController.onLockControl(
              !plPlayerController.controlsLock.value,
            );
          }
          return true;

        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.select:
          if (onSkipSegment?.call() ?? false) {
            return true;
          }
          if (plPlayerController.isLive || canPlay!()) {
            if (hasPlayer) {
              plPlayerController.onDoubleTapCenter();
            }
          }
          return true;
        case LogicalKeyboardKey.contextMenu:
          if (plPlayerController.isLive || (canPlay?.call() ?? false)) {
            if (hasPlayer) {
              onShowMenu?.call();
            }
          }
          return true;
      }

      if (!plPlayerController.isLive) {
        switch (key) {
          case LogicalKeyboardKey.arrowLeft:
            if (hasPlayer) {
              plPlayerController.onBackward(
                plPlayerController.fastForBackwardDuration,
              );
            }
            return true;

          case LogicalKeyboardKey.keyW:
            if (HardwareKeyboard.instance.isMetaPressed) {
              return true;
            }
            introController?.actionCoinVideo();
            return true;

          case LogicalKeyboardKey.keyE:
            introController?.actionFavVideo(isQuick: true);
            return true;

          case LogicalKeyboardKey.keyT || LogicalKeyboardKey.keyV:
            introController?.viewLater();
            return true;

          case LogicalKeyboardKey.keyG:
            if (introController case UgcIntroController ugcCtr) {
              ugcCtr.actionRelationMod(Get.context!);
            }
            return true;

          case LogicalKeyboardKey.bracketLeft:
            if (introController case final introController?) {
              if (!introController.prevPlay()) {
                SmartDialog.showToast('已经是第一集了');
              }
            }
            return true;

          case LogicalKeyboardKey.bracketRight:
            if (introController case final introController?) {
              if (!introController.nextPlay()) {
                SmartDialog.showToast('已经是最后一集了');
              }
            }
            return true;
        }
      }
    }

    return false;
  }
}
