import 'package:PiliPlus/common/widgets/custom_icon.dart';
import 'package:PiliPlus/pages/live_room/controller.dart';
import 'package:PiliPlus/pages/video/widgets/header_control.dart'
    show HeaderMixin;
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/video_fit_type.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/common_btn.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/play_pause_btn.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class BottomControl extends StatefulWidget {
  const BottomControl({
    super.key,
    required this.plPlayerController,
    required this.liveRoomCtr,
    required this.onRefresh,
    this.subTitleStyle = const TextStyle(fontSize: 12),
    this.titleStyle = const TextStyle(fontSize: 14),
  });

  final PlPlayerController plPlayerController;
  final LiveRoomController liveRoomCtr;
  final VoidCallback onRefresh;

  final TextStyle subTitleStyle;
  final TextStyle titleStyle;

  @override
  State<BottomControl> createState() => _BottomControlState();
}

class _BottomControlState extends State<BottomControl> with HeaderMixin {
  late final LiveRoomController liveRoomCtr = widget.liveRoomCtr;
  @override
  late final PlPlayerController plPlayerController = widget.plPlayerController;

  @override
  Widget build(BuildContext context) {
    final isFullScreen = plPlayerController.isFullScreen.value;
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      primary: false,
      automaticallyImplyLeading: false,
      titleSpacing: 14,
      title: Row(
        children: [
          PlayOrPauseButton(plPlayerController: plPlayerController),
          ComBtn(
            height: 30,
            tooltip: '刷新',
            icon: const Icon(
              Icons.refresh,
              size: 18,
              color: Colors.white,
            ),
            onTap: widget.onRefresh,
          ),
          const Spacer(),
          if (!plPlayerController.isDesktopPip)
            ComBtn(
              height: 30,
              tooltip: isFullScreen ? '退出全屏' : '全屏',
              icon: isFullScreen
                  ? const Icon(
                      Icons.fullscreen_exit,
                      size: 24,
                      color: Colors.white,
                    )
                  : const Icon(
                      Icons.fullscreen,
                      size: 24,
                      color: Colors.white,
                    ),
              onTap: () =>
                  plPlayerController.triggerFullScreen(status: !isFullScreen),
              onSecondaryTap: () => plPlayerController.triggerFullScreen(
                status: !isFullScreen,
                inAppFullScreen: true,
              ),
            ),
        ],
      ),
    );
  }
}
