import 'package:PiliPlus/common/widgets/tv_popup_menu.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/model_video.dart';
import 'package:PiliPlus/models/tv_menu_context.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/pages/video/widgets/header_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class TvMenuManager {
  static final TvMenuManager _instance = TvMenuManager._internal();

  factory TvMenuManager() {
    return _instance;
  }

  TvMenuManager._internal();

  ValueNotifier<TvMenuContext?> currentContext = ValueNotifier(null);

  void showTvMenu(BuildContext context) {
    final contextValue = currentContext.value;
    if (contextValue == null) {
      return;
    }

    List<TvPopupMenuItem> items = [];
    switch (contextValue.type) {
      case TvMenuContextType.player:
        items = _buildPlayerMenuItems(context);
        break;
      case TvMenuContextType.videoCard:
        items = _buildVideoCardMenuItems(context, contextValue.data);
        break;
      default:
        return;
    }

    if (items.isNotEmpty) {
      showDialog(
        context: context,
        builder: (dialogContext) => TvPopupMenu(items: items),
      );
    }
  }

  List<TvPopupMenuItem> _buildPlayerMenuItems(BuildContext context) {
    final videoDetailCtr = Get.find<VideoDetailController>();
    return [
      TvPopupMenuItem(
        icon: Icons.play_circle_outline,
        title: '选择画质',
        onTap: () {
          Navigator.of(context).pop();
          videoDetailCtr.showSetVideoQa();
        },
      ),
      if (videoDetailCtr.currentAudioQa != null)
        TvPopupMenuItem(
          icon: Icons.album_outlined,
          title: '选择音质',
          onTap: () {
            Navigator.of(context).pop();
            videoDetailCtr.showSetAudioQa();
          },
        ),
      TvPopupMenuItem(
        icon: MdiIcons.messageTextOutline,
        title: '弹幕设置',
        onTap: () {
          Navigator.of(context).pop();
          videoDetailCtr.showSetDanmaku();
        },
      ),
      TvPopupMenuItem(
        icon: Icons.subtitles_outlined,
        title: '字幕设置',
        onTap: () {
          Navigator.of(context).pop();
          videoDetailCtr.showSetSubtitle();
        },
      ),
      TvPopupMenuItem(
        icon: Icons.repeat,
        title: '播放顺序',
        onTap: () {
          Navigator.of(context).pop();
          videoDetailCtr.showSetRepeat();
        },
      ),
      TvPopupMenuItem(
        icon: Icons.info_outline,
        title: '播放信息',
        onTap: () {
          Navigator.of(context).pop();
          HeaderControlState.showPlayerInfo(
            context,
            plPlayerController: videoDetailCtr.plPlayerController,
          );
        },
      ),
    ];
  }

  List<TvPopupMenuItem> _buildVideoCardMenuItems(
      BuildContext context, BaseSimpleVideoItemModel videoItem) {
    return [
      TvPopupMenuItem(
        icon: Icons.watch_later_outlined,
        title: '稍后再看',
        onTap: () async {
          Navigator.of(context).pop();
          var res = await UserHttp.toViewLater(bvid: videoItem.bvid);
          SmartDialog.showToast(res['msg']);
        },
      ),
      TvPopupMenuItem(
        icon: MdiIcons.accountCircleOutline,
        title: '访问UP主: ${videoItem.owner.name}',
        onTap: () {
          Navigator.of(context).pop();
          Get.toNamed('/member?mid=${videoItem.owner.mid}');
        },
      ),
      TvPopupMenuItem(
        icon: MdiIcons.thumbDownOutline,
        title: '不感兴趣',
        onTap: () async {
          Navigator.of(context).pop();
          SmartDialog.showLoading(msg: '正在提交');
          var res =
              await VideoHttp.dislikeVideo(bvid: videoItem.bvid!, type: true);
          SmartDialog.dismiss();
          SmartDialog.showToast(res['status'] ? "点踩成功" : res['msg']);
        },
      ),
    ];
  }
}
