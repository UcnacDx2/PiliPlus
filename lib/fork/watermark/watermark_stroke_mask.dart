import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:PiliPlus/fork/watermark/bilibili_anchor_detector.dart';
import 'package:PiliPlus/fork/watermark/watermark_frame.dart';
import 'package:PiliPlus/fork/watermark/watermark_region.dart';

/// A compact, bit-packed map of the watermark's own strokes.
///
/// The overlay is identical in every frame of one video, so the mask is
/// extracted once at detection time and baked into the shader. A set bit means
/// "replace this pixel", everything else is left untouched.
final class WatermarkStrokeMask {
  const WatermarkStrokeMask({
    required this.columns,
    required this.rows,
    required this.words,
  });

  final int columns;
  final int rows;
  final Uint32List words;

  int get bitCount => columns * rows;

  bool bitAt(int x, int y) {
    if (x < 0 || y < 0 || x >= columns || y >= rows) return false;
    final index = y * columns + x;
    return (words[index >> 5] >> (index & 31)) & 1 == 1;
  }

  /// Share of the region the mask touches, for diagnostics.
  double get coverage {
    var set = 0;
    for (var index = 0; index < bitCount; index++) {
      if ((words[index >> 5] >> (index & 31)) & 1 == 1) set++;
    }
    return bitCount == 0 ? 0 : set / bitCount;
  }
}

final class WatermarkRefinement {
  const WatermarkRefinement({required this.region, required this.mask});

  final WatermarkRegion region;
  final WatermarkStrokeMask mask;
}

/// Extracts the stroke mask for an already detected creator watermark.
///
/// Runs on plain [WatermarkFrame] luma data so it can also be exercised
/// offline, without `dart:ui`.
abstract final class WatermarkStrokeMaskBuilder {
  static Future<WatermarkRefinement?> build(
    List<WatermarkFrame> frames,
    BilibiliAnchor anchor,
  ) {
    if (frames.isEmpty) return Future.value(null);
    return Isolate.run(() => buildSync(frames, anchor));
  }

  static WatermarkRefinement? buildSync(
    List<WatermarkFrame> frames,
    BilibiliAnchor anchor,
  ) {
    final region = anchor.region;
    if (region.right - region.left <= 0 || region.bottom - region.top <= 0) {
      return null;
    }
    final analysisWidth = anchor.analysisWidth;
    final analysisHeight = anchor.analysisHeight;
    if (analysisWidth <= 0 || analysisHeight <= 0) return null;

    final samples = frames
        .where(
          (frame) =>
              frame.width > 0 &&
              frame.height > 0 &&
              ((frame.width / frame.height) /
                          (analysisWidth / analysisHeight) -
                      1)
                  .abs() <
                  0.03,
        )
        .take(3)
        .toList(growable: false);
    if (samples.isEmpty) return null;

    final columns = ((region.right - region.left) * analysisWidth)
        .round()
        .clamp(32, 192);
    final rows = ((region.bottom - region.top) * analysisHeight)
        .round()
        .clamp(12, 64);
    final votes = Uint8List(columns * rows);
    for (final frame in samples) {
      _voteFrame(votes, columns, rows, frame, anchor);
    }
    final required = samples.length == 1
        ? 1
        : math.max(2, samples.length - 1);

    final mask = Uint8List(columns * rows);
    final template = _templateCells(anchor, columns, rows);
    for (var index = 0; index < mask.length; index++) {
      final x = index % columns;
      final y = index ~/ columns;
      final inTemplate = template[y * columns + x] != 0;
      if (inTemplate || votes[index] >= required) mask[index] = 1;
    }
    // Grow by one cell to cover antialiased edges, then pack.
    final grown = _grow(mask, columns, rows);
    final coverage = grown.fold<int>(0, (sum, value) => sum + value) /
        (columns * rows);
    if (coverage < 0.02 || coverage > 0.90) return null;

    final words = Uint32List((grown.length + 31) >> 5);
    for (var index = 0; index < grown.length; index++) {
      if (grown[index] != 0) words[index >> 5] |= 1 << (index & 31);
    }
    return WatermarkRefinement(
      region: region,
      mask: WatermarkStrokeMask(
        columns: columns,
        rows: rows,
        words: words,
      ),
    );
  }

