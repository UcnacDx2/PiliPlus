import 'package:PiliPlus/services/tv_menu/menu_provider.dart';
import 'package:PiliPlus/services/tv_menu/models/menu_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Default menu provider when no other provider matches
class DefaultMenuProvider implements MenuProvider {
  @override
  String get sceneName => 'Default';

  @override
  int get priority => 0; // Lowest priority - fallback

  @override
  bool canHandle(BuildContext context) {
    return true; // Always can handle as fallback
  }

  @override
  List<TvMenuItem> getMenuItems(BuildContext context) {
    return [
      TvMenuItem(
        label: '返回',
        icon: Icons.arrow_back,
        onTap: () => Get.back(),
      ),
      TvMenuItem(
        label: '返回主页',
        icon: Icons.home,
        onTap: () => Get.until((route) => route.isFirst),
      ),
    ];
  }
}
