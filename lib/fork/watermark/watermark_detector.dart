import 'dart:isolate';
import 'dart:math' show max, min;
import 'dart:typed_data';

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
    return Isolate.run(
      () => switch (mode) {
        WatermarkMode.bilibili ||
        WatermarkMode.bilibiliAuto =>
          switch (BilibiliAnchorDetector.detectInFramesSync(frames)) {
            final anchor? => [anchor.region],
            null => const <WatermarkRegion>[],
          },
        WatermarkMode.advanced => _detectAdvanced(frames),
        WatermarkMode.disabled => const <WatermarkRegion>[],
      },
    );
  }

  /// Produces compact failure telemetry without retaining or writing frames.
  /// This is intentionally run only after advanced detection returns empty.
  static Future<String> diagnoseAdvanced(List<WatermarkFrame> frames) {
    return Isolate.run(() => _diagnoseAdvanced(frames));
  }

  static List<WatermarkRegion> _detectAdvanced(List<WatermarkFrame> frames) {
    if (!_sameSize(frames) || frames.length < 6) return const [];
    final width = frames.first.width;
    final height = frames.first.height;
    final result = <WatermarkRegion>[];

    for (final corner in _Corner.values) {
      final roi = _cornerRoi(width, height, corner, 0.30, 0.25);
      var combined = _stableMask(frames, roi);
      combined = _dilate(combined, roi.width, roi.height, 2, 2);
      combined = _dilate(combined, roi.width, roi.height, 1, 1);
      final closed = _erode(
        _dilate(combined, roi.width, roi.height, 4, 2),
        roi.width,
        roi.height,
        4,
        2,
      );

      final components = _components(closed, roi.width, roi.height);
      final candidates = _componentCandidates(components, width, height)
        ..sort((a, b) => b.area.compareTo(a.area));
      WatermarkRegion? bestRegion;
      var bestArea = -1;
      for (final component in candidates) {
        if (component.area < 0.002 * width * height ||
            component.width < 14 ||
            component.height < 6) {
          continue;
        }
        final touchesInnerEdge = switch (corner) {
          _Corner.topLeft || _Corner.bottomLeft =>
            component.right >= roi.width - 2,
          _Corner.topRight || _Corner.bottomRight => component.left <= 2,
        };
        if (touchesInnerEdge ||
            component.width > 0.29 * width ||
            component.height > 0.22 * height ||
            component.width * component.height > 0.55 * roi.width * roi.height) {
          continue;
        }
        final outerGap = switch (corner) {
          _Corner.topLeft || _Corner.bottomLeft => component.left,
          _Corner.topRight || _Corner.bottomRight => roi.width - component.right,
        };
        // A real corner watermark is inset from the encoded frame. Components
        // touching the outer border are usually letterbox/content boundaries
        // or persistent sprite-page edges, especially on sharper web shots.
        if (outerGap <= 0 || outerGap > 0.085 * width) continue;
        // The closing erosion (radius 4) shaves a border-flush component by a
        // few pixels, so its closed box looks identical to a legitimately
        // inset one. Check the pre-closing mask inside the component's rows
        // instead: there a frame-flush edge still reaches the outer border.
        if (_touchesOuterBorder(
          combined,
          roi.width,
          roi.height,
          component,
          corner,
        )) {
          continue;
        }

        final x1 = roi.left + component.left;
        final y1 = roi.top + component.top;
        final x2 = roi.left + component.right;
        final y2 = roi.top + component.bottom;
        if ((corner == _Corner.topLeft || corner == _Corner.topRight) &&
            y2 > 0.25 * height) {
          continue;
        }
        if ((corner == _Corner.bottomLeft || corner == _Corner.bottomRight) &&
            y1 < 0.75 * height) {
          continue;
        }
        if (component.area <= bestArea) continue;
        bestArea = component.area;
        final paddingX = max(4, (width * 0.015).round());
        final paddingY = max(3, (height * 0.015).round());
        bestRegion = WatermarkRegion(
          left: max(0, x1 - paddingX) / width,
          top: max(0, y1 - paddingY) / height,
          right: min(width, x2 + paddingX) / width,
          bottom: min(height, y2 + paddingY) / height,
          confidence: min(1, component.area / (0.006 * width * height)),
        );
      }
      if (bestRegion != null) result.add(bestRegion);
    }
    return result;
  }

  static String _diagnoseAdvanced(List<WatermarkFrame> frames) {
    if (frames.isEmpty) return 'frames=0';
    if (!_sameSize(frames)) return 'frame-size=mismatch';
    final width = frames.first.width;
    final height = frames.first.height;
    var deltaTotal = 0;
    var deltaSamples = 0;
    for (var frameIndex = 1; frameIndex < frames.length; frameIndex++) {
      final previous = frames[frameIndex - 1].luma;
      final current = frames[frameIndex].luma;
      for (var pixel = 0; pixel < current.length; pixel += 8) {
        deltaTotal += (current[pixel] - previous[pixel]).abs();
        deltaSamples++;
      }
    }
    final meanDelta = deltaSamples == 0 ? 0 : deltaTotal / deltaSamples;
    final details = <String>[
      'size=${width}x$height',
      'meanDelta=${meanDelta.toStringAsFixed(1)}',
    ];

    for (final corner in _Corner.values) {
      final roi = _cornerRoi(width, height, corner, 0.30, 0.25);
      var mask = _stableMask(frames, roi);
      final stablePixels = mask.where((value) => value != 0).length;
      mask = _dilate(mask, roi.width, roi.height, 2, 2);
      mask = _dilate(mask, roi.width, roi.height, 1, 1);
      final closed = _erode(
        _dilate(mask, roi.width, roi.height, 4, 2),
        roi.width,
        roi.height,
        4,
        2,
      );
      final closedPixels = closed.where((value) => value != 0).length;
      final components = _components(closed, roi.width, roi.height)
        ..sort((a, b) => b.area.compareTo(a.area));
      final groups = _componentCandidates(components, width, height)
          .where((item) => !components.contains(item))
          .toList()
        ..sort((a, b) => b.area.compareTo(a.area));
      final largest = components
          .take(3)
          .map(
            (item) =>
                '${item.left},${item.top},${item.width}x${item.height},${item.area}',
          )
          .join('|');
      details.add(
        '${corner.name}{stable=$stablePixels,closed=$closedPixels,'
        'count=${components.length},largest=[$largest],groups='
        '[${groups.take(3).map((item) => '${item.left},${item.top},'
            '${item.width}x${item.height},${item.area}').join('|')}]}',
      );
    }
    return details.join(';');
  }

  static bool _touchesOuterBorder(
    Uint8List mask,
    int width,
    int height,
    _Component component,
    _Corner corner,
  ) {
    // The two small dilations spread a frame-flush edge three pixels inward,
    // so a watermark inset by anything more than that stays clear of the strip.
    const border = 3;
    final top = max(0, component.top - 2);
    final bottom = min(height - 1, component.bottom + 2);
    final leftSide = corner == _Corner.topLeft || corner == _Corner.bottomLeft;
    for (var y = top; y <= bottom; y++) {
      for (var offset = 0; offset < border; offset++) {
        final x = leftSide ? offset : width - 1 - offset;
        if (mask[y * width + x] != 0) return true;
      }
    }
    return false;
  }

  static bool _sameSize(List<WatermarkFrame> frames) => frames.every(
    (frame) =>
        frame.width == frames.first.width && frame.height == frames.first.height,
  );

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

  static Uint8List _stableMask(List<WatermarkFrame> frames, _IntRect roi) {
    final width = frames.first.width;
    final gradients = [for (final frame in frames) _gradientMap(frame)];
    final requiredCount = max(2, (frames.length * 0.6).ceil());
    final result = Uint8List(roi.width * roi.height);
    for (var y = 0; y < roi.height; y++) {
      for (var x = 0; x < roi.width; x++) {
        final sourceIndex = (roi.top + y) * width + roi.left + x;
        var count = 0;
        for (final gradient in gradients) {
          final value = gradient[sourceIndex];
          if (value > 8) count++;
        }
        if (count >= requiredCount) {
          result[y * roi.width + x] = 1;
        }
      }
    }
    return result;
  }

  static List<_Component> _componentCandidates(
    List<_Component> components,
    int frameWidth,
    int frameHeight,
  ) {
    final eligible = components
        .where((item) => item.area >= 24 && item.width >= 3 && item.height >= 3)
        .toList();
    final result = <_Component>[...components];
    final used = <_Component>{};
    for (final seed in eligible) {
      if (!used.add(seed)) continue;
      var group = seed;
      var count = 1;
      var changed = true;
      while (changed) {
        changed = false;
        for (final candidate in eligible) {
          if (used.contains(candidate)) continue;
          final horizontalGap = max(
            0,
            max(group.left, candidate.left) -
                min(group.right, candidate.right),
          );
          final verticalGap = max(
            0,
            max(group.top, candidate.top) -
                min(group.bottom, candidate.bottom),
          );
          if (horizontalGap > 0.06 * frameWidth ||
              verticalGap > 0.025 * frameHeight) {
            continue;
          }
          used.add(candidate);
          count++;
          changed = true;
          group = _Component(
            min(group.left, candidate.left),
            min(group.top, candidate.top),
            max(group.right, candidate.right),
            max(group.bottom, candidate.bottom),
            group.area + candidate.area,
          );
        }
      }
      if (count > 1) result.add(group);
    }
    return result;
  }

  static Uint8List _gradientMap(WatermarkFrame frame) {
    final width = frame.width;
    final height = frame.height;
    final result = Uint8List(width * height);
    for (var y = 1; y < height - 1; y++) {
      for (var x = 1; x < width - 1; x++) {
        final i = y * width + x;
        final dx = (frame.luma[i + 1] - frame.luma[i - 1]).abs();
        final dy = (frame.luma[i + width] - frame.luma[i - width]).abs();
        result[i] = min(255, (dx + dy) ~/ 2);
      }
    }
    return result;
  }

  static Uint8List _dilate(
    Uint8List source,
    int width,
    int height,
    int radiusX,
    int radiusY,
  ) {
    final result = Uint8List(source.length);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (source[y * width + x] == 0) continue;
        for (var yy = max(0, y - radiusY); yy <= min(height - 1, y + radiusY); yy++) {
          for (var xx = max(0, x - radiusX); xx <= min(width - 1, x + radiusX); xx++) {
            result[yy * width + xx] = 1;
          }
        }
      }
    }
    return result;
  }

  static Uint8List _erode(
    Uint8List source,
    int width,
    int height,
    int radiusX,
    int radiusY,
  ) {
    final result = Uint8List(source.length);
    for (var y = radiusY; y < height - radiusY; y++) {
      for (var x = radiusX; x < width - radiusX; x++) {
        var keep = true;
        for (var yy = y - radiusY; yy <= y + radiusY && keep; yy++) {
          for (var xx = x - radiusX; xx <= x + radiusX; xx++) {
            if (source[yy * width + xx] == 0) {
              keep = false;
              break;
            }
          }
        }
        if (keep) result[y * width + x] = 1;
      }
    }
    return result;
  }

  static List<_Component> _components(Uint8List mask, int width, int height) {
    final visited = Uint8List(mask.length);
    final queue = Int32List(mask.length);
    final result = <_Component>[];
    for (var start = 0; start < mask.length; start++) {
      if (mask[start] == 0 || visited[start] != 0) continue;
      var head = 0;
      var tail = 0;
      queue[tail++] = start;
      visited[start] = 1;
      var left = start % width;
      var right = left + 1;
      var top = start ~/ width;
      var bottom = top + 1;
      var area = 0;
      while (head < tail) {
        final index = queue[head++];
        final x = index % width;
        final y = index ~/ width;
        area++;
        left = min(left, x);
        right = max(right, x + 1);
        top = min(top, y);
        bottom = max(bottom, y + 1);
        for (var yy = max(0, y - 1); yy <= min(height - 1, y + 1); yy++) {
          for (var xx = max(0, x - 1); xx <= min(width - 1, x + 1); xx++) {
            final next = yy * width + xx;
            if (mask[next] != 0 && visited[next] == 0) {
              visited[next] = 1;
              queue[tail++] = next;
            }
          }
        }
      }
      result.add(_Component(left, top, right, bottom, area));
    }
    return result;
  }

  static _IntRect _cornerRoi(
    int width,
    int height,
    _Corner corner,
    double widthFactor,
    double heightFactor,
  ) {
    final roiWidth = (width * widthFactor).round();
    final roiHeight = (height * heightFactor).round();
    return _IntRect(
      corner == _Corner.topLeft || corner == _Corner.bottomLeft
          ? 0
          : width - roiWidth,
      corner == _Corner.topLeft || corner == _Corner.topRight
          ? 0
          : height - roiHeight,
      roiWidth,
      roiHeight,
    );
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _IntRect {
  const _IntRect(this.left, this.top, this.width, this.height);
  final int left;
  final int top;
  final int width;
  final int height;
  int get right => left + width;
  int get bottom => top + height;
}

class _Component {
  const _Component(this.left, this.top, this.right, this.bottom, this.area);
  final int left;
  final int top;
  final int right;
  final int bottom;
  final int area;
  int get width => right - left;
  int get height => bottom - top;
}
