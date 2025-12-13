import 'package:flutter/material.dart';

class FocusableControl extends StatefulWidget {
  final Widget child;
  final FocusNode? focusNode;

  const FocusableControl({super.key, required this.child, this.focusNode});

  @override
  _FocusableControlState createState() => _FocusableControlState();
}

class _FocusableControlState extends State<FocusableControl> {
  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode!;

  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
    _effectiveFocusNode.addListener(_handleFocusChange);
    _hasFocus = _effectiveFocusNode.hasFocus;
  }

  @override
  void didUpdateWidget(FocusableControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      // Remove listener from the old node
      (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(_handleFocusChange);

      if (widget.focusNode == null) {
        // If the new widget has no node, but the old one did, we need to create an internal one.
        // If the old one was also internal, we dispose it.
        if (oldWidget.focusNode != null){
           _internalFocusNode = FocusNode();
        }
      } else {
        // If the new widget has a node, we dispose of our internal one if it exists.
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }

      _effectiveFocusNode.addListener(_handleFocusChange);
      _hasFocus = _effectiveFocusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted && _effectiveFocusNode.hasFocus != _hasFocus) {
      setState(() {
        _hasFocus = _effectiveFocusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _effectiveFocusNode,
      child: Container(
        decoration: BoxDecoration(
          border: _hasFocus
              ? Border.all(color: Colors.white, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: widget.child,
      ),
    );
  }
}
