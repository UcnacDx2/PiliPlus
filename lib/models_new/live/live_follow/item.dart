class LiveFollowItem {
  int? roomid;
  String? uname;
  String? title;
  String? areaName;
  String? textSmall;
  String? roomCover;

  LiveFollowItem({
    this.roomid,
    this.uname,
    this.title,
    this.areaName,
    this.textSmall,
    this.roomCover,
  });

  factory LiveFollowItem.fromJson(Map<String, dynamic> json) => LiveFollowItem(
    roomid: _toInt(json['roomid']),
    uname: json['uname'] as String?,
    title: json['title'] as String?,
    areaName: json['area_name'] as String?,
    textSmall: json['text_small']?.toString(),
    roomCover: json['room_cover'] as String?,
  );

  static int? _toInt(dynamic value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '');
}
