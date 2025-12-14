import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      onKeyEvent: _handleGlobalKey,
      child: child,
    );
  }

  KeyEventResult _handleGlobalKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (!controller.showControls.value) {
      if (event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        _wakeUpAndFocus(controller.tvFocusManager.seekBarNode);
        return KeyEventResult.handled;
      }

      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _wakeUpAndFocus(controller.tvFocusManager.playButtonNode);
        return KeyEventResult.handled;
      }

      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _wakeUpAndFocus(controller.tvFocusManager.qualityButtonNode);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _wakeUpAndFocus(FocusNode target) {
    controller.controls = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      target.requestFocus();
    });
  }
}
