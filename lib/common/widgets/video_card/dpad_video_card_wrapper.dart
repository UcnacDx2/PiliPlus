import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

class DpadVideoCardWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onClick;

  const DpadVideoCardWrapper({
    super.key,
    required this.child,
    this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      focusEffects: [
        FocusEffects.scale(scale: 1.05),
        FocusEffects.border(
          color: Theme.of(context).colorScheme.primary,
          width: 3,
        ),
      ],
      builder: (context, hasFocus) => InkWell(
        onTap: onClick,
        child: child,
      ),
    );
  }
}
