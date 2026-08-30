import 'package:flutter/material.dart';
import 'package:PiliPlus/tv/adapters/tv_video_item.dart';
import 'base_tv_card.dart';
import 'first_frame_or_cover.dart';
import 'conditional_marquee.dart';
import 'package:PiliPlus/tv/adapters/image_url_utils.dart';

class TvVideoCard extends StatelessWidget {
  final TvVideoItem video;
  final VoidCallback onTap;
  final VoidCallback onFocus;
  final VoidCallback? onMoveLeft;
  final VoidCallback? onMoveRight;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onBack;
  final bool autofocus;
  final bool disableCache;
  final FocusNode? focusNode;
  final int? staggerIndex;

  const TvVideoCard({
    super.key,
    required this.video,
    required this.onTap,
    required this.onFocus,
    this.onMoveLeft,
    this.onMoveRight,
    this.onMoveUp,
    this.onMoveDown,
    this.onBack,
    this.autofocus = false,
    this.disableCache = false,
    this.focusNode,
    this.staggerIndex,
  });

  String get _durationText => video.durationFormatted;

  @override
  Widget build(BuildContext context) {
    return BaseTvCard(
      focusNode: focusNode,
      autofocus: autofocus,
      onTap: onTap,
      onFocus: onFocus,
      onMoveLeft: onMoveLeft,
      onMoveRight: onMoveRight,
      onMoveUp: onMoveUp,
      onMoveDown: onMoveDown,
      onBack: onBack,
      imageContent: Stack(
        fit: StackFit.expand,
        children: [
          _buildImage(),
          // 角标 (付费/充电专属)
          if (video.badge.isNotEmpty)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFfb7299),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  video.badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          // 渐变遮罩
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),
          // 底部信息
          Positioned(
            left: 6,
            right: 6,
            bottom: 6,
            child: Row(
              children: [
                const Icon(
                  Icons.play_arrow_rounded,
                  size: 14,
                  color: Colors.white70,
                ),
                Text(
                  video.viewFormatted,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
                const Spacer(),
                Text(
                  _durationText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      infoContentBuilder: (context, isFocused) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题区域
            SizedBox(
              height: 20,
              child: isFocused
                  ? ConditionalMarquee(
                      text: video.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      blankSpace: 30.0,
                      velocity: 30.0, // 稍微慢一点
                    )
                  : Text(
                      video.title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),

            // UP主信息 + 发布时间
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 12,
                  color: Colors.white38,
                ),
                const SizedBox(width: 4),
                // UP主名字 - 可省略
                Expanded(
                  child: Text(
                    video.ownerName,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 发布时间 - 固定位置，不省略
                if (video.pubdateFormatted.isNotEmpty)
                  Text(
                    video.pubdateFormatted,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildImage() {
    // 360x200 必须与 SplashScreen 的 precache 参数完全一致
    const int targetWidth = 360;
    const int targetHeight = 200;

    // 交错加载只延迟首帧检查，普通封面必须立即显示。
    return FirstFrameOrCover(
      coverUrl: ImageUrlUtils.getResizedUrl(video.pic, width: 360, height: 200),
      firstFrameUrl: video.firstFrame,
      bvid: video.bvid,
      cid: video.cid > 0 ? video.cid : null,
      resolveMissingFirstFrame: true,
      inspectDelay: Duration(milliseconds: (staggerIndex ?? 0) * 80),
      width: targetWidth.toDouble(),
      height: targetHeight.toDouble(),
    );
  }
}
