import 'package:flutter/material.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import '../../../models/videoshot.dart';
import '../../../services/api/videoshot_api.dart';

/// 快进预览缩略图 Widget
/// 从雪碧图中裁剪并显示指定帧
class SeekPreviewThumbnail extends StatelessWidget {
  /// 快照数据
  final VideoshotData videoshotData;

  /// 当前预览位置
  final Duration previewPosition;

  /// 显示尺寸缩放比例
  final double scale;

  const SeekPreviewThumbnail({
    super.key,
    required this.videoshotData,
    required this.previewPosition,
    this.scale = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final frameInfo = videoshotData.getFrameAt(previewPosition);
    if (frameInfo == null) {
      return const SizedBox.shrink();
    }

    final displayWidth = frameInfo.width * scale;
    final displayHeight = frameInfo.height * scale;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: displayWidth,
          height: displayHeight,
          child: _buildCroppedImage(frameInfo, displayWidth, displayHeight),
        ),
      ),
    );
  }

  Widget _buildCroppedImage(
    FrameInfo frameInfo,
    double displayWidth,
    double displayHeight,
  ) {
    // 计算雪碧图总尺寸
    final spriteWidth = (videoshotData.imgXLen * videoshotData.imgXSize)
        .toDouble();
    final spriteHeight = (videoshotData.imgYLen * videoshotData.imgYSize)
        .toDouble();

    // 缩放后的雪碧图尺寸
    final scaledSpriteWidth = spriteWidth * scale;
    final scaledSpriteHeight = spriteHeight * scale;

    // 缩放后的偏移
    final offsetX = frameInfo.x * scale;
    final offsetY = frameInfo.y * scale;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: -offsetX,
          top: -offsetY,
          child: CachedNetworkImage(
            imageUrl: frameInfo.imageUrl,
            cacheManager: VideoshotApi.cacheManager,
            width: scaledSpriteWidth,
            height: scaledSpriteHeight,
            fit: BoxFit.fill,
            httpHeaders: const {
              'Referer': 'https://www.bilibili.com',
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
            placeholder: (context, url) => Container(
              width: displayWidth,
              height: displayHeight,
              color: Colors.grey[800],
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              width: displayWidth,
              height: displayHeight,
              color: Colors.grey[800],
              child: const Icon(
                Icons.image_not_supported,
                color: Colors.white54,
                size: 32,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
