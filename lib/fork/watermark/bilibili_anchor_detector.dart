import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:PiliPlus/fork/watermark/watermark_detector.dart' show WatermarkFrame;
import 'package:PiliPlus/fork/watermark/watermark_region.dart';

/// Corner of a frame, used for both the standard bilibili watermark and the
/// generic temporal detector.
enum WatermarkCorner {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight;

  bool get isLeft => this == topLeft || this == bottomLeft;
  bool get isTop => this == topLeft || this == topRight;
}

/// Location of the `nickname + bilibili` creator watermark.
final class BilibiliAnchor {
  const BilibiliAnchor({
    required this.corner,
    required this.region,
    required this.score,
    required this.support,
    required this.frameCount,
    required this.anchorX,
    required this.anchorY,
    required this.analysisWidth,
    required this.analysisHeight,
  });

  final WatermarkCorner corner;
  final WatermarkRegion region;
  final double score;

  /// Number of analysed frames whose best candidate agreed with [corner].
  final int support;
  final int frameCount;

  /// Top-left of the word mark in the analysis space whose short side is 270.
  final int anchorX;
  final int anchorY;
  final int analysisWidth;
  final int analysisHeight;
}

/// Edge template of the standard bilibili word mark, measured on a 480x270
/// analysis frame. The mark is drawn at a constant size relative to the
/// frame's short side, so all geometry below is expressed in a space where
/// the short side is [_shortSide] pixels.
const bilibiliWatermarkTemplate = [
  '.###...............###...............',
  '#####........##...#####........##....',
  '#####.......####.######.......####...',
  '#####.......####..#####......#####...',
  '#####.....######.######.....######.#.',
  '#####....###########.##....#########.',
  '.####....##############....##########',
  '.####....##############....###.######',
  '.####.....####.#.#.####....##########',
  '.#######..###############..######.###',
  '.##.#########.###################.###',
  '.######################.########.####',
  '.###############################.####',
  '.################.#############.#####',
  '.###.################################',
  '..##########################.########',
  '..#######...#....#..#######...#...##.',
  '...###...............##..............',
];

/// Finds the standard `nickname + bilibili` creator watermark.
///
/// The mark is engraved by Bilibili at a fixed size and inset relative to the
/// *short* side of the encoded frame, so thick letterbox bars or a 4:3/vertical
/// frame do not move it. Every frame is therefore resampled to a space whose
/// short side is [_shortSide] pixels before matching.
///
/// A single frame is matched with a strict score. When several frames are
/// available the same candidate location must persist in at least half of
/// them, which is what separates a real watermark from a lucky content patch
/// on a busy or very bright background.
abstract final class BilibiliAnchorDetector {
  static const _shortSide = 270;
  static const _templateWidth = 37;
  static const _templateHeight = 18;

  /// Bilibili places the word mark in the top corners most of the time and in
  /// the bottom-right corner in a small minority of uploads. Bottom-left is
  /// rare and bottom corners are never used by vertical videos, so those
  /// corners must clearly beat an already viable candidate.
  static double _cornerPrior(WatermarkCorner corner, {required bool portrait}) {
    if (corner.isTop) return 0;
    // Vertical uploads never carry the creator mark in a bottom corner, and
    // landscape uploads put it there only in a small minority. Require those
    // corners to beat a viable top corner by a clear margin.
    return portrait ? -0.25 : -0.10;
  }

  /// Minimum score for a decision backed by one frame only.
  static const _singleFrameMinimum = 0.50;

  /// Minimum score when the same location was seen in several frames.
  static const _multiFrameMinimum = 0.44;

  static Future<BilibiliAnchor?> detectInFrames(
    List<WatermarkFrame> frames,
  ) {
    if (frames.isEmpty) return Future.value();
    return Isolate.run(() => detectInFramesSync(frames));
  }

