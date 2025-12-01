import 'package:flutter/material.dart';
import 'package:PiliPlus/common/widgets/tv_menu/tv_popup_menu.dart';
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
    // final videoItem = focusData;
    return [
      TvPopupMenuItem(
        icon: Icons.play_arrow_outlined,
        title: '立即播放',
        onTap: () {
          // TODO: Implement play logic
          Navigator.of(context).pop();
        },
      ),
      TvPopupMenuItem(
        icon: Icons.watch_later_outlined,
        title: '稍后再看',
        onTap: () {
          // TODO: Implement add to watch later logic
          Navigator.of(context).pop();
        },
      ),
    ];
  }

  List<TvPopupMenuItem> _buildVideoPlayerMenu(
    BuildContext context,
    dynamic focusData,
  ) {
    final headerState = focusData as HeaderControlState;
    return [
      TvPopupMenuItem(
        icon: Icons.settings_outlined,
        title: '播放设置',
        onTap: () {
          Navigator.of(context).pop();
          headerState.showSetDanmaku();
        },
      ),
      TvPopupMenuItem(
        icon: Icons.subtitles_outlined,
        title: '字幕设置',
        onTap: () {
          Navigator.of(context).pop();
          headerState.showSetSubtitle();
        },
      ),
    ];
  }
}
