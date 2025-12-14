import 'package:PiliPlus/plugin/pl_player/tv_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TvProgressControl extends StatefulWidget {
  final TvPlayerController controller;

  const TvProgressControl({required this.controller, super.key});

  @override
  State<TvProgressControl> createState() => _TvProgressControlState();
}

class _TvProgressControlState extends State<TvProgressControl> {
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.controller.focusNodeB,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          switch (event.logicalKey) {
            case LogicalKeyboardKey.select:
            case LogicalKeyboardKey.enter:
            case LogicalKeyboardKey.gameButtonA:
              widget.controller.togglePlayPause();
              return KeyEventResult.handled;
            case LogicalKeyboardKey.arrowLeft:
              // controller.seekBackward(); // 快退
              return KeyEventResult.handled;
            case LogicalKeyboardKey.arrowRight:
              // controller.seekForward(); // 快进
              return KeyEventResult.handled;
            default:
              return KeyEventResult.ignored;
          }
        }
        return KeyEventResult.ignored;
      },
      child: const Center(
        child: Text("TV Progress Control"),
      ),
    );
  }
}
