import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:flutter/material.dart';

class TvBottomControl extends StatelessWidget {
  final PlPlayerController controller;

  const TvBottomControl({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FocusableActionDetector(
          child: IconButton(
            icon: const Icon(Icons.skip_previous),
            onPressed: () {},
          ),
        ),
        FocusableActionDetector(
          child: IconButton(
            icon: Obx(() => Icon(
                  controller.playerStatus.value == PlayerStatus.playing
                      ? Icons.pause
                      : Icons.play_arrow,
                )),
            onPressed: () => controller.videoPlayerController?.playOrPause(),
          ),
        ),
        FocusableActionDetector(
          child: IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: () {},
          ),
        ),
        FocusableActionDetector(
          child: IconButton(
            icon: const Icon(Icons.aspect_ratio),
            onPressed: () {},
          ),
        ),
        FocusableActionDetector(
          child: IconButton(
            icon: const Icon(Icons.speed),
            onPressed: () {},
          ),
        ),
        FocusableActionDetector(
          child: IconButton(
            icon: const Icon(Icons.high_quality),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}
