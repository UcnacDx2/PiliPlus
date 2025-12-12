import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:PiliPlus/common/widgets/progress_bar/audio_video_progress_bar.dart';
import 'package:PiliPlus/common/widgets/progress_bar/segment_progress_bar.dart';
import 'package:PiliPlus/models/common/super_resolution_type.dart';
import 'package:PiliPlus/models/common/video/video_quality.dart';
import 'package:PiliPlus/models/video/play/url.dart';
import 'package:PiliPlus/models_new/video/video_detail/episode.dart' as ugc;
import 'package:PiliPlus/models_new/video/video_detail/episode.dart';
import 'package:PiliPlus/models_new/video/video_detail/section.dart';
import 'package:PiliPlus/models_new/video/video_detail/ugc_season.dart';
import 'package:PiliPlus/pages/common/common_intro_controller.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/pages/video/introduction/pgc/controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/bottom_control_type.dart';
import 'package:PiliPlus/plugin/pl_player/models/video_fit_type.dart';
import 'package:PiliPlus/plugin/pl_player/view.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/focusable_btn.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/play_pause_btn.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/utils/extension.dart';
import 'package:PiliPlus/utils/feed_back.dart';
import 'package:PiliPlus/utils/id_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:convert';
import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/common/widgets/button/icon_button.dart';
import 'package:PiliPlus/common/widgets/custom_sliver_persistent_header_delegate.dart';
import 'package:PiliPlus/common/widgets/dialog/report.dart';
import 'package:PiliPlus/http/danmaku.dart';
import 'package:PiliPlus/http/danmaku_block.dart';
import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/http/live.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/common/video/audio_quality.dart';
import 'package:PiliPlus/models/common/video/cdn_type.dart';
import 'package:PiliPlus/models/common/video/video_decode_type.dart';
import 'package:PiliPlus/models_new/video/video_play_info/subtitle.dart';
import 'package:PiliPlus/pages/danmaku/dnamaku_model.dart';
import 'package:PiliPlus/pages/setting/widgets/select_dialog.dart';
import 'package:PiliPlus/pages/setting/widgets/switch_item.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_repeat.dart';
import 'package:PiliPlus/services/service_locator.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/accounts/account.dart';
import 'package:PiliPlus/utils/image_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/video_utils.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/common/widgets/custom_icon.dart';
import 'package:PiliPlus/pages/video/widgets/header_control.dart';
import 'package:floating/floating.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class BottomControl extends StatefulWidget {
  const BottomControl({
    super.key,
    required this.maxWidth,
    required this.isFullScreen,
    required this.controller,
    required this.videoDetailController,
    required this.introController,
    this.showEpisodes,
    this.showViewPoints,
  });

  final double maxWidth;
  final bool isFullScreen;
  final PlPlayerController controller;
  final VideoDetailController videoDetailController;
  final CommonIntroController introController;
  final void Function([
    int?,
    UgcSeason?,
    List<ugc.BaseEpisodeItem>?,
    String?,
    int?,
    int?,
  ])? showEpisodes;
  final VoidCallback? showViewPoints;

  @override
  State<BottomControl> createState() => BottomControlState();
}

class BottomControlState extends State<BottomControl> with HeaderMixin {
  PlPlayerController get plPlayerController => widget.controller;
  late final PlayUrlModel videoInfo = widget.videoDetailController.data;
  Box setting = GStorage.setting;
  late final FocusNode _progressBarFocusNode;
  late final FocusNode _playPauseFocusNode;

