import 'package:PiliPlus/tv/adapters/tv_video_item.dart';
import 'package:PiliPlus/tv/adapters/tv_videoshot.dart';
import 'package:PiliPlus/tv/adapters/tv_settings_facade.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/http/login.dart';
import 'package:PiliPlus/utils/login_utils.dart';
import 'package:PiliPlus/models/common/search/search_type.dart';
import 'package:PiliPlus/models/search/result.dart';

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
      bvid: item.bvid ?? '', title: item.title, pic: item.cover ?? '',
      ownerName: item.owner.name ?? '', ownerMid: item.owner.mid ?? 0,
      view: item.stat.view ?? 0, danmaku: item.stat.danmu ?? 0,
      duration: item.duration < 0 ? 0 : item.duration, pubdate: item.pubdate ?? 0,
    )).toList() ?? const [];
  }
  static Future<Map<String, dynamic>> getHistory({int ps = 30, int viewAt = 0, int max = 0}) async {
    final state = await UserHttp.historyList(type: 'archive', max: max, viewAt: viewAt);
    final list = state.dataOrNull?.list?.map((item) => TvVideoItem(
      bvid: item.history.bvid ?? '', title: item.title ?? '', pic: item.cover ?? '',
      ownerName: item.authorName ?? '', ownerMid: item.authorMid ?? 0,
      progress: item.progress ?? -1, viewAt: item.viewAt ?? 0,
      duration: item.duration ?? 0, cid: item.history.cid ?? 0, badge: item.badge ?? '',
    )).toList() ?? const <TvVideoItem>[];
    return {'list': list};
  }
  static Future<DynamicFeed> getDynamicFeed({String offset = ''}) async => const DynamicFeed();
  static Future<List<TvVideoItem>> getRelatedVideos(String bvid) async => const [];
  static Future<List<TvVideoItem>> getSpaceVideos({required int mid, int page = 1, String order = 'pubdate'}) async => const [];
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
  static Future<Map<String, dynamic>?> getVideoInfo(String bvid, {AccountRole role = AccountRole.video}) async => null;
  static Future<int?> getVideoCid(String bvid) async => null;
  static Future<Map<String, dynamic>?> getVideoPlayUrl({required String bvid, required int cid, int qn = 80, VideoCodec? forceCodec}) async => null;
  static Future<List<Map<String, dynamic>>> getDanmaku(int cid) async => const [];
  static Future<bool> reportProgress({required String bvid, required int cid, required int progress}) async => true;
  static Future<Map<String, String>?> getOnlineCount({required int aid, required int cid}) async => null;
  static Future<VideoshotData?> getVideoshot({required String bvid, int? cid}) async => null;
  static Future<bool> likeVideo({required int aid, required bool like}) async => false;
  static Future<bool> checkLikeStatus(int aid) async => false;
  static Future<String?> coinVideo({required int aid, int count = 1}) async => null;
  static Future<int> checkCoinStatus(int aid) async => 0;
  static Future<bool> favoriteVideo({required int aid, required bool favorite}) async => false;
  static Future<bool> checkFavoriteStatus(int aid) async => false;
  static Future<bool> followUser({required int mid, required bool follow}) async => false;
  static Future<bool> checkFollowStatus(int mid) async => false;
}