  static BilibiliAnchor? detectInFramesSync(List<WatermarkFrame> frames) {
    final analyses = <_FrameAnalysis>[
      for (final frame in frames)
        if (frame.luma.length == frame.width * frame.height)
          _FrameAnalysis.prepare(frame),
    ];
    if (analyses.isEmpty) return null;

    final candidates = <_CornerCandidate>[
      for (final analysis in analyses) ..._frameCandidates(analysis),
    ];
    if (candidates.isEmpty) return null;

    final byCorner = <WatermarkCorner, List<_CornerCandidate>>{};
    for (final candidate in candidates) {
      if (candidate.score < 0.30) continue;
      byCorner.putIfAbsent(candidate.corner, () => []).add(candidate);
    }
    if (byCorner.isEmpty) return null;

    final portrait = analyses.first.width <= analyses.first.height;
    _CornerCandidate? best;
    var bestScore = double.negativeInfinity;
    for (final entry in byCorner.entries) {
      final group = entry.value;
      final anchor = entry.key;
      final x = _median([for (final item in group) item.x]);
      final y = _median([for (final item in group) item.y]);
      final agreeing = group
          .where((item) => (item.x - x).abs() <= 6 && (item.y - y).abs() <= 4)
          .toList();
      if (analyses.length > 1) {
        final required = math.max(2, (analyses.length * 0.5).ceil());
        if (agreeing.length < required) continue;
      }
      final score = _medianScore([for (final item in agreeing) item.score]);
      final rank = score + _cornerPrior(anchor, portrait: portrait);
      if (rank <= bestScore) continue;
      bestScore = rank;
      best = _CornerCandidate(
        anchor,
        x.round(),
        y.round(),
        rank,
        agreeing.length,
      );
    }
    if (best == null) return null;
    final minimum = analyses.length > 1
        ? _multiFrameMinimum
        : _singleFrameMinimum;
    if (bestScore < minimum) return null;

    final analysis = analyses.first;
    final region = _regionFor(analysis, best);
    return BilibiliAnchor(
      corner: best.corner,
      region: region,
      score: best.score,
      support: best.support,
      frameCount: analyses.length,
      anchorX: best.x,
      anchorY: best.y,
      analysisWidth: analysis.width,
      analysisHeight: analysis.height,
    );
  }

  static List<_CornerCandidate> _frameCandidates(_FrameAnalysis analysis) {
    final result = <_CornerCandidate>[];
    for (final corner in WatermarkCorner.values) {
      final candidate = _searchCorner(analysis, corner);
      if (candidate == null) continue;
      result.add(
        _CornerCandidate(corner, candidate.x, candidate.y, candidate.score, 1),
      );
    }
    return result;
  }

  /// The standard layout: 8 px inset from the frame border, the word mark last
  /// in the line so it always ends at the right margin, and at least two
  /// nickname characters before it on the left.
  static _PositionScore? _searchCorner(
    _FrameAnalysis analysis,
    WatermarkCorner corner,
  ) {
    final width = analysis.width;
    final height = analysis.height;
    final yStart = corner.isTop ? 5 : height - 28;
    final yEnd = corner.isTop ? 11 : height - 21;
    final int xStart;
    final int xEnd;
    if (corner.isLeft) {
      xStart = 24;
      xEnd = math.min(
        width - 40,
        math.max(136, (width * 0.34).round()),
      );
    } else {
      xStart = math.max(0, width - 53);
      xEnd = width - 40;
    }
    if (yStart < 0 || yEnd + _templateHeight > height || xEnd <= xStart) {
      return null;
    }

    final gradient = analysis.gradient;
    final luma = analysis.luma;
    final template = _template;
    final centered = _templateCentered;
    final templateCount = _templateCount;
    final backgroundCount = _backgroundCount;
    final centeredNorm = _templateCenteredNorm;
    var bestScore = double.negativeInfinity;
    var bestX = 0;
    var bestY = 0;

    for (var y = yStart; y <= yEnd; y++) {
      for (var x = xStart; x <= xEnd; x++) {
        var edges8 = 0;
        var edges4 = 0;
        var edges2 = 0;
        var edges1 = 0;
        var background8 = 0;
        var background4 = 0;
        var background2 = 0;
        var background1 = 0;
        var sum = 0.0;
        var squareSum = 0.0;
        var dot = 0.0;
        for (var ty = 0; ty < _templateHeight; ty++) {
          final offset = (y + ty) * width + x;
          final templateOffset = ty * _templateWidth;
          for (var tx = 0; tx < _templateWidth; tx++) {
            final value = luma[offset + tx];
            sum += value;
            squareSum += value * value;
            dot += value * centered[templateOffset + tx];
            final level = gradient[offset + tx];
            if (template[templateOffset + tx] != 0) {
              if (level >= 8) edges8++;
              if (level >= 4) edges4++;
              if (level >= 2) edges2++;
              if (level >= 1) edges1++;
            } else {
              if (level >= 8) background8++;
              if (level >= 4) background4++;
              if (level >= 2) background2++;
              if (level >= 1) background1++;
            }
          }
        }
        const samples = _templateWidth * _templateHeight;
        var net = edges8 / templateCount - background8 / backgroundCount * 0.75;
        final net4 =
            edges4 / templateCount - background4 / backgroundCount * 0.75;
        final net2 =
            edges2 / templateCount - background2 / backgroundCount * 0.75;
        final net1 =
            edges1 / templateCount - background1 / backgroundCount * 0.75;
        if (net4 > net) net = net4;
        if (net2 > net) net = net2;
        if (net1 > net) net = net1;
        final variance = squareSum - sum * sum / samples;
        final correlation = variance <= 1
            ? 0.0
            : math.max(
                0.0,
                dot / (math.sqrt(variance) * centeredNorm),
              );
        final score = net + 0.65 * correlation;
        if (score > bestScore) {
          bestScore = score;
          bestX = x;
          bestY = y;
        }
      }
    }
    return _PositionScore(bestX, bestY, bestScore);
  }

