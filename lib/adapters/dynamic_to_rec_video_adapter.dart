import 'package:PiliPlus/models/dynamics/result.dart' as dyn_result;
import 'package:PiliPlus/models/model_owner.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/models/model_video.dart' as mod_video;

class DynamicToRecVideoAdapter extends BaseRecVideoItemModel {
  DynamicToRecVideoAdapter.fromDynamicItem(
    dyn_result.DynamicItemModel dynamicItem,
    dyn_result.DynamicArchiveModel video,
  ) {
    aid = video.aid;
    bvid = video.bvid;
    cid = null;
    cover = video.cover;
    title = video.title ?? '';
    duration = _parseDurationText(video.durationText);
    owner = Owner.fromDynamic(dynamicItem.modules.moduleAuthor);
    stat = mod_video.Stat.fromDynamic(video.stat);
    goto = 'av';
    uri = video.jumpUrl;
    pubdate = dynamicItem.modules.moduleAuthor?.pubTs;
    isFollowed = false;
    rcmdReason = null;
  }

  int _parseDurationText(String? durationText) {
    if (durationText == null) {
      return 0;
    }
    final parts = durationText.split(':');
    if (parts.length == 2) {
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } else if (parts.length == 3) {
      return int.parse(parts[0]) * 3600 +
          int.parse(parts[1]) * 60 +
          int.parse(parts[2]);
    }
    return 0;
  }
}
