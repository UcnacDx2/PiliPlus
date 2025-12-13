import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

class DpadButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onClick;
  final bool autofocus;

  const DpadButton({
    super.key,
    required this.child,
    this.onClick,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      autofocus: autofocus,
      effects: [
        FocusEffects.scale(1.1),
        FocusEffects.border(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ],
      onClick: onClick,
      child: child,
    );
  }
}
