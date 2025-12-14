import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/pages/common/common_intro_controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/tv_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:PiliPlus/models_new/video/video_detail/episode.dart' as ugc;
import 'package:PiliPlus/models_new/video/video_detail/ugc_season.dart';
import 'widgets/tv_top_control.dart';
import 'widgets/tv_progress_control.dart';
import 'widgets/tv_bottom_control.dart';

class TvVideoPlayer extends StatefulWidget {
  const TvVideoPlayer({
    required this.maxWidth,
    required this.maxHeight,
    required this.plPlayerController,
    this.videoDetailController,
    this.introController,
    required this.headerControl,
    this.bottomControl,
    this.danmuWidget,
    this.showEpisodes,
    this.showViewPoints,
    this.fill = Colors.black,
    this.alignment = Alignment.center,
    super.key,
  });

  final double maxWidth;
  final double maxHeight;
  final PlPlayerController plPlayerController;
  final VideoDetailController? videoDetailController;
  final CommonIntroController? introController;
  final Widget headerControl;
  final Widget? bottomControl;
  final Widget? danmuWidget;
  final void Function([
    int?,
    UgcSeason?,
    List<ugc.BaseEpisodeItem>?,
    String?,
    int?,
    int?,
  ])? showEpisodes;
  final VoidCallback? showViewPoints;
  final Color fill;
  final Alignment alignment;

  @override
  State<TvVideoPlayer> createState() => _TvVideoPlayerState();
}

class _TvVideoPlayerState extends State<TvVideoPlayer> {
  late final TvPlayerController _controller =
      widget.plPlayerController as TvPlayerController;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.goBack) {
          return _controller.handleBackKey();
        }
        if (_controller.showControls.value) {
          return KeyEventResult.ignored;
        } else {
          return _controller.handleKeyEventWhenHidden(event);
        }
      },
      child: Stack(
        children: [
          SizedBox(
            width: widget.maxWidth,
            height: widget.maxHeight,
            child: Video(
              controller: _controller.videoController!,
              fill: widget.fill,
              alignment: widget.alignment,
              fit: BoxFit.contain,
            ),
          ),
          Obx(
            () => _controller.showControls.value
                ? Container(
                    color: Colors.black.withAlpha(77),
                    child: Column(
                      children: [
                        TvTopControl(controller: _controller),
                        const Spacer(),
                        TvProgressControl(controller: _controller),
                        const Spacer(),
                        TvBottomControl(
                          controller: _controller,
                          videoDetailController: widget.videoDetailController!,
                          introController: widget.introController!,
                          showEpisodes: widget.showEpisodes,
                          showViewPoints: widget.showViewPoints,
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
