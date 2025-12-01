import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:piliplus/services/tv_menu/models/menu_item.dart';
import 'package:piliplus/services/tv_menu/tv_menu_service.dart';

class TVMenuOverlay extends StatefulWidget {
  const TVMenuOverlay({Key? key}) : super(key: key);

  @override
  State<TVMenuOverlay> createState() => _TVMenuOverlayState();
}

class _TVMenuOverlayState extends State<TVMenuOverlay> {
  int _selectedIndex = 0;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    FocusScope.of(context).requestFocus(_focusNode);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final provider = TVMenuService.to.getProviderForContext(context);
      final menuItems = provider?.getMenuItems(context) ?? [];

      return RawKeyboardListener(
        focusNode: _focusNode,
        onKey: (event) {
          if (event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              setState(() {
                _selectedIndex = (_selectedIndex - 1 + menuItems.length) % menuItems.length;
              });
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              setState(() {
                _selectedIndex = (_selectedIndex + 1) % menuItems.length;
              });
            } else if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.select) {
              menuItems[_selectedIndex].onTap();
              TVMenuService.to.toggleMenu(context);
            } else if (event.logicalKey == LogicalKeyboardKey.escape || event.logicalKey == LogicalKeyboardKey.menu) {
              TVMenuService.to.toggleMenu(context);
            }
          }
        },
        child: Container(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  final isSelected = index == _selectedIndex;
                  return Container(
                    color: isSelected ? Colors.grey.withOpacity(0.5) : Colors.transparent,
                    child: ListTile(
                      leading: Icon(item.icon, color: Colors.white),
                      title: Text(item.label, style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        item.onTap();
                        TVMenuService.to.toggleMenu(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    });
  }
}
