import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/services/tv_menu/menu_provider.dart';
import 'package:PiliPlus/services/tv_menu/models/menu_item.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

/// Menu provider for video playback scene
class VideoMenuProvider implements MenuProvider {
  @override
  String get sceneName => 'Video Playback';

  @override
  int get priority => 100; // High priority for video playback

  @override
  bool canHandle(BuildContext context) {
    return PlPlayerController.instance != null;
  }

  @override
  List<TvMenuItem> getMenuItems(BuildContext context) {
    final player = PlPlayerController.instance;
    if (player == null) return [];

    return [
      // Play/Pause
      TvMenuItem(
        label: player.playerStatus.value.playing ? '暂停' : '播放',
        icon: player.playerStatus.value.playing ? Icons.pause : Icons.play_arrow,
        onTap: () => player.onDoubleTapCenter(),
      ),

      // Playback speed
      TvMenuItem(
        label: '倍速: ${player.playbackSpeed}x',
        icon: Icons.speed,
        children: player.speedList
            .map(
              (speed) => TvMenuItem(
                label: '${speed}x',
                onTap: () {
                  player.setPlaybackSpeed(speed);
                  SmartDialog.showToast('已切换至${speed}x倍速');
                },
              ),
            )
            .toList(),
      ),

      // Danmaku toggle
      TvMenuItem(
        label: '弹幕: ${player.enableShowDanmaku.value ? "开" : "关"}',
        icon: player.enableShowDanmaku.value
            ? Icons.subtitles
            : Icons.subtitles_off_outlined,
        onTap: () {
          final newVal = !player.enableShowDanmaku.value;
          player.enableShowDanmaku.value = newVal;
          if (!player.tempPlayerConf) {
            GStorage.setting.put(
              player.isLive
                  ? SettingBoxKey.enableShowLiveDanmaku
                  : SettingBoxKey.enableShowDanmaku,
              newVal,
            );
          }
          SmartDialog.showToast('弹幕已${newVal ? "开启" : "关闭"}');
        },
      ),

      // Fullscreen toggle
      TvMenuItem(
        label: player.isFullScreen.value ? '退出全屏' : '全屏',
        icon: player.isFullScreen.value
            ? Icons.fullscreen_exit
            : Icons.fullscreen,
        onTap: () => player.triggerFullScreen(
          status: !player.isFullScreen.value,
        ),
      ),

      // Lock controls (fullscreen only)
      if (player.isFullScreen.value)
        TvMenuItem(
          label: player.controlsLock.value ? '解锁' : '锁定',
          icon: player.controlsLock.value ? Icons.lock_open : Icons.lock,
          onTap: () => player.onLockControl(!player.controlsLock.value),
        ),

      // Mute toggle
      TvMenuItem(
        label: player.isMuted ? '取消静音' : '静音',
        icon: player.isMuted ? Icons.volume_off : Icons.volume_up,
        onTap: () {
          final isMuted = !player.isMuted;
          player.videoPlayerController?.setVolume(
            isMuted ? 0 : player.volume.value * 100,
          );
          player.isMuted = isMuted;
          SmartDialog.showToast('${isMuted ? '' : '取消'}静音');
        },
      ),

      // Background playback toggle
      TvMenuItem(
        label: '后台播放: ${player.continuePlayInBackground.value ? "开" : "关"}',
        icon: Icons.picture_in_picture_alt,
        onTap: () {
          player.setContinuePlayInBackground();
          SmartDialog.showToast(
            '后台播放已${player.continuePlayInBackground.value ? "开启" : "关闭"}',
          );
        },
      ),
    ];
  }
}
