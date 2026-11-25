import 'dart:typed_data';

import 'package:PiliPlus/fork/watermark/watermark_mode.dart';
import 'package:PiliPlus/fork/watermark/watermark_region.dart';
import 'package:PiliPlus/fork/watermark/watermark_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('watermark mode migrates persisted indexes from the old enum', () {
    expect(WatermarkMode.fromStoredIndex(null), WatermarkMode.disabled);
    expect(WatermarkMode.fromStoredIndex(0), WatermarkMode.disabled);
    // Old "bilibili", "advanced" and "bilibiliAuto" all map to stroke.
    expect(WatermarkMode.fromStoredIndex(1), WatermarkMode.stroke);
    expect(WatermarkMode.fromStoredIndex(2), WatermarkMode.stroke);
    expect(WatermarkMode.fromStoredIndex(3), WatermarkMode.stroke);
    expect(WatermarkMode.fromStoredIndex(4), WatermarkMode.box);
    expect(
      WatermarkMode.selectableValues,
      [WatermarkMode.disabled, WatermarkMode.stroke, WatermarkMode.box],
    );
  });

  test('single first frame anchors a clear bilibili mark', () async {
    const width = 480;
    const height = 270;
    final pixels = Uint8List(width * height)..fillRange(0, width * height, 96);
    _drawLogo(pixels, width, 383, 8, 428, 26);
    _drawBilibiliTemplate(pixels, width, 435, 8);

    final region = await WatermarkDetector.detectBilibiliAnchor(
      WatermarkFrame(width: width, height: height, luma: pixels),
    );

    expect(region, isNotNull);
    expect(region!.left, closeTo(379 / width, 0.03));
    expect(region.top, lessThan(0.1));
    expect(region.right, greaterThan(0.95));
    expect(region.right - region.left, lessThan(0.28));
  });

  test('single first frame rejects ambiguous texture in every corner', () async {
    const width = 480;
    const height = 270;
    final pixels = Uint8List(width * height);
    for (var index = 0; index < pixels.length; index++) {
      pixels[index] = (index * 37 + (index ~/ width) * 17) & 255;
    }

    final region = await WatermarkDetector.detectBilibiliAnchor(
      WatermarkFrame(width: width, height: height, luma: pixels),
    );

    expect(region, isNull);
  });

  test('independent detectors merge substantially overlapping regions', () {
    final regions = WatermarkDetector.mergeRegions(const [
      WatermarkRegion(
        left: 0.01,
        top: 0.01,
        right: 0.45,
        bottom: 0.12,
        confidence: 0.9,
      ),
      WatermarkRegion(
        left: 0.03,
        top: 0.02,
        right: 0.2,
        bottom: 0.1,
        confidence: 0.8,
      ),
      WatermarkRegion(
        left: 0.75,
        top: 0.02,
        right: 0.95,
        bottom: 0.1,
        confidence: 0.7,
      ),
    ]);

    expect(regions, hasLength(2));
    expect(regions.any((region) => region.left == 0.01), isTrue);
    expect(regions.any((region) => region.left == 0.75), isTrue);
  });








}

const _bilibiliTemplate = [
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

void _drawBilibiliTemplate(
  Uint8List pixels,
  int stride,
  int left,
  int top,
) {
  for (var y = 0; y < _bilibiliTemplate.length; y++) {
    for (var x = 0; x < _bilibiliTemplate[y].length; x++) {
      if (_bilibiliTemplate[y].codeUnitAt(x) == 35) {
        pixels[(top + y) * stride + left + x] = (x * 37 + y * 17) & 255;
      }
    }
  }
}

void _drawLogo(
  Uint8List pixels,
  int stride,
  int left,
  int top,
  int right,
  int bottom,
) {
  for (var x = left; x < right; x += 8) {
    for (var y = top; y < bottom; y++) {
      for (var xx = x; xx < x + 4 && xx < right; xx++) {
        pixels[y * stride + xx] = 230;
      }
    }
  }
  for (var y = top + 5; y < bottom; y += 8) {
    for (var yy = y; yy < y + 3 && yy < bottom; yy++) {
      for (var x = left; x < right; x++) {
        pixels[yy * stride + x] = 230;
      }
    }
  }
}
