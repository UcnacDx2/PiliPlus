import 'package:PiliPlus/plugin/pl_player/tv_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class TvProgressControl extends StatefulWidget {
  const TvProgressControl({super.key, required this.controller});

  final TvPlayerController controller;

  @override
  State<TvProgressControl> createState() => _TvProgressControlState();
}

class _TvProgressControlState extends State<TvProgressControl> {
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.controller.focusNodeB,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          switch (event.logicalKey) {
            case LogicalKeyboardKey.select:
              widget.controller.videoPlayerController?.playOrPause();
              return KeyEventResult.handled;
            case LogicalKeyboardKey.arrowLeft:
              widget.controller.seekTo(
                widget.controller.position.value - const Duration(seconds: 10),
              );
              return KeyEventResult.handled;
            case LogicalKeyboardKey.arrowRight:
              widget.controller.seekTo(
                widget.controller.position.value + const Duration(seconds: 10),
              );
              return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Obx(
        () => Row(
          children: [
            Text(
              widget.controller.position.value.toString().substring(2, 7),
              style: const TextStyle(color: Colors.white),
            ),
            Expanded(
              child: Slider(
                value: widget.controller.position.value.inMilliseconds
                    .toDouble(),
                max: widget.controller.duration.value.inMilliseconds
                    .toDouble(),
                onChanged: (value) {
                  widget.controller.seekTo(
                    Duration(milliseconds: value.toInt()),
                  );
                },
              ),
            ),
            Text(
              widget.controller.duration.value.toString().substring(2, 7),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
