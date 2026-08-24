import 'package:PiliPlus/plugin/pl_player/models/watermark_region.dart';
import 'package:PiliPlus/plugin/pl_player/utils/watermark_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a labeled delogo command in source-video coordinates', () {
    const region = WatermarkRegion(
      left: 0.87,
      top: 0.005,
      right: 0.99,
      bottom: 0.08,
      confidence: 0.9,
    );

    final command = WatermarkFilter.commandFor(region, 1, 1920, 1080);

    expect(command.take(2), ['vf', 'add']);
    expect(command.last, startsWith('@piliplus-watermark-1:lavfi=[delogo='));
    expect(command.last, contains('show=0'));
  });

  test('keeps delogo coordinates inside the video frame', () {
    const region = WatermarkRegion(
      left: 0,
      top: 0,
      right: 1,
      bottom: 1,
      confidence: 1,
    );

    final rect = region.toPixelRegion(1920, 1080);

    expect(rect.x, greaterThanOrEqualTo(0));
    expect(rect.y, greaterThanOrEqualTo(0));
    expect(rect.x + rect.width, lessThan(1920));
    expect(rect.y + rect.height, lessThan(1080));
  });
}
