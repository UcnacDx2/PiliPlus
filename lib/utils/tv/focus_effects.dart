import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

class TVFocusEffects {
  static FocusEffectBuilder primary(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return FocusEffects.combine([
      FocusEffects.scale(scale: 1.05),
      FocusEffects.border(color: color, width: 3),
      FocusEffects.glow(glowColor: color.withOpacity(0.3)),
    ]);
  }
}
