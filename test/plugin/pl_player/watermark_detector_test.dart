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

  test('advanced mode accepts a logo visible in five of eight frames', () async {
    const width = 480;
    const height = 270;
    final frames = <WatermarkFrame>[];
    for (var frameIndex = 0; frameIndex < 8; frameIndex++) {
      final pixels = Uint8List(width * height)
        ..fillRange(0, width * height, 35 + frameIndex * 18);
      if (const {0, 1, 2, 3, 5}.contains(frameIndex)) {
        _drawLogo(pixels, width, 8, 8, 82, 30);
      }
      frames.add(WatermarkFrame(width: width, height: height, luma: pixels));
    }

    final regions = await WatermarkDetector.detect(
      WatermarkMode.advanced,
      frames,
    );

    expect(regions, hasLength(1));
    expect(regions.single.left, lessThan(0.1));
    expect(regions.single.top, lessThan(0.1));
  });

  test('advanced mode accepts a tall watermark inside a bottom corner', () async {
    const width = 480;
    const height = 270;
    final frames = <WatermarkFrame>[];
    for (var frameIndex = 0; frameIndex < 8; frameIndex++) {
      final pixels = Uint8List(width * height)
        ..fillRange(0, width * height, 30 + frameIndex * 20);
      _drawLogo(pixels, width, 382, 204, 470, 254);
      frames.add(WatermarkFrame(width: width, height: height, luma: pixels));
    }

    final regions = await WatermarkDetector.detect(
      WatermarkMode.advanced,
      frames,
    );

    expect(regions, hasLength(1));
    expect(regions.single.right, greaterThan(0.9));
    expect(regions.single.bottom, greaterThan(0.9));
  });

  test('advanced mode groups nearby watermark parts on the same line', () async {
    const width = 480;
    const height = 270;
    final frames = <WatermarkFrame>[];
    for (var frameIndex = 0; frameIndex < 8; frameIndex++) {
      final pixels = Uint8List(width * height)
        ..fillRange(0, width * height, 30 + frameIndex * 20);
      _drawLogo(pixels, width, 340, 8, 413, 24);
      _drawLogo(pixels, width, 436, 8, 461, 13);
      frames.add(WatermarkFrame(width: width, height: height, luma: pixels));
    }

    final regions = await WatermarkDetector.detect(
      WatermarkMode.advanced,
      frames,
    );

    expect(regions, hasLength(1));
    expect(regions.single.left, lessThan(0.75));
    expect(regions.single.right, greaterThan(0.9));
  });

  test('advanced mode accepts a small logo eight percent from the edge', () async {
    const width = 480;
    const height = 270;
    final frames = <WatermarkFrame>[];
    for (var frameIndex = 0; frameIndex < 8; frameIndex++) {
      final pixels = Uint8List(width * height)
        ..fillRange(0, width * height, 30 + frameIndex * 20);
      _drawLogo(pixels, width, 419, 8, 442, 29);
      frames.add(WatermarkFrame(width: width, height: height, luma: pixels));
    }

    final regions = await WatermarkDetector.detect(
      WatermarkMode.advanced,
      frames,
    );

    expect(regions, hasLength(1));
    expect(regions.single.left, greaterThan(0.8));
    expect(regions.single.top, lessThan(0.15));
  });

  test(
    'advanced mode rejects a component touching the encoded frame edge',
    () async {
      const width = 480;
      const height = 270;
      final frames = <WatermarkFrame>[];
      for (var frameIndex = 0; frameIndex < 8; frameIndex++) {
        final pixels = Uint8List(width * height)
          ..fillRange(0, width * height, 30 + frameIndex * 20);
        _drawLogo(pixels, width, 435, 220, width, 245);
        frames.add(WatermarkFrame(width: width, height: height, luma: pixels));
      }

      final regions = await WatermarkDetector.detect(
        WatermarkMode.advanced,
        frames,
      );

      expect(regions, isEmpty);
    },
  );

  test('disabled mode does not analyze frames', () async {
    final regions = await WatermarkDetector.detect(
      WatermarkMode.disabled,
      const [],
    );

    expect(regions, isEmpty);
  });

  test('advanced diagnostics reports frame diversity and corner masks', () async {
    const width = 48;
    const height = 27;
    final frames = List.generate(
      8,
      (index) => WatermarkFrame(
        width: width,
        height: height,
        luma: Uint8List(width * height)..fillRange(0, width * height, index * 8),
      ),
    );

    final diagnostics = await WatermarkDetector.diagnoseAdvanced(frames);

    expect(diagnostics, contains('size=48x27'));
    expect(diagnostics, contains('meanDelta='));
    expect(diagnostics, contains('topLeft{stable='));
    expect(diagnostics, contains('bottomRight{stable='));
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
