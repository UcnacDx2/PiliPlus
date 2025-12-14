import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_status.dart';
import '../tv_controller.dart';

class TvTopControl extends StatefulWidget {
  final TvPlayerController controller;
  final String heroTag;

  const TvTopControl({super.key, required this.controller, required this.heroTag});

  @override
  State<TvTopControl> createState() => _TvTopControlState();
}

class _TvTopControlState extends State<TvTopControl> {
  late final FocusNode _backButtonFocus;
  late final FocusNode _playPauseFocus;
  late final FocusNode _nextButtonFocus;
  late final VideoDetailController _videoDetailController;

  @override
  void initState() {
    super.initState();
    _backButtonFocus = FocusNode();
    _playPauseFocus = FocusNode();
    _nextButtonFocus = FocusNode();
    _videoDetailController = Get.find<VideoDetailController>(
      tag: widget.heroTag,
    );
  }

  @override
  void dispose() {
    _backButtonFocus.dispose();
    _playPauseFocus.dispose();
    _nextButtonFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.controller.focusNodeA,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.black.withOpacity(0.5),
        child: Row(
          children: [
            // Back button
            FocusableActionDetector(
              focusNode: _backButtonFocus,
              autofocus: true,
              actions: {
                ActivateIntent:
                    CallbackAction<ActivateIntent>(onInvoke: (intent) {
                  Get.back();
                }),
              },
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            const SizedBox(width: 16),
            // Video title
            Obx(
              () => Text(
                _videoDetailController.videoTitle.value,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const Spacer(),
            // Play/Pause button
            FocusableActionDetector(
              focusNode: _playPauseFocus,
              actions: {
                ActivateIntent:
                    CallbackAction<ActivateIntent>(onInvoke: (intent) {
                  widget.controller.togglePlayPause();
                }),
              },
              child: Obx(
                () => Icon(
                  widget.controller.playerStatus.value ==
                          PlayerStatus.playing
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Next episode button
            FocusableActionDetector(
              focusNode: _nextButtonFocus,
              actions: {
                ActivateIntent:
                    CallbackAction<ActivateIntent>(onInvoke: (intent) {
                  _videoDetailController.introController.nextPlay();
                }),
              },
              child: const Icon(Icons.skip_next, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
