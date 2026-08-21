import 'package:PiliPlus/models_new/video/video_detail/dimension.dart';
import 'package:PiliPlus/models_new/video/video_detail/episode.dart'
    show BaseEpisodeItem;

class EpisodeItem extends BaseEpisodeItem {
  Dimension? dimension;
  int? duration; // pgc: millisec , pugv: sec
  String? from;
  String? link;
  String? longTitle;
  int? pubTime;
  String? shareCopy;
  String? shareUrl;
  String? showTitle;
  int? play;
  int? status;

  /// Whether the episode is not freely playable by a regular account.
  ///
  /// The season API uses status 13 for restricted episodes. Prefer that
  /// semantic field over the presentation-only badge, while retaining the
  /// known paywall badges for compatibility with incomplete responses.
  bool get isNonFree =>
      status == 13 || const {'会员', '付费'}.contains(badge?.trim());

  EpisodeItem({
    super.aid,
    super.badge,
    super.bvid,
    super.cid,
    super.cover,
    this.dimension,
    this.duration,
    super.epId,
    this.from,
    super.id,
    this.link,
    this.longTitle,
    this.pubTime,
    this.shareCopy,
    this.shareUrl,
    this.showTitle,
    super.title,
    this.play,
    this.status,
  });

  factory EpisodeItem.fromJson(Map<String, dynamic> json) => EpisodeItem(
    aid: json['aid'] as int?,
    badge: json['badge'] as String?,
    bvid: json['bvid'] as String?,
    cid: json['cid'] as int?,
    cover: json['cover'] as String?,
    dimension: json['dimension'] == null
        ? null
        : Dimension.fromJson(json['dimension'] as Map<String, dynamic>),
    duration: json['duration'] as int?,
    epId: json['ep_id'] as int?,
    from: json['from'] as String?,
    id: json['id'] as int?,
    link: json['link'] as String?,
    longTitle: json['long_title'] as String?,
    pubTime: json['pub_time'] ?? json['release_date'],
    shareCopy: json['share_copy'] as String?,
    shareUrl: json['share_url'] as String?,
    showTitle: json['show_title'] as String?,
    title: json['title'] as String?,
    play: json['play'] as int?,
    status: json['status'] as int?,
  );
}
