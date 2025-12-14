import 'package:flutter/material.dart';

class ComBtn extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double width;
  final double height;
  final String? tooltip;
  final bool autofocus;

  const ComBtn({
    super.key,
    required this.icon,
    this.onTap,
    this.onLongPress,
    this.width = 34,
    this.height = 34,
    this.tooltip,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      width: width,
      height: height,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        autofocus: autofocus,
        child: Center(child: icon),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip, child: child);
    }
    return child;
  }
}
