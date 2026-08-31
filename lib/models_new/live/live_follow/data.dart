import 'package:PiliPlus/models_new/live/live_follow/item.dart';

class LiveFollowData {
  String? title;
  int? pageSize;
  int? totalPage;
  List<LiveFollowItem>? list;
  int? count;
  int? liveCount;

  LiveFollowData({
    this.title,
    this.pageSize,
    this.totalPage,
    this.list,
    this.count,
    this.liveCount,
  });

  LiveFollowData.fromJson(Map<String, dynamic> json) {
    title = json['title'] as String?;
    pageSize = _toInt(json['pageSize']);
    totalPage = _toInt(json['totalPage']);
    list = (json['list'] as List<dynamic>?)
        ?.cast<Map<String, dynamic>>()
        // Some API/CDN variants serialize live_status as a string.
        // Accept both forms so the TV "我的关注" tab does not appear empty.
        .where((i) => i['live_status'] == 1 || i['live_status'] == '1')
        .map(LiveFollowItem.fromJson)
        .toList();
    count = _toInt(json['count']);
    liveCount = _toInt(json['live_count']);
  }

  static int? _toInt(dynamic value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '');
}
