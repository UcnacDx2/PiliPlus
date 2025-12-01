import 'package:PiliPlus/services/tv_menu/menu_provider.dart';
import 'package:PiliPlus/services/tv_menu/models/menu_item.dart';
import 'package:PiliPlus/services/tv_menu/tv_menu_service.dart';
import 'package:flutter/material.dart';

class DefaultMenuProvider implements MenuProvider {
  @override
  String get sceneName => 'default';

  @override
  bool get isReactive => false;

  @override
  List<MenuItem> getMenuItems(BuildContext context) {
    return [
      MenuItem(
        label: 'Close Menu',
        icon: Icons.close,
        onTap: () {
          TVMenuService.instance.hideMenu();
        },
      ),
    ];
  }

  @override
  bool canHandle(BuildContext context) {
    return true;
  }
}