  /// Adds one frame's vote to every grid cell whose centre looks like a glyph
  /// stroke: brighter than the local opening or darker than the local closing.
  static void _voteFrame(
    Uint8List votes,
    int columns,
    int rows,
    WatermarkFrame frame,
    BilibiliAnchor anchor,
  ) {
    final width = frame.width;
    final height = frame.height;
    final luma = frame.luma;
    final scale = height / anchor.analysisHeight;
    final radius = math.max(2, (4 * scale).round());
    final opened = _open(luma, width, height, radius);
    final closed = _close(luma, width, height, radius);

    final region = anchor.region;
    final left = region.left * width;
    final top = region.top * height;
    final regionWidth = (region.right - region.left) * width;
    final regionHeight = (region.bottom - region.top) * height;
    final bandTop = math.max(0, ((anchor.anchorY - 1) * scale).floor());
    final bandBottom =
        math.min(height, ((anchor.anchorY + 19) * scale).ceil());
    final nicknameRight =
        math.min(width, ((anchor.anchorX - 1) * scale).ceil());

    for (var y = 0; y < rows; y++) {
      final py = (top + (y + 0.5) * regionHeight / rows)
          .round()
          .clamp(0, height - 1);
      if (py < bandTop || py >= bandBottom) continue;
      for (var x = 0; x < columns; x++) {
        final px = (left + (x + 0.5) * regionWidth / columns)
            .round()
            .clamp(0, width - 1);
        if (px >= nicknameRight) continue;
        final index = py * width + px;
        final glow = luma[index] - opened[index];
        final shadow = closed[index] - luma[index];
        if (glow > 20 || shadow > 24) {
          votes[y * columns + x]++;
        }
      }
    }
  }

  /// Exact word mark cells at the detected anchor, already scaled into the
  /// region grid so scene edges can never enter the mask.
  static Uint8List _templateCells(
    BilibiliAnchor anchor,
    int columns,
    int rows,
  ) {
    final analysisWidth = anchor.analysisWidth;
    final analysisHeight = anchor.analysisHeight;
    final region = anchor.region;
    final spanX = region.right - region.left;
    final spanY = region.bottom - region.top;
    final cells = Uint8List(columns * rows);
    const template = bilibiliWatermarkTemplate;
    for (var ty = 0; ty < template.length; ty++) {
      final row = template[ty];
      for (var tx = 0; tx < row.length; tx++) {
        if (row[tx] != '#') continue;
        final nx = (anchor.anchorX + tx) / analysisWidth;
        final ny = (anchor.anchorY + ty) / analysisHeight;
        final fx = ((nx - region.left) / spanX * columns).floor();
        final fy = ((ny - region.top) / spanY * rows).floor();
        if (fx >= 0 && fy >= 0 && fx < columns && fy < rows) {
          cells[fy * columns + fx] = 1;
        }
      }
    }
    return cells;
  }

  static Uint8List _grow(Uint8List mask, int columns, int rows) {
    final result = Uint8List(mask.length);
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < columns; x++) {
        if (mask[y * columns + x] == 0) continue;
        for (var yy = math.max(0, y - 1); yy <= math.min(rows - 1, y + 1); yy++) {
          for (var xx = math.max(0, x - 1);
              xx <= math.min(columns - 1, x + 1);
              xx++) {
            result[yy * columns + xx] = 1;
          }
        }
      }
    }
    return result;
  }

  /// Separable gray-scale opening: removes bright structures smaller than the
  /// kernel, which is the background under a bright glyph.
  static Uint8List _open(Uint8List luma, int width, int height, int radius) {
    return _dilate2d(_erode2d(luma, width, height, radius), width, height,
        radius);
  }

  /// Closing removes the dark drop shadow, giving the other stroke polarity.
  static Uint8List _close(Uint8List luma, int width, int height, int radius) {
    return _erode2d(_dilate2d(luma, width, height, radius), width, height,
        radius);
  }

  static Uint8List _erode2d(
    Uint8List source,
    int width,
    int height,
    int radius,
  ) {
    final horizontal = Uint8List(source.length);
    for (var y = 0; y < height; y++) {
      final offset = y * width;
      for (var x = 0; x < width; x++) {
        var value = 255;
        final start = math.max(0, x - radius);
        final end = math.min(width - 1, x + radius);
        for (var xx = start; xx <= end; xx++) {
          final current = source[offset + xx];
          if (current < value) value = current;
        }
        horizontal[offset + x] = value;
      }
    }
    final result = Uint8List(source.length);
    for (var y = 0; y < height; y++) {
      final start = math.max(0, y - radius);
      final end = math.min(height - 1, y + radius);
      for (var x = 0; x < width; x++) {
        var value = 255;
        for (var yy = start; yy <= end; yy++) {
          final current = horizontal[yy * width + x];
          if (current < value) value = current;
        }
        result[y * width + x] = value;
      }
    }
    return result;
  }

  static Uint8List _dilate2d(
    Uint8List source,
    int width,
    int height,
    int radius,
  ) {
    final horizontal = Uint8List(source.length);
    for (var y = 0; y < height; y++) {
      final offset = y * width;
      for (var x = 0; x < width; x++) {
        var value = 0;
        final start = math.max(0, x - radius);
        final end = math.min(width - 1, x + radius);
        for (var xx = start; xx <= end; xx++) {
          final current = source[offset + xx];
          if (current > value) value = current;
        }
        horizontal[offset + x] = value;
      }
    }
    final result = Uint8List(source.length);
    for (var y = 0; y < height; y++) {
      final start = math.max(0, y - radius);
      final end = math.min(height - 1, y + radius);
      for (var x = 0; x < width; x++) {
        var value = 0;
        for (var yy = start; yy <= end; yy++) {
          final current = horizontal[yy * width + x];
          if (current > value) value = current;
        }
        result[y * width + x] = value;
      }
    }
    return result;
  }
}
