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
    final word = index >> 5;
    if (word >= words.length) return false;
    return (words[word] >> (index & 31)) & 1 == 1;
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
  /// `min(r, g, b)` floor for a watermark stroke. The creator mark is white,
  /// so on a coloured background (grass, foliage, stage lights) its whiteness
  /// stays far above this while the scene's does not. A 480 px thumbnail
  /// cannot separate the mark from a bright background at all; the mask is
  /// built from the 1280 px first frame instead, where the glyph cores keep a
  /// whiteness above this floor while even pale foliage stays below it.
  ///
  /// A semi-transparent nickname over a warm background mixes down to about
  /// 160-170, which a 170 floor rejects outright (BV1DH4h6kEfn kept every
  /// glyph), so the floor sits below that while a bright patch of scene colour
  /// still stays far underneath it.
  static const _whiteGate = 150;

  /// Minimum lit neighbours (3x3, self included) for a stroke cell. A real
  /// glyph stroke is connected; isolated specular dots are not.
  static const _density = 3;

  /// Saturated-white test for the mark's ink: the watermark is drawn pure
  /// white, so its core sits at the very top of both the luma and the
  /// whiteness range even when the scene behind it is bright.
  static const _pureLuma = 185;
  static const _pureWhite = 185;

  /// Height of the nickname band below the mark's top edge, in analysis units.
  /// The nickname sits lower than the logo and its glyphs can reach further
  /// down, so the band follows the nickname rather than the template.
  static const _bandHeight = 28;

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
    // The first-frame thumbnail is the only input that reliably carries the
    // creator watermark: sprite cells are downscaled crops, and some sprite
    // timestamps do not show the mark at all, so they must never veto the
    // nickname. A white-text gate keeps coloured scene edges (grass, foliage)
    // and a neighbourhood filter keeps isolated bright dots out of the mask.
    _voteFrame(
      votes,
      columns,
      rows,
      samples.first,
      anchor,
      _bandGlowGate(samples.first, anchor),
      24,
      _whiteGate,
    );

    final pureWhite = _pureWhiteCells(samples.first, anchor, columns, rows);
    final mask = Uint8List(columns * rows);
    final template = _templateCells(anchor, columns, rows);
    for (var index = 0; index < mask.length; index++) {
      if (template[index] != 0) {
        mask[index] = 1;
        continue;
      }
      // A saturated white pixel inside the mark's band is the mark's core. It
      // has to be masked even when it carries no gradient (it sits inside a
      // bright area, so opening leaves it) and even when it stands alone (a
      // thin stroke fragment) — otherwise it stays as a bright dot in the
      // filled band, which is far more visible than the smear.
      if (pureWhite[index] != 0) {
        mask[index] = 1;
        continue;
      }
      if (votes[index] == 0) continue;
      final x = index % columns;
      final y = index ~/ columns;
      if (_neighbours(votes, columns, rows, x, y) < _density) continue;
      mask[index] = 1;
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

  /// Cells in the nickname band that are mostly saturated white, regardless
  /// of any edge. Gradient voting alone drops two kinds of real ink: a stroke
  /// pixel inside a bright patch (no local contrast left) and a lone thin
  /// fragment (rejected by the density filter). Both stay behind as bright
  /// dots in the filled band, which the eye picks up immediately.
  static Uint8List _pureWhiteCells(
    WatermarkFrame frame,
    BilibiliAnchor anchor,
    int columns,
    int rows,
  ) {
    final cells = Uint8List(columns * rows);
    if (frame.whiteness == null) return cells;
    final width = frame.width;
    final height = frame.height;
    final scale = height / anchor.analysisHeight;
    final region = anchor.region;
    final left = region.left * width;
    final top = region.top * height;
    final regionWidth = (region.right - region.left) * width;
    final regionHeight = (region.bottom - region.top) * height;
    final bandTop = math.max(0, ((anchor.anchorY - 1) * scale).floor());
    final bandBottom =
        math.min(height, ((anchor.anchorY + _bandHeight) * scale).ceil());
    final nicknameRight =
        math.min(width, ((anchor.anchorX - 1) * scale).ceil());
    for (var y = 0; y < rows; y++) {
      final y0 = (top + y * regionHeight / rows).floor();
      final y1 = (top + (y + 1) * regionHeight / rows).ceil();
      if (y1 <= bandTop || y0 >= bandBottom) continue;
      final sy0 = y0.clamp(0, height - 1);
      final sy1 = math.min(y1, bandBottom).clamp(sy0 + 1, height);
      for (var x = 0; x < columns; x++) {
        final x0 = (left + x * regionWidth / columns).floor();
        final x1 = (left + (x + 1) * regionWidth / columns).ceil();
        if (x0 >= nicknameRight) continue;
        final sx0 = x0.clamp(0, width - 1);
        final sx1 = math.min(x1, nicknameRight).clamp(sx0 + 1, width);
        var pure = 0;
        var dark = 0;
        var total = 0;
        for (var py = sy0; py < sy1; py++) {
          final rowOffset = py * width;
          for (var px = sx0; px < sx1; px++) {
            total++;
            final index = rowOffset + px;
            final value = frame.luma[index];
            if (value >= _pureLuma && frame.whitenessAt(index) >= _pureWhite) {
              pure++;
            } else if (value + 20 <= _pureLuma) {
              dark++;
            }
          }
        }
        if (total == 0) continue;
        // Ink on a dark band: the cell is mostly background, yet its stroke
        // pixels are at full white — that contrast survives voting as a bright
        // speck, so the cell is masked as soon as it carries a couple of them.
        final inkOnDark = pure >= 2 && dark * 2 >= total;
        if (inkOnDark || pure * 4 >= total) cells[y * columns + x] = 1;
      }
    }
    return cells;
  }

  /// Counts lit cells in the 3x3 neighbourhood of ([x], [y]).
  static int _neighbours(
    Uint8List votes,
    int columns,
    int rows,
    int x,
    int y,
  ) {
    var count = 0;
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= columns || ny >= rows) continue;
        if (votes[ny * columns + nx] != 0) count++;
      }
    }
    return count;
  }

  /// Glow gate for the mark's band, chosen from how white the band already is.
  ///
  /// A band that is almost entirely white (a wall, a bright sky, a white
  /// curtain) cannot be told apart by whiteness at all, and filling it flat
  /// leaves no visible trace, so weak glyph edges are accepted there. On a
  /// textured band the gate must stay strict or the fill smears the scene.
  static int _bandGlowGate(WatermarkFrame frame, BilibiliAnchor anchor) {
    // Without a colour plane nothing is known about the band; stay strict.
    if (frame.whiteness == null) return 20;
    final width = frame.width;
    final height = frame.height;
    final scale = height / anchor.analysisHeight;
    final region = anchor.region;
    final x0 = (region.left * width).floor().clamp(0, width - 1);
    final x1 = math
        .min(((anchor.anchorX - 1) * scale).ceil(), width)
        .clamp(x0 + 1, width);
    final y0 = math.max(0, ((anchor.anchorY - 1) * scale).floor());
    final y1 = math
        .min(height, ((anchor.anchorY + _bandHeight) * scale).ceil())
        .clamp(y0 + 1, height);
    var total = 0;
    var white = 0;
    for (var y = y0; y < y1; y++) {
      final row = y * width;
      for (var x = x0; x < x1; x++) {
        total++;
        if (frame.whitenessAt(row + x) >= _whiteGate) white++;
      }
    }
    if (total == 0) return 20;
    return white * 10 >= total * 8 ? 8 : 20;
  }

  /// Adds one frame's vote to every grid cell whose centre looks like a glyph
  /// stroke: brighter than the local opening or darker than the local closing.
  /// Exposed for diagnostics and tests; [columns] and [rows] must match the
  /// grid the caller expects.
  static void vote(
    Uint8List votes,
    BilibiliAnchor anchor,
    WatermarkFrame frame,
    {
      int columns = 96,
      int rows = 32,
      int glowGate = 20,
      int shadowGate = 24,
      int whiteGate = 0,
    }
  ) {
    _voteFrame(
      votes, columns, rows, frame, anchor, glowGate, shadowGate, whiteGate,
    );
  }

  static void _voteFrame(
    Uint8List votes,
    int columns,
    int rows,
    WatermarkFrame frame,
    BilibiliAnchor anchor,
    int glowGate,
    int shadowGate,
    int whiteGate,
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
        math.min(height, ((anchor.anchorY + _bandHeight) * scale).ceil());
    // The logo half of the mark is known exactly and is filled from the
    // template; the nickname is text of unknown width, so only its zone is
    // voted.
    final nicknameRight =
        math.min(width, ((anchor.anchorX - 1) * scale).ceil());

    for (var y = 0; y < rows; y++) {
      final y0 = (top + y * regionHeight / rows).floor();
      final y1 = (top + (y + 1) * regionHeight / rows).ceil();
      if (y1 <= bandTop || y0 >= bandBottom) continue;
      final sy0 = y0.clamp(0, height - 1);
      final sy1 = math.min(y1, bandBottom).clamp(sy0 + 1, height);
      for (var x = 0; x < columns; x++) {
        final x0 = (left + x * regionWidth / columns).floor();
        final x1 = (left + (x + 1) * regionWidth / columns).ceil();
        if (x0 >= nicknameRight) continue;
        final sx0 = x0.clamp(0, width - 1);
        final sx1 = math.min(x1, nicknameRight).clamp(sx0 + 1, width);
        // A cell is a box of pixels, not one sample: at 1280 px the glyph
        // strokes are 2-3 px wide and a centre sample drops whole characters
        // ("ArYu" stayed legible while the bold "令宇" was covered). A cell
        // votes when at least a quarter of its pixels look like a stroke.
        var hits = 0;
        var total = 0;
        for (var py = sy0; py < sy1; py++) {
          final rowOffset = py * width;
          for (var px = sx0; px < sx1; px++) {
            total++;
            final index = rowOffset + px;
            final glow = luma[index] - opened[index];
            final shadow = closed[index] - luma[index];
            if (glow <= glowGate && shadow <= shadowGate) continue;
            // The mark is white: a bright green edge has a strong luma
            // gradient but a low whiteness and must stay out of the mask.
            if (whiteGate > 0 && frame.whitenessAt(index) < whiteGate) {
              continue;
            }
            hits++;
          }
        }
        if (total == 0 || hits * 4 < total) continue;
        votes[y * columns + x]++;
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
