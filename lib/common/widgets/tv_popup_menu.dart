import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Data class for an item in the [TvPopupMenu].
class TvPopupMenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  TvPopupMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

/// A TV-friendly popup menu that can be navigated with a D-pad.
///
/// It is implemented as an [AlertDialog] and manages its own focus scope.
class TvPopupMenu extends StatefulWidget {
  final List<TvPopupMenuItem> items;

  const TvPopupMenu({
    required this.items,
    super.key,
  });

  @override
  State<TvPopupMenu> createState() => _TvPopupMenuState();
}

class _TvPopupMenuState extends State<TvPopupMenu> {
  int _focusIndex = 0;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.items.length, (index) => FocusNode());

    // After the frame is built, request focus for the first item.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNodes.isNotEmpty) {
        FocusScope.of(context).requestFocus(_focusNodes[0]);
      }
    });
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Handles up/down arrow key events to navigate the menu.
  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _focusIndex = (_focusIndex + 1) % widget.items.length;
        FocusScope.of(context).requestFocus(_focusNodes[_focusIndex]);
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _focusIndex = (_focusIndex - 1 + widget.items.length) % widget.items.length;
        FocusScope.of(context).requestFocus(_focusNodes[_focusIndex]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      contentPadding: EdgeInsets.zero,
      content: FocusScope(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.escape)) {
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }
          _handleKeyEvent(event);
          return KeyEventResult.handled;
        },
        child: SizedBox(
          width: 250, // Fixed width for the menu
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 14),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return Focus(
                focusNode: _focusNodes[index],
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent &&
                      (event.logicalKey == LogicalKeyboardKey.select ||
                          event.logicalKey == LogicalKeyboardKey.enter)) {
                    item.onTap();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Builder(builder: (context) {
                  final bool hasFocus = Focus.of(context).hasFocus;
                  return ListTile(
                    autofocus: index == 0,
                    selected: hasFocus,
                    selectedTileColor: theme.colorScheme.onSurface.withOpacity(0.1),
                    leading: Icon(item.icon),
                    title: Text(item.title),
                    onTap: item.onTap,
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}
