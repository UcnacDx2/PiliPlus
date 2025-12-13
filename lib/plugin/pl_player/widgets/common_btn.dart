<<<<<<< HEAD
=======
import 'package:PiliPlus/plugin/pl_player/widgets/focusable_btn.dart';
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)
import 'package:flutter/material.dart';

class ComBtn extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final double width;
  final double height;
  final String? tooltip;
<<<<<<< HEAD
=======
  final FocusNode? focusNode;
  final bool autofocus;
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)

  const ComBtn({
    super.key,
    required this.icon,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.width = 34,
    this.height = 34,
    this.tooltip,
<<<<<<< HEAD
=======
    this.focusNode,
    this.autofocus = false,
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)
  });

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final child = SizedBox(
      width: width,
      height: height,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTap: onSecondaryTap,
        behavior: HitTestBehavior.opaque,
        child: icon,
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip, child: child);
    }
    return child;
=======
    return FocusableBtn(
      width: width,
      height: height,
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onTap,
      onLongPress: onLongPress,
      onSecondaryTap: onSecondaryTap,
      tooltip: tooltip,
      child: icon,
    );
>>>>>>> 1272fabaf (fix: 优化弹幕操作显示逻辑以支持画中画模式)
  }
}
