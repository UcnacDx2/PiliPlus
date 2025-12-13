import 'package:PiliPlus/models/common/enum_with_label.dart';
import 'package:PiliPlus/pages/dynamics/view.dart';
import 'package:PiliPlus/pages/home/view.dart';
import 'package:PiliPlus/pages/mine/view.dart';
import 'package:PiliPlus/pages/download/view.dart';
import 'package:PiliPlus/pages/fav/view.dart';
import 'package:PiliPlus/pages/history/view.dart';
import 'package:PiliPlus/pages/hot/view.dart';
import 'package:PiliPlus/pages/later/view.dart';
import 'package:PiliPlus/pages/live/view.dart';
import 'package:PiliPlus/pages/pgc/view.dart';
import 'package:PiliPlus/pages/pgc_index/view.dart';
import 'package:PiliPlus/pages/rcmd/view.dart';
import 'package:PiliPlus/pages/subscription/view.dart';
import 'package:PiliPlus/pages/tv_debug/view.dart';
import 'package:flutter/material.dart';

enum NavigationBarType implements EnumWithLabel {
  home(
    '首页',
    Icon(Icons.home_outlined, size: 23),
    Icon(Icons.home, size: 21),
    HomePage(),
  ),
  dynamics(
    '动态',
    Icon(Icons.motion_photos_on_outlined, size: 21),
    Icon(Icons.motion_photos_on, size: 21),
    DynamicsPage(),
  ),
  mine(
    '我的',
    Icon(Icons.person_outline, size: 21),
    Icon(Icons.person, size: 21),
    MinePage(),
  ),
  tv(
    'TV调试',
    Icon(Icons.tv_outlined, size: 21),
    Icon(Icons.tv, size: 21),
    TvDebugPage(),
  ),
  recommend(
    '推荐',
    Icon(Icons.thumb_up_outlined, size: 21),
    Icon(Icons.thumb_up, size: 21),
    RcmdPage(),
  ),
  movie(
    '影视',
    Icon(Icons.movie_outlined, size: 21),
    Icon(Icons.movie, size: 21),
    PgcPage(),
  ),
  anime(
    '番剧',
    Icon(Icons.video_library_outlined, size: 21),
    Icon(Icons.video_library, size: 21),
    PgcIndexPage(),
  ),
  hot(
    '热门',
    Icon(Icons.whatshot_outlined, size: 21),
    Icon(Icons.whatshot, size: 21),
    HotPage(),
  ),
  partitions(
    '分区',
    Icon(Icons.category_outlined, size: 21),
    Icon(Icons.category, size: 21),
    Placeholder(),
  ),
  live(
    '直播',
    Icon(Icons.live_tv_outlined, size: 21),
    Icon(Icons.live_tv, size: 21),
    LivePage(),
  ),
  offline(
    '离线缓存',
    Icon(Icons.download_outlined, size: 21),
    Icon(Icons.download, size: 21),
    DownloadPage(),
  ),
  history(
    '观看记录',
    Icon(Icons.history_outlined, size: 21),
    Icon(Icons.history, size: 21),
    HistoryPage(),
  ),
  subscription(
    '我的订阅',
    Icon(Icons.subscriptions_outlined, size: 21),
    Icon(Icons.subscriptions, size: 21),
    SubscriptionPage(),
  ),
  watchLater(
    '稍后再看',
    Icon(Icons.watch_later_outlined, size: 21),
    Icon(Icons.watch_later, size: 21),
    LaterPage(),
  ),
  favorite(
    '我的收藏',
    Icon(Icons.favorite_border_outlined, size: 21),
    Icon(Icons.favorite, size: 21),
    FavPage(),
  );

  @override
  final String label;
  final Icon icon;
  final Icon selectIcon;
  final Widget page;

  const NavigationBarType(this.label, this.icon, this.selectIcon, this.page);
}
