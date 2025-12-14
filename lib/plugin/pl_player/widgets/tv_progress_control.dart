import 'package:PiliPlus/plugin/pl_player/tv_controller.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// TV端进度条控制 (区域B)
/// 整个进度条作为一个可聚焦组件
/// OK键：播放/暂停
/// 左右键：快退/快进
/// 上下键：移动焦点到其他区域
class TvProgressControl extends StatefulWidget {
  const TvProgressControl({
    super.key,
    required this.controller,
  });

  final TvPlayerController controller;

  @override
  State<TvProgressControl> createState() => _TvProgressControlState();
}

class _TvProgressControlState extends State<TvProgressControl> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.controller.focusNodeB.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.controller.focusNodeB.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = widget.controller.focusNodeB.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.controller.focusNodeB,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        switch (event.logicalKey) {
          case LogicalKeyboardKey.select: // OK键 - 播放/暂停
          case LogicalKeyboardKey.enter:
            widget.controller.togglePlayPause();
            return KeyEventResult.handled;

          case LogicalKeyboardKey.arrowLeft: // 左键 - 快退
            widget.controller.seekBackward();
            return KeyEventResult.handled;

          case LogicalKeyboardKey.arrowRight: // 右键 - 快进
            widget.controller.seekForward();
            return KeyEventResult.handled;

          // 上下键由框架自动处理焦点导航
          default:
            return KeyEventResult.ignored;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: _isFocused
              ? Colors.white.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: _isFocused
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 进度条
            Obx(() {
              final position = widget.controller.position.value;
              final duration = widget.controller.duration.value;
              final buffered = widget.controller.buffered.value;

              if (duration.inSeconds <= 0) {
                return const SizedBox.shrink();
              }

              final progress = position.inMilliseconds / duration.inMilliseconds;
              final bufferedProgress = buffered.inMilliseconds / duration.inMilliseconds;

              return Stack(
                children: [
                  // 背景条
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // 缓冲条
                  FractionallySizedBox(
                    widthFactor: bufferedProgress.clamp(0.0, 1.0),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // 进度条
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 12),
            // 时间显示
            Obx(() {
              final position = widget.controller.position.value;
              final duration = widget.controller.duration.value;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DurationUtils.toStr(position),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    DurationUtils.toStr(duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              );
            }),
            // 焦点提示
            if (_isFocused) ...[
              const SizedBox(height: 8),
              const Text(
                '左右键快进快退 | OK键播放暂停',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
