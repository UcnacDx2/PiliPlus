import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:piliplus/plugin/pl_player/tv_controller.dart';
import 'package:piliplus/plugin/pl_player/utils/duration.dart';

class TvProgressControl extends StatefulWidget {
  final TvPlayerController controller;

  const TvProgressControl({super.key, required this.controller});

  @override
  State<TvProgressControl> createState() => _TvProgressControlState();
}

class _TvProgressControlState extends State<TvProgressControl> {
  late final TvPlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.select:
        case LogicalKeyboardKey.enter:
          controller.videoPlayerController!.playOrPause();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowLeft:
          controller.seekTo(
            controller.position.value - controller.fastForBackwardDuration,
          );
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowRight:
          controller.seekTo(
            controller.position.value + controller.fastForBackwardDuration,
          );
          return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: controller.focusNodeB,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.black.withOpacity(0.5),
        child: Obx(
          () {
            final position = controller.position.value;
            final duration = controller.duration.value;
            final buffered = controller.buffered.value;

            return Row(
              children: [
                Text(
                  DurationUtils.formatDuration(position.inSeconds),
                  style: const TextStyle(color: Colors.white),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
                    ),
                    child: Slider(
                      value: position.inMilliseconds.toDouble(),
                      max: duration.inMilliseconds.toDouble(),
                      secondaryTrackValue: buffered.inMilliseconds.toDouble(),
                      onChanged: (value) {
                        controller.seekTo(Duration(milliseconds: value.toInt()));
                      },
                      label: DurationUtils.formatDuration(position.inSeconds),
                    ),
                  ),
                ),
                Text(
                  DurationUtils.formatDuration(duration.inSeconds),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
