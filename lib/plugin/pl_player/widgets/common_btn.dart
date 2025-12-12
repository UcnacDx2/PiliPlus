import 'package:PiliPlus/plugin/pl_player/widgets/focusable_btn.dart';
import 'package:flutter/material.dart';

class ComBtn extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final double width;
  final double height;
  final String? tooltip;
  final FocusNode? focusNode;
  final bool autofocus;

  const ComBtn({
    super.key,
    required this.icon,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.width = 34,
    this.height = 34,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
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
  }
}
