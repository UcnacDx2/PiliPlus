import 'dart:async';
<<<<<<< HEAD
import 'dart:math' as math;
=======
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)

import 'package:PiliPlus/pages/common/common_intro_controller.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
<<<<<<< HEAD
=======
import 'package:PiliPlus/plugin/pl_player/utils/focus_manager.dart';
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)
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
<<<<<<< HEAD
    return logicalKey == LogicalKeyboardKey.tab ||
        logicalKey == LogicalKeyboardKey.arrowLeft ||
        logicalKey == LogicalKeyboardKey.arrowRight ||
        logicalKey == LogicalKeyboardKey.arrowUp ||
        logicalKey == LogicalKeyboardKey.arrowDown;
=======
    return logicalKey == LogicalKeyboardKey.tab;
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
<<<<<<< HEAD
        final handled = _handleKey(event);
        if (handled || _shouldHandle(event.logicalKey)) {
=======
        final result = _handleKey(event);
        if (result != KeyEventResult.ignored) {
          return result;
        }
        if (_shouldHandle(event.logicalKey)) {
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }

  bool get isFullScreen => plPlayerController.isFullScreen.value;
  bool get hasPlayer => plPlayerController.videoPlayerController != null;

<<<<<<< HEAD
  bool _handleKey(KeyEvent event) {
    final key = event.logicalKey;

    final isKeyQ = key == LogicalKeyboardKey.keyQ;
    if (isKeyQ || key == LogicalKeyboardKey.keyR) {
      if (HardwareKeyboard.instance.isMetaPressed) {
        return true;
=======
  bool _isInBottomControls() {
    final focusedContext = FocusManager.instance.primaryFocus?.context;
    return BottomControlsFocusMarker.isInScope(focusedContext);
  }

  KeyEventResult _handleKey(KeyEvent event) {
    final key = event.logicalKey;

    if (_isInBottomControls()) {
      // Let focus system route directional keys and activation to focused widgets.
      if (key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.arrowRight ||
          key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.contextMenu) {
        return KeyEventResult.ignored;
      }
    }

    final isKeyQ = key == LogicalKeyboardKey.keyQ;
    if (isKeyQ || key == LogicalKeyboardKey.keyR) {
      if (HardwareKeyboard.instance.isMetaPressed) {
        return KeyEventResult.handled;
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)
      }
      if (!plPlayerController.isLive) {
        if (event is KeyDownEvent) {
          introController!.onStartTriple();
        } else if (event is KeyUpEvent) {
          introController!.onCancelTriple(isKeyQ);
        }
      }
<<<<<<< HEAD
      return true;
=======
      return KeyEventResult.handled;
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)
    }

    final isArrowUp = key == LogicalKeyboardKey.arrowUp;
    if (isArrowUp || key == LogicalKeyboardKey.arrowDown) {
<<<<<<< HEAD
      if (event is! KeyDownEvent) return true;
=======
      if (event is! KeyDownEvent) return KeyEventResult.handled;
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)
      if (isArrowUp) {
        if (introController case final introController?) {
          if (!introController.prevPlay()) {
            SmartDialog.showToast('已经是第一集了');
          }
        }
      } else {
        if (introController case final introController?) {
          if (!introController.nextPlay()) {
            SmartDialog.showToast('已经是最后一集了');
          }
        }
      }
<<<<<<< HEAD
      return true;
=======
      return KeyEventResult.handled;
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)
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
<<<<<<< HEAD
      return true;
=======
      return KeyEventResult.handled;
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)
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
<<<<<<< HEAD
        return true;
=======
        return KeyEventResult.handled;
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)
      }

      switch (key) {
        case LogicalKeyboardKey.space:
          if (plPlayerController.isLive || canPlay!()) {
            if (hasPlayer) {
              plPlayerController.onDoubleTapCenter();
            }
          }
<<<<<<< HEAD
          return true;
=======
          return KeyEventResult.handled;
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)

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
<<<<<<< HEAD
          return true;
=======
          return KeyEventResult.handled;
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)

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
<<<<<<< HEAD
          return true;
