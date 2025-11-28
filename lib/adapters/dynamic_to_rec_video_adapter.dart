import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/models/model_owner.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/models/model_video.dart';

class DynamicToRecVideoAdapter extends BaseRecVideoItemModel {
  DynamicToRecVideoAdapter.fromDynamicItem(
    DynamicItemModel dynamicItem,
    DynamicArchiveModel video,
  ) {
    aid = video.aid;
    bvid = video.bvid;
    cid = null;
    cover = video.cover;
    title = video.title;
    duration = _parseDurationText(video.durationText);
    owner = Owner.fromDynamic(dynamicItem.modules.moduleAuthor);
    stat = Stat.fromDynamic(video.stat);
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

extension on Owner {
  static Owner fromDynamic(ModuleAuthorModel? moduleAuthor) {
    return Owner(
      mid: moduleAuthor?.mid,
      name: moduleAuthor?.name,
      face: moduleAuthor?.face,
    );
  }
}

extension on Stat {
  static Stat fromDynamic(dynamic stat) {
    return Stat()
      ..view = int.tryParse(stat.play ?? '0')
      ..danmu = int.tryParse(stat.danmu ?? '0');
  }
}
