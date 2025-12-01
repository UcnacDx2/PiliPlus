import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:piliplus/plugin/pl_player/controller.dart';
import 'package:piliplus/services/tv_menu/menu_provider.dart';
import 'package:piliplus/services/tv_menu/models/menu_item.dart';
import 'package:piliplus/widgets/dialogs.dart';

class VideoMenuProvider implements MenuProvider {
  @override
  String get sceneName => 'video';

  @override
  bool canHandle(BuildContext context) {
    return Get.isRegistered<PlPlayerController>() && PlPlayerController.instance != null;
  }

  @override
  List<MenuItem> getMenuItems(BuildContext context) {
    final player = PlPlayerController.instance!;
    return [
      MenuItem(
        label: player.isPlaying.value ? 'Pause' : 'Play',
        icon: player.isPlaying.value ? Icons.pause : Icons.play_arrow,
        onTap: () => player.onDoubleTapCenter(),
      ),
      MenuItem(
        label: 'Playback Speed: ${player.playbackSpeed}x',
        icon: Icons.speed,
        onTap: () => Dialogs.playbackSpeed(context, player),
      ),
      MenuItem(
        label: 'Danmaku: ${player.enableShowDanmaku.value ? "On" : "Off"}',
        icon: Icons.subtitles,
        onTap: () => player.enableShowDanmaku.value = !player.enableShowDanmaku.value,
      ),
      MenuItem(
        label: 'Toggle Fullscreen',
        icon: Icons.fullscreen,
        onTap: () => player.triggerFullScreen(status: !player.isFullScreen.value),
      ),
    ];
  }
}
