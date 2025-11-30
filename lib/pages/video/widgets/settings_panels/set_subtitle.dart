import 'package:PiliPlus/pages/video/index.dart';
import 'package:PiliPlus/plugin/pl_player/index.dart';
import 'package:flutter/material.dart';

class SetSubtitlePanel extends StatelessWidget {
  const SetSubtitlePanel({
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
        child: Text('Subtitle Panel Placeholder'),
      ),
    );
  }
}
