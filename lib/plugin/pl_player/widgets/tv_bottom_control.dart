import 'package:PiliPlus/plugin/pl_player/models/bottom_control_type.dart';
import 'package:PiliPlus/plugin/pl_player/tv_controller.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/common_btn.dart';
import 'package:PiliPlus/models/common/video/video_quality.dart';
import 'package:PiliPlus/models/video/play/url.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/play_pause_btn.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'dart:ui';
import 'package:PiliPlus/models/common/super_resolution_type.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:math' as math;
import 'package:PiliPlus/models_new/video/video_detail/episode.dart' as ugc;
import 'package:PiliPlus/models_new/video/video_detail/section.dart';
import 'package:PiliPlus/models_new/video/video_detail/episode.dart';
import 'package:PiliPlus/models_new/video/video_detail/ugc_season.dart';
import 'package:PiliPlus/utils/id_utils.dart';
import 'package:PiliPlus/pages/video/introduction/pgc/controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/video_fit_type.dart';
import 'package:PiliPlus/pages/common/common_intro_controller.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/controller.dart';
import 'package:PiliPlus/pages/video/introduction/local/controller.dart';

class TvBottomControl extends StatelessWidget {
  const TvBottomControl({super.key, required this.controller});

  final TvPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final VideoDetailController videoDetailController = Get.find();
    final CommonIntroController introController = videoDetailController.introController;
    final videoDetail = introController.videoDetail.value;
    final isSeason = videoDetail.ugcSeason != null;
    final isPart = videoDetail.pages != null && videoDetail.pages!.length > 1;
    final isPgc = !videoDetailController.isUgc;
    final isPlayAll = videoDetailController.isPlayAll;
    final anySeason = isSeason || isPart || isPgc || isPlayAll;
    final isFullScreen = controller.isFullScreen.value;
    final flag = isFullScreen || controller.isDesktopPip || MediaQuery.of(context).size.width >= 500;

    Widget progressWidget(
      BottomControlType bottomControl,
    ) =>
        FocusableActionDetector(
          child:
              _buildProgressWidget(bottomControl, videoDetailController, true, introController),
        );

    final isNotFileSource = !controller.plPlayerController.isFileSource;

    List<BottomControlType> userSpecifyItemRight = [
      if (isNotFileSource && controller.plPlayerController.showDmChart)
        BottomControlType.dmChart,
      if (controller.plPlayerController.isAnim)
        BottomControlType.superResolution,
      if (isNotFileSource && controller.plPlayerController.showViewPoints)
        BottomControlType.viewPoints,
      if (isNotFileSource && anySeason) BottomControlType.episode,
      if (flag) BottomControlType.fit,
      if (isNotFileSource) BottomControlType.aiTranslate,
      BottomControlType.subtitle,
      BottomControlType.speed,
      if (isNotFileSource && flag) BottomControlType.qa,
    ];

