import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/models/model_owner.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/models/model_video.dart';

class DynamicToRecVideoAdapter extends BaseRecVideoItemModel {
  final DynamicItemModel item;

  DynamicToRecVideoAdapter(this.item) {
    aid = item.modules?.moduleAuthor?.mid;
    bvid = item.modules?.moduleDynamic?.major?.archive?.bvid;
    cid = item.modules?.moduleDynamic?.major?.archive?.cid;
    goto = item.modules?.moduleDynamic?.major?.archive?.goto;
    uri = item.modules?.moduleDynamic?.major?.archive?.uri;
    cover = item.modules?.moduleDynamic?.major?.archive?.cover ?? '';
    title = item.modules?.moduleDynamic?.major?.archive?.title ?? '';
    duration = item.modules?.moduleDynamic?.major?.archive?.duration ?? 0;
    pubdate = item.modules?.moduleAuthor?.pubTs;
    owner = Owner(
      mid: item.modules?.moduleAuthor?.mid,
      name: item.modules?.moduleAuthor?.name,
      face: item.modules?.moduleAuthor?.face,
    );
    stat = Stat(
      view: item.modules?.moduleDynamic?.major?.archive?.stat?.play,
      danmu: item.modules?.moduleDynamic?.major?.archive?.stat?.danmaku,
      reply: item.modules?.moduleStat?.reply,
      like: item.modules?.moduleStat?.like,
      coin: null,
      fav: null,
      share: item.modules?.moduleStat?.forward,
    );
    isFollowed = item.modules?.moduleAuthor?.isFollow;
  }
}
