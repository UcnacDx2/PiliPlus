import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

enum FocusArea {
  none,
  top,
  progress,
  bottom,
}

class TvPlayerController {
  final PlPlayerController _plPlayerController;

  TvPlayerController(this._plPlayerController);

  PlPlayerController get plPlayerController => _plPlayerController;

  // 焦点节点定义
  final FocusNode focusNodeA = FocusNode(); // 顶部区域
  final FocusNode focusNodeB = FocusNode(); // 进度条区域
  final FocusNode focusNodeC = FocusNode(); // 底部区域

  // 当前激活的焦点区域
  final Rx<FocusArea> currentFocusArea = FocusArea.none.obs;

  // 在遮罩隐藏时的按键处理
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
      default:
        return KeyEventResult.ignored;
    }
  }

  // 焦点切换逻辑
  void showControlsAndFocus(FocusArea area) {
    _plPlayerController.showControls.value = true;
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

    // 启动自动隐藏计时器
    _plPlayerController.hideTaskControls();
  }

  KeyEventResult handleBackKey() {
    if (_plPlayerController.showControls.value) {
      // 隐藏遮罩
      _plPlayerController.showControls.value = false;
      return KeyEventResult.handled;
    } else {
      // 退出播放器（交给上层处理）
      return KeyEventResult.ignored;
    }
  }

  void togglePlayPause() {
    _plPlayerController.videoPlayerController?.playOrPause();
  }
}
