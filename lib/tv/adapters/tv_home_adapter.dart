import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/model_video.dart';
import 'package:PiliPlus/tv/adapters/tv_video_item.dart';

abstract final class TvVideoMapper {
  static TvVideoItem fromPili(BaseVideoItemModel item) => TvVideoItem(
    bvid: item.bvid ?? '', aid: item.aid ?? 0, title: item.title, pic: item.cover ?? '',
    firstFrame: item.firstFrame, ownerName: item.owner.name ?? '',
    ownerMid: item.owner.mid ?? 0, view: item.stat.view ?? 0,
    danmaku: item.stat.danmu ?? 0, duration: item.duration < 0 ? 0 : item.duration,
    pubdate: item.pubdate ?? 0, cid: item.cid ?? 0,
  );
}

abstract final class TvHomeAdapter {
  static Future<List<TvVideoItem>> loadRecommend({int refreshIndex = 0}) async {
    final state = await VideoHttp.rcmdVideoListApp(freshIdx: refreshIndex);
    return state.dataOrNull?.map(TvVideoMapper.fromPili).toList() ?? const [];
  }
  static Future<List<TvVideoItem>> loadPopular({int page = 1}) async {
    final state = await VideoHttp.hotVideoList(pn: page, ps: 20);
    return state.dataOrNull?.map(TvVideoMapper.fromPili).toList() ?? const [];
  }
}
