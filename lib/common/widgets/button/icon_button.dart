import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

Widget iconButton({
  BuildContext? context,
  String? tooltip,
  required Widget icon,
  required VoidCallback? onPressed,
  double size = 36,
  double? iconSize,
  Color? bgColor,
  Color? iconColor,
  bool enableDpad = true,
}) {
  Color? backgroundColor = bgColor;
  Color? foregroundColor = iconColor;
  if (context != null) {
    final colorScheme = ColorScheme.of(context);
    backgroundColor = colorScheme.secondaryContainer;
    foregroundColor = colorScheme.onSecondaryContainer;
  }
  final button = SizedBox(
    width: size,
    height: size,
    child: IconButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        iconSize: iconSize ?? size / 2,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      ),
    ),
  );

  if (enableDpad && onPressed != null) {
    return DpadFocusable(
      onSelect: onPressed,
      builder: (context, isFocused, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isFocused
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: child,
        );
      },
      child: button,
    );
  }
  return button;
}
