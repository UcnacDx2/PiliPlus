import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:PiliPlus/models/common/video/video_quality.dart';
import 'package:PiliPlus/plugin/pl_player/models/video_fit_type.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import '../tv_controller.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/utils.dart';

class TvBottomControl extends StatefulWidget {
  final TvPlayerController controller;
  final String heroTag;

  const TvBottomControl({
    super.key,
    required this.controller,
    required this.heroTag,
  });

  @override
  State<TvBottomControl> createState() => _TvBottomControlState();
}

class _TvBottomControlState extends State<TvBottomControl> {
  late final VideoDetailController _videoDetailController;
  late final FocusNode _qualityNode;
  late final FocusNode _speedNode;
  late final FocusNode _subtitleNode;
  late final FocusNode _episodeNode;
  late final FocusNode _fitNode;

  @override
  void initState() {
    super.initState();
    _videoDetailController = Get.find<VideoDetailController>(
      tag: widget.heroTag,
    );
    _qualityNode = FocusNode();
    _speedNode = FocusNode();
    _subtitleNode = FocusNode();
    _episodeNode = FocusNode();
    _fitNode = FocusNode();
  }

  @override
  void dispose() {
    _qualityNode.dispose();
    _speedNode.dispose();
    _subtitleNode.dispose();
    _episodeNode.dispose();
    _fitNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.controller.focusNodeC,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.black.withOpacity(0.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildQualityMenu(),
            _buildSpeedMenu(),
            _buildSubtitleMenu(),
            _buildEpisodeMenu(),
            _buildFitMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityMenu() {
    return Obx(
      () {
        final currentQa = _videoDetailController.currentVideoQa.value;
        if (currentQa == null) return const SizedBox.shrink();

        return PopupMenuButton<int>(
          focusNode: _qualityNode,
          tooltip: '画质',
          initialValue: currentQa.code,
          itemBuilder: (context) {
            return _videoDetailController.data.supportFormats!.map((format) {
              return PopupMenuItem<int>(
                value: format.quality,
                child: Text(format.newDesc ?? ''),
                onTap: () async {
                  if (currentQa.code == format.quality) {
                    return;
                  }
                  final newQa = VideoQuality.fromCode(format.quality);
                  _videoDetailController
                    ..plPlayerController.cacheVideoQa = newQa.code
                    ..currentVideoQa.value = newQa
                    ..updatePlayer();
                  SmartDialog.showToast('画质已变为：${newQa.desc}');
                  if (!widget.controller.tempPlayerConf) {
                    GStorage.setting.put(
                      await Utils.isWiFi
                          ? SettingBoxKey.defaultVideoQa
                          : SettingBoxKey.defaultVideoQaCellular,
                      format.quality,
                    );
                  }
                },
              );
            }).toList();
          },
          child: _buildButtonContent(
            icon: Icons.high_quality,
            label: currentQa.shortDesc,
          ),
        );
      },
    );
  }

  Widget _buildSpeedMenu() {
    return Obx(
      () => PopupMenuButton<double>(
        focusNode: _speedNode,
        tooltip: '倍速',
        initialValue: widget.controller.playbackSpeed,
        itemBuilder: (context) {
          return widget.controller.speedList.map((speed) {
            return PopupMenuItem<double>(
              value: speed,
              child: Text('${speed}X'),
              onTap: () => widget.controller.setPlaybackSpeed(speed),
            );
          }).toList();
        },
        child: _buildButtonContent(
          icon: Icons.speed,
          label: '${widget.controller.playbackSpeed}X',
        ),
      ),
    );
  }

  Widget _buildSubtitleMenu() {
    return Obx(
      () {
        if (_videoDetailController.subtitles.isEmpty) {
          return const SizedBox.shrink();
        }
        return PopupMenuButton<int>(
          focusNode: _subtitleNode,
          tooltip: '字幕',
          initialValue: _videoDetailController.vttSubtitlesIndex.value,
          itemBuilder: (context) {
            return [
              const PopupMenuItem<int>(value: 0, child: Text('关闭字幕')),
              ..._videoDetailController.subtitles.indexed.map((e) {
                return PopupMenuItem<int>(
                  value: e.$1 + 1,
                  child: Text(e.$2.lanDoc),
                );
              }),
            ];
          },
          onSelected: (index) => _videoDetailController.setSubtitle(index),
          child: _buildButtonContent(
            icon: Icons.subtitles,
            label: '字幕',
          ),
        );
      },
    );
  }

  Widget _buildButtonContent({required IconData icon, required String label}) {
    return Builder(
      builder: (context) {
        final isFocused = Focus.of(context).hasFocus;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isFocused ? Colors.white.withOpacity(0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEpisodeMenu() {
    return Obx(() {
      final introController = _videoDetailController.introController;
      if (introController.videoDetail.value.pages?.isEmpty ?? true) {
        return const SizedBox.shrink();
      }
      return PopupMenuButton<int>(
        focusNode: _episodeNode,
        tooltip: '选集',
        itemBuilder: (context) {
          return introController.videoDetail.value.pages!.map((page) {
            return PopupMenuItem<int>(
              value: page.page,
              child: Text(page.part),
              onTap: () => introController.onChangeEpisode(page),
            );
          }).toList();
        },
        child: _buildButtonContent(
          icon: Icons.list,
          label: '选集',
        ),
      );
    });
  }

  Widget _buildFitMenu() {
    return Obx(
      () => PopupMenuButton<VideoFitType>(
        focusNode: _fitNode,
        tooltip: '画面比例',
        initialValue: widget.controller.videoFit.value,
        itemBuilder: (context) {
          return VideoFitType.values.map((fit) {
            return PopupMenuItem<VideoFitType>(
              value: fit,
              child: Text(fit.desc),
              onTap: () => widget.controller.toggleVideoFit(fit),
            );
          }).toList();
        },
        child: _buildButtonContent(
          icon: Icons.aspect_ratio,
          label: widget.controller.videoFit.value.desc,
        ),
      ),
    );
  }
}
