import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pili_plus/plugin/pl_player/controller.dart';
import 'package:pili_plus/services/tv_menu/menu_provider.dart';
import 'package:pili_plus/services/tv_menu/models/menu_item.dart';
import 'package:pili_plus/services/tv_menu/tv_menu_service.dart';

class VideoMenuProvider implements MenuProvider {
  @override
  String get sceneName => 'video';

  @override
  List<MenuItem> getMenuItems(BuildContext context) {
    final player = PlPlayerController.instance!;
    return [
      MenuItem(
        title: Obx(() => Text(player.playerStatus.playing ? 'Pause' : 'Play')),
        icon: Icons.play_arrow,
        onTap: () {
          player.onDoubleTapCenter();
          TVMenuService.to.hideMenu();
        },
      ),
      MenuItem(
        title: Obx(() => Text('Speed: ${player.playbackSpeed}x')),
        icon: Icons.speed,
        onTap: () {
          // TODO: Implement speed dialog
          TVMenuService.to.hideMenu();
        },
      ),
      MenuItem(
        title: Obx(() =>
            Text('Danmaku: ${player.enableShowDanmaku.value ? "On" : "Off"}')),
        icon: Icons.subtitles,
        onTap: () {
          player.enableShowDanmaku.value = !player.enableShowDanmaku.value;
          TVMenuService.to.hideMenu();
        },
      ),
    ];
  }

  @override
  bool canHandle(BuildContext context) {
    return Get.isRegistered<PlPlayerController>();
  }
}