  static WatermarkRegion _regionFor(
    _FrameAnalysis analysis,
    _CornerCandidate anchor,
  ) {
    final width = analysis.width;
    final height = analysis.height;
    final left = anchor.corner.isLeft
        ? math.min(anchor.x.toDouble(), 7)
        : _nicknameStart(analysis, anchor.x, anchor.y);
    final top = math.max(1, anchor.y - 4);
    final right = math.min(width, anchor.x + _templateWidth + 4);
    final bottom = math.min(height - 1, anchor.y + _templateHeight + 4);
    final paddingX = math.max(4, (width * 0.015).round());
    final paddingY = math.max(3, (height * 0.015).round());
    return WatermarkRegion(
      left: math.max(0, left - paddingX) / width,
      top: math.max(0, top - paddingY) / height,
      right: math.min(width, right + paddingX) / width,
      bottom: math.min(height, bottom + paddingY) / height,
      confidence: anchor.score.clamp(0.0, 1.0),
    );
  }

  /// The standard layout puts the word mark after the nickname, so the region
  /// must extend left over text of varying width. Text rows are separated from
  /// the background rows just above and below the mark, which keeps a textured
  /// or bright background from extending the region across the frame.
  static double _nicknameStart(_FrameAnalysis analysis, int ax, int ay) {
    final width = analysis.width;
    final height = analysis.height;
    final right = math.min(width, ax + _templateWidth + 4);
    final textTop = math.max(1, ay);
    final textBottom = math.min(height - 2, ay + _templateHeight - 1);
    final textRows = textBottom - textTop + 1;

    final anchorEdges = <double>[];
    final gradient = analysis.gradient;
    for (var ty = 0; ty < _templateHeight; ty++) {
      for (var tx = 0; tx < _templateWidth; tx++) {
        if (_template[ty * _templateWidth + tx] == 0) continue;
        anchorEdges.add(gradient[(ay + ty) * width + ax + tx]);
      }
    }
    anchorEdges.sort();
    final threshold = (anchorEdges[anchorEdges.length ~/ 2] * 0.30).clamp(
      1.5,
      8.0,
    );

    final backgroundRows = <int>[
      for (var y = math.max(1, ay - 8);
          y <= math.min(height - 2, ay + _templateHeight + 8);
          y++)
        if (y < ay - 1 || y > ay + _templateHeight) y,
    ];

    final limit = math.max(0, right - (width * 0.44).round());
    var left = ax;
    var blankRun = 0;
    var stopped = false;
    for (var x = ax - 1; x >= limit; x--) {
      var textEdges = 0;
      for (var y = textTop; y <= textBottom; y++) {
        if (gradient[y * width + x] >= threshold) textEdges++;
      }
      var backgroundEdges = 0;
      for (final y in backgroundRows) {
        if (gradient[y * width + x] >= threshold) backgroundEdges++;
      }
      final text = textEdges / textRows;
      final background = backgroundRows.isEmpty
          ? 0.0
          : backgroundEdges / backgroundRows.length;
      if (text >= 0.18 && text - background >= 0.06) {
        left = x;
        blankRun = 0;
      } else {
        blankRun++;
        if (blankRun >= 8) {
          stopped = true;
          break;
        }
      }
    }
    if (!stopped || ax - left < 24) {
      left = math.max(limit, math.min(left, ax - 56));
    }
    return left.toDouble();
  }

