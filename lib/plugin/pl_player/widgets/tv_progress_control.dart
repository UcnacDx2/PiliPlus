import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/plugin/pl_player/tv_controller.dart';
import 'package:PiliPlus/plugin/pl_player/utils/duration.dart';

class TvProgressControl extends StatefulWidget {
  final TvPlayerController controller;

  const TvProgressControl({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  _TvProgressControlState createState() => _TvProgressControlState();
}

class _TvProgressControlState extends State<TvProgressControl> {
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.controller.focusNodeB,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          switch (event.logicalKey) {
            case LogicalKeyboardKey.select: // OK key
              widget.controller.plPlayerController.onDoubleTapCenter();
              return KeyEventResult.handled;
            case LogicalKeyboardKey.arrowLeft:
              widget.controller.plPlayerController.onBackward(widget.controller.plPlayerController.fastForBackwardDuration);
              return KeyEventResult.handled;
            case LogicalKeyboardKey.arrowRight:
              widget.controller.plPlayerController.onForward(widget.controller.plPlayerController.fastForBackwardDuration);
              return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Obx(
          () {
            final position = widget.controller.plPlayerController.position.value;
            final duration = widget.controller.plPlayerController.duration.value;
            final progress = duration.inMilliseconds > 0
                ? position.inMilliseconds / duration.inMilliseconds
                : 0.0;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[700],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DurationUtils.formatDuration(position.inSeconds),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      DurationUtils.formatDuration(duration.inSeconds),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
