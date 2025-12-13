import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

class DpadVideoCardWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback onClick;

  const DpadVideoCardWrapper({
    super.key,
    required this.child,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      builder: (context, hasFocus, isSelected, child) {
        final borderColor = hasFocus
            ? Theme.of(context).colorScheme.primary
            : Colors.transparent;
        final scale = hasFocus ? 1.05 : 1.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor,
                width: 3,
              ),
            ),
            child: child!,
          ),
        );
      },
      onEnter: onClick,
      child: child,
    );
  }
}
