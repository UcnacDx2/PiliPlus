import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_status.dart';
import 'package:PiliPlus/services/tv_menu/menu_builder.dart';
import 'package:PiliPlus/services/tv_menu/menu_provider.dart';
import 'package:PiliPlus/services/tv_menu/models/menu_item.dart';
import 'package:PiliPlus/services/tv_menu/tv_menu_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class VideoMenuProvider implements MenuProvider {
  @override
  String get sceneName => 'video';

  @override
  List<MenuItem> getMenuItems(BuildContext context) {
    final player = PlPlayerController.instance!;

    return MenuBuilder()
        .addItem(
          player.playerStatus.value == PlayerStatus.playing ? '暂停' : '播放',
          player.playerStatus.value == PlayerStatus.playing ? Icons.pause : Icons.play_arrow,
          () {
            player.onDoubleTapCenter();
            TVMenuService.instance.hideMenu();
          }
        )
        .addItem(
          '倍速: ${player.playbackSpeed}x',
          Icons.speed,
          () => _showSpeedDialog(context, player),
        )
        .addItem(
          '弹幕: ${player.enableShowDanmaku.value ? "开" : "关"}',
          Icons.subtitles,
          () {
            player.enableShowDanmaku.value = !player.enableShowDanmaku.value;
            TVMenuService.instance.hideMenu();
          },
        )
        .addItem(
            '全屏',
            player.isFullScreen.value
                ? Icons.fullscreen_exit
                : Icons.fullscreen,
            () {
              player.triggerFullScreen(status: !player.isFullScreen.value);
              TVMenuService.instance.hideMenu();
            })
        .build();
  }

  void _showSpeedDialog(BuildContext context, PlPlayerController player) {
    TVMenuService.instance.hideMenu(); // Hide the main menu
    SmartDialog.show(
      builder: (_) {
        return Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('选择倍速', style: TextStyle(color: Colors.white, fontSize: 18)),
                  SizedBox(height: 16),
                  ...player.speedList.map((speed) => TextButton(
                        onPressed: () {
                          player.setPlaybackSpeed(speed);
                          SmartDialog.dismiss();
                        },
                        child: Text('${speed}x', style: TextStyle(color: Colors.white, fontSize: 16)),
                      )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  bool canHandle(BuildContext context) {
    final instance = PlPlayerController.instance;
    return instance != null && instance.videoPlayerController != null;
  }
}
