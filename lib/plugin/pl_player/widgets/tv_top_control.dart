import 'package:PiliPlus/plugin/pl_player/tv_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show KeyDownEvent, KeyEvent, KeyEventResult, LogicalKeyboardKey;
import 'package:get/get.dart';

/// TV端顶部控制栏 (区域A)
/// 包含：返回按钮、标题、播放/暂停、下一集等
class TvTopControl extends StatelessWidget {
  const TvTopControl({
    super.key,
    required this.controller,
    required this.title,
    this.onBack,
    this.onNext,
  });

  final TvPlayerController controller;
  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // 返回按钮
          _TvButton(
            focusNode: controller.focusNodeA,
            icon: Icons.arrow_back,
            label: '返回',
            onPressed: onBack ?? () => Get.back(),
          ),
          const SizedBox(width: 16),
          
          // 标题
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // 播放/暂停按钮
          Obx(() {
            final isPlaying = controller.playerStatus.playing;
            return _TvButton(
              icon: isPlaying ? Icons.pause : Icons.play_arrow,
              label: isPlaying ? '暂停' : '播放',
              onPressed: controller.togglePlayPause,
            );
          }),
          
          // 下一集按钮（可选）
          if (onNext != null) ...[
            const SizedBox(width: 8),
            _TvButton(
              icon: Icons.skip_next,
              label: '下一集',
              onPressed: onNext,
            ),
          ],
        ],
      ),
    );
  }
}

/// TV端可聚焦按钮
class _TvButton extends StatefulWidget {
  const _TvButton({
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
  State<_TvButton> createState() => _TvButtonState();
}

class _TvButtonState extends State<_TvButton> {
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
            event.logicalKey == LogicalKeyboardKey.select) {
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
