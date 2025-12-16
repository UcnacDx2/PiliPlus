import 'dart:io';

import 'package:PiliPlus/common/widgets/marquee.dart';
import 'package:PiliPlus/pages/live_room/controller.dart';
import 'package:PiliPlus/pages/video/widgets/header_control.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/common_btn.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:floating/floating.dart';
import 'package:flutter/material.dart';
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
  State<LiveHeaderControl> createState() => _LiveHeaderControlState();
}

class _LiveHeaderControlState extends State<LiveHeaderControl>
    with TimeBatteryMixin {
  final GlobalKey _menuKey = GlobalKey();

  void showMenu() {
    final PopupMenuButtonState? menuButtonState =
        _menuKey.currentState as PopupMenuButtonState?;
    menuButtonState?.showButtonMenu();
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
        key: titleKey,
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
          _moreBtn(),
        ],
      ),
    );
  }

  Widget _moreBtn() {
    return PopupMenuButton(
      key: _menuKey,
      icon: const Icon(
        Icons.more_vert,
        color: Colors.white,
        size: 18,
      ),
      tooltip: '更多选项',
      itemBuilder: (BuildContext context) => <PopupMenuEntry>[
        PopupMenuItem(
          onTap: widget.onSendDanmaku,
          child: const Text('发弹幕'),
        ),
        PopupMenuItem(
          onTap: () {
            plPlayerController.onlyPlayAudio.value =
                !plPlayerController.onlyPlayAudio.value;
            widget.onPlayAudio();
          },
          child: Obx(
            () => Text(
              plPlayerController.onlyPlayAudio.value ? '关闭仅音频' : '仅播放音频',
            ),
          ),
        ),
        if (Platform.isAndroid || (Utils.isDesktop && !isFullScreen))
          PopupMenuItem(
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
            child: const Text('画中画'),
          ),
        PopupMenuItem(
          onTap: () => PageUtils.scheduleExit(context, isFullScreen, true),
          child: const Text('定时关闭'),
        ),
        PopupMenuItem(
          onTap: () => HeaderControlState.showPlayerInfo(
            context,
            plPlayerController: plPlayerController,
          ),
          child: const Text('播放信息'),
        ),
      ],
    );
  }
}
