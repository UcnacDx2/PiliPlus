import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

class DpadVideoCardWrapper extends StatelessWidget {
  const DpadVideoCardWrapper({
    super.key,
    required this.child,
    required this.onEnter,
  });

  final Widget child;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      builder: (context, hasFocus, child) {
        final a = FocusEffects.scale(
          context: context,
          hasFocus: hasFocus,
          child: child!,
          scale: 1.05,
        );
        return FocusEffects.border(
          context: context,
          hasFocus: hasFocus,
          child: a,
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        );
      },
      onEnter: onEnter,
      child: child,
    );
  }
}
