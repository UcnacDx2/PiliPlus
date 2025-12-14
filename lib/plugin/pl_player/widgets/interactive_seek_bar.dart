import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';

class InteractiveSeekBar extends StatefulWidget {
  final Widget child;
  final PlPlayerController controller;

  const InteractiveSeekBar({
    Key? key,
    required this.child,
    required this.controller,
  }) : super(key: key);

  @override
  _InteractiveSeekBarState createState() => _InteractiveSeekBarState();
}

class _InteractiveSeekBarState extends State<InteractiveSeekBar> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.controller.tvFocusManager.seekBarNode;
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            widget.controller.seekTo(
              widget.controller.position.value - const Duration(seconds: 5),
              isSeek: false,
            );
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            widget.controller.seekTo(
              widget.controller.position.value + const Duration(seconds: 5),
              isSeek: false,
            );
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            widget.controller.onDoubleTapCenter();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: _focusNode.hasFocus
              ? Border.all(color: Colors.white, width: 2)
              : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: widget.child,
      ),
    );
  }
}
