import 'dart:typed_data';

import 'package:PiliPlus/models/common/watermark_mode.dart';
import 'package:PiliPlus/plugin/pl_player/utils/watermark_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('advanced mode keeps two independent persistent corner overlays', () async {
    const width = 480;
    const height = 270;
    final frames = <WatermarkFrame>[];
    for (var frameIndex = 0; frameIndex < 8; frameIndex++) {
      final pixels = Uint8List(width * height)
        ..fillRange(0, width * height, 35 + frameIndex * 18);
      _drawLogo(pixels, width, 8, 8, 82, 30);
      _drawLogo(pixels, width, 414, 7, 472, 31);
      frames.add(WatermarkFrame(width: width, height: height, luma: pixels));
    }

    final regions = await WatermarkDetector.detect(
      WatermarkMode.advanced,
      frames,
    );

    expect(regions, hasLength(2));
    expect(regions.any((region) => region.left < 0.1), isTrue);
    expect(regions.any((region) => region.right > 0.9), isTrue);
  });

  test('disabled mode does not analyze frames', () async {
    final regions = await WatermarkDetector.detect(
      WatermarkMode.disabled,
      const [],
    );

    expect(regions, isEmpty);
  });
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
