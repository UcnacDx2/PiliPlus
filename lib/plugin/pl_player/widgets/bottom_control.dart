import 'dart:math' as math;
import 'dart:ui';

import 'package:PiliPlus/common/widgets/progress_bar/audio_video_progress_bar.dart';
import 'package:PiliPlus/common/widgets/progress_bar/segment_progress_bar.dart';
import 'package:PiliPlus/models/common/super_resolution_type.dart';
import 'package:PiliPlus/models/common/video/video_quality.dart';
import 'package:PiliPlus/models_new/video/video_detail/episode.dart' as ugc;
import 'package:PiliPlus/models_new/video/video_detail/section.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/pages/video/introduction/pgc/controller.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/bottom_control_type.dart';
import 'package:PiliPlus/plugin/pl_player/models/video_fit_type.dart';
import 'package:PiliPlus/plugin/pl_player/view.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/common_btn.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/focusable_wrapper.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/interactive_seek_bar.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/play_pause_btn.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/utils/extension.dart';
import 'package:PiliPlus/utils/feed_back.dart';
import 'package:PiliPlus/utils/id_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class BottomControl extends StatelessWidget {
  const BottomControl({
    super.key,
    required this.controller,
    required this.videoDetailController,
    required this.maxWidth,
  });

  final PlPlayerController controller;
  final VideoDetailController videoDetailController;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMainControlRow(context),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: InteractiveSeekBar(
              controller: controller,
              child: _buildOriginalStackProgressBar(context),
            ),
          ),
          _buildSecondaryControlRow(context),
        ],
      ),
    );
  }

  Widget _buildOriginalStackProgressBar(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final primary =
        colorScheme.isLight ? colorScheme.inversePrimary : colorScheme.primary;
    final thumbGlowColor = primary.withAlpha(80);
    final bufferedBarColor = primary.withValues(alpha: 0.4);

    void onDragStart(ThumbDragDetails duration) {
      feedBack();
      controller.onChangedSliderStart(duration.timeStamp);
    }

    void onDragUpdate(ThumbDragDetails duration, int max) {
      if (!controller.isFileSource && controller.showSeekPreview) {
        controller.updatePreviewIndex(duration.timeStamp.inSeconds);
      }
      controller.onUpdatedSliderProgress(duration.timeStamp);
    }

    void onSeek(Duration duration, int max) {
      if (controller.showSeekPreview) {
        controller.showPreview.value = false;
      }
      controller
        ..onChangedSliderEnd()
        ..onChangedSlider(duration.inSeconds.toDouble())
        ..seekTo(Duration(seconds: duration.inSeconds), isSeek: false);
    }

    Widget progressBar() {
      final child = Obx(() {
        final int value = controller.sliderPositionSeconds.value;
        final int max = controller.durationSeconds.value.inSeconds;
        if (value > max || max <= 0) {
          return const SizedBox.shrink();
        }
        return ProgressBar(
          progress: Duration(seconds: value),
          buffered: Duration(seconds: controller.bufferedSeconds.value),
          total: Duration(seconds: max),
          progressBarColor: primary,
          baseBarColor: const Color(0x33FFFFFF),
          bufferedBarColor: bufferedBarColor,
          thumbColor: primary,
          thumbGlowColor: thumbGlowColor,
          barHeight: 3.5,
          thumbRadius: 7,
          thumbGlowRadius: 25,
          onDragStart: onDragStart,
          onDragUpdate: (e) => onDragUpdate(e, max),
          onSeek: (e) => onSeek(e, max),
        );
      });
      if (Utils.isDesktop) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: child,
        );
      }
      return child;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 7),
      child: Obx(
        () => Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            progressBar(),
            if (controller.enableBlock &&
                videoDetailController.segmentProgressList.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 5.25,
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      key: const Key('segmentList'),
                      size: const Size(double.infinity, 3.5),
                      painter: SegmentProgressBar(
                        segmentColors:
                            videoDetailController.segmentProgressList,
                      ),
                    ),
                  ),
                ),
              ),
            if (controller.showViewPoints &&
                videoDetailController.viewPointList.isNotEmpty &&
                videoDetailController.showVP.value) ...[
              Positioned(
                left: 0,
                right: 0,
                bottom: 5.25,
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      key: const Key('viewPointList'),
                      size: const Size(double.infinity, 3.5),
                      painter: SegmentProgressBar(
                        segmentColors: videoDetailController.viewPointList,
                      ),
                    ),
                  ),
                ),
              ),
              if (!Utils.isMobile)
                buildViewPointWidget(
                  videoDetailController,
                  controller,
                  8.75,
                  maxWidth - 40,
                ),
            ],
            if (videoDetailController.showDmTrendChart.value)
              if (videoDetailController.dmTrend.value?.dataOrNull
                  case final list?)
                buildDmChart(primary, list, videoDetailController, 4.5),
          ],
        ),
      ),
    );
  }

  Widget _buildMainControlRow(BuildContext context) {
    final introController = videoDetailController.isUgc
        ? Get.find<UgcIntroController>()
        : Get.find<PgcIntroController>();
    final videoDetail = introController.videoDetail.value;
    final isSeason = videoDetail.ugcSeason != null;
    final isPart = videoDetail.pages != null && videoDetail.pages!.length > 1;
    final isPgc = !videoDetailController.isUgc;
    final isPlayAll = videoDetailController.isPlayAll;
    final anySeason = isSeason || isPart || isPgc || isPlayAll;
    final isNotFileSource = !controller.isFileSource;

    List<BottomControlType> mainControlTypes = [
      BottomControlType.playOrPause,
      BottomControlType.time,
      if (!isNotFileSource || anySeason) ...[
        BottomControlType.pre,
        BottomControlType.next,
      ],
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ...mainControlTypes
            .map((type) => _buildControlItem(type, context))
            .toList(),
        const Spacer(),
      ],
    );
  }

  Widget _buildSecondaryControlRow(BuildContext context) {
    final isFullScreen = controller.isFullScreen.value;
    final isNotFileSource = !controller.isFileSource;
    final flag =
        isFullScreen || controller.isDesktopPip || maxWidth >= 500;
    final introController = videoDetailController.isUgc
        ? Get.find<UgcIntroController>()
        : Get.find<PgcIntroController>();
    final videoDetail = introController.videoDetail.value;
    final isSeason = videoDetail.ugcSeason != null;
    final isPart = videoDetail.pages != null && videoDetail.pages!.length > 1;
    final isPgc = !videoDetailController.isUgc;
    final isPlayAll = videoDetailController.isPlayAll;
    final anySeason = isSeason || isPart || isPgc || isPlayAll;

    List<BottomControlType> secondaryControlTypes = [
      if (isNotFileSource && controller.showDmChart)
        BottomControlType.dmChart,
      if (controller.isAnim) BottomControlType.superResolution,
      if (isNotFileSource && controller.showViewPoints)
        BottomControlType.viewPoints,
      if (isNotFileSource && anySeason) BottomControlType.episode,
      if (flag) BottomControlType.fit,
      if (isNotFileSource) BottomControlType.aiTranslate,
      BottomControlType.subtitle,
      BottomControlType.speed,
      if (isNotFileSource && flag) BottomControlType.qa,
      if (!controller.isDesktopPip) BottomControlType.fullscreen,
    ];
    return Row(
      children: [
        const Spacer(),
        ...secondaryControlTypes
            .map((type) => _buildControlItem(type, context))
            .toList(),
      ],
    );
  }

  Widget _buildControlItem(BottomControlType type, BuildContext context) {
    FocusNode? focusNode;
    if (type == BottomControlType.playOrPause) {
      focusNode = controller.tvFocusManager.playButtonNode;
    } else if (type == BottomControlType.qa) {
      focusNode = controller.tvFocusManager.qualityButtonNode;
    }

    final isFullScreen = controller.isFullScreen.value;
    final isLandscape = maxWidth > Get.height;
    final widgetWidth = isLandscape && isFullScreen ? 42.0 : 35.0;

    final introController = videoDetailController.isUgc
        ? Get.find<UgcIntroController>()
        : Get.find<PgcIntroController>();
    final videoDetail = introController.videoDetail.value;
    final isSeason = videoDetail.ugcSeason != null;
    final isPart = videoDetail.pages != null && videoDetail.pages!.length > 1;
    final isPgc = !videoDetailController.isUgc;
    final isPlayAll = videoDetailController.isPlayAll;

    Widget child;

    switch (type) {
      case BottomControlType.playOrPause:
        child = PlayOrPauseButton(plPlayerController: controller);
        break;
      case BottomControlType.pre:
        if (isSeason || isPart || isPgc || isPlayAll) {
          child = ComBtn(
            width: widgetWidth,
            height: 30,
            tooltip: '上一集',
            icon: const Icon(Icons.skip_previous, size: 22, color: Colors.white),
            onTap: () {
              if (!introController.prevPlay()) {
                SmartDialog.showToast('已经是第一集了');
              }
            },
          );
        } else {
          child = const SizedBox.shrink();
        }
        break;
      case BottomControlType.next:
        if (isSeason || isPart || isPgc || isPlayAll) {
          child = ComBtn(
            width: widgetWidth,
            height: 30,
            tooltip: '下一集',
            icon: const Icon(Icons.skip_next, size: 22, color: Colors.white),
            onTap: () {
              if (!introController.nextPlay()) {
                SmartDialog.showToast('已经是最后一集了');
              }
            },
          );
        } else {
          child = const SizedBox.shrink();
        }
        break;
      case BottomControlType.time:
        child = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Obx(
                () => Text(
                  DurationUtils.formatDuration(
                    controller.positionSeconds.value,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    height: 1.4,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Obx(
                () => Text(
                  DurationUtils.formatDuration(
                    controller.durationSeconds.value.inSeconds,
                  ),
                  style: const TextStyle(
                    color: Color(0xFFD0D0D0),
                    fontSize: 10,
                    height: 1.4,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        );
        break;
      case BottomControlType.dmChart:
        child = Obx(() {
          final list = videoDetailController.dmTrend.value?.dataOrNull;
          if (list != null && list.isNotEmpty) {
            return ComBtn(
              width: widgetWidth,
              height: 30,
              tooltip: '高能进度条',
              icon: videoDetailController.showDmTrendChart.value
                  ? const Icon(Icons.show_chart, size: 22, color: Colors.white)
                  : const Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.show_chart, size: 22, color: Colors.white),
                        Icon(Icons.hide_source, size: 22, color: Colors.white),
                      ],
                    ),
              onTap: () => videoDetailController.showDmTrendChart.value =
                  !videoDetailController.showDmTrendChart.value,
            );
          }
          return const SizedBox.shrink();
        });
        break;
      case BottomControlType.superResolution:
        child = Obx(
          () => PopupMenuButton<SuperResolutionType>(
            tooltip: '超分辨率',
            requestFocus: true,
            onCanceled: () {},
            initialValue: controller.superResolutionType.value,
            color: Colors.black.withAlpha(204),
            itemBuilder: (context) {
              return SuperResolutionType.values
                  .map(
                    (type) => PopupMenuItem<SuperResolutionType>(
                      height: 35,
                      padding: const EdgeInsets.only(left: 30),
                      value: type,
                      onTap: () => controller.setShader(type),
                      child: Text(
                        type.title,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  )
                  .toList();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                controller.superResolutionType.value.title,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        );
        break;
      case BottomControlType.viewPoints:
        child = Obx(
          () => videoDetailController.viewPointList.isEmpty
              ? const SizedBox.shrink()
              : ComBtn(
                  width: widgetWidth,
                  height: 30,
                  tooltip: '分段信息',
                  icon: Transform.rotate(
                    angle: math.pi / 2,
                    child: const Icon(MdiIcons.viewHeadline,
                        size: 22, color: Colors.white),
                  ),
                  onTap: () => Get.find<PLVideoPlayer>().showViewPoints?.call(),
                  onLongPress: () {
                    Feedback.forLongPress(context);
                    videoDetailController.showVP.value =
                        !videoDetailController.showVP.value;
                  },
                  onSecondaryTap: Utils.isMobile
                      ? null
                      : () => videoDetailController.showVP.value =
                          !videoDetailController.showVP.value,
                ),
        );
        break;
      case BottomControlType.episode:
        child = ComBtn(
          width: widgetWidth,
          height: 30,
          tooltip: '选集',
          icon: const Icon(Icons.list, size: 22, color: Colors.white),
          onTap: () {
            if (videoDetailController.isFileSource) return;
            if (isPlayAll && !isPart) {
              Get.find<PLVideoPlayer>().showEpisodes?.call();
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
                final List<ugc.EpisodeItem> episodesList =
                    sections[i].episodes!;
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
            Get.find<PLVideoPlayer>().showEpisodes?.call(
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
        break;
      case BottomControlType.fit:
        child = Obx(
          () => PopupMenuButton<VideoFitType>(
            tooltip: '画面比例',
            requestFocus: true,
            onCanceled: () {},
            initialValue: controller.videoFit.value,
            color: Colors.black.withAlpha(204),
            itemBuilder: (context) {
              return VideoFitType.values
                  .map(
                    (boxFit) => PopupMenuItem<VideoFitType>(
                      height: 35,
                      padding: const EdgeInsets.only(left: 30),
                      value: boxFit,
                      onTap: () => controller.toggleVideoFit(boxFit),
                      child: Text(
                        boxFit.desc,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  )
                  .toList();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                controller.videoFit.value.desc,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        );
        break;
      case BottomControlType.aiTranslate:
        child = Obx(
          () {
            final list = videoDetailController.languages.value;
            if (list != null && list.isNotEmpty) {
              return PopupMenuButton<String>(
                tooltip: '翻译',
                requestFocus: true,
                onCanceled: () {},
                initialValue: videoDetailController.currLang.value,
                color: Colors.black.withAlpha(204),
                itemBuilder: (context) {
                  return [
                    PopupMenuItem<String>(
                      height: 35,
                      value: '',
                      onTap: () => videoDetailController.setLanguage(''),
                      child: const Text("关闭翻译",
                          style:
                              TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                    ...list.map((e) {
                      return PopupMenuItem<String>(
                        height: 35,
                        value: e.lang,
                        onTap: () =>
                            videoDetailController.setLanguage(e.lang!),
                        child: Text(e.title!,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13)),
                      );
                    }),
                  ];
                },
                child: SizedBox(
                  width: widgetWidth,
                  height: 30,
                  child:
                      const Icon(Icons.translate, size: 18, color: Colors.white),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        );
        break;
      case BottomControlType.subtitle:
        child = Obx(
          () => videoDetailController.subtitles.isEmpty
              ? const SizedBox.shrink()
              : PopupMenuButton<int>(
                  tooltip: '字幕',
                  requestFocus: true,
                  onCanceled: () {},
                  initialValue: videoDetailController.vttSubtitlesIndex.value
                      .clamp(0, videoDetailController.subtitles.length),
                  color: Colors.black.withAlpha(204),
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem<int>(
                        value: 0,
                        height: 35,
                        onTap: () => videoDetailController.setSubtitle(0),
                        child: const Text("关闭字幕",
                            style: TextStyle(
                                color: Colors.white, fontSize: 13)),
                      ),
                      ...videoDetailController.subtitles.indexed.map((e) {
                        return PopupMenuItem<int>(
                          value: e.$1 + 1,
                          height: 35,
                          onTap: () =>
                              videoDetailController.setSubtitle(e.$1 + 1),
                          child: Text(
                            e.$2.lanDoc ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        );
                      }),
                    ];
                  },
                  child: SizedBox(
                    width: widgetWidth,
                    height: 30,
                    child: videoDetailController.vttSubtitlesIndex.value == 0
                        ? const Icon(Icons.closed_caption_off_outlined,
                            size: 22, color: Colors.white)
                        : const Icon(Icons.closed_caption_off_rounded,
                            size: 22, color: Colors.white),
                  ),
                ),
        );
        break;
      case BottomControlType.speed:
        child = Obx(
          () => PopupMenuButton<double>(
            tooltip: '倍速',
            requestFocus: true,
            onCanceled: () {},
            initialValue: controller.playbackSpeed,
            color: Colors.black.withAlpha(204),
            itemBuilder: (context) {
              return controller.speedList
                  .map(
                    (double speed) => PopupMenuItem<double>(
                      height: 35,
                      padding: const EdgeInsets.only(left: 30),
                      value: speed,
                      onTap: () => controller.setPlaybackSpeed(speed),
                      child: Text("${speed}X",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                    ),
                  )
                  .toList();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                "${controller.playbackSpeed}X",
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        );
        break;
      case BottomControlType.qa:
        child = Obx(() {
          final currentVideoQa = videoDetailController.currentVideoQa.value;
          if (currentVideoQa == null) return const SizedBox.shrink();

          final videoInfo = videoDetailController.data;
          if (videoInfo.dash == null) return const SizedBox.shrink();

          final videoFormat = videoInfo.supportFormats!;
          final totalQaSam = videoFormat.length;
          final video = videoInfo.dash!.video!;
          final idSet = <int>{};
          for (final item in video) {
            final id = item.id!;
            if (!idSet.contains(id)) {
              idSet.add(id);
            }
          }
          final usefulQaSam = idSet.length;

          return PopupMenuButton<int>(
            tooltip: '画质',
            requestFocus: true,
            onCanceled: () {
              controller.tvFocusManager.qualityButtonNode.requestFocus();
            },
            initialValue: currentVideoQa.code,
            color: Colors.black.withAlpha(204),
            itemBuilder: (context) {
              return List.generate(totalQaSam, (index) {
                final item = videoFormat[index];
                final enabled = index >= totalQaSam - usefulQaSam;
                return PopupMenuItem<int>(
                  enabled: enabled,
                  height: 35,
                  padding: const EdgeInsets.only(left: 15, right: 10),
                  value: item.quality,
                  onTap: () async {
                    if (currentVideoQa.code == item.quality) return;
                    final quality = item.quality!;
                    final newQa = VideoQuality.fromCode(quality);
                    videoDetailController
                      ..plPlayerController.cacheVideoQa = newQa.code
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
                            color: Color(0x62FFFFFF), fontSize: 13),
                  ),
                );
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                currentVideoQa.shortDesc,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          );
        });
        break;
      case BottomControlType.fullscreen:
        child = ComBtn(
          width: widgetWidth,
          height: 30,
          tooltip: isFullScreen ? '退出全屏' : '全屏',
          icon: isFullScreen
              ? const Icon(Icons.fullscreen_exit, size: 24, color: Colors.white)
              : const Icon(Icons.fullscreen, size: 24, color: Colors.white),
          onTap: () => controller.triggerFullScreen(status: !isFullScreen),
          onSecondaryTap: () => controller.triggerFullScreen(
              status: !isFullScreen, inAppFullScreen: true),
        );
        break;
      default:
        child = const SizedBox.shrink();
    }
    return FocusableWrapper(focusNode: focusNode, child: child);
  }
}
