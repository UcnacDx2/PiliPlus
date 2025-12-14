import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/plugin/pl_player/tv_controller.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/tv_bottom_control.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/tv_progress_control.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/tv_top_control.dart';
import 'package:media_kit_video/media_kit_video.dart';

class TvVideoPlayer extends StatefulWidget {
  final TvPlayerController controller;

  const TvVideoPlayer({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  _TvVideoPlayerState createState() => _TvVideoPlayerState();
}

class _TvVideoPlayerState extends State<TvVideoPlayer> {
  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.goBack) {
          return widget.controller.handleBackKey();
        }
        return widget.controller.handleKeyEventWhenHidden(event);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video player widget
          Video(controller: widget.controller.plPlayerController.videoController!),

          // TV-specific controls
          Obx(() => Visibility(
            visible: widget.controller.plPlayerController.showControls.value,
            child: _buildTvControls(),
          )),
        ],
      ),
    );
  }

  Widget _buildTvControls() {
    return Column(
      children: [
        // Top control bar
        Focus(
          focusNode: widget.controller.focusNodeA,
          onFocusChange: (hasFocus) {
            if (hasFocus) widget.controller.handleFocusChange(FocusArea.top);
          },
          child: TvTopControl(controller: widget.controller),
        ),

        const Spacer(),

        // Progress bar
        Focus(
          focusNode: widget.controller.focusNodeB,
          onFocusChange: (hasFocus) {
            if (hasFocus) widget.controller.handleFocusChange(FocusArea.progress);
          },
          child: TvProgressControl(controller: widget.controller),
        ),

        // Bottom control bar
        Focus(
          focusNode: widget.controller.focusNodeC,
          onFocusChange: (hasFocus) {
            if (hasFocus) widget.controller.handleFocusChange(FocusArea.bottom);
          },
          child: TvBottomControl(controller: widget.controller),
        ),
      ],
    );
  }
}