=======
          return KeyEventResult.handled;
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)

        case LogicalKeyboardKey.keyP:
          if (Utils.isDesktop && hasPlayer && !isFullScreen) {
            plPlayerController
              ..toggleDesktopPip()
              ..controlsLock.value = false
              ..showControls.value = false;
          }
<<<<<<< HEAD
          return true;
=======
          return KeyEventResult.handled;
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)

        case LogicalKeyboardKey.keyM:
          if (hasPlayer) {
            final isMuted = !plPlayerController.isMuted;
            plPlayerController.videoPlayerController!.setVolume(
              isMuted ? 0 : plPlayerController.volume.value * 100,
            );
            plPlayerController.isMuted = isMuted;
            SmartDialog.showToast('${isMuted ? '' : '取消'}静音');
          }
<<<<<<< HEAD
          return true;
=======
          return KeyEventResult.handled;
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)

        case LogicalKeyboardKey.keyS:
          if (hasPlayer && isFullScreen) {
            plPlayerController.takeScreenshot();
          }
<<<<<<< HEAD
          return true;
=======
          return KeyEventResult.handled;
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)

        case LogicalKeyboardKey.keyL:
          if (isFullScreen || plPlayerController.isDesktopPip) {
            plPlayerController.onLockControl(
              !plPlayerController.controlsLock.value,
            );
          }
<<<<<<< HEAD
          return true;
=======
          return KeyEventResult.handled;
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)

        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.select:
          if (onSkipSegment?.call() ?? false) {
<<<<<<< HEAD
            return true;
=======
            return KeyEventResult.handled;
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)
          }
          if (plPlayerController.isLive || canPlay!()) {
            if (hasPlayer) {
              plPlayerController.onDoubleTapCenter();
            }
          }
<<<<<<< HEAD
          return true;
=======
          return KeyEventResult.handled;
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)
        case LogicalKeyboardKey.contextMenu:
          if (plPlayerController.isLive || (canPlay?.call() ?? false)) {
            if (hasPlayer) {
              onShowMenu?.call();
            }
          }
<<<<<<< HEAD
          return true;
=======
          return KeyEventResult.handled;
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)
      }

      if (!plPlayerController.isLive) {
        switch (key) {
          case LogicalKeyboardKey.arrowLeft:
            if (hasPlayer) {
              plPlayerController.onBackward(
                plPlayerController.fastForBackwardDuration,
              );
            }
<<<<<<< HEAD
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
=======
            return KeyEventResult.handled;

          case LogicalKeyboardKey.keyW:
            if (HardwareKeyboard.instance.isMetaPressed) {
              return KeyEventResult.handled;
            }
            introController?.actionCoinVideo();
            return KeyEventResult.handled;

          case LogicalKeyboardKey.keyE:
            introController?.actionFavVideo(isQuick: true);
            return KeyEventResult.handled;

          case LogicalKeyboardKey.keyT || LogicalKeyboardKey.keyV:
            introController?.viewLater();
            return KeyEventResult.handled;
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)

          case LogicalKeyboardKey.keyG:
            if (introController case UgcIntroController ugcCtr) {
              ugcCtr.actionRelationMod(Get.context!);
            }
<<<<<<< HEAD
            return true;
=======
            return KeyEventResult.handled;
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)

          case LogicalKeyboardKey.bracketLeft:
            if (introController case final introController?) {
              if (!introController.prevPlay()) {
                SmartDialog.showToast('已经是第一集了');
              }
            }
<<<<<<< HEAD
            return true;
=======
            return KeyEventResult.handled;
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)

          case LogicalKeyboardKey.bracketRight:
            if (introController case final introController?) {
              if (!introController.nextPlay()) {
                SmartDialog.showToast('已经是最后一集了');
              }
            }
<<<<<<< HEAD
            return true;
=======
            return KeyEventResult.handled;
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)
        }
      }
    }

<<<<<<< HEAD
    return false;
=======
    return KeyEventResult.ignored;
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)
  }
}
