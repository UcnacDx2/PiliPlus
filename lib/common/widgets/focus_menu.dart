import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FocusMenu<T> extends StatefulWidget {
  final Widget Function(GlobalKey<PopupMenuButtonState<T>> key) builder;

  const FocusMenu({
    super.key,
    required this.builder,
  });

  @override
  State<FocusMenu<T>> createState() => _FocusMenuState<T>();
}

class _FocusMenuState<T> extends State<FocusMenu<T>> {
  final GlobalKey<PopupMenuButtonState<T>> _popupMenuKey =
      GlobalKey<PopupMenuButtonState<T>>();

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.contextMenu) {
          _popupMenuKey.currentState?.showButtonMenu();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: widget.builder(_popupMenuKey),
    );
  }
}
