// Offline evaluation harness for the fork's watermark detectors.
//
// Usage:
//   dart run tool/watermark_eval.dart <manifest.json>
//
// The manifest is a JSON list of entries produced by the evaluation scripts:
//   {"name": "L00", "bvid": "...", "width": 480, "height": 270,
//    "gt": "tl" | "tr" | "bl" | "br" | null, "luma": "path/to/name.bin"}
//
// Each `.bin` file is a raw 8-bit luma plane of width*height bytes. Keeping the
// fixtures as luma planes lets this harness import the real detector without
// `dart:ui`, so results match the app exactly.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:PiliPlus/fork/watermark/bilibili_anchor_detector.dart';
import 'package:PiliPlus/fork/watermark/watermark_frame.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run tool/watermark_eval.dart <manifest.json>');
    exit(64);
  }
  final manifestFile = File(args.first);
  final entries =
      (jsonDecode(manifestFile.readAsStringSync()) as List)
          .cast<Map<String, dynamic>>();
  final directory = manifestFile.parent;

  var positives = 0;
  var truePositives = 0;
  var wrongCorner = 0;
  var missed = 0;
  var negatives = 0;
  var falsePositives = 0;
  final failures = <String>[];

  for (final entry in entries) {
    final name = entry['name'] as String;
    final width = entry['width'] as int;
    final height = entry['height'] as int;
    final lumaPath = entry['luma'] as String? ?? '$name.bin';
    final bytes = File('${directory.path}/$lumaPath').readAsBytesSync();
    final frame = WatermarkFrame(
      width: width,
      height: height,
      luma: Uint8List.fromList(bytes),
    );
    final expected = entry['gt'] as String?;
    final anchor = BilibiliAnchorDetector.detectInFramesSync([frame]);
    final detected = anchor == null ? null : _cornerName(anchor.corner);
    final score = anchor?.score ?? 0;

    if (expected == null) {
      negatives++;
      if (detected != null) {
        falsePositives++;
        failures.add(
          'FP  $name ${width}x$height -> $detected '
          'score=${score.toStringAsFixed(3)} '
          'frame=${_regionText(anchor)}',
        );
      }
      continue;
    }

    positives++;
    if (detected == null) {
      missed++;
      failures.add('MISS $name ${width}x$height expected=$expected');
    } else if (detected != expected) {
      wrongCorner++;
      failures.add(
        'WRONG $name ${width}x$height expected=$expected got=$detected '
        'score=${score.toStringAsFixed(3)}',
      );
    } else {
      truePositives++;
    }
  }

  for (final line in failures) {
    stdout.writeln(line);
  }
  final accuracy = positives == 0 ? 0.0 : truePositives / positives * 100;
  stdout
    ..writeln('')
    ..writeln(
      'positives=$positives hit=$truePositives '
      '(${accuracy.toStringAsFixed(1)}%) wrongCorner=$wrongCorner '
      'missed=$missed',
    )
    ..writeln('negatives=$negatives falsePositives=$falsePositives');
}

String _cornerName(WatermarkCorner corner) => switch (corner) {
  WatermarkCorner.topLeft => 'tl',
  WatermarkCorner.topRight => 'tr',
  WatermarkCorner.bottomLeft => 'bl',
  WatermarkCorner.bottomRight => 'br',
};

String _regionText(BilibiliAnchor? anchor) {
  if (anchor == null) return '-';
  final region = anchor.region;
  return '[${region.left.toStringAsFixed(3)},'
      '${region.top.toStringAsFixed(3)},'
      '${region.right.toStringAsFixed(3)},'
      '${region.bottom.toStringAsFixed(3)}]';
}
