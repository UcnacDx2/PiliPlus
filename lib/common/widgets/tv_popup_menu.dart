import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class TvPopupMenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const TvPopupMenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

class TvPopupMenu extends StatefulWidget {
  final List<TvPopupMenuItem> items;

  const TvPopupMenu({
    super.key,
    required this.items,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    });
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('菜单'),
      contentPadding: const EdgeInsets.only(top: 16),
      constraints: const BoxConstraints(
        minWidth: 280,
        maxWidth: 425,
      ),
      content: FocusScope(
        onKeyEvent: (node, event) {
          if (event.logicalKey == LogicalKeyboardKey.escape ||
              event.logicalKey == LogicalKeyboardKey.goBack) {
            return KeyEventResult.ignored;
          }
          _handleKeyEvent(event);
          return KeyEventResult.handled;
        },
        child: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: widget.items.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return Focus(
                focusNode: _focusNodes[index],
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent &&
                      (event.logicalKey == LogicalKeyboardKey.select ||
                          event.logicalKey == LogicalKeyboardKey.enter)) {
                    Get.back();
                    item.onTap();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Builder(
                  builder: (context) {
                    final bool hasFocus = Focus.of(context).hasFocus;
                    return ListTile(
                      autofocus: index == 0,
                      selected: hasFocus,
                      selectedTileColor: theme.colorScheme.primary.withOpacity(0.2),
                      leading: Icon(item.icon),
                      title: Text(item.title),
                      onTap: () {
                        Get.back();
                        item.onTap();
                      },
                    );
                  }
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
