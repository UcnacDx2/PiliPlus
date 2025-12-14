import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';

class TVEventInterceptor extends StatelessWidget {
  final PlPlayerController controller;
  final Widget child;

  const TVEventInterceptor({
    Key? key,
    required this.controller,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && !controller.showControls.value) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            controller.controls = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.tvFocusManager.seekBarNode.requestFocus();
            });
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            controller.controls = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.tvFocusManager.playButtonNode.requestFocus();
            });
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            controller.controls = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.tvFocusManager.qualityButtonNode.requestFocus();
            });
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}
