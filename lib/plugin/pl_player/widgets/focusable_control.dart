import 'package:flutter/material.dart';

class FocusableControl extends StatefulWidget {
  final Widget child;

  const FocusableControl({super.key, required this.child});

  @override
  _FocusableControlState createState() => _FocusableControlState();
}

class _FocusableControlState extends State<FocusableControl> {
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
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
