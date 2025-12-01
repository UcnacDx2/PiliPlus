import 'package:flutter/material.dart';
import 'package:pili_plus/services/tv_menu/models/menu_item.dart';

class MenuItemWidget extends StatefulWidget {
  final MenuItem item;
  final bool autoFocus;

  const MenuItemWidget({
    Key? key,
    required this.item,
    this.autoFocus = false,
  }) : super(key: key);

  @override
  State<MenuItemWidget> createState() => _MenuItemWidgetState();
}

class _MenuItemWidgetState extends State<MenuItemWidget> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autoFocus,
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      child: InkWell(
        onTap: widget.item.onTap,
        child: Container(
          color: _isFocused ? Colors.blue.withOpacity(0.3) : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Row(
            children: [
              Icon(widget.item.icon, color: Colors.white),
              const SizedBox(width: 12.0),
              DefaultTextStyle(
                style: const TextStyle(color: Colors.white, fontSize: 16.0),
                child: widget.item.title,
              )
            ],
          ),
        ),
      ),
    );
  }
}
