import 'package:PiliPlus/models/dynamics/result.dart' as dyn;
import 'package:PiliPlus/models/model_owner.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/models/model_video.dart' as model_video;
import 'package:PiliPlus/utils/utils.dart';

class DynamicToRecVideoAdapter extends BaseRecVideoItemModel {
  final dyn.DynamicItemModel item;

  DynamicToRecVideoAdapter(this.item) {
    aid = item.modules?.moduleDynamic?.major?.archive?.aid;
    bvid = item.modules?.moduleDynamic?.major?.archive?.bvid;
    cid = item.modules?.moduleDynamic?.major?.archive?.cid;
    goto = item.modules?.moduleDynamic?.major?.archive?.goto ?? 'av';
    uri = item.modules?.moduleDynamic?.major?.archive?.jumpUrl;
    firstFrame = item.modules?.moduleDynamic?.major?.archive?.firstFrame;
    cover = item.modules?.moduleDynamic?.major?.archive?.cover ?? '';
    title = item.modules?.moduleDynamic?.major?.archive?.title ?? '';

    final durationText =
        item.modules?.moduleDynamic?.major?.archive?.durationText;
    if (durationText != null && durationText.isNotEmpty) {
      final parts = durationText.split(':');
      duration = switch (parts.length) {
        2 => (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0),
        3 =>
          (int.tryParse(parts[0]) ?? 0) * 3600 +
              (int.tryParse(parts[1]) ?? 0) * 60 +
              (int.tryParse(parts[2]) ?? 0),
        _ => null
      };
    }

    pubdate = item.modules?.moduleAuthor?.pubTs;
    owner = Owner(
      mid: item.modules?.moduleAuthor?.mid,
      name: item.modules?.moduleAuthor?.name,
      face: item.modules?.moduleAuthor?.face,
    );
    stat = model_video.Stat.fromJson({
      "view":
          Utils.safeToNum(item.modules?.moduleDynamic?.major?.archive?.stat?.play),
      "danmaku":
          Utils.safeToNum(item.modules?.moduleDynamic?.major?.archive?.stat?.danmu),
      "like": item.modules?.moduleStat?.like?.count,
    });
    isFollowed = item.modules?.moduleAuthor?.isFollow ?? false;
  }
}
