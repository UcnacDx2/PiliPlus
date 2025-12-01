import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/models/video/video_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/common/widgets/tv_menu/tv_popup_menu.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/utils/page_utils.dart';

class TvMenuManager {
  TvMenuManager._privateConstructor();
  static final TvMenuManager _instance = TvMenuManager._privateConstructor();
  factory TvMenuManager() {
    return _instance;
  }

  void showTvMenu({
    required BuildContext context,
    required String contextType,
    required dynamic focusData,
  }) {
    final items = _buildMenuItems(context, contextType, focusData);
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
  ) {
    switch (contextType) {
      case 'videoCard':
        return _buildVideoCardMenu(context, focusData);
      case 'videoPlayer':
        return _buildVideoPlayerMenu(context, focusData);
      default:
        return [];
    }
  }

  List<TvPopupMenuItem> _buildVideoCardMenu(
    BuildContext context,
    dynamic focusData,
  ) {
    final videoItem = focusData as VideoItem;
    final heroTag = 'tvMenu_${videoItem.bvid}';
    return [
      TvPopupMenuItem(
        icon: Icons.play_arrow_outlined,
        title: '立即播放',
        onTap: () {
          try {
            Navigator.of(context).pop();
            PageUtils.toVideoPage(
              bvid: videoItem.bvid,
              cid: videoItem.cid,
              aid: videoItem.aid,
              cover: videoItem.cover,
              heroTag: heroTag,
              title: videoItem.title,
            );
          } catch (e) {
            SmartDialog.showToast('播放失败: $e');
          }
        },
      ),
      TvPopupMenuItem(
        icon: Icons.watch_later_outlined,
        title: '稍后再看',
        onTap: () async {
          try {
            Navigator.of(context).pop();
            var res = await UserHttp.toViewLater(bvid: videoItem.bvid);
            SmartDialog.showToast(res['msg']);
          } catch (e) {
            SmartDialog.showToast('操作失败: $e');
          }
        },
      ),
    ];
  }

  List<TvPopupMenuItem> _buildVideoPlayerMenu(
    BuildContext context,
    dynamic focusData,
  ) {
    // final videoDetail = focusData;
    return [
      TvPopupMenuItem(
        icon: Icons.settings_outlined,
        title: '播放设置',
        onTap: () {
          try {
            Navigator.of(context).pop();
            final controller = Get.find<VideoDetailController>();
            controller.showSettingSheet();
          } catch (e) {
            SmartDialog.showToast('操作失败: $e');
          }
        },
      ),
      TvPopupMenuItem(
        icon: Icons.subtitles_outlined,
        title: '字幕设置',
        onTap: () {
          try {
            Navigator.of(context).pop();
            final controller = Get.find<VideoDetailController>();
            controller.showSetSubtitle();
          } catch (e) {
            SmartDialog.showToast('操作失败: $e');
          }
        },
      ),
    ];
  }
}
