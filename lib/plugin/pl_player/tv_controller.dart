import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// TV端焦点区域枚举
enum FocusArea {
  none,    // 无焦点（遮罩隐藏状态）
  top,     // 顶部控制区域
  progress, // 进度条区域
  bottom,  // 底部功能区域
}

/// TV端播放器控制器
/// 继承自PlPlayerController，添加TV端特有的焦点管理和按键控制
class TvPlayerController extends PlPlayerController {
  // 焦点节点定义
  final FocusNode focusNodeA = FocusNode(debugLabel: 'TV_Top');     // 顶部区域
  final FocusNode focusNodeB = FocusNode(debugLabel: 'TV_Progress'); // 进度条区域
  final FocusNode focusNodeC = FocusNode(debugLabel: 'TV_Bottom');   // 底部区域

  // 当前激活的焦点区域
  final Rx<FocusArea> currentFocusArea = FocusArea.none.obs;

  // 添加一个私有静态变量来保存TV实例
  static TvPlayerController? _tvInstance;

  // 私有构造函数
  TvPlayerController._() : super._() {
    _initFocusNodes();
  }

  // 获取TV实例
  static TvPlayerController getInstance({bool isLive = false}) {
    _tvInstance ??= TvPlayerController._();
    _tvInstance!
      ..isLive = isLive
      .._playerCount += 1;
    return _tvInstance!;
  }

  // 初始化焦点节点监听
  void _initFocusNodes() {
    focusNodeA.addListener(() {
      if (focusNodeA.hasFocus) {
        currentFocusArea.value = FocusArea.top;
      }
    });
    focusNodeB.addListener(() {
      if (focusNodeB.hasFocus) {
        currentFocusArea.value = FocusArea.progress;
      }
    });
    focusNodeC.addListener(() {
      if (focusNodeC.hasFocus) {
        currentFocusArea.value = FocusArea.bottom;
      }
    });
  }

  /// Layer 1: 盲操逻辑 - 遮罩隐藏时的按键处理
  KeyEventResult handleKeyEventWhenHidden(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.select: // OK/Enter键
      case LogicalKeyboardKey.enter:
        showControlsAndFocus(FocusArea.progress);
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowUp: // 上方向键
      case LogicalKeyboardKey.gameButtonA: // 手柄A键
        showControlsAndFocus(FocusArea.top);
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowDown: // 下方向键
        showControlsAndFocus(FocusArea.bottom);
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowLeft: // 左方向键 - 快退
        seekBackward();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowRight: // 右方向键 - 快进
        seekForward();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.space: // 空格键 - 播放/暂停
      case LogicalKeyboardKey.mediaPlayPause:
        togglePlayPause();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.escape: // ESC键 - 退出全屏或返回
      case LogicalKeyboardKey.goBack:
        return handleBackKey();

      default:
        return KeyEventResult.ignored;
    }
  }

  /// 显示控制条并聚焦到指定区域
  void showControlsAndFocus(FocusArea area) {
    showControls.value = true;
    currentFocusArea.value = area;

    // 延迟一帧后请求焦点，确保Widget已构建
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (area) {
        case FocusArea.top:
          if (!focusNodeA.hasFocus) {
            focusNodeA.requestFocus();
          }
          break;
        case FocusArea.progress:
          if (!focusNodeB.hasFocus) {
            focusNodeB.requestFocus();
          }
          break;
        case FocusArea.bottom:
          if (!focusNodeC.hasFocus) {
            focusNodeC.requestFocus();
          }
          break;
        case FocusArea.none:
          // 移除所有焦点
          focusNodeA.unfocus();
          focusNodeB.unfocus();
          focusNodeC.unfocus();
          break;
      }
    });

    // 启动自动隐藏计时器
    startAutoHideTimer();
  }

  /// 启动自动隐藏计时器
  void startAutoHideTimer() {
    // TODO: 实现自动隐藏逻辑
    // 复用父类的自动隐藏机制或重新实现
  }

  /// 返回键处理
  KeyEventResult handleBackKey() {
    if (showControls.value) {
      // 隐藏遮罩
      showControls.value = false;
      currentFocusArea.value = FocusArea.none;
      return KeyEventResult.handled;
    } else {
      // 退出播放器（交给上层处理）
      return KeyEventResult.ignored;
    }
  }

  /// 切换播放/暂停
  void togglePlayPause() {
    if (playerStatus.playing) {
      pause();
    } else {
      play();
    }
  }

  /// 快进
  void seekForward() {
    final newPosition = position.value + fastForBackwardDuration;
    if (newPosition < duration.value) {
      seekTo(newPosition);
    } else {
      seekTo(duration.value);
    }
  }

  /// 快退
  void seekBackward() {
    final newPosition = position.value - fastForBackwardDuration;
    if (newPosition > Duration.zero) {
      seekTo(newPosition);
    } else {
      seekTo(Duration.zero);
    }
  }

  @override
  void dispose() {
    focusNodeA.dispose();
    focusNodeB.dispose();
    focusNodeC.dispose();
    super.dispose();
  }
}
