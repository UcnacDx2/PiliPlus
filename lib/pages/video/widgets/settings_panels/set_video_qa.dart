import 'package:PiliPlus/models/common/video/video_quality.dart';
import 'package:PiliPlus/models/video/play/url.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class SetVideoQaPanel extends StatelessWidget {
  const SetVideoQaPanel({
    super.key,
    required this.videoDetailCtr,
    required this.plPlayerController,
  });

  final VideoDetailController videoDetailCtr;
  final PlPlayerController plPlayerController;

  @override
  Widget build(BuildContext context) {
    final VideoQuality? currentVideoQa = videoDetailCtr.currentVideoQa.value;
    if (currentVideoQa == null) return const SizedBox.shrink();

    final List<FormatItem> videoFormat = videoDetailCtr.data.supportFormats!;
    final int totalQaSam = videoFormat.length;
    int userfulQaSam = 0;
    final List<VideoItem> video = videoDetailCtr.data.dash!.video!;
    final Set<int> idSet = {};
    for (final VideoItem item in video) {
      final int id = item.id!;
      if (!idSet.contains(id)) {
        idSet.add(id);
        userfulQaSam++;
      }
    }

    final theme = Theme.of(context);
    const titleStyle = TextStyle(fontSize: 14);
    const subTitleStyle = TextStyle(fontSize: 12);

    return Material(
      clipBehavior: Clip.hardEdge,
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 45,
              child: GestureDetector(
                onTap: () => SmartDialog.showToast(
                  '标灰画质需要bilibili会员（已是会员？请关闭无痕模式）；4k和杜比视界播放效果可能不佳',
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('选择画质', style: titleStyle),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.outline,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: totalQaSam,
            itemBuilder: (context, index) {
              final item = videoFormat[index];
              final isCurr = currentVideoQa.code == item.quality;
              return ListTile(
                dense: true,
                onTap: () async {
                  if (isCurr) {
                    return;
                  }
                  Get.back();
                  final int quality = item.quality!;
                  final newQa = VideoQuality.fromCode(quality);
                  videoDetailCtr
                    ..plPlayerController.cacheVideoQa = newQa.code
                    ..currentVideoQa.value = newQa
                    ..updatePlayer();

                  SmartDialog.showToast("画质已变为：${newQa.desc}");

                  if (!plPlayerController.tempPlayerConf) {
                    GStorage.setting.put(
                      await Utils.isWiFi
                          ? SettingBoxKey.defaultVideoQa
                          : SettingBoxKey.defaultVideoQaCellular,
                      quality,
                    );
                  }
                },
                enabled: index >= totalQaSam - userfulQaSam,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                title: Text(item.newDesc!),
                trailing: isCurr
                    ? Icon(
                        Icons.done,
                        color: theme.colorScheme.primary,
                      )
                    : Text(
                        item.format!,
                        style: subTitleStyle,
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}
