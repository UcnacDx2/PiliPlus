import 'dart:typed_data';

import 'package:PiliPlus/services/first_frame_quality_service.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List pixels(List<(int, int, int)> colors) {
  final bytes = Uint8List(colors.length * 4);
  for (var i = 0; i < colors.length; i++) {
    final offset = i * 4;
    bytes[offset] = colors[i].$1;
    bytes[offset + 1] = colors[i].$2;
    bytes[offset + 2] = colors[i].$3;
    bytes[offset + 3] = 255;
  }
  return bytes;
}

void main() {
  test('rejects a uniformly black frame', () {
    final metrics = FirstFrameQualityAnalyzer.metrics(
      pixels(List.filled(576, (0, 0, 0))),
    );
    expect(
      FirstFrameQualityAnalyzer.classify(metrics),
      FirstFrameQuality.mostlyBlack,
    );
  });

  test('rejects a black frame with a tiny bright point', () {
    final colors = List<(int, int, int)>.filled(576, (0, 0, 0));
    for (var i = 0; i < 4; i++) {
      colors[280 + i] = (180, 220, 255);
    }
    final metrics = FirstFrameQualityAnalyzer.metrics(pixels(colors));
    expect(
      FirstFrameQualityAnalyzer.classify(metrics),
      FirstFrameQuality.tinyVisibleSubject,
    );
  });

  test('keeps a dark frame that contains a substantial subject', () {
    final colors = List<(int, int, int)>.filled(576, (4, 4, 5));
    for (var y = 4; y < 14; y++) {
      for (var x = 8; x < 24; x++) {
        colors[y * 32 + x] = (90, 75, 68);
      }
    }
    final metrics = FirstFrameQualityAnalyzer.metrics(pixels(colors));
    expect(
      FirstFrameQualityAnalyzer.classify(metrics),
      FirstFrameQuality.usable,
    );
  });

  test('keeps a normally exposed frame', () {
    final colors = List.generate(
      576,
      (index) => index.isEven ? (210, 150, 100) : (50, 90, 140),
    );
    final metrics = FirstFrameQualityAnalyzer.metrics(pixels(colors));
    expect(
      FirstFrameQualityAnalyzer.classify(metrics),
      FirstFrameQuality.usable,
    );
  });
}