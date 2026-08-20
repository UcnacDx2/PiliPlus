import 'package:PiliPlus/models/dynamics/result.dart' as dynamic_model;
import 'package:PiliPlus/models/model_owner.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/models/model_video.dart' as video_model;
import 'package:PiliPlus/utils/parse_int.dart';

class DynamicToRecVideoAdapter extends BaseRcmdVideoItemModel {
  DynamicToRecVideoAdapter(dynamic_model.DynamicItemModel item) {
    final archive = item.modules.moduleDynamic?.major?.archive;
    final author = item.modules.moduleAuthor;
    aid = archive?.aid;
    bvid = archive?.bvid;
    goto = 'av';
    uri = archive?.jumpUrl;
    firstFrame = archive?.firstFrame;
    cover = archive?.cover ?? '';
    title = archive?.title ?? '';
    duration = _parseDuration(archive?.durationText);
    pubdate = author?.pubTs;
    owner = Owner(mid: author?.mid, name: author?.name, face: author?.face);
    stat = video_model.Stat.fromJson({
      'view': safeToInt(archive?.stat?.play),
      'danmaku': safeToInt(archive?.stat?.danmu),
      'like': item.modules.moduleStat?.like?.count,
    });
    isFollowed = false;
  }

  static int _parseDuration(String? value) {
    if (value == null || value.isEmpty) return -1;
    final parts = value.split(':').map((part) => int.tryParse(part)).toList();
    if (parts.any((part) => part == null)) return -1;
    return switch (parts.length) {
      2 => parts[0]! * 60 + parts[1]!,
      3 => parts[0]! * 3600 + parts[1]! * 60 + parts[2]!,
      _ => -1,
    };
  }
}
