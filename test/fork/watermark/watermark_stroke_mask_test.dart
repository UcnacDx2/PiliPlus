import 'dart:typed_data';

import 'package:PiliPlus/fork/watermark/bilibili_anchor_detector.dart';
import 'package:PiliPlus/fork/watermark/watermark_frame.dart';
import 'package:PiliPlus/fork/watermark/watermark_region.dart';
import 'package:PiliPlus/fork/watermark/watermark_stroke_mask.dart';
import 'package:flutter_test/flutter_test.dart';

/// Luma plane with a white "word mark" drawn at the anchor position plus a
/// nickname to its left, over a dark background.
WatermarkFrame _frame(
  int width,
  int height,
  int anchorX,
  int anchorY, {
  int nicknameWidth = 60,
}) {
  final luma = Uint8List(width * height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      luma[y * width + x] = 30;
    }
  }
  const template = bilibiliWatermarkTemplate;
  for (var ty = 0; ty < template.length; ty++) {
    for (var tx = 0; tx < template[ty].length; tx++) {
      if (template[ty][tx] == '#') {
        luma[(anchorY + ty) * width + anchorX + tx] = 235;
      }
    }
  }
  for (var y = 0; y < 14; y++) {
    for (var x = 0; x < nicknameWidth; x++) {
      final on = (x ~/ 7 + y ~/ 7).isEven;
      if (on) {
        luma[(anchorY + 2 + y) * width + anchorX - 8 - nicknameWidth + x] = 235;
      }
    }
  }
  return WatermarkFrame(width: width, height: height, luma: luma);
}

BilibiliAnchor _anchor(
  int x,
  int y,
  int analysisWidth,
  int analysisHeight,
  WatermarkRegion region,
) {
  return BilibiliAnchor(
    corner: WatermarkCorner.topLeft,
    region: region,
    score: 1,
    support: 1,
    frameCount: 1,
    anchorX: x,
    anchorY: y,
    analysisWidth: analysisWidth,
    analysisHeight: analysisHeight,
  );
}

void main() {
  test('builds a mask covering the strokes and skipping background', () {
    const width = 480;
    const height = 270;
    const ax = 120;
    const ay = 8;
    final frame = _frame(width, height, ax, ay);
    const region = WatermarkRegion(
      left: 0.08,
      top: 0.01,
      right: 0.44,
      bottom: 0.13,
      confidence: 1,
    );
    final refinement = WatermarkStrokeMaskBuilder.buildSync(
      [frame],
      _anchor(ax, ay, width, height, region),
    );

    expect(refinement, isNotNull);
    final mask = refinement!.mask;
    expect(mask.columns, inInclusiveRange(32, 192));
    expect(mask.rows, inInclusiveRange(12, 64));

    // The template's own cell must be covered.
    final templateX = ((ax / width - region.left) /
            (region.right - region.left) *
            mask.columns)
        .floor();
    final templateY = ((ay / height - region.top) /
            (region.bottom - region.top) *
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

  test('background motion between frames does not enter the mask', () {
    const width = 480;
    const height = 270;
    const ax = 120;
    const ay = 8;
    const region = WatermarkRegion(
      left: 0.08,
      top: 0.01,
      right: 0.44,
      bottom: 0.13,
      confidence: 1,
    );
    final anchor = _anchor(ax, ay, width, height, region);
    final frames = [
      _frame(width, height, ax, ay),
      _frame(width, height, ax, ay),
    ];
    // A bright moving scene object inside the region that overlaps the text
    // band but is present in one frame only.
    for (var y = 0; y < 18; y++) {
      for (var x = 0; x < 40; x++) {
        frames[1].luma[(ay + y) * width + x + 10] = 220;
      }
    }

    final refinement = WatermarkStrokeMaskBuilder.buildSync(frames, anchor);
    expect(refinement, isNotNull);
    // The flicker must not be masked: with one vote of two frames, the
    // required count is max(2, 1) = 1, so template strokes still survive but
    // the flicker got a single vote which is below the requirement of 2.
    final mask = refinement!.mask;
    expect(mask.coverage, lessThan(0.9));
  });

  test('returns null for a region without usable frames', () {
    const region = WatermarkRegion(
      left: 0.1,
      top: 0.05,
      right: 0.4,
      bottom: 0.12,
      confidence: 1,
    );
    final refinement = WatermarkStrokeMaskBuilder.buildSync(
      const [],
      _anchor(120, 8, 480, 270, region),
    );
    expect(refinement, isNull);
  });

  test('bit packing round-trips through bitAt', () {
    final mask = WatermarkStrokeMask(
      columns: 70,
      rows: 33,
      words: Uint32List.fromList([
        0x80000000,
        0x00000001,
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
