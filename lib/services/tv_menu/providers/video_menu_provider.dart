import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/services/tv_menu/menu_provider.dart';
import 'package:PiliPlus/services/tv_menu/models/menu_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VideoMenuProvider implements MenuProvider {
  @override
  String get sceneName => 'video';

  @override
  bool canHandle(BuildContext context) {
    // Check if the PlPlayerController instance exists, indicating a video is active.
    return PlPlayerController.instance != null;
  }

  @override
  List<MenuItem> getMenuItems(BuildContext context) {
    final player = PlPlayerController.instance!;

    return [
      MenuItem(
        label: player.playerStatus.playing ? 'Pause' : 'Play',
        icon: player.playerStatus.playing ? Icons.pause : Icons.play_arrow,
        onTap: () => player.onDoubleTapCenter(),
      ),
      MenuItem(
        label: 'Fullscreen',
        icon: player.isFullScreen.value ? Icons.fullscreen_exit : Icons.fullscreen,
        onTap: () => player.triggerFullScreen(status: !player.isFullScreen.value),
      ),
      MenuItem(
        label: 'Danmaku: ${player.enableShowDanmaku.value ? "On" : "Off"}',
        icon: player.enableShowDanmaku.value ? Icons.subtitles : Icons.subtitles_off,
        onTap: () => player.enableShowDanmaku.value = !player.enableShowDanmaku.value,
      ),
    ];
  }
}
