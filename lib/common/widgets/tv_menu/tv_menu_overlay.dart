import 'package:PiliPlus/common/widgets/tv_menu/menu_item_widget.dart';
import 'package:PiliPlus/services/tv_menu/menu_provider.dart';
import 'package:PiliPlus/services/tv_menu/models/menu_item.dart';
import 'package:PiliPlus/services/tv_menu/tv_menu_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class TVMenuOverlay extends StatefulWidget {
  final MenuProvider provider;

  const TVMenuOverlay({Key? key, required this.provider}) : super(key: key);

  @override
  State<TVMenuOverlay> createState() => _TVMenuOverlayState();
}

class _TVMenuOverlayState extends State<TVMenuOverlay> {
  int _focusedIndex = 0;
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
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Focus(
            focusNode: _focusNode,
            onKeyEvent: (node, event) {
              final menuItems = widget.provider.getMenuItems(context);
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.escape) {
                  TVMenuService.instance.hideMenu();
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  setState(() {
                    _focusedIndex = (_focusedIndex - 1 + menuItems.length) % menuItems.length;
                  });
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  setState(() {
                    _focusedIndex = (_focusedIndex + 1) % menuItems.length;
                  });
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
                  menuItems[_focusedIndex].onTap();
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: Container(
              width: 250,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Obx(() {
                final menuItems = widget.provider.getMenuItems(context);
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    return MenuItemWidget(
                      item: menuItems[index],
                      isFocused: index == _focusedIndex,
                    );
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
