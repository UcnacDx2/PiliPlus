import 'package:PiliPlus/pages/video/index.dart';
import 'package:PiliPlus/plugin/pl_player/index.dart';
import 'package:flutter/material.dart';

class SetVideoQaPanel extends StatelessWidget {
  const SetVideoQaPanel({
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
        child: Text('Video QA Panel Placeholder'),
      ),
    );
  }
}
