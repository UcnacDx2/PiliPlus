import 'dart:isolate';
import 'dart:math' show max, min;

import 'package:PiliPlus/fork/watermark/bilibili_anchor_detector.dart';
import 'package:PiliPlus/fork/watermark/watermark_frame.dart';
import 'package:PiliPlus/fork/watermark/watermark_mode.dart';
import 'package:PiliPlus/fork/watermark/watermark_region.dart';

export 'package:PiliPlus/fork/watermark/watermark_frame.dart';

abstract final class WatermarkDetector {
  /// Detects the standard creator `bilibili` word mark from one first-frame
  /// thumbnail. This deliberately returns a generous fixed creator region;
  /// the advanced temporal detector remains responsible for source watermarks.
  static Future<WatermarkRegion?> detectBilibiliAnchor(
    WatermarkFrame frame,
  ) async {
    final anchor = await BilibiliAnchorDetector.detectInFrames([frame]);
    return anchor?.region;
  }

  /// Locates the standard creator watermark across several frames. Frames may
  /// come from a first-frame thumbnail and from screen captures.
  static Future<BilibiliAnchor?> detectBilibiliAnchorInFrames(
    List<WatermarkFrame> frames,
  ) => BilibiliAnchorDetector.detectInFrames(frames);

  /// Combines independently detected regions without stacking filters over
  /// substantially the same pixels.
  static List<WatermarkRegion> mergeRegions(
    Iterable<WatermarkRegion> regions,
  ) {
    final result = <WatermarkRegion>[];
    for (final region in regions) {
      final area = _regionArea(region);
      if (area <= 0) continue;
      final overlapIndex = result.indexWhere((item) {
        final intersection = _intersectionArea(item, region);
        return intersection / min(_regionArea(item), area) >= 0.5;
      });
      if (overlapIndex == -1) {
        result.add(region);
        continue;
      }
      final current = result[overlapIndex];
      result[overlapIndex] = WatermarkRegion(
        left: min(current.left, region.left),
        top: min(current.top, region.top),
        right: max(current.right, region.right),
        bottom: max(current.bottom, region.bottom),
        confidence: max(current.confidence, region.confidence),
      );
    }
    return result;
  }

  static Future<List<WatermarkRegion>> detect(
    WatermarkMode mode,
    List<WatermarkFrame> frames,
  ) {
    if (mode == WatermarkMode.disabled || frames.isEmpty) {
      return Future.value(const []);
    }
    return Isolate.run(() => detectSync(mode, frames));
  }

  static List<WatermarkRegion> detectSync(
    WatermarkMode mode,
    List<WatermarkFrame> frames,
  ) {
    if (mode == WatermarkMode.disabled || frames.isEmpty) return const [];
    return switch (BilibiliAnchorDetector.detectInFramesSync(frames)) {
      final anchor? => [anchor.region],
      null => const <WatermarkRegion>[],
    };
  }

  static double _regionArea(WatermarkRegion region) =>
      max(0.0, region.right - region.left) *
      max(0.0, region.bottom - region.top);

  static double _intersectionArea(
    WatermarkRegion first,
    WatermarkRegion second,
  ) =>
      max(
        0.0,
        min(first.right, second.right) - max(first.left, second.left),
      ) *
      max(
        0.0,
        min(first.bottom, second.bottom) - max(first.top, second.top),
      );
}


