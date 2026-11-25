// Offline check: build the refine shader from a dumped mask and verify the
// GLSL is ES 1.00 compatible.
//
// Usage:
//   dart --packages=.dart_tool/package_config.json \
//     tool/watermark_shader_dump.dart <regions.json> <outDir>
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:PiliPlus/fork/watermark/watermark_shader.dart';
import 'package:PiliPlus/fork/watermark/watermark_region.dart';
import 'package:PiliPlus/fork/watermark/watermark_stroke_mask.dart';

void main(List<String> args) {
  final regions =
      (jsonDecode(File(args[0]).readAsStringSync()) as List)
          .cast<Map<String, dynamic>>();
  final outDir = Directory(args[1])..createSync(recursive: true);

  for (final entry in regions) {
    if (entry['corner'] == null) continue;
    final name = entry['name'] as String;
    final region = WatermarkRegion(
      left: entry['left'] as double,
      top: entry['top'] as double,
      right: entry['right'] as double,
      bottom: entry['bottom'] as double,
      confidence: 1,
    );
    const columns = 91;
    const rows = 34;
    final words = Uint32List(((columns * rows) + 31) >> 5);
    // Deterministic pattern, good enough for shader syntax validation.
    for (var i = 0; i < words.length; i++) {
      words[i] = 0x55555555 ^ i;
    }
    final bytes = WatermarkShader.source(
      [region],
      refinement: WatermarkRefinement(
        region: region,
        mask: WatermarkStrokeMask(columns: columns, rows: rows, words: words),
      ),
    );
    final text = utf8.decode(bytes);
    final hookAt = text.indexOf('//!HOOK MAIN');
    final problems = <String>[
      if (hookAt < 0) 'missing hook header',
      if (RegExp(r'\buint\b').hasMatch(text)) 'uint present',
      if (text.contains('const vec2 dirs')) 'const array dirs',
      if (text.contains('const float radii')) 'const array radii',
      if (text.contains('piliplus_mask[')) 'mask const array',
      if (RegExp(r'>>\s*5|<<\s*1').hasMatch(text)) 'bit ops',
      if (text.contains('//!TEXTURE')) 'embedded texture blob',
      if (bytes.any((b) => b > 0x7f)) 'non-ascii bytes',
      if (!text.contains('piliplus_refine')) 'no refine (mask too fragmented)',
      if (text.contains('region0') && !text.contains('hook()')) 'no hook',
    ];
    if (problems.isNotEmpty) {
      stderr.writeln('$name: $problems');
      if (problems.any((p) => p != 'no refine (mask too fragmented)')) {
        exitCode = 1;
      }
    }
    File('${outDir.path}/$name.glsl').writeAsBytesSync(bytes);
    stdout.writeln(
      '$name ok (${bytes.length} bytes, rects: '
      '${RegExp('piliplus_cell\\(uv, rect, vec4\\(').allMatches(text).length})',
    );
  }
}
