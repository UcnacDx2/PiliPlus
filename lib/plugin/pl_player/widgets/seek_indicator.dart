import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';

class SeekIndicator extends StatelessWidget {
  final PlPlayerController controller;

  const SeekIndicator({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.showSeekIndicator.value) {
        return const SizedBox.shrink();
      }
      return Material(
        type: MaterialType.transparency,
        child: Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Obx(
                () => Icon(
                  controller.isSeekingForward.value
                      ? Icons.fast_forward
                      : Icons.fast_rewind,
                  size: 24.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8.0),
              Obx(() => Text(
                '${DurationUtils.formatDuration(controller.sliderPosition.value.inSeconds)} / ${DurationUtils.formatDuration(controller.duration.value.inSeconds)}',
                style: const TextStyle(
                  fontSize: 12.0,
                  color: Colors.white,
                ),
              )),
            ],
          ),
        ),
      );
    });
  }
}
