
import 'package:PiliPlus/http/index.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:dio/dio.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class CoverReplaceService {
  static Future<String?> getReplacedCover(String? bvid, int? cid) async {
    if (bvid == null ||
        bvid.isEmpty ||
        cid == null ||
        !Pref.replaceCover) {
      return null;
    }

    try {
      final response = await dio.get(
        'https://api.bilibili.com/x/player/v2',
        queryParameters: {'bvid': bvid, 'cid': cid},
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
