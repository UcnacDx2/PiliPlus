import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pili_plus/pages/main/view.dart';
import 'package:pili_plus/plugin/pl_player/controller.dart';
import 'package:pili_plus/services/tv_menu/menu_provider.dart';
import 'package:pili_plus/services/tv_menu/models/menu_item.dart';
import 'package:pili_plus/services/tv_menu/tv_menu_service.dart';

class BrowseMenuProvider implements MenuProvider {
  @override
  String get sceneName => 'browse';

  @override
  List<MenuItem> getMenuItems(BuildContext context) {
    return [
      MenuItem(
        title: const Text('Home'),
        icon: Icons.home,
        onTap: () {
          // TODO: Implement home navigation
          TVMenuService.to.hideMenu();
        },
      ),
      MenuItem(
        title: const Text('Search'),
        icon: Icons.search,
        onTap: () {
          // TODO: Implement search navigation
          TVMenuService.to.hideMenu();
        },
      ),
    ];
  }

  @override
  bool canHandle(BuildContext context) {
    final route = Get.routing.current;
    final isBrowserRoute = route == '/' || route == '/main';
    return isBrowserRoute && !Get.isRegistered<PlPlayerController>();
  }
}
