import 'dart:collection';
import 'dart:typed_data';

import 'package:PiliPlus/http/api.dart';
import 'package:PiliPlus/http/browser_ua.dart';
import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/models_new/video/video_shot/data.dart';
import 'package:PiliPlus/utils/app_sign.dart';
import 'package:PiliPlus/utils/extension/string_ext.dart';
import 'package:PiliPlus/utils/id_utils.dart';
import 'package:dio/dio.dart';

final class VideoFirstFrameInfo {
  const VideoFirstFrameInfo({required this.url, required this.cid});

  final String url;
  final int? cid;
}

/// Extra video metadata endpoints used by the fork's cover and watermark
/// features. They live here instead of `VideoHttp` so upstream logic stays
/// conflict-free.
abstract final class ForkVideoApi {
  static const _firstFrameCacheMaxEntries = 320;
  static const _appVideoshotPath = '/x/v2/view/video/shot';

  static final LinkedHashMap<String, Future<VideoFirstFrameInfo?>>
  _firstFrameCache = LinkedHashMap();

  static Future<String?> getFirstFrame(String? bvid) async =>
      (await getFirstFrameInfo(bvid))?.url;

  /// Seeds the shared lookup cache when an enclosing API already supplied a
  /// first-frame URL, avoiding a later `/x/player/pagelist` request.
  static void rememberFirstFrame({
    required String? bvid,
    required String? url,
    int? cid,
  }) {
    if (bvid == null || bvid.isEmpty || url == null || url.isEmpty) return;
    _firstFrameCache.remove(bvid);
    _firstFrameCache[bvid] = Future.value(
      VideoFirstFrameInfo(url: url, cid: cid),
    );
    _trimFirstFrameCache();
  }

  static Future<VideoFirstFrameInfo?> getFirstFrameInfo(String? bvid) {
    if (bvid == null || bvid.isEmpty) {
      return Future<VideoFirstFrameInfo?>.value();
    }
    final cached = _firstFrameCache.remove(bvid);
    if (cached != null) {
      _firstFrameCache[bvid] = cached;
      return cached;
    }

    final request = () async {
      try {
        final res = await Request().get(
          Api.ab2c,
          queryParameters: {'bvid': bvid},
        );
        if (res.data['code'] == 0) {
          final list = res.data['data'] as List?;
          if (list != null && list.isNotEmpty) {
            final page = list.first as Map<String, dynamic>;
            final url = page['first_frame'] as String? ?? '';
            final cid = page['cid'] is num
                ? (page['cid'] as num).toInt()
                : null;
            if (url.isNotEmpty || cid != null) {
              return VideoFirstFrameInfo(url: url, cid: cid);
            }
          }
        }
      } catch (_) {
        _firstFrameCache.remove(bvid);
      }
      return null;
    }();
    _firstFrameCache[bvid] = request;
    _trimFirstFrameCache();
    return request;
  }

  static void _trimFirstFrameCache() {
    while (_firstFrameCache.length > _firstFrameCacheMaxEntries) {
      _firstFrameCache.remove(_firstFrameCache.keys.first);
    }
  }

  /// Web videoshot metadata (higher-resolution sprites).
  static Future<VideoShotData?> webVideoShot({
    required String bvid,
    required int cid,
  }) async {
    try {
      final res = await Request().get(
        Api.videoshot,
        queryParameters: {'bvid': bvid, 'cid': cid, 'index': 1},
        options: Options(
          headers: {
            'user-agent': BrowserUa.pc,
            'referer': 'https://www.bilibili.com/video/$bvid',
          },
        ),
      );
      if (res.data['code'] != 0) return null;
      final data = _parseVideoShot(res.data['data']);
      if (data == null || data.image.isEmpty) return null;
      if (data.index.isEmpty && data.pvdata?.isNotEmpty == true) {
        data.index = await _indexFromPvData(data.pvdata!);
      }
      if (data.index.isEmpty) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  /// APP videoshot metadata, used when the web endpoint returns nothing.
  static Future<VideoShotData?> appVideoShot({
    required String bvid,
    required int cid,
  }) async {
    try {
      final params = <String, dynamic>{
        'aid': IdUtils.bv2av(bvid),
        'cid': cid,
      };
      AppSign.appSign(params);
      final res = await Request().get(
        'https://app.bilibili.com$_appVideoshotPath',
        queryParameters: params,
        options: Options(headers: {'user-agent': BrowserUa.pc}),
      );
      if (res.data['code'] != 0) return null;
      final data = _parseVideoShot(res.data['data']);
      if (data == null || data.image.isEmpty) return null;
      if (data.index.isEmpty && data.pvdata?.isNotEmpty == true) {
        data.index = await _indexFromPvData(data.pvdata!);
      }
      if (data.index.isEmpty) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  static VideoShotData? _parseVideoShot(dynamic json) {
    if (json is! Map) return null;
    // The APP endpoint may omit `index`, which the shared model requires.
    final map = Map<String, dynamic>.from(json);
    map['index'] = (map['index'] as List?) ?? const <int>[];
    map['image'] = (map['image'] as List?) ?? const <String>[];
    if (map['img_x_len'] == null ||
        map['img_y_len'] == null ||
        map['img_x_size'] == null ||
        map['img_y_size'] == null) {
      return null;
    }
    try {
      return VideoShotData.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<List<int>> _indexFromPvData(String url) async {
    try {
      final response = await Request.dio.get<List<int>>(
        url.http2https,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 8),
          headers: {'user-agent': BrowserUa.pc},
        ),
      );
      final bytes = response.data;
      if (bytes == null) return const [];
      return parseVideoShotIndexBytes(bytes);
    } catch (_) {
      return const [];
    }
  }

  /// Decodes the binary sprite index (`uint16` big endian list).
  static List<int> parseVideoShotIndexBytes(List<int> bytes) {
    if (bytes.isEmpty || bytes.length.isOdd) return const [];
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    final index = List<int>.generate(
      bytes.length ~/ 2,
      (offset) => data.getUint16(offset * 2, Endian.big),
      growable: false,
    );
    for (var i = 1; i < index.length; i++) {
      if (index[i] < index[i - 1]) return const [];
    }
    return index;
  }
}
