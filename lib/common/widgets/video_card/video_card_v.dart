import 'dart:typed_data';

import 'package:PiliPlus/bilibili_api.dart';
import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/stat/stat.dart';
import 'package:PiliPlus/common/widgets/video_popup_menu.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/models/common/badge_type.dart';
import 'package:PiliPlus/models/common/stat_type.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/utils/app_scheme.dart';
import 'package:PiliPlus/utils/date_util.dart';
import 'package:PiliPlus/utils/duration_util.dart';
import 'package:PiliPlus/utils/id_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:intl/intl.dart';

class VideoCardV extends StatefulWidget {
  final BaseRecVideoItemModel videoItem;
  final VoidCallback? onRemove;

  const VideoCardV({
    super.key,
    required this.videoItem,
    this.onRemove,
  });

  static final shortFormat = DateFormat('M-d');
  static final longFormat = DateFormat('yy-M-d');

  @override
  State<VideoCardV> createState() => _VideoCardVState();
}

class _VideoCardVState extends State<VideoCardV> {
  late final Future<Uint8List?> _thumbnailFuture;
  final BilibiliApi _bilibiliApi = BilibiliApi();

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = _bilibiliApi.getThumbnail(
      aid: widget.videoItem.aid?.toString(),
      bvid: widget.videoItem.bvid,
    );
  }

  Future<void> onPushDetail(String heroTag) async {
    String? goto = widget.videoItem.goto;
    switch (goto) {
      case 'bangumi':
        PageUtils.viewPgc(epId: widget.videoItem.param!);
        break;
      case 'av':
        String bvid =
            widget.videoItem.bvid ?? IdUtils.av2bv(widget.videoItem.aid!);
        int? cid =
            widget.videoItem.cid ??
            await SearchHttp.ab2c(aid: widget.videoItem.aid, bvid: bvid);
        if (cid != null) {
          PageUtils.toVideoPage(
            aid: widget.videoItem.aid,
            bvid: bvid,
            cid: cid,
            cover: widget.videoItem.cover,
            title: widget.videoItem.title,
          );
        }
        break;
      case 'picture':
        try {
          PiliScheme.routePushFromUrl(widget.videoItem.uri!);
        } catch (err) {
          SmartDialog.showToast(err.toString());
        }
        break;
      default:
        if (widget.videoItem.uri?.isNotEmpty == true) {
          PiliScheme.routePushFromUrl(widget.videoItem.uri!);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTap: () => onPushDetail(Utils.makeHeroTag(widget.videoItem.aid)),
            onLongPress: () => imageSaveDialog(
              title: widget.videoItem.title,
              cover: widget.videoItem.cover,
              bvid: widget.videoItem.bvid,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: StyleString.aspectRatio,
                  child: LayoutBuilder(
                    builder: (context, boxConstraints) {
                      double maxWidth = boxConstraints.maxWidth;
                      double maxHeight = boxConstraints.maxHeight;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          FutureBuilder<Uint8List?>(
                            future: _thumbnailFuture,
                            builder: (context, snapshot) {
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                                child: _buildImage(
                                  snapshot,
                                  maxWidth,
                                  maxHeight,
                                ),
                              );
                            },
                          ),
                          if (widget.videoItem.duration > 0)
                            PBadge(
                              bottom: 6,
                              right: 7,
                              size: PBadgeSize.small,
                              type: PBadgeType.gray,
                              text: DurationUtil.formatDuration(
                                widget.videoItem.duration,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                content(context),
              ],
            ),
          ),
        ),
        if (widget.videoItem.goto == 'av')
          Positioned(
            right: -5,
            bottom: -2,
            child: VideoPopupMenu(
              size: 29,
              iconSize: 17,
              videoItem: widget.videoItem,
              onRemove: widget.onRemove,
            ),
          ),
      ],
    );
  }

  // [最终版“三步加载策略”]
  Widget _buildImage(
    AsyncSnapshot<Uint8List?> snapshot,
    double maxWidth,
    double maxHeight,
  ) {
    // 关键点：为 AnimatedSwitcher 的 child 提供唯一的 Key
    // Key 的选择要能代表当前UI的状态，以确保动画能被正确触发
    final key = ValueKey(
      snapshot.connectionState == ConnectionState.done
          ? (snapshot.data ?? widget.videoItem.cover ?? 'final_placeholder')
          : 'waiting_placeholder',
    );

    // 状态1: 正在加载中
    if (snapshot.connectionState == ConnectionState.waiting) {
      // 只显示无网络的灰色占位符，不加载任何图片
      return Container(
        key: key,
        color: Colors.grey[200],
        width: maxWidth,
        height: maxHeight,
      );
    }

    // 状态2: 加载完成，并且成功获取到预览图
    if (snapshot.hasData && snapshot.data != null) {
      return Image.memory(
        key: key,
        snapshot.data!,
        width: maxWidth,
        height: maxHeight,
        fit: BoxFit.cover,
      );
    }

    // 状态3: 加载完成但失败了，执行“下下策” -> 加载原始封面
    final coverUrl = widget.videoItem.cover;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      return Image.network(
        key: key,
        coverUrl,
        width: maxWidth,
        height: maxHeight,
        fit: BoxFit.cover,
        // 如果连原始封面都加载失败，显示灰色占位符
        errorBuilder: (context, error, stackTrace) {
          return Container(
            key: const ValueKey('error_placeholder'),
            color: Colors.grey[200],
            width: maxWidth,
            height: maxHeight,
          );
        },
      );
    }

    // 状态4: 所有尝试都失败了，只能显示灰色占位符
    return Container(
      key: key,
      color: Colors.grey[200],
      width: maxWidth,
      height: maxHeight,
    );
  }

  Widget content(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                "${widget.videoItem.title}\n",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  height: 1.38,
                ),
              ),
            ),
            videoStat(context, theme),
            Row(
              children: [
                if (widget.videoItem.goto == 'bangumi')
                  PBadge(
                    text: widget.videoItem.pgcBadge,
                    isStack: false,
                    size: PBadgeSize.small,
                    type: PBadgeType.line_primary,
                    fontSize: 9,
                  ),
                if (widget.videoItem.rcmdReason != null)
                  PBadge(
                    text: widget.videoItem.rcmdReason,
                    isStack: false,
                    size: PBadgeSize.small,
                    type: PBadgeType.secondary,
                  ),
                if (widget.videoItem.goto == 'picture')
                  const PBadge(
                    text: '动态',
                    isStack: false,
                    size: PBadgeSize.small,
                    type: PBadgeType.line_primary,
                    fontSize: 9,
                  ),
                if (widget.videoItem.isFollowed)
                  const PBadge(
                    text: '已关注',
                    isStack: false,
                    size: PBadgeSize.small,
                    type: PBadgeType.secondary,
                  ),
                if (widget.videoItem.goto == 'bangumi' ||
                    widget.videoItem.rcmdReason != null ||
                    widget.videoItem.goto == 'picture' ||
                    widget.videoItem.isFollowed)
                  const SizedBox(width: 2),
                Expanded(
                  flex: 1,
                  child: Text(
                    widget.videoItem.owner.name.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      height: 1.5,
                      fontSize: theme.textTheme.labelMedium!.fontSize,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                if (widget.videoItem.goto == 'av') const SizedBox(width: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget videoStat(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        StatWidget(
          type: StatType.play,
          value: widget.videoItem.stat.view,
        ),
        if (widget.videoItem.goto != 'picture') ...[
          const SizedBox(width: 4),
          StatWidget(
            type: StatType.danmaku,
            value: widget.videoItem.stat.danmu,
          ),
        ],
        if (widget.videoItem is RecVideoItemModel) ...[
          const Spacer(),
          Text.rich(
            maxLines: 1,
            TextSpan(
              style: TextStyle(
                fontSize: theme.textTheme.labelSmall!.fontSize,
                color: theme.colorScheme.outline.withValues(alpha: 0.8),
              ),
              text: DateUtil.dateFormat(
                widget.videoItem.pubdate,
                shortFormat: VideoCardV.shortFormat,
                longFormat: VideoCardV.longFormat,
              ),
            ),
          ),
          const SizedBox(width: 2),
        ],
      ],
    );
  }
}
