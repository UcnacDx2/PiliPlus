import 'dart:collection';
import 'dart:ui' as ui;

import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/plugin/pl_player/models/watermark_region.dart';
import 'package:PiliPlus/plugin/pl_player/utils/watermark_detector.dart';
import 'package:PiliPlus/utils/cache_manager.dart';
import 'package:PiliPlus/utils/extension/string_ext.dart';
import 'package:PiliPlus/utils/image_utils.dart';

/// Resolves the standard creator watermark from Bilibili's first-frame image.
///
/// A first frame already displayed by [ImageUtils] is read from the shared
/// image file cache. Otherwise only a 480 px CDN thumbnail is downloaded and
/// cached, so this path never needs to decode or seek the playing video.
abstract final class FirstFrameWatermarkService {
  static const _maxEntries = 160;
  static final LinkedHashMap<String, Future<WatermarkRegion?>> _cache =
      LinkedHashMap();

  static Future<WatermarkRegion?> detect(String bvid) {
    final cached = _cache.remove(bvid);
    if (cached != null) {
      _cache[bvid] = cached;
      return cached;
    }

    final request = _resolve(bvid);
    _cache[bvid] = request;
    while (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    return request;
  }

  static Future<WatermarkRegion?> _resolve(String bvid) async {
    try {
      final firstFrame = await VideoHttp.getVideoFirstFrame(bvid);
      if (firstFrame == null || firstFrame.isEmpty) return null;

      final displayUrl = ImageUtils.thumbnailUrl(firstFrame);
      var file = (await CacheManager.manager.getFileFromCache(displayUrl))?.file;
      file ??= await CacheManager.manager.getSingleFile(
        _analysisUrl(firstFrame),
        headers: Constants.baseHeaders,
      );

      ui.Codec? codec;
      ui.Image? image;
      try {
        codec = await ui.instantiateImageCodec(
          await file.readAsBytes(),
          targetWidth: 480,
        );
        image = (await codec.getNextFrame()).image;
        final frame = await WatermarkFrame.fromImage(image, upscale: true);
        if (frame == null) return null;
        return WatermarkDetector.detectBilibiliAnchor(frame);
      } finally {
        image?.dispose();
        codec?.dispose();
      }
    } catch (_) {
      _cache.remove(bvid);
      return null;
    }
  }

  static String _analysisUrl(String url) {
    final uri = Uri.tryParse(url.http2https);
    if (uri == null || uri.host.isEmpty) return url.http2https;
    final isBiliCdn = uri.host.endsWith('.hdslb.com') ||
        uri.host.endsWith('.bilivideo.com') ||
        uri.host.endsWith('.biliimg.com');
    if (!isBiliCdn) return uri.toString();

    final separator = uri.path.contains('@') ? '_' : '@';
    return uri.replace(path: '${uri.path}${separator}480w_85q.webp').toString();
  }
}
