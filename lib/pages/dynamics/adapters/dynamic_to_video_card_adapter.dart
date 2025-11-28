import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/models/model_owner.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/models/model_video.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/utils/num_utils.dart';

class DynamicToVideoCardAdapter extends BaseRecVideoItemModel {
  final DynamicItemModel item;

  DynamicToVideoCardAdapter({required this.item}) {
    final video = _getVideo();
    final author = item.modules.moduleAuthor;

    aid = video?.aid;
    bvid = video?.bvid;
    cid = null;
    goto = 'av';
    uri = video?.jumpUrl;
    cover = video?.cover;
    title = video?.title;
    duration = DurationUtils.durationToSeconds(video?.durationText ?? '0:00');
    owner = Owner(
      mid: author?.mid,
      name: author?.name,
      face: author?.face,
      officialVerify: author?.officialVerify,
    );
    stat = Stat(
      danmu: NumUtils.numOtherFormat(video?.stat?.danmu),
      view: NumUtils.numOtherFormat(video?.stat?.play),
    );
    isFollowed = false;
    rcmdReason = null;
  }

  DynamicArchiveModel? _getVideo() {
    return switch (item.type) {
      'DYNAMIC_TYPE_AV' => item.modules.moduleDynamic?.major?.archive,
      'DYNAMIC_TYPE_UGC_SEASON' => item.modules.moduleDynamic?.major?.ugcSeason,
      'DYNAMIC_TYPE_PGC' ||
      'DYNAMIC_TYPE_PGC_UNION' => item.modules.moduleDynamic?.major?.pgc,
      'DYNAMIC_TYPE_COURSES_SEASON' =>
        item.modules.moduleDynamic?.major?.courses,
      _ => null,
    };
  }
}
