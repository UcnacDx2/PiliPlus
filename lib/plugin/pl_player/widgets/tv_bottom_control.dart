import 'package:PiliPlus/common/widgets/pair.dart';
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
  const TvBottomControl({
    super.key,
    required this.controller,
    required this.videoDetailController,
    required this.introController,
    this.showEpisodes,
    this.showViewPoints,
  });

  final TvPlayerController controller;
  final VideoDetailController videoDetailController;
  final CommonIntroController introController;
  final Function? showEpisodes;
  final VoidCallback? showViewPoints;

  @override
  Widget build(BuildContext context) {
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

    final isNotFileSource = !controller.isFileSource;

    List<BottomControlType> userSpecifyItemRight = [
      if (isNotFileSource && controller.showDmChart)
        BottomControlType.dmChart,
      if (controller.isAnim)
        BottomControlType.superResolution,
      if (isNotFileSource && controller.showViewPoints)
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
          plPlayerController: controller,
        );
      case BottomControlType.qa:
        return _buildQaButton(videoDetailController);
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
            if (videoDetailController.isFileSource) {
              // TODO
              return;
            }
            // part -> playAll -> season(pgc)
            if (isPlayAll && !isPart) {
              videoDetailController.showMediaListPanel(Get.context!);
              return;
            }
            int? index;
            int currentCid = controller.cid!;
            String bvid = controller.bvid;
            List<ugc.BaseEpisodeItem> episodes = [];
            if (isSeason) {
              final List<SectionItem> sections =
                  videoDetail.ugcSeason!.sections!;
              for (int i = 0; i < sections.length; i++) {
                final List<EpisodeItem> episodesList = sections[i].episodes!;
                for (int j = 0; j < episodesList.length; j++) {
                  if (episodesList[j].cid == controller.cid) {
                    index = i;
                    episodes = episodesList;
                    break;
                  }
                }
              }
            } else if (isPart) {
              episodes = videoDetail.pages!;
            } else if (isPgc) {
              episodes =
                  (introController as PgcIntroController).pgcItem.episodes!;
            }
            showEpisodes?.call(
              index,
              isSeason ? videoDetail.ugcSeason! : null,
              isSeason ? null : episodes,
              bvid,
              IdUtils.bv2av(bvid),
              isSeason && isPart
                  ? videoDetailController.seasonCid ?? currentCid
                  : currentCid,
            );
          },
        );
      case BottomControlType.fit:
        return Obx(
          () => _buildMenuButton(
            tooltip: '画面比例',
            label: controller.videoFit.value.desc,
            items: VideoFitType.values
                .map(
                  (fit) => Pair(
                    first: fit.desc,
                    second: () => controller.toggleVideoFit(fit),
                  ),
                )
                .toList(),
          ),
        );
      default:
        return const SizedBox.shrink();
      case BottomControlType.aiTranslate:
        return Obx(
          () {
            final list = videoDetailController.languages.value;
            if (list != null && list.isNotEmpty) {
              return _buildMenuButton(
                tooltip: '翻译',
                label: '翻译',
                items: [
                  Pair(
                    '关闭翻译',
                    () => videoDetailController.setLanguage(''),
                  ),
                  ...list.map(
                    (e) => Pair(
                      e.title!,
                      () => videoDetailController.setLanguage(e.lang!),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        );
      case BottomControlType.viewPoints:
        return Obx(
          () => videoDetailController.viewPointList.isEmpty
              ? const SizedBox.shrink()
              : ComBtn(
                  width: widgetWidth,
                  height: 30,
                  tooltip: '分段信息',
                  icon: Transform.rotate(
                    angle: math.pi / 2,
                    child: const Icon(
                      MdiIcons.viewHeadline,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                  onTap: showViewPoints,
                  onLongPress: () {
                    Feedback.forLongPress(Get.context!);
                    videoDetailController.showVP.value =
                        !videoDetailController.showVP.value;
                  },
                  onSecondaryTap: Utils.isMobile
                      ? null
                      : () => videoDetailController.showVP.value =
                            !videoDetailController.showVP.value,
                ),
        );
      case BottomControlType.superResolution:
        return Obx(
          () => _buildMenuButton(
            tooltip: '超分辨率',
            label: controller.superResolutionType.value.title,
            items: SuperResolutionType.values
                .map(
                  (type) => Pair(
                    first: type.title,
                    second: () => controller.setShader(type),
                  ),
                )
                .toList(),
          ),
        );

      case BottomControlType.dmChart:
        return Obx(
          () {
            final list = videoDetailController.dmTrend.value?.dataOrNull;
            if (list != null && list.isNotEmpty) {
              return ComBtn(
                width: widgetWidth,
                height: 30,
                tooltip: '高能进度条',
                icon: videoDetailController.showDmTrendChart.value
                    ? const Icon(
                        Icons.show_chart,
                        size: 22,
                        color: Colors.white,
                      )
                    : const Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.show_chart,
                            size: 22,
                            color: Colors.white,
                          ),
                          Icon(
                            Icons.hide_source,
                            size: 22,
                            color: Colors.white,
                          ),
                        ],
                      ),
                onTap: () => videoDetailController.showDmTrendChart.value =
                    !videoDetailController.showDmTrendChart.value,
              );
            }
            return const SizedBox.shrink();
          },
        );
    }
  }

  Widget _buildQaButton(VideoDetailController videoDetailController) {
    return Obx(() {
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
      return _buildMenuButton(
        tooltip: '画质',
        label: currentVideoQa.shortDesc,
        items: List.generate(
          totalQaSam,
          (index) {
            final item = videoFormat[index];
            final enabled = index >= totalQaSam - userfulQaSam;
            return Pair(
              first: item.newDesc ?? '',
              second: enabled
                  ? () async {
                      if (currentVideoQa.code == item.quality) {
                        return;
                      }
                      final int quality = item.quality!;
                      final newQa = VideoQuality.fromCode(quality);
                      controller.cacheVideoQa = newQa.code;
                      videoDetailController
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
                    }
                  : () {},
            );
          },
        ),
      );
    });
  }

  Widget _buildSpeedButton() {
    return Obx(
      () => _buildMenuButton(
        tooltip: '倍速',
        label: "${controller.playbackSpeed}X",
        items: controller.speedList
            .map(
              (speed) => Pair(
                first: "${speed}X",
                second: () => controller.setPlaybackSpeed(speed),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSubtitleButton(VideoDetailController videoDetailController) {
    return Obx(
      () => videoDetailController.subtitles.isEmpty
          ? const SizedBox.shrink()
          : _buildMenuButton(
              tooltip: '字幕',
              label: '字幕',
              items: [
                Pair(
                  '关闭字幕',
                  () => videoDetailController.setSubtitle(0),
                ),
                ...videoDetailController.subtitles.indexed.map(
                  (e) => Pair(
                    e.$2.lanDoc!,
                    () => videoDetailController.setSubtitle(e.$1 + 1),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMenuButton({
    required String tooltip,
    required String label,
    required List<Pair<String, VoidCallback>> items,
  }) {
    return Builder(
      builder: (context) {
        return ComBtn(
          tooltip: tooltip,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.black.withOpacity(0.8),
                content: SizedBox(
                  width: 250, // A bit wider for text
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: Colors.grey, height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        autofocus: index == 0, // Autofocus the first item
                        title: Text(
                          item.first,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                        ),
                        onTap: () {
                          item.second();
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        );
      },
    );
  }
}
