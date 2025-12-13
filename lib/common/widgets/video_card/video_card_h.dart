import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/progress_bar/video_progress_indicator.dart';
import 'package:PiliPlus/common/widgets/stat/stat.dart';
import 'package:PiliPlus/common/widgets/video_popup_menu.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/common/badge_type.dart';
import 'package:PiliPlus/models/common/stat_type.dart';
import 'package:PiliPlus/models/model_hot_video_item.dart';
import 'package:PiliPlus/models/model_video.dart';
import 'package:PiliPlus/models/search/result.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter/services.dart';
import 'package:dpad/dpad.dart';
import 'dpad_video_card_wrapper.dart';

// 视频卡片 - 水平布局
class VideoCardH extends StatefulWidget {
  const VideoCardH({
    super.key,
    required this.videoItem,
    this.onTap,
    this.onViewLater,
    this.onRemove,
  });
  final BaseVideoItemModel videoItem;
  final VoidCallback? onTap;
  final ValueChanged<int>? onViewLater;
  final VoidCallback? onRemove;

  @override
  State<VideoCardH> createState() => _VideoCardHState();
}

class _VideoCardHState extends State<VideoCardH> {
  // [Feat] TV 菜单键支持
  final GlobalKey<VideoPopupMenuState> _menuKey =
      GlobalKey<VideoPopupMenuState>();
  
  // [Main] 首帧图支持
  String? _firstFrame;

  @override
  void initState() {
    super.initState();
    _fetchFirstFrame();
  }

  @override
  void didUpdateWidget(covariant VideoCardH oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoItem.bvid != widget.videoItem.bvid) {
      _firstFrame = null;
      _fetchFirstFrame();
    }
  }

  Future<void> _fetchFirstFrame() async {
    if (Pref.useFirstFrameAsCover && widget.videoItem.firstFrame == null) {
      final firstFrame =
          await VideoHttp.getVideoFirstFrame(widget.videoItem.bvid);
      if (firstFrame != null && mounted) {
        setState(() {
          _firstFrame = firstFrame;
        });
      }
    }
  }

  // [Feat] 抽离出的点击逻辑
  Future<void> _onTap() async {
    String type = 'video';
    if (widget.videoItem case SearchVideoItemModel item) {
      var typeOrNull = item.type;
      if (typeOrNull?.isNotEmpty == true) {
        type = typeOrNull!;
      }
    }

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
  }

  @override
  Widget build(BuildContext context) {
    String type = 'video';
    String? badge;
    if (widget.videoItem case SearchVideoItemModel item) {
      var typeOrNull = item.type;
      if (typeOrNull != null && typeOrNull.isNotEmpty) {
        type = typeOrNull;
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
      if (item.isCharging == true) {
        badge = '充电专属';
      } else if (item.isCooperation == 1) {
        badge = '合作';
      } else {
        badge = item.pgcLabel;
      }
    }
    void onLongPress() => imageSaveDialog(
      bvid: widget.videoItem.bvid,
      title: widget.videoItem.title,
      cover: widget.videoItem.cover,
    );

    return DpadVideoCardWrapper(
      onClick: widget.onTap ?? _onTap,
      child: Material(
        type: MaterialType.transparency,
        // [Feat] Focus 监听逻辑
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.contextMenu) {
              _menuKey.currentState?.showButtonMenu();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                onLongPress: onLongPress,
                onSecondaryTap: Utils.isMobile ? null : onLongPress,
                onTap: widget.onTap ?? _onTap, // 使用合并后的 onTap
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
                                // [Main] 使用首帧图逻辑
                                NetworkImgLayer(
                                  src: _firstFrame ??
                                      widget.videoItem.firstFrame ??
                                      widget.videoItem.cover,
                                  width: maxWidth,
                                  height: maxHeight,
                                ),
                                if (badge != null)
                                  PBadge(
                                    text: badge,
                                    top: 6.0,
                                    right: 6.0,
                                    type: switch (badge) {
                                      '充电专属' => PBadgeType.error,
                                      _ => PBadgeType.primary,
                                    },
                                  ),
                                // [Main] 进度条逻辑
                                if (progress != null && progress != 0) ...[
                                  PBadge(
                                    text: progress == -1
                                        ? '已看完'
                                        : '${DurationUtils.formatDuration(progress)}/${DurationUtils.formatDuration(widget.videoItem.duration ?? 0)}',
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
                                          : progress /
                                              (widget.videoItem.duration ?? 1),
                                    ),
                                  ),
                                ] else if ((widget.videoItem.duration ?? 0) > 0)
                                  PBadge(
                                    text: DurationUtils.formatDuration(
                                      widget.videoItem.duration!,
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
                child: ExcludeFocus(
                  child: VideoPopupMenu(
                    // [Feat] 绑定 Key
                    key: _menuKey,
                    size: 29,
                    iconSize: 17,
                    videoItem: widget.videoItem,
                    onRemove: widget.onRemove,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget content(BuildContext context) {
    final theme = Theme.of(context);
    String pubdate = DateFormatUtils.dateFormat(widget.videoItem.pubdate!);
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
            spacing: 8,
            children: [
              StatWidget(
                type: StatType.play,
                value: widget.videoItem.stat.view,
              ),
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