import 'package:PiliPlus/common/widgets/image/first_frame_or_cover.dart';
import 'package:PiliPlus/pages_tv/common/tv_focus_wrapper.dart';
import 'package:material_ui/material_ui.dart';

/// Shared TV presentation card. Data stays in PiliPlus models; these fields
/// only describe optional text rendered by the BiliTV-style skin.
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
    this.viewText,
    this.durationText,
    this.ownerText,
    this.publishText,
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
  final String? viewText;
  final String? durationText;
  final String? ownerText;
  final String? publishText;
  final VoidCallback? onSelect;
  final VoidCallback? onLongPress;
  final double width;
  final double? height;
  final bool isVertical;
  final bool autoFocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final infinite = width == double.infinity;
    final coverHeight = infinite ? null : (isVertical ? width * 1.4 : width * 9 / 16);
    final cardHeight = infinite ? null : (height ?? coverHeight! + 64);

    Widget cover(double w, double h) => ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(children: [
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
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(badge!, style: TextStyle(
                      color: theme.colorScheme.onPrimary, fontSize: 11)),
                  ),
                ),
              ),
            if (viewText != null || durationText != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 18, 8, 7),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xE6000000)],
                    ),
                  ),
                  child: Row(children: [
                    if (viewText != null) ...[
                      const Icon(Icons.play_arrow_rounded, size: 14, color: Colors.white70),
                      const SizedBox(width: 2),
                      Text(viewText!, style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                    if (durationText != null) ...[
                      const Spacer(),
                      Text(durationText!, style: const TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ]),
                ),
              ),
          ]),
        );

    Widget info() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            ),
            if (ownerText != null || publishText != null || subtitle != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(children: [
                  if (ownerText != null || subtitle != null)
                    Expanded(child: Text(ownerText ?? subtitle!, maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant))),
                  if (publishText != null)
                    Text(publishText!, style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
                ]),
              ),
          ],
        );

    return TVFocusWrapper(
      onSelect: onSelect,
      onLongPress: onLongPress,
      autoFocus: autoFocus,
      child: infinite
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: LayoutBuilder(builder: (_, c) => cover(c.maxWidth, c.maxHeight))),
              const SizedBox(height: 8),
              info(),
            ])
          : SizedBox(
              width: width,
              height: cardHeight,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                cover(width, coverHeight!),
                const SizedBox(height: 8),
                info(),
              ]),
            ),
    );
  }
}
