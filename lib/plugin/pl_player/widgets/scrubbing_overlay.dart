import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/models_new/video/video_shot/data.dart';

class ScrubbingOverlay extends StatelessWidget {
  final PlPlayerController controller;

  const ScrubbingOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isScrubbing.value) {
        return const SizedBox.shrink();
      }

      return Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThumbnail(),
              const SizedBox(height: 16),
              Text(
                '${DurationUtils.formatDuration(
                  controller.scrubbingPosition.value.inSeconds.toDouble(),
                )} / ${DurationUtils.formatDuration(
                  controller.duration.value.inSeconds.toDouble(),
                )}',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 300,
                child: LinearProgressIndicator(
                  value: controller.duration.value.inSeconds == 0
                      ? 0
                      : controller.scrubbingPosition.value.inSeconds /
                          controller.duration.value.inSeconds,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildThumbnail() {
    return Obx(() {
      final videoShot = controller.videoShot;
      if (videoShot == null || videoShot is! Success<VideoShotData>) {
        return const SizedBox(
          width: 160,
          height: 90,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      final data = (videoShot as Success<VideoShotData>).response;
      final seconds = controller.scrubbingPosition.value.inSeconds;
      final index = data.index.lastWhere((i) => i <= seconds, orElse: () => -1);
      if (index == -1) {
        return const SizedBox(width: 160, height: 90);
      }

      return MpvConvertWebp(
        imgUrl: data.image.first,
        seconds: controller.scrubbingPosition.value.inSeconds,
        videoShot: data,
        width: 160,
        height: 90,
      );
    });
  }
}
