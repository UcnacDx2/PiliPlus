import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

class DpadVideoCardWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onEnter;

  const DpadVideoCardWrapper({
    super.key,
    required this.child,
    this.onEnter,
  });

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      effects: [
        FocusEffects.scale(scale: 1.05),
        FocusEffects.border(
          color: Theme.of(context).colorScheme.primary,
          width: 3,
        ),
      ],
      onEnter: onEnter,
      builder: (context, hasFocus, _) => child,
    );
  }
}
