import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

class FocusableWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSelect;
  final bool autofocus;

  const FocusableWidget({
    super.key,
    required this.child,
    this.onSelect,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      autofocus: autofocus,
      onSelect: onSelect,
      builder: (context, isFocused, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: Border.all(
              color: isFocused ? Colors.blue : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}
