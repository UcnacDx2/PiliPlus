// Dumps detected watermark regions as JSON for offline tooling.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:PiliPlus/fork/watermark/bilibili_anchor_detector.dart';
import 'package:PiliPlus/fork/watermark/watermark_frame.dart';

void main(List<String> args) {
  final manifest = File(args.first);
  final entries =
      (jsonDecode(manifest.readAsStringSync()) as List).cast<Map<String, dynamic>>();
  final dir = manifest.parent.path;
  final out = <Map<String, Object?>>[];
  for (final entry in entries) {
    final width = entry['width'] as int;
    final height = entry['height'] as int;
    final frame = WatermarkFrame(
      width: width,
      height: height,
      luma: Uint8List.fromList(
        File('$dir/${entry['luma']}').readAsBytesSync(),
      ),
    );
    final anchor = BilibiliAnchorDetector.detectInFramesSync([frame]);
    out.add({
      'name': entry['name'],
      if (anchor != null) ...{
        'corner': anchor.corner.name,
        'left': anchor.region.left,
        'top': anchor.region.top,
        'right': anchor.region.right,
        'bottom': anchor.region.bottom,
        'score': anchor.score,
        'ax': anchor.anchorX,
        'ay': anchor.anchorY,
        'aw': anchor.analysisWidth,
        'ah': anchor.analysisHeight,
      },
    });
  }
  stdout.writeln(const JsonEncoder.withIndent(' ').convert(out));
}
