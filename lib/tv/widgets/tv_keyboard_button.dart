import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 虚拟键盘按钮
class TvKeyboardButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onMoveLeft;
  final VoidCallback? onBack; // 返回键回调

  const TvKeyboardButton({
    super.key,
    required this.label,
    required this.onTap,
    this.onMoveLeft,
    this.onBack,
  });

  @override
  State<TvKeyboardButton> createState() => _TvKeyboardButtonState();
}

class _TvKeyboardButtonState extends State<TvKeyboardButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
              widget.onMoveLeft != null) {
            widget.onMoveLeft!();
            return KeyEventResult.handled;
          }
          // 返回键
          if ((event.logicalKey == LogicalKeyboardKey.escape ||
                  event.logicalKey == LogicalKeyboardKey.goBack ||
                  event.logicalKey == LogicalKeyboardKey.browserBack) &&
              widget.onBack != null) {
            widget.onBack!();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isFocused ? Colors.white : Colors.white12,
          borderRadius: BorderRadius.circular(8),
          border: _isFocused ? Border.all(color: Colors.white, width: 2) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: TextStyle(
            color: _isFocused ? Colors.black : Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// 操作按钮 (搜索/清空等)
class TvActionButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onMoveLeft;
  final VoidCallback? onBack; // 返回键回调

  const TvActionButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.onMoveLeft,
    this.onBack,
  });

  @override
  State<TvActionButton> createState() => _TvActionButtonState();
}

class _TvActionButtonState extends State<TvActionButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
              widget.onMoveLeft != null) {
            widget.onMoveLeft!();
            return KeyEventResult.handled;
          }
          // 返回键
          if ((event.logicalKey == LogicalKeyboardKey.escape ||
                  event.logicalKey == LogicalKeyboardKey.goBack ||
                  event.logicalKey == LogicalKeyboardKey.browserBack) &&
              widget.onBack != null) {
            widget.onBack!();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isFocused ? Colors.white : widget.color,
          borderRadius: BorderRadius.circular(8),
          border: _isFocused ? Border.all(color: Colors.white, width: 2) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: TextStyle(
            color: _isFocused ? Colors.black : Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
