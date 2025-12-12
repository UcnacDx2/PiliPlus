import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A focusable button with simple hover/focus highlights and keyboard activation.
class FocusableBtn extends StatefulWidget {
  const FocusableBtn({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.onSecondaryTap,
    this.focusNode,
    this.autofocus = false,
    this.width = 34,
    this.height = 34,
    this.tooltip,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final FocusNode? focusNode;
  final bool autofocus;
  final double width;
  final double height;
  final String? tooltip;

  @override
  State<FocusableBtn> createState() => _FocusableBtnState();
}

class _FocusableBtnState extends State<FocusableBtn> {
  bool _focused = false;
  bool _hovered = false;

  void _handleFocusHighlight(bool value) {
    if (_focused != value) {
      setState(() => _focused = value);
    }
  }

  void _handleHoverHighlight(bool value) {
    if (_hovered != value) {
      setState(() => _hovered = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.of(context);
    final Color focusColor = colorScheme.primary.withAlpha(70);
    final Widget button = FocusableActionDetector(
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      onShowFocusHighlight: _handleFocusHighlight,
      onShowHoverHighlight: _handleHoverHighlight,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onLongPress: widget.onLongPress,
        onSecondaryTap: widget.onSecondaryTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.width,
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _focused
                ? focusColor.withAlpha(40)
                : (_hovered ? focusColor.withAlpha(20) : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
            border: _focused ? Border.all(color: focusColor, width: 1.2) : null,
          ),
          child: Center(child: widget.child),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip, child: button);
    }
    return button;
  }
}
