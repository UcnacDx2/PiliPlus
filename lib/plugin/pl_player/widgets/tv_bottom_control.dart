import 'package:PiliPlus/plugin/pl_player/tv_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show KeyDownEvent, KeyEvent, KeyEventResult, LogicalKeyboardKey;
import 'package:get/get.dart';

/// TV端底部功能区 (区域C)
/// 包含：画质、倍速、字幕等功能按钮
class TvBottomControl extends StatelessWidget {
  const TvBottomControl({
    super.key,
    required this.controller,
    this.onQualityTap,
    this.onSpeedTap,
    this.onSubtitleTap,
    this.onSettingsTap,
  });

  final TvPlayerController controller;
  final VoidCallback? onQualityTap;
  final VoidCallback? onSpeedTap;
  final VoidCallback? onSubtitleTap;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 画质
          if (onQualityTap != null)
            _TvBottomButton(
              focusNode: controller.focusNodeC,
              icon: Icons.high_quality,
              label: '画质',
              onPressed: onQualityTap!,
            ),
          if (onQualityTap != null) const SizedBox(width: 16),

          // 倍速
          if (onSpeedTap != null) ...[
            Obx(() {
              final speed = controller.playbackSpeed;
              return _TvBottomButton(
                icon: Icons.speed,
                label: '${speed}x',
                onPressed: onSpeedTap!,
              );
            }),
            const SizedBox(width: 16),
          ],

          // 字幕
          if (onSubtitleTap != null) ...[
            _TvBottomButton(
              icon: Icons.subtitles,
              label: '字幕',
              onPressed: onSubtitleTap!,
            ),
            const SizedBox(width: 16),
          ],

          // 弹幕开关
          Obx(() {
            final enabled = controller.enableShowDanmaku.value;
            return _TvBottomButton(
              icon: enabled ? Icons.comment : Icons.comments_disabled,
              label: enabled ? '弹幕' : '弹幕已关',
              onPressed: () {
                controller.enableShowDanmaku.value = !enabled;
              },
            );
          }),
          const SizedBox(width: 16),

          // 设置
          if (onSettingsTap != null)
            _TvBottomButton(
              icon: Icons.settings,
              label: '设置',
              onPressed: onSettingsTap!,
            ),
        ],
      ),
    );
  }
}

/// TV底部功能按钮
class _TvBottomButton extends StatefulWidget {
  const _TvBottomButton({
    super.key,
    this.focusNode,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final FocusNode? focusNode;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_TvBottomButton> createState() => _TvBottomButtonState();
}

class _TvBottomButtonState extends State<_TvBottomButton> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isFocused
              ? Colors.white.withOpacity(0.3)
              : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: _isFocused
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
