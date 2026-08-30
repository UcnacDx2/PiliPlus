import 'package:flutter/material.dart';

/// TV 遥控器优化的视频进度条
///
/// 特性:
/// - 圆点指示器显示当前位置
/// - 支持焦点高亮
/// - 显示缓冲进度
class TvProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final bool isFocused;
  final Duration? previewPosition; // 预览位置（快进/快退时显示）

  const TvProgressBar({
    super.key,
    required this.position,
    required this.duration,
    this.buffered = Duration.zero,
    this.isFocused = false,
    this.previewPosition,
  });

  @override
  Widget build(BuildContext context) {
    final totalMs = duration.inMilliseconds;
    final positionMs = position.inMilliseconds;
    final bufferedMs = buffered.inMilliseconds;
    final previewMs = previewPosition?.inMilliseconds;

    // 计算百分比
    final progress = totalMs > 0 ? positionMs / totalMs : 0.0;
    final bufferedProgress = totalMs > 0 ? bufferedMs / totalMs : 0.0;
    final previewProgress = (previewMs != null && totalMs > 0)
        ? previewMs / totalMs
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final dotX = progress * width;
        final previewDotX = previewProgress != null
            ? previewProgress * width
            : null;

        return SizedBox(
          height: 40, // 增加高度以容纳预览标签
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 进度条主体
              Positioned(
                left: 0,
                right: 0,
                top: 16,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  child: Stack(
                    children: [
                      // 缓冲进度
                      FractionallySizedBox(
                        widthFactor: bufferedProgress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: Colors.white24,
                          ),
                        ),
                      ),
                      // 已播放进度
                      FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: const Color(0xFFfb7299), // B站粉
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 预览位置指示器（快进/快退时）
              if (previewDotX != null && previewProgress != null)
                Positioned(
                  left: previewDotX.clamp(10.0, width - 10.0) - 10,
                  top: 8,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFFfb7299),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.6),
                          blurRadius: 10,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),

              // 当前位置圆点
              if (previewDotX == null) // 正常播放时显示
                Positioned(
                  left: dotX.clamp(8.0, width - 8.0) - 8,
                  top: isFocused ? 8 : 10,
                  child: Container(
                    width: isFocused ? 20 : 16,
                    height: isFocused ? 20 : 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFfb7299),
                      border: isFocused
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isFocused
                          ? [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.6),
                                blurRadius: 12,
                                spreadRadius: 3,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),

              // 预览时间标签
              if (previewPosition != null && previewDotX != null)
                Positioned(
                  left: (previewDotX - 30).clamp(0.0, width - 60),
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDuration(previewPosition!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
