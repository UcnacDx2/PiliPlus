import 'dart:async';

import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';

class PlayOrPauseButton extends StatefulWidget {
  final PlPlayerController plPlayerController;
  final FocusNode? focusNode;

  const PlayOrPauseButton({
    super.key,
    required this.plPlayerController,
    this.focusNode,
  });

  @override
  PlayOrPauseButtonState createState() => PlayOrPauseButtonState();
}

class PlayOrPauseButtonState extends State<PlayOrPauseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final StreamSubscription<bool> subscription;
  late Player player;

  @override
  void initState() {
    super.initState();
    player = widget.plPlayerController.videoPlayerController!;
    controller = AnimationController(
      vsync: this,
      value: player.state.playing ? 1 : 0,
      duration: const Duration(milliseconds: 200),
    );
    subscription = player.stream.playing.listen((playing) {
      if (playing) {
        controller.forward();
      } else {
        controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.plPlayerController.onDoubleTapCenter();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: SizedBox(
        width: 42,
        height: 34,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.plPlayerController.onDoubleTapCenter,
          child: Center(
            child: AnimatedIcon(
              semanticLabel: player.state.playing ? '暂停' : '播放',
              progress: controller,
              icon: AnimatedIcons.play_pause,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
