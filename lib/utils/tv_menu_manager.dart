import 'package:PiliPlus/common/widgets/tv_menu/tv_popup_menu.dart';
import 'package:PiliPlus/common/widgets/tv_menu/tv_popup_menu_item.dart';
import 'package:PiliPlus/common/widgets/tv_menu/tv_video_card_menu.dart';
import 'package:PiliPlus/common/widgets/tv_menu/tv_video_player_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class TvMenuManager {
  // Singleton for easy access
  static final TvMenuManager _instance = TvMenuManager._internal();
  factory TvMenuManager() {
    return _instance;
  }
  TvMenuManager._internal();

  void showTvMenu({
    required BuildContext context,
    required String contextType,
    dynamic focusData,
  }) {
    List<TvPopupMenuItem> menuItems;

    switch (contextType) {
      case 'videoCard':
        menuItems = buildVideoCardMenu(context: context, focusData: focusData);
        break;
      case 'videoPlayer':
        menuItems = buildVideoPlayerMenu(context: context, focusData: focusData);
        break;
      default:
        menuItems = _buildDefaultMenu();
        break;
    }

    if (menuItems.isEmpty) {
      menuItems = _buildDefaultMenu();
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return TvPopupMenu(items: menuItems);
      },
    );
  }

  List<TvPopupMenuItem> _buildDefaultMenu() {
    return [
      TvPopupMenuItem(
        title: '添加账户',
        icon: Icons.person_add_alt_1_outlined,
        onTap: () {
          Get.back(); // Close the menu first
          Get.toNamed('/loginPage');
        },
      ),
      TvPopupMenuItem(
        title: '退出程序',
        icon: Icons.exit_to_app,
        onTap: () {
          Get.back(); // Close the menu first
          SystemNavigator.pop();
        },
      ),
    ];
  }
}
