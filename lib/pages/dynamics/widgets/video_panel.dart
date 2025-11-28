// 视频or合集
import 'package:PiliPlus/common/widgets/video_card/video_card_v.dart';
import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/pages/dynamics/adapters/dynamic_to_video_card_adapter.dart';
import 'package:flutter/material.dart';

Widget videoSeasonWidget(
  BuildContext context, {
  required int floor,
  required ThemeData theme,
  required DynamicItemModel item,
  required bool isSave,
  required bool isDetail,
  required double maxWidth,
}) {
  DynamicArchiveModel? video = switch (item.type) {
    'DYNAMIC_TYPE_AV' => item.modules.moduleDynamic?.major?.archive,
    'DYNAMIC_TYPE_UGC_SEASON' => item.modules.moduleDynamic?.major?.ugcSeason,
    'DYNAMIC_TYPE_PGC' ||
    'DYNAMIC_TYPE_PGC_UNION' => item.modules.moduleDynamic?.major?.pgc,
    'DYNAMIC_TYPE_COURSES_SEASON' => item.modules.moduleDynamic?.major?.courses,
    _ => null,
  };

  if (video == null) {
    return const SizedBox.shrink();
  }

  EdgeInsets padding;
  if (floor == 1) {
    maxWidth -= 24;
    padding = const EdgeInsets.symmetric(horizontal: 12);
  } else {
    padding = EdgeInsets.zero;
  }
  return Padding(
    padding: padding,
    child: VideoCardV(videoItem: DynamicToVideoCardAdapter(item: item)),
  );
}
