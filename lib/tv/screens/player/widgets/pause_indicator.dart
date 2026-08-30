import 'package:flutter/material.dart';
import 'mpv_video_player_compat.dart';

class PauseIndicator extends StatelessWidget {
  final VideoPlayerController? controller;

  const PauseIndicator({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller == null) return const SizedBox.shrink();

    // 由于 VideoPlayerValue 不是 ValueListenable，我们依赖父组件重建
    final isPlaying = controller!.value.isPlaying;
    final isBuffering = controller!.value.isBuffering;

    if (!isPlaying && !isBuffering) {
      return Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(20),
          child: const Icon(Icons.pause, color: Colors.white, size: 64),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
