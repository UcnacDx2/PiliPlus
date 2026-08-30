import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class ConditionalMarquee extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double blankSpace;
  final double velocity;
  final int? maxLines;
  final bool alwaysScroll; // 如果为 true，则强制滚动（不推荐，除非无法计算宽度）

  const ConditionalMarquee({
    super.key,
    required this.text,
    required this.style,
    this.blankSpace = 30.0,
    this.velocity = 50.0,
    this.maxLines = 1,
    this.alwaysScroll = false,
  });

  @override
  Widget build(BuildContext context) {
    if (alwaysScroll) {
      return _buildMarquee();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 使用 TextPainter 测量文本宽度
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(minWidth: 0, maxWidth: double.infinity);

        // 如果文本宽度超出了容器的最大宽度，使用 Marquee
        if (textPainter.width > constraints.maxWidth) {
          return _buildMarquee();
        }

        // 否则显示普通文本
        return Text(
          text,
          style: style,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  Widget _buildMarquee() {
    return Marquee(
      text: text,
      style: style,
      scrollAxis: Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.start,
      blankSpace: blankSpace,
      velocity: velocity,
      pauseAfterRound: const Duration(seconds: 2), // 停顿久一点
      startPadding: 0.0,
      accelerationDuration: const Duration(milliseconds: 500),
      accelerationCurve: Curves.linear,
      decelerationDuration: const Duration(milliseconds: 300),
      decelerationCurve: Curves.easeOut,
    );
  }
}
