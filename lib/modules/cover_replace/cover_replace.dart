
import 'package:PiliPlus/http/index.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:dio/dio.dart';

class CoverReplaceService {
  static Future<String?> getReplacedCover(String? bvid) async {
    if (bvid == null || bvid.isEmpty || !Pref.get(PrefKey.replaceCover, false)) {
      return null;
    }

    try {
      final response = await dio.get(
        'https://api.bilibili.com/x/web-interface/view',
        queryParameters: {'bvid': bvid},
      );
      final data = response.data;
      if (data != null && data['code'] == 0) {
        return data['data']['pic'];
      }
    } catch (e) {
      print('Failed to fetch replaced cover: $e');
    }
    return null;
  }
}
