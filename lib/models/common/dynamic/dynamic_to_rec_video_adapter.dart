import 'package:PiliPlus/models/dynamics/result.dart' as dyn;
import 'package:PiliPlus/models/model_owner.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/models/model_video.dart' as model_video;
import 'package:PiliPlus/utils/utils.dart';

class DynamicToRecVideoAdapter extends BaseRecVideoItemModel {
  final dyn.DynamicItemModel item;

  DynamicToRecVideoAdapter(this.item) {
    aid = item.modules?.moduleAuthor?.mid;
    bvid = item.modules?.moduleDynamic?.major?.archive?.bvid;
    cid = item.modules?.moduleDynamic?.major?.archive?.cid;
    goto = item.modules?.moduleDynamic?.major?.archive?.goto ?? 'av';
    uri = item.modules?.moduleDynamic?.major?.archive?.jumpUrl;
    cover = item.modules?.moduleDynamic?.major?.archive?.cover ?? '';
    firstFrame = item.modules?.moduleDynamic?.major?.archive?.firstFrame;
    title = item.modules?.moduleDynamic?.major?.archive?.title ?? '';

    final durationText = item.modules?.moduleDynamic?.major?.archive?.durationText;
    if (durationText != null) {
      final parts = durationText.split(':');
      if (parts.length == 2) {
        duration = (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
      }
    }

    pubdate = item.modules?.moduleAuthor?.pubTs;
    owner = Owner(
      mid: item.modules?.moduleAuthor?.mid,
      name: item.modules?.moduleAuthor?.name,
      face: item.modules?.moduleAuthor?.face,
    );
    stat = model_video.Stat.fromJson({
      "view": Utils.safeToInt(item.modules?.moduleDynamic?.major?.archive?.stat?.play),
      "danmaku": Utils.safeToInt(item.modules?.moduleDynamic?.major?.archive?.stat?.danmu),
      "like": item.modules?.moduleStat?.like?.count,
    });
    isFollowed = item.modules?.moduleAuthor?.isFollow ?? false;
  }
}
