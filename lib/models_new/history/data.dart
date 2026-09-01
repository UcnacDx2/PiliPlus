import 'package:PiliPlus/models_new/history/list.dart';
import 'package:PiliPlus/models_new/history/tab.dart';

class HistoryData {
  List<HistoryTab>? tab;
  List<HistoryItemModel>? list;
  int viewAt;
  int max;

  HistoryData({this.tab, this.list, this.viewAt = 0, this.max = 0});

  factory HistoryData.fromJson(Map<String, dynamic> json) {
    final cursor = json['cursor'] as Map<String, dynamic>? ?? const {};
    return HistoryData(
      tab: (json['tab'] as List<dynamic>?)
          ?.map((e) => HistoryTab.fromJson(e as Map<String, dynamic>))
          .toList(),
      list: (json['list'] as List<dynamic>?)
          ?.map((e) => HistoryItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      viewAt: (cursor['view_at'] as num?)?.toInt() ?? 0,
      max: (cursor['max'] as num?)?.toInt() ?? 0,
    );
  }
}
