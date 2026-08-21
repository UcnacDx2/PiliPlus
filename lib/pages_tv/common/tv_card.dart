import 'package:PiliPlus/common/widgets/image/first_frame_or_cover.dart';
import 'package:PiliPlus/pages_tv/common/tv_focus_wrapper.dart';
import 'package:flutter/material.dart';

class TVCard extends StatelessWidget {
  const TVCard({
    super.key,
    required this.title,
    this.subtitle,
    this.coverUrl,
    this.firstFrameUrl,
    this.bvid,
    this.cid,
    this.badge,
    this.onSelect,
    this.onLongPress,
    this.width = 200,
    this.height,
    this.isVertical = false,
    this.autoFocus = false,
  });

  final String title;
  final String? subtitle;
  final String? coverUrl;
  final String? firstFrameUrl;
  final String? bvid;
  final int? cid;
  final String? badge;
  final VoidCallback? onSelect;
  final VoidCallback? onLongPress;
  final double width;
  final double? height;
  final bool isVertical;
  final bool autoFocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isInfiniteWidth = width == double.infinity;
    final coverHeight = isInfiniteWidth
        ? null
        : (isVertical
            ? width * 1.4
            : width * 9 / 16);
    final cardHeight = isInfiniteWidth
        ? null
        : (height ?? coverHeight! + 60);

    Widget buildCover(double w, double h) => Stack(
          children: [
            FirstFrameOrCover(
              coverUrl: coverUrl,
              firstFrameUrl: firstFrameUrl,
              bvid: bvid,
              cid: cid,
              width: w,
              height: h,
              borderRadius: BorderRadius.zero,
            ),
            if (badge != null)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        );

    return TVFocusWrapper(
      onSelect: onSelect,
      onLongPress: onLongPress,
      autoFocus: autoFocus,
      child: isInfiniteWidth
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => buildCover(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            )
          : SizedBox(
              width: width,
              height: cardHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildCover(width, coverHeight!),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
