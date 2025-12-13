import 'package:flutter/material.dart';

class TVFocusEffects {
  static Widget scaleAndGlow(BuildContext context, Widget child, bool hasFocus) {
    final color = Theme.of(context).colorScheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: hasFocus ? (Matrix4.identity()..scale(1.05)) : Matrix4.identity(),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: hasFocus
            ? [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: child,
    );
  }
}
