import 'package:PiliPlus/common/widgets/custom_icon.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/pages/common/common_intro_controller.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class TvPopupMenu extends StatefulWidget {
  final dynamic focusData;
  final String contextType;

  const TvPopupMenu({
    required this.focusData,
    required this.contextType,
    super.key,
  });

  @override
  State<TvPopupMenu> createState() => _TvPopupMenuState();
}

class _TvPopupMenuState extends State<TvPopupMenu> {
  List<Widget> _buildMenuItems() {
    switch (widget.contextType) {
      case 'videoCard':
        return _buildVideoCardMenu();
      case 'videoPlayer':
        return _buildVideoPlayerMenu();
      default:
        return [
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('退出'),
            onTap: () => SystemNavigator.pop(),
          )
        ];
    }
  }

  List<Widget> _buildVideoCardMenu() {
    final videoItem = widget.focusData as BaseRecVideoItemModel;
    final UgcIntroController introController = Get.find<UgcIntroController>();
    return [
      ListTile(
        leading: const Icon(Icons.play_arrow_outlined),
        title: const Text('立即播放'),
        onTap: () {
          Get.back();
          PageUtils.toVideoPage(
            bvid: videoItem.bvid,
            cid: videoItem.cid,
            aid: videoItem.aid,
            cover: videoItem.cover,
            title: videoItem.title,
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.watch_later_outlined),
        title: const Text('稍后再看'),
        onTap: () {
          Get.back();
          introController.viewLater(
              bvid: videoItem.bvid, aid: videoItem.aid!);
        },
      ),
    ];
  }

  List<Widget> _buildVideoPlayerMenu() {
    final plPlayerController = widget.focusData as PlPlayerController;
    final introController = Get.find<CommonIntroController>();
    return [
      ListTile(
        leading: const Icon(Icons.speed_outlined),
        title: const Text('倍速播放'),
        onTap: () {
          Get.back();
          // Simple cycle for playback speed
          final currentSpeed = plPlayerController.playbackSpeed;
          double newSpeed = 1.0;
          if (currentSpeed == 1.0) {
            newSpeed = 1.5;
          } else if (currentSpeed == 1.5) {
            newSpeed = 2.0;
          } else if (currentSpeed == 2.0) {
            newSpeed = 0.5;
          } else {
            newSpeed = 1.0;
          }
          plPlayerController.setPlaybackSpeed(newSpeed);
          SmartDialog.showToast('${newSpeed}x');
        },
      ),
      ListTile(
        leading: const Icon(Icons.repeat),
        title: const Text('播放顺序'),
        onTap: () {
          Get.back();
          plPlayerController.setPlayRepeat(
              plPlayerController.playRepeat.next);
        },
      ),
      ListTile(
        leading: plPlayerController.enableShowDanmaku.value
            ? const Icon(CustomIcons.dm_on)
            : const Icon(CustomIcons.dm_off),
        title: Text(
            '${plPlayerController.enableShowDanmaku.value ? "关闭" : "显示"}弹幕'),
        onTap: () {
          Get.back();
          plPlayerController.enableShowDanmaku.value =
              !plPlayerController.enableShowDanmaku.value;
        },
      ),
      ListTile(
        leading: const Icon(Icons.watch_later_outlined),
        title: const Text('稍后再看'),
        onTap: () {
          Get.back();
          introController.viewLater();
        },
      ),
      ListTile(
        leading: const Icon(Icons.refresh_outlined),
        title: const Text('重载视频'),
        onTap: () {
          Get.back();
          Get.find<VideoDetailController>()
              .queryVideoUrl(fromReset: true);
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: Material(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: SizedBox(
          width: 250, // Set a fixed width for the menu
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 14),
            children: _buildMenuItems(),
          ),
        ),
      ),
    );
  }
}
