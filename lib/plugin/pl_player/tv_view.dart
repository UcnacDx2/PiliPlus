import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:flutter/material.dart';

class TvVideoPlayer extends StatefulWidget {
  const TvVideoPlayer({
    required this.plPlayerController,
    this.headerControl,
    this.bottomControl,
    super.key,
  });

  final PlPlayerController plPlayerController;
  final Widget? headerControl;
  final Widget? bottomControl;

  @override
  State<TvVideoPlayer> createState() => _TvVideoPlayerState();
}

class _TvVideoPlayerState extends State<TvVideoPlayer> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("TV Video Player"),
      ),
    );
  }
}
