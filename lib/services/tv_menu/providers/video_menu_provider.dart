import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:flutter/material.dart';
import 'package:PiliPlus/services/tv_menu/menu_provider.dart';
import 'package:PiliPlus/services/tv_menu/models/menu_item.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class VideoMenuProvider implements MenuProvider {
  @override
  String get sceneName => 'video';

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
        label: 'Speed: ${player.playbackSpeed}x',
        icon: Icons.speed,
        onTap: () => _showSpeedDialog(context),
      ),
      MenuItem(
        label: 'Danmaku: ${player.enableShowDanmaku.value ? "On" : "Off"}',
        icon: Icons.subtitles,
        onTap: () =>
            player.enableShowDanmaku.value = !player.enableShowDanmaku.value,
      ),
    ];
  }

  void _showSpeedDialog(BuildContext context) {
    final speeds = [0.5, 1.0, 1.5, 2.0];
    SmartDialog.show(
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: speeds.length,
                itemBuilder: (context, index) {
                  final speed = speeds[index];
                  return InkWell(
                    autofocus: PlPlayerController.instance!.playbackSpeed == speed,
                    onTap: () {
                      PlPlayerController.instance!.setPlaybackSpeed(speed);
                      SmartDialog.dismiss();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 16.0),
                      child: Text(
                        '${speed}x',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  bool canHandle(BuildContext context) {
    return PlPlayerController.instance != null;
  }
}
