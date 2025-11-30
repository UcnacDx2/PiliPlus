import 'package:PiliPlus/models/common/video/audio_quality.dart';
import 'package:PiliPlus/models/video/play/url.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class SetAudioQaPanel extends StatelessWidget {
  const SetAudioQaPanel({
    super.key,
    required this.videoDetailCtr,
    required this.plPlayerController,
  });

  final VideoDetailController videoDetailCtr;
  final PlPlayerController plPlayerController;

  @override
  Widget build(BuildContext context) {
    final AudioQuality currentAudioQa = videoDetailCtr.currentAudioQa!;
    final List<AudioItem> audio = videoDetailCtr.data.dash!.audio!;
    final theme = Theme.of(context);
    const titleStyle = TextStyle(fontSize: 14);
    const subTitleStyle = TextStyle(fontSize: 12);

    return Material(
      clipBehavior: Clip.hardEdge,
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 45,
              child: Center(
                child: Text('选择音质', style: titleStyle),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: audio.length,
            itemBuilder: (context, index) {
              final item = audio[index];
              final isCurr = currentAudioQa.code == item.id;
              return ListTile(
                dense: true,
                onTap: () async {
                  if (isCurr) {
                    return;
                  }
                  Get.back();
                  final int quality = item.id!;
                  final newQa = AudioQuality.fromCode(quality);
                  videoDetailCtr
                    ..plPlayerController.cacheAudioQa = newQa.code
                    ..currentAudioQa = newQa
                    ..updatePlayer();

                  SmartDialog.showToast("音质已变为：${newQa.desc}");

                  if (!plPlayerController.tempPlayerConf) {
                    GStorage.setting.put(
                      await Utils.isWiFi
                          ? SettingBoxKey.defaultAudioQa
                          : SettingBoxKey.defaultAudioQaCellular,
                      quality,
                    );
                  }
                },
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                title: Text(item.quality),
                subtitle: Text(
                  item.codecs!,
                  style: subTitleStyle,
                ),
                trailing: isCurr
                    ? Icon(
                        Icons.done,
                        color: theme.colorScheme.primary,
                      )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
