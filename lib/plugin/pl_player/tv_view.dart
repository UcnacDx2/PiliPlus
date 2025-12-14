import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'tv_controller.dart';
import 'widgets/tv_bottom_control.dart';
import 'widgets/tv_progress_control.dart';
import 'widgets/tv_top_control.dart';

class TvVideoPlayer extends StatefulWidget {
  final TvPlayerController controller;
  final String heroTag;

  const TvVideoPlayer({
    super.key,
    required this.controller,
    required this.heroTag,
  });

  @override
  State<TvVideoPlayer> createState() => _TvVideoPlayerState();
}

class _TvVideoPlayerState extends State<TvVideoPlayer> {
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.showControls.listen((show) {
      if (show) {
        _startHideTimer();
      } else {
        _hideTimer?.cancel();
      }
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (ModalRoute.of(context)?.isCurrent ?? false) {
        widget.controller.showControls.value = false;
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.goBack) {
          return widget.controller.handleBackKey(event);
        }
        // Reset timer on any key event
        if (widget.controller.showControls.value) {
          _startHideTimer();
        } else {
          return widget.controller.handleKeyEventWhenHidden(event);
        }
        return KeyEventResult.ignored;
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Video(
            controller: widget.controller.videoController!,
            fit: BoxFit.contain,
          ),
          Obx(
            () => AnimatedOpacity(
              opacity: widget.controller.showControls.value ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: AbsorbPointer(
                absorbing: !widget.controller.showControls.value,
                child: Column(
                  children: [
                    TvTopControl(
                      controller: widget.controller,
                      heroTag: widget.heroTag,
                    ),
                    const Spacer(),
                    TvProgressControl(controller: widget.controller),
                    TvBottomControl(
                      controller: widget.controller,
                      heroTag: widget.heroTag,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