  static int _median(List<int> values) {
    final sorted = [...values]..sort();
    return sorted[sorted.length ~/ 2];
  }

  static double _medianScore(List<double> values) {
    final sorted = [...values]..sort();
    return sorted[sorted.length ~/ 2];
  }

  static final Uint8List _template = Uint8List.fromList([
    for (final row in bilibiliWatermarkTemplate)
      for (final char in row.codeUnits) char == 35 ? 1 : 0,
  ]);

  static final Float32List _templateCentered = () {
    final mean =
        _template.fold<int>(0, (sum, value) => sum + value) / _template.length;
    return Float32List.fromList([
      for (final value in _template) value - mean,
    ]);
  }();

  static final int _templateCount =
      _template.fold<int>(0, (sum, value) => sum + value);

  static final int _backgroundCount = _template.length - _templateCount;

  static final double _templateCenteredNorm = math.sqrt(
    _templateCentered.fold<double>(0, (sum, value) => sum + value * value),
  );
}

/// Alias used by [_median] over candidate scores.

final class _FrameAnalysis {
  const _FrameAnalysis(this.luma, this.gradient, this.width, this.height);

  factory _FrameAnalysis.prepare(WatermarkFrame frame) {
    final int width;
    final int height;
    if (frame.width <= frame.height) {
      width = BilibiliAnchorDetector._shortSide;
      height = math.max(
        width,
        (frame.height * width / frame.width).round(),
      );
    } else {
      height = BilibiliAnchorDetector._shortSide;
      width = math.max(height, (frame.width * height / frame.height).round());
    }
    final luma = frame.width == width && frame.height == height
        ? Float32List.fromList([
            for (final value in frame.luma) value.toDouble(),
          ])
        : _resample(frame, width, height);
    return _FrameAnalysis(luma, _gradient(luma, width, height), width, height);
  }

  final Float32List luma;
  final Float32List gradient;
  final int width;
  final int height;

  static Float32List _resample(WatermarkFrame frame, int width, int height) {
    final source = frame.luma;
    final sourceWidth = frame.width;
    final sourceHeight = frame.height;
    final scaleX = sourceWidth / width;
    final scaleY = sourceHeight / height;
    final result = Float32List(width * height);
    for (var y = 0; y < height; y++) {
      final sourceY = ((y + 0.5) * scaleY - 0.5).clamp(0.0, sourceHeight - 1.0);
      final y0 = sourceY.floor();
      final y1 = math.min(sourceHeight - 1, y0 + 1);
      final fy = sourceY - y0;
      for (var x = 0; x < width; x++) {
        final sourceX = ((x + 0.5) * scaleX - 0.5).clamp(
          0.0,
          sourceWidth - 1.0,
        );
        final x0 = sourceX.floor();
        final x1 = math.min(sourceWidth - 1, x0 + 1);
        final fx = sourceX - x0;
        final top =
            source[y0 * sourceWidth + x0] * (1 - fx) +
            source[y0 * sourceWidth + x1] * fx;
        final bottom =
            source[y1 * sourceWidth + x0] * (1 - fx) +
            source[y1 * sourceWidth + x1] * fx;
        result[y * width + x] = top * (1 - fy) + bottom * fy;
      }
    }
    return result;
  }

  static Float32List _gradient(
    Float32List luma,
    int width,
    int height,
  ) {
    final result = Float32List(luma.length);
    for (var y = 1; y < height - 1; y++) {
      for (var x = 1; x < width - 1; x++) {
        final index = y * width + x;
        result[index] =
            ((luma[index + 1] - luma[index - 1]).abs() +
                (luma[index + width] - luma[index - width]).abs()) *
            0.5;
      }
    }
    return result;
  }
}

final class _CornerCandidate {
  const _CornerCandidate(this.corner, this.x, this.y, this.score, this.support);

  final WatermarkCorner corner;
  final int x;
  final int y;
  final double score;
  final int support;
}

final class _PositionScore {
  const _PositionScore(this.x, this.y, this.score);

  final int x;
  final int y;
  final double score;
}
