import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_status.dart';
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
    final isPlaying = player.playerStatus.value == PlayerStatus.playing;

    return [
      MenuItem(
        label: isPlaying ? 'Pause' : 'Play',
        icon: isPlaying ? Icons.pause : Icons.play_arrow,
        onTap: () => player.onDoubleTapCenter(),
      ),
      MenuItem(
        label: player.isFullScreen.value ? 'Exit Fullscreen' : 'Fullscreen',
        icon: player.isFullScreen.value ? Icons.fullscreen_exit : Icons.fullscreen,
        onTap: () => player.triggerFullScreen(status: !player.isFullScreen.value),
      ),
      MenuItem(
        label: 'Danmaku: ${player.enableShowDanmaku.value ? "On" : "Off"}',
        icon: player.enableShowDanmaku.value ? Icons.subtitles : Icons.subtitles_off,
        onTap: () => player.enableShowDanmaku.value = !player.enableShowDanmaku.value,
      ),
      MenuItem(
        label: 'Speed: ${player.playbackSpeed}x',
        icon: Icons.speed,
        onTap: () {
          // TODO: Implement speed selection dialog
        },
      ),
      MenuItem(
        label: 'Quality',
        icon: Icons.high_quality,
        onTap: () {
          // TODO: Implement quality selection dialog
        },
      ),
      MenuItem(
        label: 'Subtitles',
        icon: Icons.closed_caption,
        onTap: () {
          // TODO: Implement subtitle selection dialog
        },
      ),
    ];
  }
}
