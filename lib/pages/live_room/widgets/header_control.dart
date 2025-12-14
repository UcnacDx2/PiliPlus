import 'dart:io';

import 'package:PiliPlus/common/widgets/marquee.dart';
import 'package:PiliPlus/models_new/live/live_room_info_h5/data.dart';
import 'package:PiliPlus/pages/live_room/controller.dart';
import 'package:PiliPlus/pages/video/widgets/header_control.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/common_btn.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:floating/floating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class LiveHeaderControl extends StatefulWidget {
  const LiveHeaderControl({
    super.key,
    required this.title,
    required this.upName,
    required this.plPlayerController,
    required this.onSendDanmaku,
    required this.onPlayAudio,
    required this.isPortrait,
    required this.liveController,
  });

  final String? title;
  final String? upName;
  final PlPlayerController plPlayerController;
  final VoidCallback onSendDanmaku;
  final VoidCallback onPlayAudio;
  final bool isPortrait;
  final LiveRoomController liveController;

  @override
  State<LiveHeaderControl> createState() => LiveHeaderControlState();
}

class LiveHeaderControlState extends State<LiveHeaderControl>
    with TimeBatteryMixin {
  void showSettingSheet() {
    final liveUrl = 'https://live.bilibili.com/${widget.liveController.roomId}';
    PageUtils.showVideoBottomSheet(
      context,
      isFullScreen: () => isFullScreen,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
          child: Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              ComBtn(
                height: 30,
                tooltip: '发弹幕',
                autofocus: true,
                icon: const Icon(
                  size: 18,
                  Icons.comment_outlined,
                  color: Colors.white,
                ),
                onTap: widget.onSendDanmaku,
              ),
              Obx(
                () {
                  final onlyPlayAudio = plPlayerController.onlyPlayAudio.value;
                  return ComBtn(
                    height: 30,
                    tooltip: '仅播放音频',
                    onTap: () {
                      plPlayerController.onlyPlayAudio.value = !onlyPlayAudio;
                      widget.onPlayAudio();
                    },
                    icon: onlyPlayAudio
                        ? const Icon(
                            size: 18,
                            MdiIcons.musicCircle,
                            color: Colors.white,
                          )
                        : const Icon(
                            size: 18,
                            MdiIcons.musicCircleOutline,
                            color: Colors.white,
                          ),
                  );
                },
              ),
              if (Platform.isAndroid || (Utils.isDesktop && !isFullScreen))
                ComBtn(
                  height: 30,
                  tooltip: '画中画',
                  onTap: () async {
                    if (Utils.isDesktop) {
                      plPlayerController.toggleDesktopPip();
                      return;
                    }
                    if (await Floating().isPipAvailable) {
                      plPlayerController
                        ..showControls.value = false
                        ..enterPip();
                    }
                  },
                  icon: const Icon(
                    size: 18,
                    Icons.picture_in_picture_outlined,
                    color: Colors.white,
                  ),
                ),
              ComBtn(
                height: 30,
                tooltip: '定时关闭',
                onTap: () => PageUtils.scheduleExit(context, isFullScreen, true),
                icon: const Icon(
                  size: 18,
                  Icons.schedule,
                  color: Colors.white,
                ),
              ),
              ComBtn(
                height: 30,
                tooltip: '播放信息',
                onTap: () => HeaderControlState.showPlayerInfo(
                  context,
                  plPlayerController: plPlayerController,
                ),
                icon: const Icon(
                  size: 18,
                  Icons.info_outline,
                  color: Colors.white,
                ),
              ),
              ComBtn(
                height: 30,
                tooltip: '复制链接',
                onTap: () => Utils.copyText(liveUrl),
                icon: const Icon(
                  size: 18,
                  Icons.copy,
                  color: Colors.white,
                ),
              ),
              if (Utils.isMobile)
                ComBtn(
                  height: 30,
                  tooltip: '分享直播间',
                  onTap: () => Utils.shareText(liveUrl),
                  icon: const Icon(
                    size: 18,
                    Icons.share,
                    color: Colors.white,
                  ),
                ),
              ComBtn(
                height: 30,
                tooltip: '浏览器打开',
                onTap: () => PageUtils.inAppWebview(liveUrl, off: true),
                icon: const Icon(
                  size: 18,
                  Icons.open_in_browser,
                  color: Colors.white,
                ),
              ),
              if (widget.liveController.roomInfoH5.value != null)
                ComBtn(
                  height: 30,
                  tooltip: '分享至消息',
                  onTap: () {
                    try {
                      RoomInfoH5Data roomInfo =
                          widget.liveController.roomInfoH5.value!;
                      PageUtils.pmShare(
                        context,
                        content: {
                          "cover": roomInfo.roomInfo!.cover!,
                          "sourceID": widget.liveController.roomId.toString(),
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
                  icon: const Icon(
                    size: 18,
                    Icons.forward_to_inbox,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  late final plPlayerController = widget.plPlayerController;

  @override
  bool get horizontalScreen => true;

  @override
  bool get isFullScreen => plPlayerController.isFullScreen.value;

  @override
  bool get isPortrait => widget.isPortrait;

  @override
  Widget build(BuildContext context) {
    final isFullScreen = this.isFullScreen;
    showCurrTimeIfNeeded(isFullScreen);
    final liveController = widget.liveController;
    Widget child;
    child = Obx(
      () => MarqueeText(
        liveController.title.value,
        spacing: 30,
        velocity: 30,
        style: const TextStyle(
          fontSize: 15,
          height: 1,
          color: Colors.white,
        ),
      ),
    );
    if (isFullScreen) {
      child = Column(
        spacing: 5,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          Row(
            spacing: 10,
            children: [
              if (widget.upName case final upName?)
                Text(
                  upName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              liveController.watchedWidget,
              liveController.onlineWidget,
              liveController.timeWidget,
            ],
          ),
        ],
      );
    }
    child = Expanded(child: child);
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      primary: false,
      automaticallyImplyLeading: false,
      titleSpacing: 14,
      title: Row(
        children: [
          if (isFullScreen || plPlayerController.isDesktopPip)
            ComBtn(
              height: 30,
              tooltip: '返回',
              icon: const Icon(FontAwesomeIcons.arrowLeft, size: 15),
              onTap: () {
                if (plPlayerController.isDesktopPip) {
                  plPlayerController.exitDesktopPip();
                } else {
                  plPlayerController.triggerFullScreen(status: false);
                }
              },
            ),
          child,
          ...?timeBatteryWidgets,
          const SizedBox(width: 10),
          ComBtn(
            height: 30,
            tooltip: '更多',
            onTap: showSettingSheet,
            icon: const Icon(
              Icons.more_vert_outlined,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
