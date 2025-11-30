import 'package:flutter/material.dart';

class TvPopupMenu extends StatefulWidget {
  final List<PopupMenuItem> menuItems;

  const TvPopupMenu({Key? key, required this.menuItems}) : super(key: key);

  @override
  _TvPopupMenuState createState() => _TvPopupMenuState();
}

class _TvPopupMenuState extends State<TvPopupMenu> {
  int _selectedIndex = 0;
  final FocusNode _listViewFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Request focus for the list view when the widget is first built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_listViewFocusNode);
    });
  }

  @override
  void dispose() {
    _listViewFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: 250, // Constrain width for TV
        child: Focus(
          focusNode: _listViewFocusNode,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                setState(() {
                  _selectedIndex = (_selectedIndex - 1).clamp(0, widget.menuItems.length - 1);
                });
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                setState(() {
                  _selectedIndex = (_selectedIndex + 1).clamp(0, widget.menuItems.length - 1);
                });
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
                widget.menuItems[_selectedIndex].onTap?.call();
                Navigator.of(context).pop(); // Close the menu on selection
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.menuItems.length,
            itemBuilder: (context, index) {
              final item = widget.menuItems[index];
              final bool isSelected = index == _selectedIndex;
              return Container(
                color: isSelected ? Theme.of(context).highlightColor : null,
                child: ListTile(
                  title: item.child,
                  onTap: () {
                    item.onTap?.call();
                    Navigator.of(context).pop(); // Close the menu on tap
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
