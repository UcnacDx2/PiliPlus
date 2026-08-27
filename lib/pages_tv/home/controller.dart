import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/services/account_service.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';

enum TVHomeCategory {
  recommend('推荐', Icons.thumb_up_outlined),
  hot('热门', Icons.whatshot_outlined),
  live('直播', Icons.live_tv_outlined),
  pgc('番剧', Icons.movie_outlined),
  rank('排行', Icons.leaderboard_outlined),
  dynamics('动态', Icons.dynamic_feed_outlined),
  history('历史', Icons.history_outlined),
  later('稍后再看', Icons.watch_later_outlined),
  favorite('收藏', Icons.star_outline),
  search('搜索', Icons.search),
  setting('设置', Icons.settings_outlined);

  const TVHomeCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

class TVHomeController extends GetxController {
  final RxInt selectedCategory = 0.obs;
  final RxBool sidebarExpanded = false.obs;
  final Rx<LoadingState<List?>> rcmdState = LoadingState<List?>.loading().obs;
  final Rx<LoadingState<List?>> hotState = LoadingState<List?>.loading().obs;

  int _rcmdFreshIdx = 0;
  int _hotPage = 1;
  bool _rcmdLoading = false;
  bool _hotLoading = false;
  bool _rcmdHasMore = true;
  bool _hotHasMore = true;

  AccountService get accountService => Get.find<AccountService>();

  @override
  void onInit() {
    super.onInit();
    loadRcmd();
    loadHot();
  }

  Future<void> loadRcmd({bool loadMore = false}) async {
    if (_rcmdLoading || (loadMore && !_rcmdHasMore)) return;
    _rcmdLoading = true;
    if (!loadMore) {
      _rcmdFreshIdx = 0;
      _rcmdHasMore = true;
      rcmdState.value = LoadingState.loading();
    }
    try {
      final res = await VideoHttp.rcmdVideoListApp(
        freshIdx: _rcmdFreshIdx,
      );
      switch (res) {
        case Success(:final response):
          final next = response;
          rcmdState.value = Success<List?>(
            loadMore ? _mergeItems(rcmdState.value, next) : next,
          );
          if (next.isEmpty) {
            _rcmdHasMore = false;
          } else {
            _rcmdFreshIdx++;
          }
        case Error(:final errMsg):
          if (!loadMore) rcmdState.value = Error(errMsg);
        default:
          if (!loadMore) rcmdState.value = const Error(null);
      }
    } finally {
      _rcmdLoading = false;
    }
  }

  Future<void> loadHot({bool loadMore = false}) async {
    if (_hotLoading || (loadMore && !_hotHasMore)) return;
    _hotLoading = true;
    if (!loadMore) {
      _hotPage = 1;
      _hotHasMore = true;
      hotState.value = LoadingState.loading();
    }
    try {
      final res = await VideoHttp.hotVideoList(pn: _hotPage, ps: 20);
      switch (res) {
        case Success(:final response):
          final next = response;
          hotState.value = Success<List?>(
            loadMore ? _mergeItems(hotState.value, next) : next,
          );
          if (next.isEmpty) {
            _hotHasMore = false;
          } else {
            _hotPage++;
          }
        case Error(:final errMsg):
          if (!loadMore) hotState.value = Error(errMsg);
        default:
          if (!loadMore) hotState.value = const Error(null);
      }
    } finally {
      _hotLoading = false;
    }
  }

  List<dynamic> _mergeItems(LoadingState<List?> state, List next) {
    final current = switch (state) {
      Success(:final response) => List<dynamic>.of(response ?? const []),
      _ => <dynamic>[],
    };
    final seen = current.map(_itemKey).whereType<Object>().toSet();
    for (final item in next) {
      final key = _itemKey(item);
      if (key == null || seen.add(key)) current.add(item);
    }
    return current;
  }

  Object? _itemKey(dynamic item) => item.bvid ?? item.aid;
}
