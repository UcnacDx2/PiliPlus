import 'package:PiliPlus/common/widgets/tv_popup_menu.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/models/tv_menu_context.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/pages/video/widgets/header_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class TvMenuManager {
  static final TvMenuManager _instance = TvMenuManager._internal();

  factory TvMenuManager() {
    return _instance;
  }

  TvMenuManager._internal();

  TvMenuContextData _currentContext = TvMenuContextData(type: TvMenuContextType.none);

  void updateContext(TvMenuContextData context) {
    _currentContext = context;
  }

  void showTvMenu(BuildContext context) {
    if (_currentContext.type == TvMenuContextType.none) {
      // Default menu or no-op
      showDialog(
        context: context,
        builder: (dialogContext) => TvPopupMenu(
          menuItems: [
            PopupMenuItem(
              child: Text('Exit Program'),
              onTap: () => SystemNavigator.pop(),
            ),
          ],
        ),
      );
      return;
    }

    List<PopupMenuItem<dynamic>> menuItems = _generateMenuItems(context, _currentContext);

    showDialog(
      context: context,
      builder: (dialogContext) => TvPopupMenu(menuItems: menuItems),
    );
  }

  List<PopupMenuItem> _generateMenuItems(BuildContext context, TvMenuContextData contextData) {
    switch (contextData.type) {
      case TvMenuContextType.player:
        return _buildPlayerMenuItems(context, contextData);
      case TvMenuContextType.videoCard:
        return _buildVideoCardMenuItems(context, contextData);
      default:
        return [
          PopupMenuItem(
            child: Text('Exit Program'),
            onTap: () => SystemNavigator.pop(),
          ),
        ];
    }
  }

  List<PopupMenuItem> _buildPlayerMenuItems(BuildContext context, TvMenuContextData contextData) {
    final plPlayerController = contextData.plPlayerController;
    if (plPlayerController == null) return [];

    final videoDetailCtr = Get.find<VideoDetailController>();

    return [
      PopupMenuItem(
        child: Text('选择画質'),
        onTap: () => videoDetailCtr.showSetVideoQa(context),
      ),
      if (videoDetailCtr.currentAudioQa != null)
        PopupMenuItem(
          child: Text('选择音质'),
          onTap: () => videoDetailCtr.showSetAudioQa(context),
        ),
      PopupMenuItem(
        child: Text('弹幕设置'),
        onTap: () => videoDetailCtr.showSetDanmaku(context),
      ),
      PopupMenuItem(
        child: Text('字幕设置'),
        onTap: () => videoDetailCtr.showSetSubtitle(context),
      ),
      PopupMenuItem(
        child: Text('播放顺序'),
        onTap: () => videoDetailCtr.showSetRepeat(context),
      ),
      PopupMenuItem(
        child: Text('播放信息'),
        onTap: () => videoDetailCtr.showPlayerInfo(context),
      ),
    ];
  }

  List<PopupMenuItem> _buildVideoCardMenuItems(BuildContext context, TvMenuContextData contextData) {
    final videoItem = contextData.videoItem;
    if (videoItem == null) return [];

    return [
      PopupMenuItem(
        child: Text('稍后再看'),
        onTap: () async {
          if (videoItem.bvid?.isNotEmpty == true) {
            var res = await UserHttp.toViewLater(
              bvid: videoItem.bvid,
            );
            SmartDialog.showToast(res['msg']);
          }
        },
      ),
      PopupMenuItem(
        child: Text('访问UP主'),
        onTap: () {
          Get.toNamed('/member?mid=${videoItem.owner.mid}');
        },
      ),
      PopupMenuItem(
        child: Text('不感兴趣'),
        onTap: () {
          // Simplified "Not Interested" logic for TV
          SmartDialog.showToast("将减少相关内容推荐");
        },
      ),
    ];
  }
}
