import 'package:flutter/material.dart';
import 'package:PiliPlus/services/tv_menu/models/menu_item.dart';

class MenuItemWidget extends StatefulWidget {
  final MenuItem item;
  final bool autofocus;

  const MenuItemWidget({
    Key? key,
    required this.item,
    this.autofocus = false,
  }) : super(key: key);

  @override
  _MenuItemWidgetState createState() => _MenuItemWidgetState();
}

class _MenuItemWidgetState extends State<MenuItemWidget> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_focusNode);
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.item.onTap,
      focusNode: _focusNode,
      child: Container(
        color: _isFocused ? Colors.blue.withOpacity(0.5) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            Icon(widget.item.icon, color: Colors.white),
            const SizedBox(width: 16.0),
            Text(widget.item.label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
