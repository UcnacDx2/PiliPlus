import 'package:flutter/material.dart';

class FocusableBtn extends StatefulWidget {
  final FocusNode focusNode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final Widget icon;
  final String? tooltip;
  final double? width;
  final double? height;

  const FocusableBtn({
    Key? key,
    required this.focusNode,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    required this.icon,
    this.tooltip,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  _FocusableBtnState createState() => _FocusableBtnState();
}

class _FocusableBtnState extends State<FocusableBtn> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      width: widget.width,
      height: widget.height,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onSecondaryTap: widget.onSecondaryTap,
        focusNode: widget.focusNode,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: widget.focusNode.hasFocus
                ? Border.all(color: Colors.white, width: 2)
                : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: widget.icon,
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: child);
    }
    return child;
  }
}
