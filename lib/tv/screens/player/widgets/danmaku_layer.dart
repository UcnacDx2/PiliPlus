import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/material.dart';

class DanmakuLayer extends StatelessWidget {
  final Function(DanmakuController) onCreated;
  final DanmakuOption option;

  const DanmakuLayer({
    super.key,
    required this.onCreated,
    required this.option,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DanmakuScreen(createdController: onCreated, option: option),
    );
  }
}
