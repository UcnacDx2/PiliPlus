import 'package:PiliPlus/common/widgets/tv_menu/tv_popup_menu_item.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/pages/video/widgets/header_control.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

List<TvPopupMenuItem> buildVideoPlayerMenu({
  required BuildContext context,
  required dynamic focusData,
}) {
  // We need access to the HeaderControlState to show the sheets.
  // A GlobalKey is the most straightforward way to do this from a decoupled module.
  final videoDetailController = Get.find<VideoDetailController>();
  final headerControlState =
      videoDetailController.headerKey.currentState;

  if (headerControlState == null) {
    return [];
  }

  return [
    TvPopupMenuItem(
      icon: Icons.settings_outlined,
      title: '播放设置',
      onTap: () {
        Get.back();
        headerControlState.showSettingSheet();
      },
    ),
    TvPopupMenuItem(
      icon: Icons.subtitles_outlined,
      title: '字幕设置',
      onTap: () {
        Get.back();
        headerControlState.showSetSubtitle();
      },
    ),
  ];
}
