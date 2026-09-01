import 'package:PiliPlus/tv/adapters/tv_video_item.dart';
import 'package:PiliPlus/tv/adapters/tv_videoshot.dart';
import 'package:PiliPlus/tv/adapters/tv_settings_facade.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/http/login.dart';
import 'package:PiliPlus/utils/login_utils.dart';
import 'package:PiliPlus/models/common/search/search_type.dart';
import 'package:PiliPlus/models/search/result.dart';
import 'package:PiliPlus/http/dynamics.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/http/member.dart';
import 'package:PiliPlus/models/common/member/archive_order_type_app.dart';
import 'package:PiliPlus/models/common/member/contribute_type.dart';
import 'package:PiliPlus/models/common/member/archive_sort_type_app.dart';
import 'package:PiliPlus/models/common/video/video_type.dart';
import 'package:PiliPlus/models/common/dynamic/dynamics_type.dart';
import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/utils/duration_utils.dart';

enum AccountRole { main, video, history }

class DynamicFeed {
  const DynamicFeed({this.videos = const [], this.offset = '', this.hasMore = false, this.succeeded = true});
  final List<TvVideoItem> videos;
  final String offset;
  final bool hasMore;
  final bool succeeded;
}

abstract final class TvBilibiliFacade {
  static Future<List<String>> getSearchSuggestions(String keyword) async {
    if (keyword.trim().isEmpty) return const [];
    final state = await SearchHttp.searchSuggest(term: keyword.trim());
    return state.dataOrNull?.tag
            ?.map((item) => item.term ?? item.textRich)
            .where((item) => item.isNotEmpty)
            .toList() ??
        const [];
  }
  static Future<List<TvVideoItem>> searchVideos(String keyword, {int page = 1, String order = 'totalrank'}) async {
    final state = await SearchHttp.searchByType<SearchVideoData>(
      searchType: SearchType.video, keyword: keyword, page: page, order: order,
      onSuccess: (_) {},
    );
    return state.dataOrNull?.list?.map((item) => TvVideoItem(
      bvid: item.bvid ?? '', aid: item.aid ?? 0, title: item.title, pic: item.cover ?? '',
      ownerName: item.owner.name ?? '', ownerMid: item.owner.mid ?? 0,
      view: item.stat.view ?? 0, danmaku: item.stat.danmu ?? 0,
      duration: item.duration < 0 ? 0 : item.duration, pubdate: item.pubdate ?? 0,
    )).toList() ?? const [];
  }
  static Future<Map<String, dynamic>> getHistory({int ps = 30, int viewAt = 0, int max = 0}) async {
    final state = await UserHttp.historyList(type: 'archive', ps: ps, max: max, viewAt: viewAt);
    final data = state.dataOrNull;
    if (data == null) {
      return {
        'list': const <TvVideoItem>[],
        'viewAt': viewAt,
        'max': max,
        'hasMore': false,
        'succeeded': false,
        'error': state.toString(),
      };
    }
    final list = data.list?.map((item) => TvVideoItem(
      bvid: item.history.bvid ?? '', title: item.title ?? '', pic: item.cover ?? '',
      ownerName: item.authorName ?? '', ownerMid: item.authorMid ?? 0,
      progress: item.progress ?? -1, viewAt: item.viewAt ?? 0,
      duration: item.duration ?? 0, cid: item.history.cid ?? item.history.oid ?? 0,
      aid: item.history.oid ?? 0, historyPage: item.history.page ?? 0,
      historyVideos: item.videos ?? 0,
      badge: item.badge ?? '',
    )).toList() ?? const <TvVideoItem>[];
    return {
      'list': list,
      'viewAt': data.viewAt,
      'max': data.max,
      'hasMore': list.isNotEmpty && (data.viewAt > 0 || data.max > 0),
      'succeeded': true,
    };
  }
  static Future<DynamicFeed> getDynamicFeed({String offset = ''}) async {
    final state = await DynamicsHttp.followDynamic(
      offset: offset,
      type: DynamicsTabType.video,
    );
    final data = state.dataOrNull;
    if (data == null) return const DynamicFeed(succeeded: false);
    final videos = <TvVideoItem>[];
    for (final item in data.items ?? const <DynamicItemModel>[]) {
      final major = item.modules.moduleDynamic?.major;
      final archive = major?.archive ?? major?.ugcSeason ?? major?.pgc;
      final bvid = archive?.bvid;
      if (archive == null || bvid == null || bvid.isEmpty) continue;
      final author = item.modules.moduleAuthor;
      videos.add(TvVideoItem(
        bvid: bvid, aid: archive.aid ?? 0, title: archive.title ?? '', pic: archive.cover ?? '',
        firstFrame: archive.firstFrame, ownerName: author?.name ?? '',
        ownerMid: author?.mid ?? 0,
        duration: DurationUtils.parseDuration(archive.durationText ?? ''),
      ));
    }
    return DynamicFeed(videos: videos, offset: data.offset ?? '', hasMore: data.hasMore ?? false);
  }
  static Future<List<TvVideoItem>> getRelatedVideos(String bvid) async {
    final state = await VideoHttp.relatedVideoList(bvid: bvid);
    return state.dataOrNull?.map((item) => TvVideoItem(
      bvid: item.bvid ?? '', title: item.title, pic: item.cover ?? '',
      firstFrame: item.firstFrame, ownerName: item.owner.name ?? '', ownerMid: item.owner.mid ?? 0,
      view: item.stat.view ?? 0, danmaku: item.stat.danmu ?? 0, duration: item.duration,
      pubdate: item.pubdate ?? 0, cid: item.cid ?? 0,
    )).toList() ?? const [];
  }
  static Future<List<TvVideoItem>> getSpaceVideos({required int mid, int page = 1, String order = 'pubdate'}) async {
    final state = await MemberHttp.spaceArchive(
      type: ContributeType.video,
      mid: mid,
      pn: page,
      order: order == 'click' ? ArchiveOrderTypeApp.click : ArchiveOrderTypeApp.pubdate,
      sort: ArchiveSortTypeApp.desc,
    );
    return state.dataOrNull?.item?.map((item) => TvVideoItem(
      bvid: item.bvid ?? '', title: item.title, pic: item.cover ?? '',
      ownerName: item.owner.name ?? '', ownerMid: item.owner.mid ?? mid,
      view: item.stat.view ?? 0, danmaku: item.stat.danmu ?? 0,
      duration: item.duration < 0 ? 0 : item.duration, cid: item.cid ?? 0,
    )).where((item) => item.bvid.isNotEmpty).toList() ?? const [];
  }
  static Future<Map<String, String>?> generateTvQrCode() async {
    final state = await LoginHttp.getHDcode();
    final data = state.dataOrNull;
    return data == null ? null : {'auth_code': data.authCode, 'url': data.url};
  }
  static Future<Map<String, dynamic>> pollTvLogin(String code) async {
    final result = await LoginHttp.codePoll(code);
    if (result['status'] != true) {
      return {'status': result['code'] == 86090 ? 'scanned' : 'waiting', 'code': result['code']};
    }
    final data = result['data'] as Map?;
    final token = data?['token_info'] as Map?;
    final cookies = data?['cookie_info'];
    return {
      'status': 'success',
      'access_token': token?['access_token'] ?? '',
      'refresh_token': token?['refresh_token'] ?? '',
      'mid': token?['mid'] ?? 0,
      'cookie_info': cookies,
    };
  }
  static Future<void> fetchAndSaveUserInfo() => LoginUtils.onLoginMain();
  static Future<Map<String, dynamic>?> getVideoInfo(String bvid, {AccountRole role = AccountRole.video}) async {
    final state = await VideoHttp.videoIntro(bvid: bvid);
    final data = state.dataOrNull;
    if (data == null) return null;
    final pages = data.pages
        ?.map((page) => <String, dynamic>{
              'cid': page.cid ?? 0,
              'page': page.page ?? 0,
              'part': page.part ?? '',
              'duration': page.duration ?? 0,
              'first_frame': page.firstFrame,
            })
        .toList();
    return {
      'bvid': data.bvid,
      'aid': data.aid,
      'cid': data.cid,
      'title': data.title,
      'pic': data.pic,
      'duration': data.duration,
      'pages': pages,
    };
  }
  static Future<int?> getVideoCid(String bvid, {int aid = 0}) async {
    if (aid > 0) {
      final cid = await SearchHttp.ab2c(aid: aid, bvid: bvid);
      if (cid != null && cid > 0) return cid;
    }
    return (await VideoHttp.videoIntro(bvid: bvid)).dataOrNull?.cid;
  }
  static Future<Map<String, dynamic>?> getVideoPlayUrl({required String bvid, required int cid, int qn = 80, VideoCodec? forceCodec}) async {
    final state = await VideoHttp.videoUrl(bvid: bvid, cid: cid, qn: qn, tryLook: true, videoType: VideoType.ugc);
    final data = state.dataOrNull;
    return data == null ? null : {'play_url': data.durl?.firstOrNull?.url, 'last_play_time': data.lastPlayTime};
  }
  static Future<List<Map<String, dynamic>>> getDanmaku(int cid) async => const [];
  static Future<bool> reportProgress({required String bvid, required int cid, required int progress}) async => true;
  static Future<Map<String, String>?> getOnlineCount({required int aid, required int cid}) async => null;
  static Future<VideoshotData?> getVideoshot({required String bvid, int? cid}) async {
    final resolvedCid = cid ?? await getVideoCid(bvid);
    if (resolvedCid == null || resolvedCid == 0) return null;
    final state = await VideoHttp.videoshot(bvid: bvid, cid: resolvedCid);
    final data = state.dataOrNull;
    if (data == null || data.image.isEmpty) return null;
    final result = VideoshotData(
      images: data.image,
      imgXLen: data.imgXLen,
      imgYLen: data.imgYLen,
      imgXSize: data.imgXSize.round(),
      imgYSize: data.imgYSize.round(),
    );
    result.setTimestamps(data.index);
    return result;
  }
  static Future<bool> likeVideo({required int aid, required bool like}) async => false;
  static Future<bool> checkLikeStatus(int aid) async => false;
  static Future<String?> coinVideo({required int aid, int count = 1}) async => null;
  static Future<int> checkCoinStatus(int aid) async => 0;
  static Future<bool> favoriteVideo({required int aid, required bool favorite}) async => false;
  static Future<bool> checkFavoriteStatus(int aid) async => false;
  static Future<bool> followUser({required int mid, required bool follow}) async => false;
  static Future<bool> checkFollowStatus(int mid) async => false;
}
