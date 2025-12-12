import 'package:PiliPlus/utils/tv/focus_effects.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

class TVButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool autofocus;

  const TVButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      autofocus: autofocus,
      effects: [TVFocusEffects.primary(context)],
      child: ElevatedButton(
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}
