import 'dart:typed_data';

import 'package:PiliPlus/fork/watermark/bilibili_anchor_detector.dart';
import 'package:PiliPlus/fork/watermark/watermark_frame.dart';
import 'package:PiliPlus/fork/watermark/watermark_region.dart';
import 'package:PiliPlus/fork/watermark/watermark_stroke_mask.dart';
import 'package:flutter_test/flutter_test.dart';

const _region = WatermarkRegion(
  left: 0.08,
  top: 0.01,
  right: 0.44,
  bottom: 0.13,
  confidence: 1,
);

/// Luma plane with a white "word mark" drawn at the anchor position plus a
/// nickname to its left, over a dark background.
///
/// [whiteness] mirrors [luma] (the mark is drawn white) so the white-text gate
/// behaves as it does on a real frame; `null` keeps the frame colourless, which
/// the builder treats as fully white.
WatermarkFrame _frame(
  int width,
  int height,
  int anchorX,
  int anchorY, {
  int nicknameWidth = 60,
  bool withWhiteness = true,
}) {
  final luma = Uint8List(width * height);
  final whiteness = withWhiteness ? Uint8List(width * height) : null;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      luma[y * width + x] = 30;
      if (whiteness != null) whiteness[y * width + x] = 24;
    }
  }
  void paint(int x, int y) {
    luma[y * width + x] = 235;
    if (whiteness != null) whiteness[y * width + x] = 232;
  }

  const template = bilibiliWatermarkTemplate;
  for (var ty = 0; ty < template.length; ty++) {
    for (var tx = 0; tx < template[ty].length; tx++) {
      if (template[ty][tx] == '#') {
        paint(anchorX + tx, anchorY + ty);
      }
    }
  }
  for (var y = 0; y < 14; y++) {
    for (var x = 0; x < nicknameWidth; x++) {
      final on = (x ~/ 7 + y ~/ 7).isEven;
      if (on) {
        paint(anchorX - 8 - nicknameWidth + x, anchorY + 2 + y);
      }
    }
  }
  return WatermarkFrame(
    width: width,
    height: height,
    luma: luma,
    whiteness: whiteness,
  );
}

BilibiliAnchor _anchor(
  int x,
  int y,
  int analysisWidth,
  int analysisHeight,
) {
  return BilibiliAnchor(
    corner: WatermarkCorner.topLeft,
    region: _region,
    score: 1,
    support: 1,
    frameCount: 1,
    anchorX: x,
    anchorY: y,
    analysisWidth: analysisWidth,
    analysisHeight: analysisHeight,
  );
}

/// Grid cell holding frame pixel ([px], [py]).
(int, int) _cell(int px, int py, int columns, int rows) => (
      ((px - _region.left * 1280) /
                  (_region.right - _region.left) /
                  1280 *
                  columns)
              .floor()
              .clamp(0, columns - 1),
      ((py / 720 - _region.top) / (_region.bottom - _region.top) * rows)
          .floor()
          .clamp(0, rows - 1),
    );

