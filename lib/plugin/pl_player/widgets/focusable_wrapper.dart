import 'package:flutter/material.dart';

class FocusableWrapper extends StatefulWidget {
  final FocusNode? focusNode;
  final Widget child;
  final bool autoFocus;

  const FocusableWrapper({
    Key? key,
    this.focusNode,
    required this.child,
    this.autoFocus = false,
  }) : super(key: key);

  @override
  State<FocusableWrapper> createState() => _FocusableWrapperState();
}

class _FocusableWrapperState extends State<FocusableWrapper> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autoFocus,
      onFocusChange: (hasFocus) {
        setState(() {
          _hasFocus = hasFocus;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          border: _hasFocus ? Border.all(color: Theme.of(context).primaryColor, width: 2) : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: widget.child,
      ),
    );
  }
}
