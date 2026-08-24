import 'package:PiliPlus/models/common/watermark_position.dart';
import 'package:PiliPlus/plugin/pl_player/models/watermark_region.dart';
import 'package:PiliPlus/plugin/pl_player/utils/watermark_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generates a GLSL shader with the normalized region coordinates', () {
    const region = WatermarkRegion(
      left: 0.87,
      top: 0.005,
      right: 0.99,
      bottom: 0.08,
      confidence: 0.9,
    );

    final shader = WatermarkFilter.shaderFor([region]);

    expect(shader, contains('//!HOOK MAIN'));
    expect(shader, contains('//!BIND HOOKED'));
    expect(shader, contains('vec4(0.870000, 0.005000, 0.990000, 0.080000)'));
    expect(shader, contains('HOOKED_tex'));
    expect(shader, contains('mix(top, bottom, position.y)'));
    expect(shader, isNot(contains('#version 330')));
    expect(shader, isNot(contains('delogo')));
    expect(shader, isNot(contains('lavfi')));
  });

  test('keeps pixel coordinates inside the video frame', () {
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

  test('maps fixed watermark regions to all four corners', () {
    const expected = <WatermarkPosition, ({double left, double top})>{
      WatermarkPosition.topLeft: (left: 0.012, top: 0.012),
      WatermarkPosition.topRight: (left: 0.548, top: 0.012),
      WatermarkPosition.bottomLeft: (left: 0.012, top: 0.878),
      WatermarkPosition.bottomRight: (left: 0.548, top: 0.878),
    };

    for (final entry in expected.entries) {
      final region = WatermarkRegion.fixed(entry.key);
      final shader = WatermarkFilter.shaderFor([region]);

      expect(region.left, closeTo(entry.value.left, 0.0001));
      expect(region.top, closeTo(entry.value.top, 0.0001));
      expect(region.right - region.left, closeTo(0.44, 0.0001));
      expect(region.bottom - region.top, closeTo(0.11, 0.0001));
      expect(
        shader,
        contains(
          'vec4(${region.left.toStringAsFixed(6)}, '
          '${region.top.toStringAsFixed(6)}, '
          '${region.right.toStringAsFixed(6)}, '
          '${region.bottom.toStringAsFixed(6)})',
        ),
      );
    }
  });

  test('limits generated shader regions to four', () {
    final regions = List.generate(
      5,
      (index) => WatermarkRegion(
        left: index / 10,
        top: 0.01,
        right: index / 10 + 0.1,
        bottom: 0.1,
        confidence: 1,
      ),
    );

    final shader = WatermarkFilter.shaderFor(regions);

    expect(RegExp(r'const vec4 region\d').allMatches(shader), hasLength(4));
    expect(shader, isNot(contains('region4')));
  });

  test('builds remove and append commands for only the owned shader', () {
    const shaderPath = '/support/piliplus_watermark.glsl';

    expect(WatermarkFilter.removeCommandFor(shaderPath), [
      'change-list',
      'glsl-shaders',
      'remove',
      shaderPath,
    ]);
    expect(WatermarkFilter.appendCommandFor(shaderPath), [
      'change-list',
      'glsl-shaders',
      'append',
      shaderPath,
    ]);
    expect(WatermarkFilter.commandSequenceFor(shaderPath), [
      ['change-list', 'glsl-shaders', 'remove', shaderPath],
      ['change-list', 'glsl-shaders', 'append', shaderPath],
    ]);
    expect(
      WatermarkFilter.commandSequenceFor(shaderPath).join(' '),
      isNot(contains(' clr ')),
    );
  });
}
