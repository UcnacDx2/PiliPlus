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

class PlayerFocus extends StatefulWidget {
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

  @override
  State<PlayerFocus> createState() => _PlayerFocusState();
}

class _PlayerFocusState extends State<PlayerFocus> {
  Timer? _longPressTimer;
  Timer? _scrubbingTimer;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _scrubbingTimer?.cancel();
    _scrubbingTimer = null;
    super.dispose();
  }

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
      child: widget.child,
    );
  }

  bool get isFullScreen => widget.plPlayerController.isFullScreen.value;
  bool get hasPlayer => widget.plPlayerController.videoPlayerController != null;

  bool _handleKey(KeyEvent event) {
    final key = event.logicalKey;

    final isKeyQ = key == LogicalKeyboardKey.keyQ;
    if (isKeyQ || key == LogicalKeyboardKey.keyR) {
      if (HardwareKeyboard.instance.isMetaPressed) {
        return true;
      }
      if (!widget.plPlayerController.isLive) {
        if (event is KeyDownEvent) {
          widget.introController!.onStartTriple();
        } else if (event is KeyUpEvent) {
          widget.introController!.onCancelTriple(isKeyQ);
        }
      }
      return true;
    }

    final isArrowUp = key == LogicalKeyboardKey.arrowUp;
    if (isArrowUp || key == LogicalKeyboardKey.arrowDown) {
      if (event is! KeyDownEvent) return true;
      if (isArrowUp) {
        if (widget.introController case final introController?) {
          if (!introController.prevPlay()) {
            SmartDialog.showToast('已经是第一集了');
          }
        }
      } else {
        if (widget.introController case final introController?) {
          if (!introController.nextPlay()) {
            SmartDialog.showToast('已经是最后一集了');
          }
        }
      }
      return true;
    }

    final isForward = key == LogicalKeyboardKey.arrowRight;
    final isBackward = key == LogicalKeyboardKey.arrowLeft;

    if (isForward || isBackward) {
      if (widget.plPlayerController.isLive) return true;

      if (event is KeyDownEvent) {
        if (hasPlayer && _longPressTimer == null) {
          _longPressTimer = Timer(const Duration(milliseconds: 300), () {
            widget.plPlayerController.startScrubbing();
            _scrubbingTimer?.cancel();
            _scrubbingTimer =
                Timer.periodic(const Duration(milliseconds: 200), (_) {
              widget.plPlayerController.updateScrubbing(isForward);
            });
          });
        }
      } else if (event is KeyUpEvent) {
        _longPressTimer?.cancel();
        _longPressTimer = null;
        _scrubbingTimer?.cancel();
        _scrubbingTimer = null;

        if (hasPlayer) {
          if (widget.plPlayerController.isScrubbing.value) {
            widget.plPlayerController.endScrubbing();
          } else {
            if (isForward) {
              widget.plPlayerController
                  .onForward(widget.plPlayerController.fastForBackwardDuration);
            } else {
              // isBackward
              widget.plPlayerController.onBackward(
                  widget.plPlayerController.fastForBackwardDuration);
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
          if (speed != widget.plPlayerController.playbackSpeed) {
            widget.plPlayerController.setPlaybackSpeed(speed);
          }
          SmartDialog.showToast('${speed}x播放');
        }
        return true;
      }

      switch (key) {
        case LogicalKeyboardKey.space:
          if (widget.plPlayerController.isLive || widget.canPlay!()) {
            if (hasPlayer) {
              widget.plPlayerController.onDoubleTapCenter();
            }
          }
          return true;

        case LogicalKeyboardKey.keyF:
          final isFullScreen = this.isFullScreen;
          if (isFullScreen && widget.plPlayerController.controlsLock.value) {
            widget.plPlayerController
              ..controlsLock.value = false
              ..showControls.value = false;
          }
          widget.plPlayerController.triggerFullScreen(
            status: !isFullScreen,
            inAppFullScreen: HardwareKeyboard.instance.isShiftPressed,
          );
          return true;

        case LogicalKeyboardKey.keyD:
          final newVal = !widget.plPlayerController.enableShowDanmaku.value;
          widget.plPlayerController.enableShowDanmaku.value = newVal;
          if (!widget.plPlayerController.tempPlayerConf) {
            GStorage.setting.put(
              widget.plPlayerController.isLive
                  ? SettingBoxKey.enableShowLiveDanmaku
                  : SettingBoxKey.enableShowDanmaku,
              newVal,
            );
          }
          return true;

        case LogicalKeyboardKey.keyP:
          if (Utils.isDesktop && hasPlayer && !isFullScreen) {
            widget.plPlayerController
              ..toggleDesktopPip()
              ..controlsLock.value = false
              ..showControls.value = false;
          }
          return true;

        case LogicalKeyboardKey.keyM:
          if (hasPlayer) {
            final isMuted = !widget.plPlayerController.isMuted;
            widget.plPlayerController.videoPlayerController!.setVolume(
              isMuted ? 0 : widget.plPlayerController.volume.value * 100,
            );
            widget.plPlayerController.isMuted = isMuted;
            SmartDialog.showToast('${isMuted ? '' : '取消'}静音');
          }
          return true;

        case LogicalKeyboardKey.keyS:
          if (hasPlayer && isFullScreen) {
            widget.plPlayerController.takeScreenshot();
          }
          return true;

        case LogicalKeyboardKey.keyL:
          if (isFullScreen || widget.plPlayerController.isDesktopPip) {
            widget.plPlayerController.onLockControl(
              !widget.plPlayerController.controlsLock.value,
            );
          }
          return true;

        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.select:
          if (widget.onSkipSegment?.call() ?? false) {
            return true;
          }
          if (widget.plPlayerController.isLive || widget.canPlay!()) {
            if (hasPlayer) {
              widget.plPlayerController.onDoubleTapCenter();
            }
          }
          return true;
        case LogicalKeyboardKey.contextMenu:
          if (widget.plPlayerController.isLive ||
              (widget.canPlay?.call() ?? false)) {
            if (hasPlayer) {
              widget.onShowMenu?.call();
            }
          }
          return true;
      }

      if (!widget.plPlayerController.isLive) {
        switch (key) {
          case LogicalKeyboardKey.keyW:
            if (HardwareKeyboard.instance.isMetaPressed) {
              return true;
            }
            widget.introController?.actionCoinVideo();
            return true;

          case LogicalKeyboardKey.keyE:
            widget.introController?.actionFavVideo(isQuick: true);
            return true;

          case LogicalKeyboardKey.keyT || LogicalKeyboardKey.keyV:
            widget.introController?.viewLater();
            return true;

          case LogicalKeyboardKey.keyG:
            if (widget.introController case UgcIntroController ugcCtr) {
              ugcCtr.actionRelationMod(Get.context!);
            }
            return true;

          case LogicalKeyboardKey.bracketLeft:
            if (widget.introController case final introController?) {
              if (!introController.prevPlay()) {
                SmartDialog.showToast('已经是第一集了');
              }
            }
            return true;

          case LogicalKeyboardKey.bracketRight:
            if (widget.introController case final introController?) {
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
