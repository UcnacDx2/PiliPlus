import 'dart:math';

import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/models/model_owner.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/models/model_video.dart';

class DynamicToRecVideoAdapter extends BaseRecVideoItemModel {
  final DynamicItemModel item;

  DynamicToRecVideoAdapter(this.item) {
    goto = _getGoto(item);
    param = _getParam(item);
    cover = _getCover(item);
    title = _getTitle(item);
    duration = _getDuration(item);
    owner = Owner(
      mid: item.modules.moduleAuthor?.mid ?? 0,
      name: item.modules.moduleAuthor?.name ?? '',
      face: item.modules.moduleAuthor?.face ?? '',
    );
    stat = _getStat(item);
    bvid = _getBvid(item);
    aid = _getAid(item);
    cid = null;
    uri = null;
    pgcBadge = null;
    rcmdReason = null;
    isFollowed = false;
  }

  static String _getGoto(DynamicItemModel item) {
    switch (item.type) {
      case 'DYNAMIC_TYPE_AV':
        return 'av';
      case 'DYNAMIC_TYPE_UGC_SEASON':
        return 'av';
      case 'DYNAMIC_TYPE_PGC':
      case 'DYNAMIC_TYPE_PGC_UNION':
        return 'bangumi';
      default:
        return '';
    }
  }

  static String? _getParam(DynamicItemModel item) {
    final major = item.modules.moduleDynamic?.major;
    if (major != null) {
      switch (item.type) {
        case 'DYNAMIC_TYPE_AV':
          return major.archive?.aid.toString();
        case 'DYNAMIC_TYPE_UGC_SEASON':
          return major.ugcSeason?.aid.toString();
        case 'DYNAMIC_TYPE_PGC':
        case 'DYNAMIC_TYPE_PGC_UNION':
          return major.pgc?.epid.toString();
        default:
          return null;
      }
    }
    return null;
  }

  static String _getCover(DynamicItemModel item) {
    final major = item.modules.moduleDynamic?.major;
    if (major != null) {
      switch (item.type) {
        case 'DYNAMIC_TYPE_AV':
          return major.archive?.cover ?? '';
        case 'DYNAMIC_TYPE_UGC_SEASON':
          return major.ugcSeason?.cover ?? '';
        case 'DYNAMIC_TYPE_PGC':
        case 'DYNAMIC_TYPE_PGC_UNION':
          return major.pgc?.cover ?? '';
        case 'DYNAMIC_TYPE_COURSES_SEASON':
          return major.courses?.cover ?? '';
        default:
          return '';
      }
    }
    return '';
  }

  static String _getTitle(DynamicItemModel item) {
    final major = item.modules.moduleDynamic?.major;
    if (major != null) {
      switch (item.type) {
        case 'DYNAMIC_TYPE_AV':
          return major.archive?.title ?? '';
        case 'DYNAMIC_TYPE_UGC_SEASON':
          return major.ugcSeason?.title ?? '';
        case 'DYNAMIC_TYPE_PGC':
        case 'DYNAMIC_TYPE_PGC_UNION':
          return major.pgc?.title ?? '';
        case 'DYNAMIC_TYPE_COURSES_SEASON':
          return major.courses?.title ?? '';
        default:
          return '';
      }
    }
    return '';
  }

  static int _getDuration(DynamicItemModel item) {
    final major = item.modules.moduleDynamic?.major;
    if (major != null) {
      String? durationText;
      switch (item.type) {
        case 'DYNAMIC_TYPE_AV':
          durationText = major.archive?.durationText;
          break;
        case 'DYNAMIC_TYPE_UGC_SEASON':
          durationText = major.ugcSeason?.durationText;
          break;
        case 'DYNAMIC_TYPE_PGC':
        case 'DYNAMIC_TYPE_PGC_UNION':
          durationText = major.pgc?.durationText;
          break;
        case 'DYNAMIC_TYPE_COURSES_SEASON':
          durationText = major.courses?.durationText;
          break;
        default:
          return 0;
      }
      if (durationText != null) {
        List<String> parts = durationText.split(':').reversed.toList();
        int seconds = 0;
        for (int i = 0; i < parts.length; i++) {
          seconds += (int.tryParse(parts[i]) ?? 0) * (pow(60, i) as int);
        }
        return seconds;
      }
    }
    return 0;
  }

  static PlayStat _getStat(DynamicItemModel item) {
    final major = item.modules.moduleDynamic?.major;
    if (major != null) {
      switch (item.type) {
        case 'DYNAMIC_TYPE_AV':
          return PlayStat.fromJson({
            'play': int.tryParse(major.archive?.stat?.play ?? '0') ?? 0,
            'danmaku': int.tryParse(major.archive?.stat?.danmu ?? '0') ?? 0,
          });
        case 'DYNAMIC_TYPE_UGC_SEASON':
          return PlayStat.fromJson({
            'play': int.tryParse(major.ugcSeason?.stat?.play ?? '0') ?? 0,
            'danmaku': int.tryParse(major.ugcSeason?.stat?.danmu ?? '0') ?? 0,
          });
        case 'DYNAMIC_TYPE_PGC':
        case 'DYNAMIC_TYPE_PGC_UNION':
          return PlayStat.fromJson({
            'play': int.tryParse(major.pgc?.stat?.play ?? '0') ?? 0,
            'danmaku': int.tryParse(major.pgc?.stat?.danmu ?? '0') ?? 0,
          });
        case 'DYNAMIC_TYPE_COURSES_SEASON':
          return PlayStat.fromJson({
            'play': int.tryParse(major.courses?.stat?.play ?? '0') ?? 0,
            'danmaku': int.tryParse(major.courses?.stat?.danmu ?? '0') ?? 0,
          });
        default:
          return PlayStat.fromJson({'play': 0, 'danmaku': 0});
      }
    }
    return PlayStat.fromJson({'play': 0, 'danmaku': 0});
  }

  static String? _getBvid(DynamicItemModel item) {
    final major = item.modules.moduleDynamic?.major;
    if (major != null) {
      switch (item.type) {
        case 'DYNAMIC_TYPE_AV':
          return major.archive?.bvid;
        case 'DYNAMIC_TYPE_UGC_SEASON':
          return major.ugcSeason?.bvid;
        default:
          return null;
      }
    }
    return null;
  }

  static int? _getAid(DynamicItemModel item) {
    final major = item.modules.moduleDynamic?.major;
    if (major != null) {
      switch (item.type) {
        case 'DYNAMIC_TYPE_AV':
          return int.tryParse(major.archive?.aid?.toString() ?? '');
        case 'DYNAMIC_TYPE_UGC_SEASON':
          return int.tryParse(major.ugcSeason?.aid?.toString() ?? '');
        default:
          return null;
      }
    }
    return null;
  }
}
