import 'package:PiliPlus/common/widgets/tv_menu/tv_popup_menu_item.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

List<TvPopupMenuItem> buildVideoCardMenu({
  required BuildContext context,
  required dynamic focusData,
}) {
  final item = focusData as BaseRecVideoItemModel;
  return [
    TvPopupMenuItem(
      icon: Icons.play_arrow_outlined,
      title: '立即播放',
      onTap: () {
        Get.back();
        PageUtils.toVideoPage(
          aid: item.aid,
          bvid: item.bvid,
          cid: item.cid,
          cover: item.cover,
          title: item.title,
        );
      },
    ),
    TvPopupMenuItem(
      icon: Icons.watch_later_outlined,
      title: '稍后再看',
      onTap: () async {
        Get.back();
        final res = await UserHttp.toViewLater(bvid: item.bvid);
        SmartDialog.showToast(res['msg']);
      },
    ),
  ];
}
