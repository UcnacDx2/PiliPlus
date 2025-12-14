import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/plugin/pl_player/tv_controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_status.dart';

class TvTopControl extends StatelessWidget {
  final TvPlayerController controller;

  const TvTopControl({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(8.0),
        color: Colors.black.withOpacity(0.5),
        child: Row(
          children: [
            // Back button
            FocusableActionDetector(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            // Title
            Expanded(
              child: Text(
                controller.plPlayerController.videoPlayerController?.state.playlist.medias.first.extras?['title'] ?? 'Video Title',
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const Spacer(),

            // Play/Pause button
            FocusableActionDetector(
              child: IconButton(
                icon: Icon(
                  controller.plPlayerController.playerStatus.value == PlayerStatus.playing
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () => controller.plPlayerController.onDoubleTapCenter(),
              ),
            ),

            // Next episode button
            FocusableActionDetector(
              child: IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white),
                onPressed: () {
                  // Handle next episode
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
