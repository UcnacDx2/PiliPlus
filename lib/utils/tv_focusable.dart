import 'package:flutter/widgets.dart';
import 'tv_key_handler.dart';

class TvKeyHandlerProvider extends InheritedWidget {
  final TvKeyHandler tvKeyHandler;

  const TvKeyHandlerProvider({
    Key? key,
    required this.tvKeyHandler,
    required Widget child,
  }) : super(key: key, child: child);

  static TvKeyHandler? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TvKeyHandlerProvider>()
        ?.tvKeyHandler;
  }

  @override
  bool updateShouldNotify(TvKeyHandlerProvider oldWidget) {
    return tvKeyHandler != oldWidget.tvKeyHandler;
  }
}

class TvFocusable extends StatefulWidget {
  final Widget child;
  final FocusNode? focusNode;

  const TvFocusable({
    Key? key,
    required this.child,
    this.focusNode,
  }) : super(key: key);

  @override
  _TvFocusableState createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  late FocusNode _focusNode;
  TvKeyHandler? _tvKeyHandler;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tvKeyHandler = TvKeyHandlerProvider.of(context);
    if (tvKeyHandler != _tvKeyHandler) {
      _tvKeyHandler?.focusManager.removeFocusableNode(_focusNode);
      _tvKeyHandler = tvKeyHandler;
      _tvKeyHandler?.focusManager.addFocusableNode(_focusNode);
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    _tvKeyHandler?.focusManager.removeFocusableNode(_focusNode);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: widget.child,
    );
  }
}