  @override
  void initState() {
    super.initState();
    _progressBarFocusNode = FocusNode();
    _progressBarFocusNode.addListener(() {
      setState(() {});
    });
    _playPauseFocusNode = FocusNode();
    _playPauseFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _progressBarFocusNode.dispose();
    _playPauseFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final primary = colorScheme.isLight
        ? colorScheme.inversePrimary
        : colorScheme.primary;
    final thumbGlowColor = primary.withAlpha(80);
    final bufferedBarColor = primary.withValues(alpha: 0.4);
    //阅读器限制
    Timer? accessibilityDebounce;
    double lastAnnouncedValue = -1;
    void onDragStart(ThumbDragDetails duration) {
      feedBack();
      widget.controller.onChangedSliderStart(duration.timeStamp);
    }

    void onDragUpdate(ThumbDragDetails duration, int max) {
      if (!widget.controller.isFileSource && widget.controller.showSeekPreview) {
        widget.controller.updatePreviewIndex(
          duration.timeStamp.inSeconds,
        );
      }
      double newProgress = duration.timeStamp.inSeconds / max;
      if ((newProgress - lastAnnouncedValue).abs() > 0.02) {
        accessibilityDebounce?.cancel();
        accessibilityDebounce = Timer(
          const Duration(milliseconds: 200),
          () {
            SemanticsService.announce(
              "${(newProgress * 100).round()}%",
              TextDirection.ltr,
            );
            lastAnnouncedValue = newProgress;
          },
        );
      }
      widget.controller.onUpdatedSliderProgress(
        duration.timeStamp,
      );
    }

    void onSeek(Duration duration, int max) {
      if (widget.controller.showSeekPreview) {
        widget.controller.showPreview.value = false;
      }
      widget.controller
        ..onChangedSliderEnd()
        ..onChangedSlider(duration.inSeconds.toDouble())
        ..seekTo(
          Duration(seconds: duration.inSeconds),
          isSeek: false,
        );
      SemanticsService.announce(
        "${(duration.inSeconds / max * 100).round()}%",
        TextDirection.ltr,
      );
    }

    Widget progressBar() {
      final child = Obx(() {
        final int value = widget.controller.sliderPositionSeconds.value;
        final int max = widget.controller.durationSeconds.value.inSeconds;
        if (value > max || max <= 0) {
          return const SizedBox.shrink();
        }
        return Focus(
          focusNode: _progressBarFocusNode,
          onKey: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                widget.controller.seekTo(
                  Duration(seconds: value - 5),
                  isSeek: false,
                );
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                widget.controller.seekTo(
                  Duration(seconds: value + 5),
                  isSeek: false,
                );
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: _progressBarFocusNode.hasFocus
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: ProgressBar(
              progress: Duration(seconds: value),
              buffered:
                  Duration(seconds: widget.controller.bufferedSeconds.value),
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
            ),
          ),
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

    final videoDetail = widget.introController.videoDetail.value;
    final isSeason = videoDetail.ugcSeason != null;
    final isPart = videoDetail.pages != null && videoDetail.pages!.length > 1;
    final isPgc = !widget.videoDetailController.isUgc;
    final isPlayAll = widget.videoDetailController.isPlayAll;
    final anySeason = isSeason || isPart || isPgc || isPlayAll;
    final isLandscape = widget.maxWidth > Get.height;
    final double widgetWidth =
        isLandscape && widget.isFullScreen ? 42 : 35;

    Widget progressWidget(
      BottomControlType bottomControl,
    ) =>
        switch (bottomControl) {
          /// 播放暂停
          BottomControlType.playOrPause => PlayOrPauseButton(
              plPlayerController: widget.controller,
              focusNode: _playPauseFocusNode,
            ),

          /// 上一集
          BottomControlType.pre => FocusableBtn(
              width: widgetWidth,
              height: 30,
              tooltip: '上一集',
              icon: const Icon(
                Icons.skip_previous,
                size: 22,
                color: Colors.white,
              ),
              onTap: () {
                if (!widget.introController.prevPlay()) {
                  SmartDialog.showToast('已经是第一集了');
                }
              },
            ),

          /// 下一集
          BottomControlType.next => FocusableBtn(
              width: widgetWidth,
              height: 30,
              tooltip: '下一集',
              icon: const Icon(
                Icons.skip_next,
                size: 22,
                color: Colors.white,
              ),
              onTap: () {
                if (!widget.introController.nextPlay()) {
                  SmartDialog.showToast('已经是最后一集了');
                }
              },
            ),

          /// 时间进度
          BottomControlType.time => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 播放时间
                Obx(
                  () => Text(
                    DurationUtils.formatDuration(
                      widget.controller.positionSeconds.value,
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
                      widget.controller.durationSeconds.value.inSeconds,
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

          /// 高能进度条
          BottomControlType.dmChart => Obx(
              () {
                final list =
                    widget.videoDetailController.dmTrend.value?.dataOrNull;
                if (list != null && list.isNotEmpty) {
                  return FocusableBtn(
                    width: widgetWidth,
                    height: 30,
                    tooltip: '高能进度条',
                    icon: widget.videoDetailController.showDmTreandChart.value
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
                    onTap: () => widget
                        .videoDetailController.showDmTreandChart.value =
                        !widget.videoDetailController.showDmTreandChart.value,
                  );
                }
                return const SizedBox.shrink();
              },
            ),

          /// 超分辨率
          BottomControlType.superResolution => Obx(
              () => PopupMenuButton<SuperResolutionType>(
                tooltip: '超分辨率',
                requestFocus: false,
                initialValue: widget.controller.superResolutionType.value,
                color: Colors.black.withValues(alpha: 0.8),
                itemBuilder: (context) {
                  return SuperResolutionType.values
                      .map(
                        (type) => PopupMenuItem<SuperResolutionType>(
                          height: 35,
                          padding: const EdgeInsets.only(left: 30),
                          value: type,
                          onTap: () => widget.controller.setShader(type),
                          child: Text(
                            type.title,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ),
                      )
                      .toList();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    widget.controller.superResolutionType.value.title,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),

          /// 分段信息
          BottomControlType.viewPoints => Obx(
              () => widget.videoDetailController.viewPointList.isEmpty
                  ? const SizedBox.shrink()
                  : FocusableBtn(
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
                      onTap: widget.showViewPoints,
                      onLongPress: () {
                        Feedback.forLongPress(context);
                        widget.videoDetailController.showVP.value =
                            !widget.videoDetailController.showVP.value;
                      },
                      onSecondaryTap: Utils.isMobile
                          ? null
                          : () => widget.videoDetailController.showVP.value =
                              !widget.videoDetailController.showVP.value,
                    ),
            ),

          /// 选集
          BottomControlType.episode => FocusableBtn(
              width: widgetWidth,
              height: 30,
              tooltip: '选集',
              icon: const Icon(
                Icons.list,
                size: 22,
                color: Colors.white,
              ),
              onTap: () {
                if (widget.videoDetailController.isFileSource) {
                  // TODO
                  return;
                }
                // part -> playAll -> season(pgc)
                if (isPlayAll && !isPart) {
                  widget.showEpisodes?.call();
                  return;
                }
                int? index;
                int currentCid = widget.controller.cid!;
                String bvid = widget.controller.bvid;
                List<ugc.BaseEpisodeItem> episodes = [];
                if (isSeason) {
                  final List<SectionItem> sections =
                      videoDetail.ugcSeason!.sections!;
                  for (int i = 0; i < sections.length; i++) {
                    final List<EpisodeItem> episodesList = sections[i].episodes!;
                    for (int j = 0; j < episodesList.length; j++) {
                      if (episodesList[j].cid == widget.controller.cid) {
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
                      (widget.introController as PgcIntroController).pgcItem.episodes!;
                }
                widget.showEpisodes?.call(
                  index,
                  isSeason ? videoDetail.ugcSeason! : null,
                  isSeason ? null : episodes,
                  bvid,
                  IdUtils.bv2av(bvid),
                  isSeason && isPart
                      ? widget.videoDetailController.seasonCid ?? currentCid
                      : currentCid,
                );
              },
            ),

          /// 画面比例
          BottomControlType.fit => Obx(
              () => PopupMenuButton<VideoFitType>(
                tooltip: '画面比例',
                requestFocus: false,
                initialValue: widget.controller.videoFit.value,
                color: Colors.black.withValues(alpha: 0.8),
                itemBuilder: (context) {
                  return VideoFitType.values
                      .map(
                        (boxFit) => PopupMenuItem<VideoFitType>(
                          height: 35,
                          padding: const EdgeInsets.only(left: 30),
                          value: boxFit,
                          onTap: () => widget.controller.toggleVideoFit(boxFit),
                          child: Text(
                            boxFit.desc,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ),
                      )
                      .toList();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    widget.controller.videoFit.value.desc,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),

          BottomControlType.aiTranslate => Obx(
              () {
                final list = widget.videoDetailController.languages.value;
                if (list != null && list.isNotEmpty) {
                  return PopupMenuButton<String>(
                    tooltip: '翻译',
                    requestFocus: false,
                    initialValue: widget.videoDetailController.currLang.value,
                    color: Colors.black.withValues(alpha: 0.8),
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem<String>(
                          height: 35,
                          value: '',
                          onTap: () =>
                              widget.videoDetailController.setLanguage(''),
                          child: const Text(
                            "关闭翻译",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        ...list.map((e) {
                          return PopupMenuItem<String>(
                            height: 35,
                            value: e.lang,
                            onTap: () => widget.videoDetailController
                                .setLanguage(e.lang!),
                            child: Text(
                              e.title!,
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
                      width: widgetWidth,
                      height: 30,
                      child: const Icon(
                        Icons.translate,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

          /// 字幕
          BottomControlType.subtitle => Obx(
              () => widget.videoDetailController.subtitles.isEmpty == true
                  ? const SizedBox.shrink()
                  : PopupMenuButton<int>(
                      tooltip: '字幕',
                      requestFocus: false,
                      initialValue:
                          widget.videoDetailController.vttSubtitlesIndex.value
                              .clamp(
                        0,
                        widget.videoDetailController.subtitles.length,
                      ),
                      color: Colors.black.withValues(alpha: 0.8),
                      itemBuilder: (context) {
                        return [
                          PopupMenuItem<int>(
                            value: 0,
                            height: 35,
                            onTap: () =>
                                widget.videoDetailController.setSubtitle(0),
                            child: const Text(
                              "关闭字幕",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          ...widget.videoDetailController.subtitles.indexed
                              .map((e) {
                            return PopupMenuItem<int>(
                              value: e.$1 + 1,
                              height: 35,
                              onTap: () => widget.videoDetailController
                                  .setSubtitle(e.$1 + 1),
                              child: Text(
                                "${e.$2.lanDoc}",
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
                        width: widgetWidth,
                        height: 30,
                        child:
                            widget.videoDetailController.vttSubtitlesIndex.value ==
                                    0
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
            ),

          /// 播放速度
          BottomControlType.speed => Obx(
              () => PopupMenuButton<double>(
                tooltip: '倍速',
                requestFocus: false,
                initialValue: widget.controller.playbackSpeed,
                color: Colors.black.withValues(alpha: 0.8),
                itemBuilder: (context) {
                  return widget.controller.speedList
                      .map(
                        (double speed) => PopupMenuItem<double>(
                          height: 35,
                          padding: const EdgeInsets.only(left: 30),
                          value: speed,
                          onTap: () =>
                              widget.controller.setPlaybackSpeed(speed),
                          child: Text(
                            "${speed}X",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                            semanticsLabel: "$speed倍速",
                          ),
                        ),
                      )
                      .toList();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    "${widget.controller.playbackSpeed}X",
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    semanticsLabel: "${widget.controller.playbackSpeed}倍速",
                  ),
                ),
              ),
            ),

          BottomControlType.qa => Obx(
              () {
                final VideoQuality? currentVideoQa =
                    widget.videoDetailController.currentVideoQa.value;
                if (currentVideoQa == null) {
                  return const SizedBox.shrink();
                }
                final PlayUrlModel videoInfo = widget.videoDetailController.data;
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
                  requestFocus: false,
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
                            widget.videoDetailController
                              ..plPlayerController.cacheVideoQa = newQa.code
                              ..currentVideoQa.value = newQa
                              ..updatePlayer();

                            SmartDialog.showToast("画质已变为：${newQa.desc}");

                            // update
                            if (!widget.controller.tempPlayerConf) {
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
                                ? const TextStyle(
                                    color: Colors.white, fontSize: 13)
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
            ),

          /// 全屏
          BottomControlType.fullscreen => FocusableBtn(
              width: widgetWidth,
              height: 30,
              tooltip: widget.isFullScreen ? '退出全屏' : '全屏',
              icon: widget.isFullScreen
                  ? const Icon(
                      Icons.fullscreen_exit,
                      size: 24,
                      color: Colors.white,
                    )
                  : const Icon(
                      Icons.fullscreen,
                      size: 24,
                      color: Colors.white,
                    ),
              onTap: () => widget.controller
                  .triggerFullScreen(status: !widget.isFullScreen),
              onSecondaryTap: () => widget.controller.triggerFullScreen(
                status: !widget.isFullScreen,
                inAppFullScreen: true,
              ),
            ),
        };

    Widget buildPrimaryControls() {
      final isNotFileSource = !widget.controller.isFileSource;
      List<BottomControlType> userSpecifyItemLeft = [
        BottomControlType.playOrPause,
        if (!isNotFileSource || anySeason) ...[
          BottomControlType.pre,
          BottomControlType.next,
        ],
      ];
      return Row(
        children: [
          ...userSpecifyItemLeft.map(progressWidget),
          const Spacer(),
        ],
      );
    }

    Widget buildSecondaryControls() {
      final isNotFileSource = !widget.controller.isFileSource;
      final isFSOrPip =
          widget.isFullScreen || widget.controller.isDesktopPip;
      final flag = isFSOrPip || widget.maxWidth >= 500;
      List<BottomControlType> userSpecifyItemRight = [
        if (isNotFileSource && widget.controller.showDmChart)
          BottomControlType.dmChart,
        if (widget.controller.isAnim) BottomControlType.superResolution,
        if (isNotFileSource && widget.controller.showViewPoints)
          BottomControlType.viewPoints,
        if (isNotFileSource && anySeason) BottomControlType.episode,
        if (flag) BottomControlType.fit,
        if (isNotFileSource) BottomControlType.aiTranslate,
        BottomControlType.subtitle,
        BottomControlType.speed,
        if (isNotFileSource && flag) BottomControlType.qa,
      ];

      return Row(
        children: [
          ...userSpecifyItemRight.map(progressWidget),
          const Spacer(),
          if (isFSOrPip || Utils.isDesktop) ...[
            FocusableBtn(
              width: 42,
              height: 34,
              tooltip: '发弹幕',
              onTap: widget.videoDetailController.showShootDanmakuSheet,
              icon: const Icon(
                Icons.comment_outlined,
                size: 19,
                color: Colors.white,
              ),
            ),
            Obx(
              () {
                final enableShowDanmaku =
                    widget.controller.enableShowDanmaku.value;
                return FocusableBtn(
                  width: 42,
                  height: 34,
                  tooltip: "${enableShowDanmaku ? '关闭' : '开启'}弹幕",
                  onTap: () {
                    final newVal = !enableShowDanmaku;
                    widget.controller.enableShowDanmaku.value = newVal;
                    if (!widget.controller.tempPlayerConf) {
                      GStorage.setting.put(
                        SettingBoxKey.enableShowDanmaku,
                        newVal,
                      );
                    }
                  },
                  icon: enableShowDanmaku
                      ? const Icon(
                          size: 20,
                          CustomIcons.dm_on,
                          color: Colors.white,
                        )
                      : const Icon(
                          size: 20,
                          CustomIcons.dm_off,
                          color: Colors.white,
                        ),
                );
              },
            ),
          ],
          if (Platform.isAndroid || (Utils.isDesktop && !widget.isFullScreen))
            FocusableBtn(
              width: 42,
              height: 34,
              tooltip: '画中画',
              onTap: () async {
                if (Utils.isDesktop) {
                  widget.controller.toggleDesktopPip();
                  return;
                }
                if (await Floating().isPipAvailable) {
                  widget.controller.showControls.value = false;
                  widget.controller.enterPip();
                }
              },
              icon: const Icon(
                Icons.picture_in_picture_outlined,
                size: 19,
                color: Colors.white,
              ),
            ),
          FocusableBtn(
            width: 42,
            height: 34,
            tooltip: "更多设置",
            onTap: showSettingSheet,
            icon: const Icon(
              Icons.more_vert_outlined,
              size: 19,
              color: Colors.white,
            ),
          ),
          progressWidget(BottomControlType.time),
          if (!widget.controller.isDesktopPip)
            progressWidget(BottomControlType.fullscreen),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildPrimaryControls(),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 7),
            child: Obx(
              () => Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  progressBar(),
                  if (widget.controller.enableBlock &&
                      widget.videoDetailController.segmentProgressList
                          .isNotEmpty)
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
                              segmentColors: widget
                                  .videoDetailController.segmentProgressList,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (widget.controller.showViewPoints &&
                      widget.videoDetailController.viewPointList.isNotEmpty &&
                      widget.videoDetailController.showVP.value) ...[
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
                              segmentColors:
                                  widget.videoDetailController.viewPointList,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!Utils.isMobile)
                      buildViewPointWidget(
                        widget.videoDetailController,
                        widget.controller,
                        8.75,
                        widget.maxWidth - 40,
                      ),
                  ],
                  if (widget.videoDetailController.showDmTreandChart.value)
                    if (widget.videoDetailController.dmTrend.value?.dataOrNull
                        case final list?)
                      buildDmChart(
                          primary, list, widget.videoDetailController, 4.5),
                ],
              ),
            ),
          ),
          buildSecondaryControls(),
        ],
      ),
    );
  }

  /// 设置面板
  void showSettingSheet() {
    showBottomSheet(
      (context, setState) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
            clipBehavior: Clip.hardEdge,
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 14),
              children: [
                ListTile(
                  dense: true,
                  onTap: () {
                    Get.back();
                    widget.introController.viewLater();
                  },
                  leading: const Icon(Icons.watch_later_outlined, size: 20),
                  title: const Text('添加至「稍后再看」', style: TextStyle(fontSize: 14)),
                ),
                if (widget.videoDetailController.epId == null)
                  ListTile(
                    dense: true,
                    onTap: () {
                      Get.back();
                      widget.videoDetailController.showNoteList(context);
                    },
                    leading: const Icon(Icons.note_alt_outlined, size: 20),
                    title: const Text('查看笔记', style: TextStyle(fontSize: 14)),
                  ),
                if (!widget.videoDetailController.isFileSource)
                  ListTile(
                    dense: true,
                    onTap: () {
                      Get.back();
                      widget.videoDetailController.onDownload(this.context);
                    },
                    leading: const Icon(
                      MdiIcons.folderDownloadOutline,
                      size: 20,
                    ),
                    title: const Text('离线缓存', style: TextStyle(fontSize: 14)),
                  ),
                if (widget.videoDetailController.cover.value.isNotEmpty)
                  ListTile(
                    dense: true,
                    onTap: () {
                      Get.back();
                      ImageUtils.downloadImg(
                        context,
                        [widget.videoDetailController.cover.value],
                      );
                    },
                    leading: const Icon(Icons.image_outlined, size: 20),
                    title: const Text('保存封面', style: TextStyle(fontSize: 14)),
                  ),
                ListTile(
                  dense: true,
                  onTap: () {
                    Get.back();
                    PageUtils.scheduleExit(this.context, widget.isFullScreen);
                  },
                  leading: const Icon(Icons.hourglass_top_outlined, size: 20),
                  title: const Text('定时关闭', style: TextStyle(fontSize: 14)),
                ),
                if (!widget.videoDetailController.isFileSource) ...[
                  ListTile(
                    dense: true,
                    onTap: () {
                      Get.back();
                      widget.videoDetailController.editPlayUrl();
                    },
                    leading: const Icon(
                      Icons.link,
                      size: 20,
                    ),
                    title: const Text('播放地址', style: TextStyle(fontSize: 14)),
                  ),
                  ListTile(
                    dense: true,
                    onTap: () {
                      Get.back();
                      widget.videoDetailController.queryVideoUrl(
                        defaultST: widget.videoDetailController.playedTime,
                        fromReset: true,
                      );
                    },
                    leading: const Icon(Icons.refresh_outlined, size: 20),
                    title: const Text('重载视频', style: TextStyle(fontSize: 14)),
                  ),
                ],
                ListTile(
                  dense: true,
                  onTap: () {
                    Get.back();
                    showSetRepeat();
                  },
                  leading: const Icon(Icons.repeat, size: 20),
                  title: const Text('播放顺序', style: TextStyle(fontSize: 14)),
                  subtitle: Text(
                    plPlayerController.playRepeat.desc,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                ListTile(
                  dense: true,
                  onTap: () {
                    Get.back();
                    showDanmakuPool();
                  },
                  leading: const Icon(CustomIcons.dm_on, size: 20),
                  title: const Text('弹幕列表', style: TextStyle(fontSize: 14)),
                ),
                ListTile(
                  dense: true,
                  onTap: () {
                    Get.back();
                    showSetDanmaku();
                  },
                  leading: const Icon(CustomIcons.dm_settings, size: 20),
                  title: const Text('弹幕设置', style: TextStyle(fontSize: 14)),
                ),
                ListTile(
                  dense: true,
                  onTap: () {
                    Get.back();
                    showSetSubtitle();
                  },
                  leading: const Icon(Icons.subtitles_outlined, size: 20),
                  title: const Text('字幕设置', style: TextStyle(fontSize: 14)),
                ),
                ListTile(
                  dense: true,
                  onTap: () async {
                    Get.back();
                    try {
                      final FilePickerResult? file = await FilePicker.platform
                          .pickFiles();
                      if (file != null) {
                        final first = file.files.first;
                        final path = first.path;
                        if (path != null) {
                          final file = File(path);
                          final stream = file.openRead().transform(
                            utf8.decoder,
                          );
                          final buffer = StringBuffer();
                          await for (final chunk in stream) {
                            if (!mounted) return;
                            buffer.write(chunk);
                          }
                          if (!mounted) return;
                          String sub = buffer.toString();
                          final name = first.name;
                          if (name.endsWith('.json')) {
                            sub = await compute<List, String>(
                              VideoHttp.processList,
                              jsonDecode(sub)['body'],
                            );
                            if (!mounted) return;
                          }
                          final length = widget.videoDetailController.subtitles.length;
                          widget.videoDetailController
                            ..subtitles.add(
                              Subtitle(
                                lan: '',
                                lanDoc: name.split('.').firstOrNull ?? name,
                              ),
                            )
                            ..vttSubtitles[length] = sub;
                          await widget.videoDetailController.setSubtitle(length + 1);
                        }
                      }
                    } catch (e) {
                      SmartDialog.showToast('加载失败: $e');
                    }
                  },
                  leading: const Icon(Icons.file_open_outlined, size: 20),
                  title: const Text('加载字幕', style: TextStyle(fontSize: 14)),
                ),
                if (!widget.videoDetailController.isFileSource &&
                    widget.videoDetailController.subtitles.isNotEmpty)
                  ListTile(
                    dense: true,
                    onTap: () {
                      Get.back();
                      onExportSubtitle();
                    },
                    leading: const Icon(Icons.download_outlined, size: 20),
                    title: const Text('保存字幕', style: TextStyle(fontSize: 14)),
                  ),
                ListTile(
                  dense: true,
                  title: const Text('播放信息', style: TextStyle(fontSize: 14)),
                  leading: const Icon(Icons.info_outline, size: 20),
                  onTap: () => HeaderControlState.showPlayerInfo(
                    context,
                    plPlayerController: plPlayerController,
                  ),
                ),
                ListTile(
                  dense: true,
                  onTap: () {
                    if (!Accounts.main.isLogin) {
                      SmartDialog.showToast('账号未登录');
                      return;
                    }
                    Get.back();
                    PageUtils.reportVideo(widget.videoDetailController.aid);
                  },
                  leading: const Icon(Icons.error_outline, size: 20),
                  title: const Text('举报', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 播放顺序
  void showSetRepeat() {
    showBottomSheet(
      (context, setState) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
            clipBehavior: Clip.hardEdge,
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 45,
                    child: Center(
                      child: Text('选择播放顺序', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                ),
                SliverList.builder(
                  itemCount: PlayRepeat.values.length,
                  itemBuilder: (context, index) {
                    final i = PlayRepeat.values[index];
                    return ListTile(
                      dense: true,
                      onTap: () {
                        Get.back();
                        widget.controller.setPlayRepeat(i);
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      title: Text(i.desc),
                      trailing: widget.controller.playRepeat == i
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
          ),
        );
      },
    );
  }

  void showDanmakuPool() {
    final ctr = widget.controller.danmakuController;
    if (ctr == null) return;
    showBottomSheet((context, setState) {
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Material(
          clipBehavior: Clip.hardEdge,
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: CustomSliverPersistentHeaderDelegate(
                  child: Container(
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.1,
                          ),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('弹幕列表'),
                        iconButton(
                          onPressed: () => setState(() {}),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  ),
                  bgColor: theme.colorScheme.surface,
                ),
              ),
              if (ctr.staticDanmaku.isNotEmpty)
                _buildDanmakuList(ctr.staticDanmaku)!,
              if (ctr.scrollDanmaku.isNotEmpty)
                _buildDanmakuList(ctr.scrollDanmaku)!,
              if (ctr.specialDanmaku.isNotEmpty)
                _buildDanmakuList(ctr.specialDanmaku)!,
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],
          ),
        ),
      );
    });
  }

  Sliver? _buildDanmakuList(List<DanmakuItem<DanmakuExtra>> list) {
    if (list.isEmpty) return null;
    list = List.of(list);

    return SliverList.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final extra = item.content.extra! as VideoDanmaku;
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          onLongPress: () => Utils.copyText(item.content.text),
          title: Text(
            item.content.text,
            style: const TextStyle(fontSize: 14),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(
                builder: (context) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    iconButton(
                      onPressed: () async {
                        if (await HeaderControl.likeDanmaku(
                              extra,
                              widget.controller.cid!,
                            ) &&
                            context.mounted) {
                          (context as Element).markNeedsBuild();
                        }
                      },
                      icon: extra.isLike
                          ? const Icon(CustomIcons.player_dm_tip_like_solid)
                          : const Icon(CustomIcons.player_dm_tip_like),
                    ),
                    if (extra.like > 0)
                      Positioned(
                        left: 24.5,
                        top: 1.5,
                        child: Text(
                          extra.like.toString(),
                          style: const TextStyle(
                            fontSize: 10.5,
                            letterSpacing: 0,
                            // fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (item.content.selfSend)
                iconButton(
                  onPressed: () => HeaderControl.deleteDanmaku(
                    extra.id,
                    widget.controller.cid!,
                  ).then((_) => item.expired = true),
                  icon: const Icon(CustomIcons.player_dm_tip_recall),
                )
              else
                iconButton(
                  onPressed: () => HeaderControl.reportDanmaku(
                    context,
                    extra: extra,
                    ctr: widget.controller,
                  ),
                  icon: const Icon(CustomIcons.player_dm_tip_back),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 字幕设置
  void showSetSubtitle() {
    double subtitleFontScale = plPlayerController.subtitleFontScale;
    double subtitleFontScaleFS = plPlayerController.subtitleFontScaleFS;
    int subtitlePaddingH = plPlayerController.subtitlePaddingH;
    int subtitlePaddingB = plPlayerController.subtitlePaddingB;
    double subtitleBgOpaticy = plPlayerController.subtitleBgOpaticy;
    double subtitleStrokeWidth = plPlayerController.subtitleStrokeWidth;
    int subtitleFontWeight = plPlayerController.subtitleFontWeight;

    showBottomSheet(
      padding: isFullScreen ? 70 : null,
      (context, setState) {
        final theme = Theme.of(context);

        final sliderTheme = SliderThemeData(
          trackHeight: 10,
          trackShape: const MSliderTrackShape(),
          thumbColor: theme.colorScheme.primary,
          activeTrackColor: theme.colorScheme.primary,
          inactiveTrackColor: theme.colorScheme.onInverseSurface,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
        );

        void updateStrokeWidth(double val) {
          subtitleStrokeWidth = val;
          plPlayerController
            ..subtitleStrokeWidth = subtitleStrokeWidth
            ..updateSubtitleStyle();
          setState(() {});
        }

        void updateOpacity(double val) {
          subtitleBgOpaticy = val.toPrecision(2);
          plPlayerController
            ..subtitleBgOpaticy = subtitleBgOpaticy
            ..updateSubtitleStyle();
          setState(() {});
        }

        void updateBottomPadding(double val) {
          subtitlePaddingB = val.round();
          plPlayerController
            ..subtitlePaddingB = subtitlePaddingB
            ..updateSubtitleStyle();
          setState(() {});
        }

        void updateHorizontalPadding(double val) {
          subtitlePaddingH = val.round();
          plPlayerController
            ..subtitlePaddingH = subtitlePaddingH
            ..updateSubtitleStyle();
          setState(() {});
        }

        void updateFontScaleFS(double val) {
          subtitleFontScaleFS = val;
          plPlayerController
            ..subtitleFontScaleFS = subtitleFontScaleFS
            ..updateSubtitleStyle();
          setState(() {});
        }

        void updateFontScale(double val) {
          subtitleFontScale = val;
          plPlayerController
            ..subtitleFontScale = subtitleFontScale
            ..updateSubtitleStyle();
          setState(() {});
        }

        void updateFontWeight(double val) {
          subtitleFontWeight = val.toInt();
          plPlayerController
            ..subtitleFontWeight = subtitleFontWeight
            ..updateSubtitleStyle();
          setState(() {});
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
            clipBehavior: Clip.hardEdge,
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(
                    height: 45,
                    child: Center(child: Text('字幕设置', style: TextStyle(fontSize: 14))),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '字体大小 ${(subtitleFontScale * 100).toStringAsFixed(1)}%',
                      ),
                      resetBtn(
                        theme,
                        '100.0%',
                        () => updateFontScale(1.0),
                        isDanmaku: false,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        min: 0.5,
                        max: 2.5,
                        value: subtitleFontScale,
                        divisions: 20,
                        label:
                            '${(subtitleFontScale * 100).toStringAsFixed(1)}%',
                        onChanged: updateFontScale,
                        onChangeEnd: (_) =>
                            plPlayerController.putSubtitleSettings(),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '全屏字体大小 ${(subtitleFontScaleFS * 100).toStringAsFixed(1)}%',
                      ),
                      resetBtn(
                        theme,
                        '150.0%',
                        () => updateFontScaleFS(1.5),
                        isDanmaku: false,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        min: 0.5,
                        max: 2.5,
                        value: subtitleFontScaleFS,
                        divisions: 20,
                        label:
                            '${(subtitleFontScaleFS * 100).toStringAsFixed(1)}%',
                        onChanged: updateFontScaleFS,
                        onChangeEnd: (_) =>
                            plPlayerController.putSubtitleSettings,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('字体粗细 ${subtitleFontWeight + 1}（可能无法精确调节）'),
                      resetBtn(
                        theme,
                        6,
                        () => updateFontWeight(5),
                        isDanmaku: false,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        min: 0,
                        max: 8,
                        value: subtitleFontWeight.toDouble(),
                        divisions: 8,
                        label: '${subtitleFontWeight + 1}',
                        onChanged: updateFontWeight,
                        onChangeEnd: (_) =>
                            plPlayerController.putSubtitleSettings(),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('描边粗细 $subtitleStrokeWidth'),
                      resetBtn(
                        theme,
                        2.0,
                        () => updateStrokeWidth(2.0),
                        isDanmaku: false,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        min: 0,
                        max: 5,
                        value: subtitleStrokeWidth,
                        divisions: 10,
                        label: '$subtitleStrokeWidth',
                        onChanged: updateStrokeWidth,
                        onChangeEnd: (_) =>
                            plPlayerController.putSubtitleSettings(),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('左右边距 $subtitlePaddingH'),
                      resetBtn(
                        theme,
                        24,
                        () => updateHorizontalPadding(24),
                        isDanmaku: false,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        min: 0,
                        max: 100,
                        value: subtitlePaddingH.toDouble(),
                        divisions: 100,
                        label: '$subtitlePaddingH',
                        onChanged: updateHorizontalPadding,
                        onChangeEnd: (_) =>
                            plPlayerController.putSubtitleSettings(),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('底部边距 $subtitlePaddingB'),
                      resetBtn(
                        theme,
                        24,
                        () => updateBottomPadding(24),
                        isDanmaku: false,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        min: 0,
                        max: 200,
                        value: subtitlePaddingB.toDouble(),
                        divisions: 200,
                        label: '$subtitlePaddingB',
                        onChanged: updateBottomPadding,
                        onChangeEnd: (_) =>
                            plPlayerController.putSubtitleSettings(),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('背景不透明度 ${(subtitleBgOpaticy * 100).toInt()}%'),
                      resetBtn(
                        theme,
                        '67%',
                        () => updateOpacity(0.67),
                        isDanmaku: false,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        min: 0,
                        max: 1,
                        value: subtitleBgOpaticy,
                        onChanged: updateOpacity,
                        onChangeEnd: (_) =>
                            plPlayerController.putSubtitleSettings(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void onExportSubtitle() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          clipBehavior: Clip.hardEdge,
          contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
          title: const Text('保存字幕'),
          content: SingleChildScrollView(
            child: Column(
              children: widget.videoDetailController.subtitles
                  .map(
                    (item) => ListTile(
                      dense: true,
                      onTap: () async {
                        Get.back();
                        final url = item.subtitleUrl;
                        if (url == null || url.isEmpty) return;
                        try {
                          final res = await Request.dio.get<Uint8List>(
                            url.http2https,
                            options: Options(
                              responseType: ResponseType.bytes,
                              headers: Constants.baseHeaders,
                              extra: {'account': const NoAccount()},
                            ),
                          );
                          if (res.statusCode == 200) {
                            final bytes = Uint8List.fromList(
                              Request.responseBytesDecoder(
                                res.data!,
                                res.headers.map,
                              ),
                            );
                            String name =
                                '${widget.introController.videoDetail.value.title}-${widget.videoDetailController.bvid}-${widget.videoDetailController.cid.value}-${item.lanDoc}.json';
                            if (Platform.isWindows) {
                              // Reserved characters may not be used in file names. See: https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file#naming-conventions
                              name = name.replaceAll(
                                RegExp(r'[<>:/\\|?*"]'),
                                '',
                              );
                            }
                            Utils.saveBytes2File(
                              name: name,
                              bytes: bytes,
                              allowedExtensions: const ['json'],
                            );
                          }
                        } catch (e, s) {
                          Utils.reportError(e, s);
                          SmartDialog.showToast(e.toString());
                        }
                      },
                      title: Text(
                        item.lanDoc!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  // 选择解码格式
  void showSetDecodeFormats() {
    final VideoItem firstVideo = widget.videoDetailController.firstVideo;
    // 当前视频可用的解码格式
    final List<FormatItem> videoFormat = videoInfo.supportFormats!;
    final List<String>? list = videoFormat
        .firstWhere((FormatItem e) => e.quality == firstVideo.quality.code)
        .codecs;
    if (list == null) {
      SmartDialog.showToast('当前视频不支持选择解码格式');
      return;
    }

    // 当前选中的解码格式
    final VideoDecodeFormatType currentDecodeFormats =
        widget.videoDetailController.currentDecodeFormats;
    showBottomSheet(
      (context, setState) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
            clipBehavior: Clip.hardEdge,
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: Column(
              children: [
                const SizedBox(
                  height: 45,
                  child: Center(
                    child: Text('选择解码格式', style: TextStyle(fontSize: 14)),
                  ),
                ),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverList.builder(
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final item = list[index];
                          final format = VideoDecodeFormatType.fromString(item);
                          final isCurr = currentDecodeFormats.codes.any(
                            item.startsWith,
                          );
                          return ListTile(
                            dense: true,
                            onTap: () {
                              if (isCurr) {
                                return;
                              }
                              Get.back();
                              widget.videoDetailController
                                ..currentDecodeFormats = format
                                ..updatePlayer();
                            },
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            title: Text(format.description),
                            subtitle: Text(item, style: const TextStyle(fontSize: 12)),
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 选择音质
  void showSetAudioQa() {
    final AudioQuality currentAudioQa = widget.videoDetailController.currentAudioQa!;
    final List<AudioItem> audio = videoInfo.dash!.audio!;
    showBottomSheet(
      (context, setState) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
            clipBehavior: Clip.hardEdge,
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 45,
                    child: Center(
                      child: Text('选择音质', style: TextStyle(fontSize: 14)),
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
                        widget.videoDetailController
                          ..plPlayerController.cacheAudioQa = newQa.code
                          ..currentAudioQa = newQa
                          ..updatePlayer();

                        SmartDialog.showToast("音质已变为：${newQa.desc}");

                        // update
                        if (!widget.controller.tempPlayerConf) {
                          setting.put(
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
                        style: const TextStyle(fontSize: 12),
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
          ),
        );
      },
    );
  }

  /// 选择画质
  void showSetVideoQa() {
    if (videoInfo.dash == null) {
      SmartDialog.showToast('当前视频不支持选择画质');
      return;
    }
    final VideoQuality? currentVideoQa = widget.videoDetailController.currentVideoQa.value;
    if (currentVideoQa == null) return;

    final List<FormatItem> videoFormat = videoInfo.supportFormats!;

    /// 总质量分类
    final int totalQaSam = videoFormat.length;

    /// 可用的质量分类
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

    showBottomSheet(
      (context, setState) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
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
                          const Text('选择画质', style: TextStyle(fontSize: 14)),
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
                        widget.videoDetailController
                          ..plPlayerController.cacheVideoQa = newQa.code
                          ..currentVideoQa.value = newQa
                          ..updatePlayer();

                        SmartDialog.showToast("画质已变为：${newQa.desc}");

                        // update
                        if (!widget.controller.tempPlayerConf) {
                          setting.put(
                            await Utils.isWiFi
                                ? SettingBoxKey.defaultVideoQa
                                : SettingBoxKey.defaultVideoQaCellular,
                            quality,
                          );
                        }
                      },
                      // 可能包含会员解锁画质
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
                              style: const TextStyle(fontSize: 12),
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
