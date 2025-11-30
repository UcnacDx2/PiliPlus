import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:flutter/material.dart';

class SetDanmakuPanel extends StatelessWidget {
  const SetDanmakuPanel({
    super.key,
    required this.videoDetailCtr,
    required this.plPlayerController,
  });

  final VideoDetailController videoDetailCtr;
  final PlPlayerController plPlayerController;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      child: Center(
        child: Text('Danmaku Panel Placeholder'),
      ),
    );
  }
}
