import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

class DpadVideoCardWrapper extends StatelessWidget {
  const DpadVideoCardWrapper({
    super.key,
    required this.child,
    this.onEnter,
    this.onLongPress,
  });

  final Widget child;
  final VoidCallback? onEnter;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      onEnter: onEnter,
      onLongPress: onLongPress,
      builder: (context, hasFocus, child) {
        if (hasFocus) {
          return FocusEffects.combine(
            [
              FocusEffects.scale(scale: 1.05),
              FocusEffects.border(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
            ],
            child: child!,
          );
        }
        return child!;
      },
      child: child,
    );
  }
}
