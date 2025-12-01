import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pilipala/models/focus_context.dart';
import 'package:pilipala/pages/video/controller.dart';
import 'package:pilipala/pages/common/common_intro_controller.dart';
import 'package:pilipala/pages/live_room/controller.dart';
import 'package:pilipala/utils/image_utils.dart';
import 'package:pilipala/utils/page_utils.dart';
import 'package:pilipala/utils/accounts.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:pilipala/utils/utils.dart';

abstract class MenuContentStrategy {
  List<PopupMenuEntry> generateItems(FocusContext context);
}

class VideoPageMenuStrategy implements MenuContentStrategy {
  final VideoDetailController videoDetailController;
  final CommonIntroController introController;

  VideoPageMenuStrategy()
      : videoDetailController = Get.find<VideoDetailController>(),
        introController = Get.find<CommonIntroController>();

  @override
  List<PopupMenuEntry> generateItems(FocusContext context) {
    return [
      PopupMenuItem(
        onTap: introController.viewLater,
        child: const Text('稍后再看'),
      ),
      if (videoDetailController.epId == null)
        PopupMenuItem(
          onTap: () => videoDetailController.showNoteList(Get.context!),
          child: const Text('查看笔记'),
        ),
      if (!videoDetailController.isFileSource)
        PopupMenuItem(
          onTap: () => videoDetailController.onDownload(Get.context!),
          child: const Text('缓存视频'),
        ),
      if (videoDetailController.cover.value.isNotEmpty)
        PopupMenuItem(
          onTap: () => ImageUtils.downloadImg(
            Get.context!,
            [videoDetailController.cover.value],
          ),
          child: const Text('保存封面'),
        ),
      if (!videoDetailController.isFileSource && videoDetailController.isUgc)
        PopupMenuItem(
          onTap: videoDetailController.toAudioPage,
          child: const Text('听音频'),
        ),
      PopupMenuItem(
        onTap: () {
          if (!Accounts.main.isLogin) {
            SmartDialog.showToast('账号未登录');
          } else {
            PageUtils.reportVideo(videoDetailController.aid);
          }
        },
        child: const Text('举报'),
      ),
    ];
  }
}

class LiveRoomMenuStrategy implements MenuContentStrategy {
  final LiveRoomController liveRoomController;

  LiveRoomMenuStrategy() : liveRoomController = Get.find<LiveRoomController>();

  @override
  List<PopupMenuEntry> generateItems(FocusContext context) {
    final liveUrl = 'https://live.bilibili.com/${liveRoomController.roomId}';
    return [
      PopupMenuItem(
        onTap: () => Utils.copyText(liveUrl),
        child: const Text('复制链接'),
      ),
      if (Utils.isMobile)
        PopupMenuItem(
          onTap: () => Utils.shareText(liveUrl),
          child: const Text('分享直播间'),
        ),
      PopupMenuItem(
        onTap: () => PageUtils.inAppWebview(liveUrl, off: true),
        child: const Text('浏览器打开'),
      ),
      if (liveRoomController.roomInfoH5.value != null)
        PopupMenuItem(
          onTap: () {
            try {
              final roomInfo = liveRoomController.roomInfoH5.value!;
              PageUtils.pmShare(
                Get.context!,
                content: {
                  "cover": roomInfo.roomInfo!.cover!,
                  "sourceID": liveRoomController.roomId.toString(),
                  "title": roomInfo.roomInfo!.title!,
                  "url": liveUrl,
                  "authorID": roomInfo.roomInfo!.uid.toString(),
                  "source": "直播",
                  "desc": roomInfo.roomInfo!.title!,
                  "author": roomInfo.anchorInfo!.baseInfo!.uname,
                },
              );
            } catch (e) {
              SmartDialog.showToast(e.toString());
            }
          },
          child: const Text('分享至消息'),
        ),
    ];
  }
}

class DefaultMenuStrategy implements MenuContentStrategy {
  @override
  List<PopupMenuEntry> generateItems(FocusContext context) {
    return [];
  }
}