    return Focus(
      focusNode: controller.focusNodeC,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: userSpecifyItemRight.map(progressWidget).toList(),
        ),
      ),
    );
  }

  Widget _buildProgressWidget(
    BottomControlType bottomControl,
    VideoDetailController videoDetailController,
    bool isLandscape,
    CommonIntroController introController,
  ) {
    // This logic is adapted from PLVideoPlayerState.buildBottomControl
    final videoDetail = introController.videoDetail.value;
    final isSeason = videoDetail.ugcSeason != null;
    final isPart = videoDetail.pages != null && videoDetail.pages!.length > 1;
    final isPgc = !videoDetailController.isUgc;
    final isPlayAll = videoDetailController.isPlayAll;
    final anySeason = isSeason || isPart || isPgc || isPlayAll;
    final isFullScreen = controller.isFullScreen.value;
    final double widgetWidth = isLandscape && isFullScreen ? 42 : 35;

    switch (bottomControl) {
      case BottomControlType.playOrPause:
        return PlayOrPauseButton(
          plPlayerController: controller.plPlayerController,
        );
      case BottomControlType.qa:
        return _buildQaButton();
      case BottomControlType.speed:
        return _buildSpeedButton();
      case BottomControlType.subtitle:
        return _buildSubtitleButton(videoDetailController);
      case BottomControlType.episode:
        return ComBtn(
          width: widgetWidth,
          height: 30,
          tooltip: '选集',
          icon: const Icon(
            Icons.list,
            size: 22,
            color: Colors.white,
          ),
          onTap: () {
            // TODO
          },
        );
      case BottomControlType.fit:
        return Obx(
          () => PopupMenuButton<VideoFitType>(
            tooltip: '画面比例',
            requestFocus: false,
            initialValue: controller.plPlayerController.videoFit.value,
            color: Colors.black.withValues(alpha: 0.8),
            itemBuilder: (context) {
              return VideoFitType.values
                  .map(
                    (boxFit) => PopupMenuItem<VideoFitType>(
                      height: 35,
                      padding: const EdgeInsets.only(left: 30),
                      value: boxFit,
                      onTap: () => controller.plPlayerController.toggleVideoFit(boxFit),
                      child: Text(
                        boxFit.desc,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  )
                  .toList();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                controller.plPlayerController.videoFit.value.desc,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQaButton() {
    return Obx(
      () {
        final VideoDetailController videoDetailController = Get.find();
        final VideoQuality? currentVideoQa =
            videoDetailController.currentVideoQa.value;
        if (currentVideoQa == null) {
          return const SizedBox.shrink();
        }
        final PlayUrlModel videoInfo = videoDetailController.data;
        if (videoInfo.dash == null) {
          return const SizedBox.shrink();
        }
        final List<FormatItem> videoFormat = videoInfo.supportFormats!;
        final int totalQaSam = videoFormat.length;
        int userfulQaSam = 0;
        final List<VideoItem> video = videoInfo.dash!.video!;
        final Set<int> idSet = {};
        for (final VideoItem item in video) {
          final int id = item.id!;
          if (!idSet.contains(id)) {
            idSet.add(id);
            userfulQaSam++;
          }
        }
        return PopupMenuButton<int>(
          tooltip: '画质',
          initialValue: currentVideoQa.code,
          color: Colors.black.withValues(alpha: 0.8),
          itemBuilder: (context) {
            return List.generate(
              totalQaSam,
              (index) {
                final item = videoFormat[index];
                final enabled = index >= totalQaSam - userfulQaSam;
                return PopupMenuItem<int>(
                  enabled: enabled,
                  height: 35,
                  padding: const EdgeInsets.only(left: 15, right: 10),
                  value: item.quality,
                  onTap: () async {
                    if (currentVideoQa.code == item.quality) {
                      return;
                    }
                    final int quality = item.quality!;
                    final newQa = VideoQuality.fromCode(quality);
                    videoDetailController
                      ..cacheVideoQa = newQa.code
                      ..currentVideoQa.value = newQa
                      ..updatePlayer();

                    SmartDialog.showToast("画质已变为：${newQa.desc}");

                    if (!controller.tempPlayerConf) {
                      GStorage.setting.put(
                        await Utils.isWiFi
                            ? SettingBoxKey.defaultVideoQa
                            : SettingBoxKey.defaultVideoQaCellular,
                        quality,
                      );
                    }
                  },
                  child: Text(
                    item.newDesc ?? '',
                    style: enabled
                        ? const TextStyle(color: Colors.white, fontSize: 13)
                        : const TextStyle(
                            color: Color(0x62FFFFFF),
                            fontSize: 13,
                          ),
                  ),
                );
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              currentVideoQa.shortDesc,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpeedButton() {
    return Obx(
      () => PopupMenuButton<double>(
        tooltip: '倍速',
        initialValue: controller.playbackSpeed,
        color: Colors.black.withValues(alpha: 0.8),
        itemBuilder: (context) {
          return controller.speedList
              .map(
                (double speed) => PopupMenuItem<double>(
                  height: 35,
                  padding: const EdgeInsets.only(left: 30),
                  value: speed,
                  onTap: () => controller.setPlaybackSpeed(speed),
                  child: Text(
                    "${speed}X",
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    semanticsLabel: "$speed倍速",
                  ),
                ),
              )
              .toList();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            "${controller.playbackSpeed}X",
            style: const TextStyle(color: Colors.white, fontSize: 13),
            semanticsLabel: "${controller.playbackSpeed}倍速",
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitleButton(VideoDetailController videoDetailController) {
    return Obx(
      () => videoDetailController.subtitles.isEmpty
          ? const SizedBox.shrink()
          : PopupMenuButton<int>(
              tooltip: '字幕',
              initialValue:
                  videoDetailController.vttSubtitlesIndex.value.clamp(
                0,
                videoDetailController.subtitles.length,
              ),
              color: Colors.black.withValues(alpha: 0.8),
              itemBuilder: (context) {
                return [
                  PopupMenuItem<int>(
                    value: 0,
                    height: 35,
                    onTap: () => videoDetailController.setSubtitle(0),
                    child: const Text(
                      "关闭字幕",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  ...videoDetailController.subtitles.indexed.map((e) {
                    return PopupMenuItem<int>(
                      value: e.$1 + 1,
                      height: 35,
                      onTap: () => videoDetailController.setSubtitle(e.$1 + 1),
                      child: Text(
                        e.$2.lanDoc!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }),
                ];
              },
              child: SizedBox(
                width: 42,
                height: 30,
                child: videoDetailController.vttSubtitlesIndex.value == 0
                    ? const Icon(
                        Icons.closed_caption_off_outlined,
                        size: 22,
                        color: Colors.white,
                      )
                    : const Icon(
                        Icons.closed_caption_off_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
              ),
            ),
    );
  }
}
