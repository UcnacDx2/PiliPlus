import 'dart:typed_data';

import 'package:PiliPlus/bilibili_api.dart';
import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/progress_bar/video_progress_indicator.dart';
import 'package:PiliPlus/common/widgets/stat/stat.dart';
import 'package:PiliPlus/common/widgets/video_popup_menu.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/models/common/badge_type.dart';
import 'package:PiliPlus/models/common/stat_type.dart';
import 'package:PiliPlus/models/model_hot_video_item.dart';
import 'package:PiliPlus/models/model_video.dart';
import 'package:PiliPlus/models/search/result.dart';
import 'package:PiliPlus/utils/date_util.dart';
import 'package:PiliPlus/utils/duration_util.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class VideoCardH extends StatefulWidget {
  const VideoCardH({
    super.key,
    required this.videoItem,
    this.onTap,
    this.onLongPress,
    this.onViewLater,
    this.onRemove,
  });
  final BaseVideoItemModel videoItem;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<int>? onViewLater;
  final VoidCallback? onRemove;

  @override
  State<VideoCardH> createState() => _VideoCardHState();
}

class _VideoCardHState extends State<VideoCardH> {
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

  @override
  Widget build(BuildContext context) {
    String type = 'video';
    String? badge;
    if (widget.videoItem case SearchVideoItemModel item) {
      var typeOrNull = item.type;
      if (typeOrNull?.isNotEmpty == true) {
        type = typeOrNull!;
        if (type == 'ketang') {
          badge = '课堂';
        } else if (type == 'live_room') {
          badge = '直播';
        }
      }
      if (item.isUnionVideo == 1) {
        badge = '合作';
      }
    } else if (widget.videoItem case HotVideoItemModel item) {
      if (item.isCooperation == 1) {
        badge = '合作';
      } else {
        badge = item.pgcLabel;
      }
    }
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onLongPress:
                widget.onLongPress ??
                () => imageSaveDialog(
                  bvid: widget.videoItem.bvid,
                  title: widget.videoItem.title,
                  cover: widget.videoItem.cover,
                ),
            onTap:
                widget.onTap ??
                () async {
                  if (type == 'ketang') {
                    PageUtils.viewPugv(seasonId: widget.videoItem.aid);
                    return;
                  } else if (type == 'live_room') {
                    if (widget.videoItem case SearchVideoItemModel item) {
                      int? roomId = item.id;
                      if (roomId != null) {
                        PageUtils.toLiveRoom(roomId);
                      }
                    } else {
                      SmartDialog.showToast(
                        'err: live_room : ${widget.videoItem.runtimeType}',
                      );
                    }
                    return;
                  }
                  if (widget.videoItem case HotVideoItemModel item) {
                    if (item.redirectUrl?.isNotEmpty == true &&
                        PageUtils.viewPgcFromUri(item.redirectUrl!)) {
                      return;
                    }
                  }

                  try {
                    final int? cid =
                        widget.videoItem.cid ??
                        await SearchHttp.ab2c(
                          aid: widget.videoItem.aid,
                          bvid: widget.videoItem.bvid,
                        );
                    if (cid != null) {
                      PageUtils.toVideoPage(
                        bvid: widget.videoItem.bvid,
                        cid: cid,
                        cover: widget.videoItem.cover,
                        title: widget.videoItem.title,
                      );
                    }
                  } catch (err) {
                    SmartDialog.showToast(err.toString());
                  }
                },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: StyleString.safeSpace,
                vertical: 5,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: StyleString.aspectRatio,
                    child: LayoutBuilder(
                      builder: (context, boxConstraints) {
                        final double maxWidth = boxConstraints.maxWidth;
                        final double maxHeight = boxConstraints.maxHeight;
                        num? progress;
                        if (widget.videoItem case HotVideoItemModel item) {
                          progress = item.progress;
                        }

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            FutureBuilder<Uint8List?>(
                              future: _thumbnailFuture,
                              builder: (context, snapshot) {
                                // [核心修改] 使用 AnimatedSwitcher 实现平滑过渡
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
                            if (badge != null)
                              PBadge(
                                text: badge,
                                top: 6.0,
                                right: 6.0,
                              ),
                            if (progress != null && progress != 0) ...[
                              PBadge(
                                text: progress == -1
                                    ? '已看完'
                                    : '${DurationUtil.formatDuration(progress)}/${DurationUtil.formatDuration(widget.videoItem.duration)}',
                                right: 6,
                                bottom: 8,
                                type: PBadgeType.gray,
                              ),
                              Positioned(
                                left: 0,
                                bottom: 0,
                                right: 0,
                                child: videoProgressIndicator(
                                  progress == -1
                                      ? 1
                                      : progress / widget.videoItem.duration,
                                ),
                              ),
                            ] else if (widget.videoItem.duration > 0)
                              PBadge(
                                text: DurationUtil.formatDuration(
                                  widget.videoItem.duration,
                                ),
                                right: 6.0,
                                bottom: 6.0,
                                type: PBadgeType.gray,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  content(context),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 12,
            child: VideoPopupMenu(
              size: 29,
              iconSize: 17,
              videoItem: widget.videoItem,
              onRemove: widget.onRemove,
            ),
          ),
        ],
      ),
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
    String pubdate = DateUtil.dateFormat(widget.videoItem.pubdate!);
    if (pubdate != '') pubdate += '  ';
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.videoItem case SearchVideoItemModel item) ...[
            if (item.titleList?.isNotEmpty == true)
              Expanded(
                child: Text.rich(
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  TextSpan(
                    children: item.titleList!
                        .map(
                          (e) => TextSpan(
                            text: e.text,
                            style: TextStyle(
                              fontSize: theme.textTheme.bodyMedium!.fontSize,
                              height: 1.42,
                              letterSpacing: 0.3,
                              color: e.isEm
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
          ] else
            Expanded(
              child: Text(
                widget.videoItem.title,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: theme.textTheme.bodyMedium!.fontSize,
                  height: 1.42,
                  letterSpacing: 0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Text(
            "$pubdate${widget.videoItem.owner.name}",
            maxLines: 1,
            style: TextStyle(
              fontSize: 12,
              height: 1,
              color: theme.colorScheme.outline,
              overflow: TextOverflow.clip,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              StatWidget(
                type: StatType.play,
                value: widget.videoItem.stat.view,
              ),
              const SizedBox(width: 8),
              StatWidget(
                type: StatType.danmaku,
                value: widget.videoItem.stat.danmu,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
