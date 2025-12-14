import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/tv_controller.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/tv_progress_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';

class TvVideoPlayer extends StatefulWidget {
  const TvVideoPlayer({
    required this.plPlayerController,
    this.headerControl,
    this.bottomControl,
    super.key,
  });

  final PlPlayerController plPlayerController;
  final Widget? headerControl;
  final Widget? bottomControl;

  @override
  State<TvVideoPlayer> createState() => _TvVideoPlayerState();
}

class _TvVideoPlayerState extends State<TvVideoPlayer> {
  late final TvPlayerController _tvController =
      TvPlayerController(widget.plPlayerController);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (widget.plPlayerController.showControls.value) {
              if (event.logicalKey == LogicalKeyboardKey.goBack ||
                  event.logicalKey == LogicalKeyboardKey.escape) {
                widget.plPlayerController.showControls.value = false;
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            } else {
              return _tvController.handleKeyEventWhenHidden(event);
            }
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(child: Video(controller: widget.plPlayerController.videoController!)),
            Obx(() {
              if (!widget.plPlayerController.showControls.value) {
                return const SizedBox.shrink();
              }
              return Container(
                color: Colors.black.withOpacity(0.5),
                child: Column(
                  children: [
                    SizedBox(
                      height: 60,
                      child: Focus(
                        focusNode: _tvController.focusNodeA,
                        child: widget.headerControl ?? const SizedBox.shrink(),
                      ),
                    ),
                    const Spacer(),
                    TvProgressControl(controller: _tvController),
                    const Spacer(),
                    SizedBox(
                      height: 60,
                      child: Focus(
                        focusNode: _tvController.focusNodeC,
                        child: widget.bottomControl ?? const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
