import 'package:PiliPlus/services/tv_menu/models/menu_item.dart';
import 'package:PiliPlus/services/tv_menu/tv_menu_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class TVMenuOverlay {
  static void show(BuildContext context) {
    final menuService = TVMenuService.instance;
    final provider = menuService.activeProvider;
    if (provider == null) return;

    final menuItems = provider.getMenuItems(context);

    SmartDialog.show(
      clickMaskDismiss: true,
      animationType: SmartAnimationType.fade,
      maskColor: Colors.black54,
      builder: (context) {
        return const TVMenuWidget();
      },
    );
  }
}

class TVMenuWidget extends StatefulWidget {
  const TVMenuWidget({super.key});

  @override
  State<TVMenuWidget> createState() => _TVMenuWidgetState();
}

class _TVMenuWidgetState extends State<TVMenuWidget> {
  final FocusScopeNode _focusNode = FocusScopeNode();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 50,
      top: 50,
      bottom: 50,
      child: FocusScope(
        node: _focusNode,
        child: Container(
          width: 250,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Obx(() {
            final menuItems =
                TVMenuService.instance.activeProvider!.getMenuItems(context);
            return ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return MenuItemWidget(
                  item: item,
                  isSelected: _selectedIndex == index,
                  onTap: () {
                    SmartDialog.dismiss();
                    item.onTap();
                  },
                  onFocusChange: (hasFocus) {
                    if (hasFocus) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    }
                  },
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

class MenuItemWidget extends StatefulWidget {
  final MenuItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool> onFocusChange;

  const MenuItemWidget({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onFocusChange,
  });

  @override
  State<MenuItemWidget> createState() => _MenuItemWidgetState();
}

class _MenuItemWidgetState extends State<MenuItemWidget> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      widget.onFocusChange(_focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      focusNode: _focusNode,
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: widget.isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
        child: Row(
          children: [
            Icon(widget.item.icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Text(
              widget.item.label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
