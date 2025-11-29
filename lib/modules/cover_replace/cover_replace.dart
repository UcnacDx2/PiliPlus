
import 'package:PiliPlus/http/index.dart';
import 'package:PiliPlus/utils/id_utils.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:dio/dio.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class CoverReplaceService {
  static Future<String?> getReplacedCover(
      String? bvid, int? cid, int? aid) async {
    if ((bvid == null && aid == null) ||
        cid == null ||
        !Pref.replaceCover) {
      return null;
    }

    try {
      String? effectiveBvid = bvid;
      if (effectiveBvid == null) {
        effectiveBvid = IdUtils.av2bv(aid!);
      }

      final response = await dio.get(
        'https://api.bilibili.com/x/player/v2',
        queryParameters: {'bvid': effectiveBvid, 'cid': cid},
      );
      final data = response.data;
      if (data != null && data['code'] == 0) {
        return data['data']['pic'];
      } else {
        SmartDialog.showToast(
            'Failed to fetch replaced cover: ${data['message']}');
      }
    } catch (e) {
      SmartDialog.showToast('Failed to fetch replaced cover: $e');
    }
    return null;
  }
}
