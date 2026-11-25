import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/fork/http/fork_video_api.dart';
import 'package:PiliPlus/fork/watermark/bilibili_anchor_detector.dart';
import 'package:PiliPlus/fork/watermark/watermark_region.dart';
import 'package:PiliPlus/fork/watermark/watermark_detector.dart';
import 'package:PiliPlus/fork/watermark/watermark_input.dart';
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
  static final LinkedHashMap<String, Future<FirstFrameDetail>> _cache =
      LinkedHashMap();

  static Future<WatermarkRegion?> detect(String bvid) async =>
      (await detectDetail(bvid)).region;

  static Future<FirstFrameDetail> detectDetail(String bvid) {
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

  static Future<FirstFrameDetail> _resolve(String bvid) async {
    try {
      final firstFrame = await ForkVideoApi.getFirstFrame(bvid);
      if (firstFrame == null || firstFrame.isEmpty) {
        return const FirstFrameDetail(null, []);
      }

      // Always analyse a 1280 px frame: at 480 px the glyph strokes are 1-2 px
      // wide, so a stroke mask cannot separate them from the scene and falls
      // back to covering the whole nickname block.
      final analysisBytes =
          await _downloadAnalysis(firstFrame) ?? await _cachedDisplay(firstFrame);
      if (analysisBytes == null) return const FirstFrameDetail(null, []);

      ui.Codec? codec;
      ui.Image? image;
      try {
        codec = await ui.instantiateImageCodec(
          analysisBytes,
          targetWidth: 1280,
        );
        image = (await codec.getNextFrame()).image;
        final frame =
            await WatermarkInput.fromImage(image, targetWidth: 1280);
        if (frame == null) return const FirstFrameDetail(null, []);
        final anchor =
            await WatermarkDetector.detectBilibiliAnchorInFrames([frame]);
        return FirstFrameDetail(anchor?.region, [frame], anchor: anchor);
      } finally {
        image?.dispose();
        codec?.dispose();
      }
    } catch (_) {
      _cache.remove(bvid);
      return const FirstFrameDetail(null, []);
    }
  }

  /// Downloads the high-resolution analysis frame; returns null when the CDN
  /// request fails so the caller can fall back to an already cached thumbnail.
  static Future<Uint8List?> _downloadAnalysis(String firstFrame) async {
    try {
      final file = await CacheManager.manager.getSingleFile(
        _analysisUrl(firstFrame),
        headers: Constants.baseHeaders,
      );
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _cachedDisplay(String firstFrame) async {
    try {
      final displayUrl = ImageUtils.thumbnailUrl(firstFrame);
      final file = (await CacheManager.manager.getFileFromCache(displayUrl))?.file;
      return await file?.readAsBytes();
    } catch (_) {
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
    return uri
        .replace(path: '${uri.path}${separator}1280w_85q.webp')
        .toString();
  }
}

/// Detection result plus the frames it ran on, kept only while the video's
/// watermark filter is being built. The anchor is carried over so the stroke
/// mask is built against the very same location the region came from.
final class FirstFrameDetail {
  const FirstFrameDetail(
    this.region,
    this.frames, {
    this.anchor,
  });

  final WatermarkRegion? region;
  final List<WatermarkFrame> frames;
  final BilibiliAnchor? anchor;
}
