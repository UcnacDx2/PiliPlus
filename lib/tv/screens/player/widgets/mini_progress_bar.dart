import 'package:flutter/material.dart';

/// 迷你进度条 - 显示在屏幕底部，当控制栏隐藏时显示
class MiniProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;

  const MiniProgressBar({
    super.key,
    required this.position,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 4,
        child: Stack(
          children: [
            // 背景条
            Container(color: Colors.white.withValues(alpha: 0.3)),
            // 进度条
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 粉色进度
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFfb7299), // B站粉
                    ),
                  ),
                  // 半圆指示器
                  Positioned(
                    right: -4,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFfb7299), // B站粉
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
