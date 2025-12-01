import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:piliplus/services/tv_menu/menu_provider.dart';
import 'package:piliplus/services/tv_menu/models/menu_item.dart';
import 'package:get/get.dart';
import 'package:piliplus/pages/login/index.dart';

class DefaultMenuProvider implements MenuProvider {
  @override
  String get sceneName => 'default';

  @override
  bool canHandle(BuildContext context) {
    // This is the default provider, so it can always handle the request.
    return true;
  }

  @override
  List<MenuItem> getMenuItems(BuildContext context) {
    return [
      MenuItem(
        label: 'Add Account',
        icon: Icons.person_add,
        onTap: () => Get.toNamed("/login"),
      ),
      MenuItem(
        label: 'Exit App',
        icon: Icons.exit_to_app,
        onTap: () => SystemNavigator.pop(),
      ),
    ];
  }
}
