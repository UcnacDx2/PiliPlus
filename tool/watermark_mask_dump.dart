// Offline check for WatermarkStrokeMaskBuilder against real frames.
//
// Usage:
//   dart --packages=.dart_tool/package_config.json \
//     tool/watermark_mask_dump.dart <regions.json> <manifest.json> <outDir>
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:PiliPlus/fork/watermark/bilibili_anchor_detector.dart';
import 'package:PiliPlus/fork/watermark/watermark_frame.dart';
import 'package:PiliPlus/fork/watermark/watermark_region.dart';
import 'package:PiliPlus/fork/watermark/watermark_stroke_mask.dart';

const _corners = {
  'topLeft': WatermarkCorner.topLeft,
  'topRight': WatermarkCorner.topRight,
  'bottomLeft': WatermarkCorner.bottomLeft,
  'bottomRight': WatermarkCorner.bottomRight,
};

WatermarkFrame _frame(String path, int width, int height) => WatermarkFrame(
  width: width,
  height: height,
  luma: Uint8List.fromList(File(path).readAsBytesSync()),
);

void main(List<String> args) {
  final regions =
      (jsonDecode(File(args[0]).readAsStringSync()) as List)
          .cast<Map<String, dynamic>>();
  final manifest =
      (jsonDecode(File(args[1]).readAsStringSync()) as List)
          .cast<Map<String, dynamic>>();
  final byName = {for (final entry in manifest) entry['name']: entry};
  final outDir = Directory(args[2])..createSync(recursive: true);

  for (final entry in regions) {
    final name = entry['name'] as String;
    if (entry['corner'] == null) continue;
    final base = name.substring(0, name.length - 3);
    final frames = <WatermarkFrame>[];
    var width = 0;
    var height = 0;
    for (var index = 0; index < 3; index++) {
      final frameEntry = byName['${base}f$index'] ?? byName[name];
      if (frameEntry == null) break;
      width = frameEntry['width'] as int;
      height = frameEntry['height'] as int;
      frames.add(
        _frame(
          '${File(args[1]).parent.path}/${frameEntry['luma']}',
          width,
          height,
        ),
      );
    }
    if (frames.isEmpty) continue;

    final anchor = BilibiliAnchor(
      corner: _corners[entry['corner']]!,
      region: WatermarkRegion(
        left: entry['left'] as double,
        top: entry['top'] as double,
        right: entry['right'] as double,
        bottom: entry['bottom'] as double,
        confidence: 1,
      ),
      score: entry['score'] as double,
      support: frames.length,
      frameCount: frames.length,
      anchorX: entry['ax'] as int,
      anchorY: entry['ay'] as int,
      analysisWidth: entry['aw'] as int,
      analysisHeight: entry['ah'] as int,
    );
    final stopwatch = Stopwatch()..start();
    final refinement = WatermarkStrokeMaskBuilder.buildSync(frames, anchor);
    stopwatch.stop();
    if (refinement == null) {
      stdout.writeln('$name: null (${stopwatch.elapsedMilliseconds}ms)');
      continue;
    }
    final mask = refinement.mask;
    stdout.writeln(
      '$name: ${mask.columns}x${mask.rows} '
      'coverage=${mask.coverage.toStringAsFixed(3)} '
      '${stopwatch.elapsedMilliseconds}ms',
    );

    final bytes = <int>[];
    for (var y = 0; y < mask.rows; y++) {
      for (var x = 0; x < mask.columns; x++) {
        bytes.add(mask.bitAt(x, y) ? 255 : 0);
      }
    }
    final header = 'P5\n${mask.columns} ${mask.rows}\n255\n';
    File('${outDir.path}/$name.pgm').writeAsBytesSync([
      ...header.codeUnits,
      ...bytes,
    ]);
  }
}
