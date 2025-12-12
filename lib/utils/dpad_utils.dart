import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

/// Utility class for dpad navigation helpers
class DpadUtils {
  DpadUtils._();

  /// Creates a focusable widget with standard border effect for PiliPlus
  static DpadFocusableBuilder defaultBorderEffect({
    Color? color,
    double width = 2,
    BorderRadius? borderRadius,
  }) {
    return (context, isFocused, child) {
      final theme = Theme.of(context);
      final focusColor = color ?? theme.colorScheme.primary;
      
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border.all(
            color: isFocused ? focusColor : Colors.transparent,
            width: width,
          ),
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: child,
      );
    };
  }

  /// Creates a focusable widget with scale effect
  static DpadFocusableBuilder scaleEffect({
    double scale = 1.05,
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return (context, isFocused, child) {
      final theme = Theme.of(context);
      final focusColor = color ?? theme.colorScheme.primary;
      
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(isFocused ? scale : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
            color: isFocused ? focusColor : Colors.transparent,
            width: 2,
          ),
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: child,
      );
    };
  }

  /// Creates a focusable widget with glow effect
  static DpadFocusableBuilder glowEffect({
    Color? color,
    double blurRadius = 20,
    double spreadRadius = 2,
  }) {
    return (context, isFocused, child) {
      final theme = Theme.of(context);
      final focusColor = color ?? theme.colorScheme.primary;
      
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: focusColor.withOpacity(0.6),
                    blurRadius: blurRadius,
                    spreadRadius: spreadRadius,
                  ),
                ]
              : null,
        ),
        child: child,
      );
    };
  }

  /// Combines border and scale effects
  static DpadFocusableBuilder combinedEffect({
    Color? color,
    double scale = 1.02,
    BorderRadius? borderRadius,
  }) {
    return (context, isFocused, child) {
      final theme = Theme.of(context);
      final focusColor = color ?? theme.colorScheme.primary;
      
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(isFocused ? scale : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
            color: isFocused ? focusColor : Colors.transparent,
            width: 2,
          ),
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: focusColor.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: child,
      );
    };
  }
}
