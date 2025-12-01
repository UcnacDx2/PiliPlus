import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:flutter/material.dart';
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
    required dynamic focusData,
    dynamic headerState,
  }) {
    final items = _buildMenuItems(context, contextType, focusData, headerState);
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
  ) {
    switch (contextType) {
      case 'videoCard':
        return _buildVideoCardMenu(context, focusData);
      case 'videoPlayer':
        return _buildVideoPlayerMenu(context, focusData, headerState);
      default:
        return [];
    }
  }

  List<TvPopupMenuItem> _buildVideoCardMenu(
    BuildContext context,
    dynamic focusData,
  ) {
    final videoItem = focusData as BaseRecVideoItemModel;
    return [
      TvPopupMenuItem(
        icon: Icons.play_arrow_outlined,
        title: '立即播放',
        onTap: () {
          try {
            Navigator.of(context).pop();
            PageUtils.toVideoPage(
              bvid: videoItem.bvid,
              cid: videoItem.cid!,
              aid: videoItem.aid,
              cover: videoItem.cover,
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
    dynamic headerState,
  ) {
    final state = headerState as HeaderControlState;
    return [
      TvPopupMenuItem(
        icon: Icons.settings_outlined,
        title: '播放设置',
        onTap: () {
          try {
            Navigator.of(context).pop();
            state.showSettingSheet();
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
            state.showSetSubtitle();
          } catch (e) {
            SmartDialog.showToast('操作失败: $e');
          }
        },
      ),
    ];
  }
}
