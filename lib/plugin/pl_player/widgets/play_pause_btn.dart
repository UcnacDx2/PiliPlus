import 'dart:async';

import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/focusable_btn.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class PlayOrPauseButton extends StatefulWidget {
  final PlPlayerController plPlayerController;
  final FocusNode? focusNode;
  final bool autofocus;

  const PlayOrPauseButton({
    super.key,
    required this.plPlayerController,
    this.focusNode,
    this.autofocus = false,
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
    return FocusableBtn(
      width: 42,
      height: 34,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onPressed: widget.plPlayerController.onDoubleTapCenter,
      child: AnimatedIcon(
        semanticLabel: player.state.playing ? '暂停' : '播放',
        progress: controller,
        icon: AnimatedIcons.play_pause,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
