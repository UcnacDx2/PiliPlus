import 'package:flutter/material.dart';
import 'package:pili_plus/services/tv_menu/menu_provider.dart';
import 'package:pili_plus/services/tv_menu/models/menu_item.dart';
import 'package:pili_plus/services/tv_menu/tv_menu_service.dart';

class DefaultMenuProvider implements MenuProvider {
  @override
  String get sceneName => 'default';

  @override
  List<MenuItem> getMenuItems(BuildContext context) {
    return [
      MenuItem(
        title: const Text('Settings'),
        icon: Icons.settings,
        onTap: () {
          // TODO: Implement settings navigation
          TVMenuService.to.hideMenu();
        },
      ),
    ];
  }

  @override
  bool canHandle(BuildContext context) {
    return true;
  }
}
