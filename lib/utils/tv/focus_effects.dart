import 'package:flutter/material.dart';

class TVFocusEffects {
  static Widget primary(BuildContext context, bool hasFocus, Widget? child) {
    final color = Theme.of(context).colorScheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        border: Border.all(
          color: hasFocus ? color : Colors.transparent,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}