void main() {
  test('builds a mask covering the strokes and skipping background', () {
    const width = 480;
    const height = 270;
    const ax = 120;
    const ay = 8;
    final frame = _frame(width, height, ax, ay);
    final refinement = WatermarkStrokeMaskBuilder.buildSync(
      [frame],
      _anchor(ax, ay, width, height),
    );

    expect(refinement, isNotNull);
    final mask = refinement!.mask;
    expect(mask.columns, inInclusiveRange(32, 192));
    expect(mask.rows, inInclusiveRange(12, 64));

    // The template's own cell must be covered.
    final templateX =
        ((ax / width - _region.left) / (_region.right - _region.left) *
                mask.columns)
            .floor();
    final templateY =
        ((ay / height - _region.top) / (_region.bottom - _region.top) *
                mask.rows)
            .floor();
    expect(mask.bitAt(templateX, templateY), isTrue);

    // Far corners of the region are plain background.
    expect(mask.bitAt(0, 0), isFalse);
    expect(mask.bitAt(mask.columns - 1, 0), isFalse);

    // Coverage stays a fraction of the whole region.
    expect(mask.coverage, lessThan(0.9));
    expect(mask.coverage, greaterThan(0.02));
  });

  test('coloured background glow stays out of the mask', () {
    // At 1280 px the glyph strokes are only a few pixels wide, so cells are
    // wider than one pixel and the vote aggregates a cell's pixels.
    const width = 1280;
    const height = 720;
    const ax = 120;
    const ay = 20;
    // No synthetic nickname: two patches sit side by side in the nickname
    // zone, one white (letters) and one saturated green (foliage).
    final base = _frame(width, height, ax, ay, nicknameWidth: 0);
    final luma = Uint8List.fromList(base.luma);
    final whiteness = Uint8List.fromList(base.whiteness!);

    void patch(int x0, int x1, int y0, int y1, int l, int w) {
      for (var y = y0; y < y1; y++) {
        for (var x = x0; x < x1; x++) {
          luma[y * width + x] = l;
          whiteness[y * width + x] = w;
        }
      }
    }

    // Bars narrower than the opening kernel's 2 * 11 px, so they register as a
    // glow like a glyph stroke does; only whiteness can tell them apart.
    patch(140, 148, 58, 82, 235, 232); // white letters
    patch(220, 228, 58, 82, 225, 40); // green foliage: bright, not white
    final frame = WatermarkFrame(
      width: width,
      height: height,
      luma: luma,
      whiteness: whiteness,
    );

    final anchor = _anchor(ax, ay, 480, 270);
    final refinement = WatermarkStrokeMaskBuilder.buildSync([frame], anchor);
    expect(refinement, isNotNull);
    final mask = refinement!.mask;

    int maskedInside(int x0, int x1, int y0, int y1) {
      var count = 0;
      for (var y = y0; y < y1; y++) {
        for (var x = x0; x < x1; x++) {
          final (cx, cy) = _cell(x, y, mask.columns, mask.rows);
          if (mask.bitAt(cx, cy)) count++;
        }
      }
      return count;
    }

    expect(maskedInside(140, 148, 60, 80), greaterThan(0));
    expect(maskedInside(220, 228, 60, 80), 0);
  });

  test('a two pixel stroke between cell centres is still voted in', () {
    const width = 1280;
    const height = 720;
    const ax = 300;
    const ay = 20;
    final base = _frame(width, height, ax, ay, nicknameWidth: 0);
    final luma = Uint8List.fromList(base.luma);
    final whiteness = Uint8List.fromList(base.whiteness!);
    // A single 2 px wide white stroke, narrower than one grid cell.
    const strokeX = 190;
    for (var y = 58; y < 82; y++) {
      for (var x = strokeX; x < strokeX + 2; x++) {
        luma[y * width + x] = 240;
        whiteness[y * width + x] = 236;
      }
    }
    final frame = WatermarkFrame(
      width: width,
      height: height,
      luma: luma,
      whiteness: whiteness,
    );

    const columns = 172;
    const rows = 32;
    final votes = Uint8List(columns * rows);
    WatermarkStrokeMaskBuilder.vote(
      votes,
      _anchor(ax, ay, 480, 270),
      frame,
      columns: columns,
      rows: rows,
      glowGate: 20,
      shadowGate: 24,
      whiteGate: 170,
    );
    final (cx, cy) = _cell(strokeX, 70, columns, rows);
    expect(votes[cy * columns + cx], greaterThan(0));
  });

  test('a lone ink fragment on a dark band is masked without a vote', () {
    const width = 1280;
    const height = 720;
    const ax = 120;
    const ay = 20;
    final base = _frame(width, height, ax, ay, nicknameWidth: 0);
    final luma = Uint8List.fromList(base.luma);
    final whiteness = Uint8List.fromList(base.whiteness!);
    // Two saturated white pixels: a thin stroke fragment standing alone. The
    // density filter drops it, so only the ink test keeps it from surviving as
    // a bright dot inside the filled band.
    const fx = 190;
    const fy = 70;
    for (var x = fx; x < fx + 2; x++) {
      luma[fy * width + x] = 236;
      whiteness[fy * width + x] = 233;
    }
    final frame = WatermarkFrame(
      width: width,
      height: height,
      luma: luma,
      whiteness: whiteness,
    );

    final refinement = WatermarkStrokeMaskBuilder.buildSync(
      [frame],
      _anchor(ax, ay, 480, 270),
    );
    expect(refinement, isNotNull);
    final mask = refinement!.mask;
    final (cx, cy) = _cell(fx, fy, mask.columns, mask.rows);
    expect(mask.bitAt(cx, cy), isTrue);
  });

  test('returns null for a region without usable frames', () {
    final refinement = WatermarkStrokeMaskBuilder.buildSync(
      const [],
      _anchor(120, 8, 480, 270),
    );
    expect(refinement, isNull);
  });

  test('bit packing round-trips through bitAt', () {
    final mask = WatermarkStrokeMask(
      columns: 70,
      rows: 33,
      words: Uint32List.fromList([
        0x80000000,
        0x00000002,
        0xFFFFFFFF,
        0x12345678,
      ]),
    );
    expect(mask.bitAt(31, 0), isTrue); // last bit of word 0
    expect(mask.bitAt(0, 0), isFalse);
    expect(mask.bitAt(32, 0), isFalse); // first bit of word 1
    expect(mask.bitAt(33, 0), isTrue); // second bit of word 1
    expect(mask.bitAt(31, 1), isTrue); // inside word 2
    expect(mask.bitAt(69, 32), isFalse); // outside
  });
}
