import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

class TVFocusEffects {
  static FocusEffectBuilder primary(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    FocusEffectBuilder borderEffect = (context, hasFocus, child) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          border: hasFocus
              ? Border.all(color: color, width: 3)
              : Border.all(color: Colors.transparent, width: 3),
          borderRadius:
              BorderRadius.circular(8.0), // A reasonable default radius
        ),
        child: child,
      );
    };

    return FocusEffects.combine([
      FocusEffects.scale(scale: 1.05),
      borderEffect,
      FocusEffects.glow(glowColor: color.withOpacity(0.3)),
    ]);
  }
}
