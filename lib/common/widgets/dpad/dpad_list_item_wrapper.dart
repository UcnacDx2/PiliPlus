import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

class DpadListItemWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onClick;

  const DpadListItemWrapper({
    super.key,
    required this.child,
    this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      focusEffects: [
        FocusEffects.scale(scale: 1.02),
        FocusEffects.backgroundColor(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
      ],
      builder: (context, hasFocus) => InkWell(
        onTap: onClick,
        child: child,
      ),
    );
  }
}
