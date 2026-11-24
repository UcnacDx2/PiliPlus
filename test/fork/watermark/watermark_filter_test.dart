import 'package:PiliPlus/fork/watermark/watermark_position.dart';
import 'package:PiliPlus/fork/watermark/watermark_region.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:PiliPlus/fork/watermark/watermark_filter.dart';
import 'package:PiliPlus/fork/watermark/watermark_shader.dart';
import 'package:PiliPlus/fork/watermark/watermark_stroke_mask.dart';
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

    final shader = utf8.decode(WatermarkShader.source([region]));

    expect(shader, contains('//!HOOK MAIN'));
    expect(shader, contains('//!BIND HOOKED'));
    expect(shader, contains('vec4(0.870000, 0.005000, 0.990000, 0.080000)'));
    expect(shader, contains('HOOKED_tex'));
    expect(shader, contains('if (rect.y <= pad.y) vertical = bottom;'));
    expect(shader, contains('if (rect.z >= 1.0 - pad.x) horizontal = left;'));
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
      final shader = utf8.decode(WatermarkShader.source([region]));

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

    final shader = utf8.decode(WatermarkShader.source(regions));

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


  test('refinement adds stroke helpers and keeps fallback regions', () {
    const region = WatermarkRegion(
      left: 0.8,
      top: 0.01,
      right: 0.99,
      bottom: 0.12,
      confidence: 1,
    );
    const other = WatermarkRegion(
      left: 0.01,
      top: 0.01,
      right: 0.2,
      bottom: 0.1,
      confidence: 1,
    );
    final mask = WatermarkStrokeMask(
      columns: 64,
      rows: 20,
      words: Uint32List.fromList([0x80000000, 0x00000001]),
    );
    final refinement = WatermarkRefinement(region: region, mask: mask);

    final bytes = WatermarkShader.source([region, other], refinement: refinement);
    // Binary mask bytes precede the GLSL source, which starts at //!HOOK.
    final hook = utf8.encode('//!HOOK MAIN');
    final start = _indexOf(bytes, hook);
    final shader = utf8.decode(bytes.sublist(start));

    expect(shader, contains('piliplus_refine'));
    expect(shader, contains('const int piliplus_cols = 64;'));
    
    expect(shader, contains('const int piliplus_rows = 20;'));
    expect(shader, contains('//!TEXTURE piliplus_mask_tex'));
    
    expect(shader, contains('piliplus_stroke'));
    // The second region keeps the whole-rectangle blend.
    expect(shader, contains('piliplus_fill(HOOKED_pos, region1)'));
    expect(shader, contains('piliplus_refine(HOOKED_pos, region0)'));
    // GLSL ES 1.00 forbids const-array initializers.
    expect(shader, isNot(contains('const vec2 dirs')));
    expect(shader, isNot(contains('const float radii')));
    expect(shader, isNot(contains('piliplus_mask[')));
  });

  test('shader without refinement keeps the plain fill only', () {
    const region = WatermarkRegion(
      left: 0.8,
      top: 0.01,
      right: 0.99,
      bottom: 0.12,
      confidence: 1,
    );

    final shader = utf8.decode(WatermarkShader.source([region]));

    expect(shader, isNot(contains('piliplus_refine')));
    expect(shader, contains('piliplus_fill'));
  });
}

/// Returns the first index of [needle] in [haystack], or -1.
int _indexOf(Uint8List haystack, List<int> needle) {
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    var matched = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        matched = false;
        break;
      }
    }
    if (matched) return i;
  }
  return -1;
}
