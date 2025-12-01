import 'package:PiliPlus/common/widgets/video_popup_menu.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/common/widgets/tv_menu/tv_popup_menu.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/pages/video/widgets/header_control.dart';

class TvMenuManager {
  TvMenuManager._privateConstructor();
  static final TvMenuManager _instance = TvMenuManager._privateConstructor();
  factory TvMenuManager() {
    return _instance;
  }

  void showTvMenu({
    required BuildContext context,
    required String contextType,
    dynamic focusData,
    dynamic headerState,
    GlobalKey<VideoPopupMenuState>? videoCardMenuKey,
  }) {
    final items = _buildMenuItems(
        context, contextType, focusData, headerState, videoCardMenuKey);
    showDialog(
      context: context,
      builder: (context) => TvPopupMenu(
        items: items,
      ),
    );
  }

  List<TvPopupMenuItem> _buildMenuItems(
    BuildContext context,
    String contextType,
    dynamic focusData,
    dynamic headerState,
    GlobalKey<VideoPopupMenuState>? videoCardMenuKey,
  ) {
    switch (contextType) {
      case 'videoCard':
        return _buildVideoCardMenu(context, focusData, videoCardMenuKey);
      case 'videoPlayer':
        return _buildVideoPlayerMenu(context, focusData, headerState);
      case 'global':
        return _buildGlobalMenu(context);
      default:
        return [];
    }
  }

  List<TvPopupMenuItem> _buildVideoCardMenu(
    BuildContext context,
    dynamic focusData,
    GlobalKey<VideoPopupMenuState>? videoCardMenuKey,
  ) {
    return [
      TvPopupMenuItem(
        icon: Icons.more_vert_outlined,
        title: '更多选项',
        onTap: () {
          Navigator.of(context).pop();
          videoCardMenuKey?.currentState?.showButtonMenu();
        },
      ),
    ];
  }

  List<TvPopupMenuItem> _buildVideoPlayerMenu(
    BuildContext context,
    dynamic focusData,
    dynamic headerState,
  ) {
    final state = headerState as HeaderControlState;
    return [
      TvPopupMenuItem(
        icon: Icons.settings_outlined,
        title: '更多选项',
        onTap: () {
          try {
            Navigator.of(context).pop();
            state.showSettingSheet();
          } catch (e) {
            SmartDialog.showToast('操作失败: $e');
          }
        },
      ),
    ];
  }

  List<TvPopupMenuItem> _buildGlobalMenu(BuildContext context) {
    return [
      TvPopupMenuItem(
        icon: Icons.person_add_alt_1_outlined,
        title: '添加账户',
        onTap: () {
          Navigator.of(context).pop();
          Get.toNamed('/loginPage');
        },
      ),
      TvPopupMenuItem(
        icon: Icons.exit_to_app_outlined,
        title: '退出程序',
        onTap: () {
          Navigator.of(context).pop();
          SystemNavigator.pop();
        },
      ),
    ];
  }
}
