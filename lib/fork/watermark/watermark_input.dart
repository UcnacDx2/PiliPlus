import 'dart:math' show max, min;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:PiliPlus/fork/watermark/watermark_frame.dart';

/// Decodes a `ui.Image` (screen capture or decoded thumbnail) into a luma
/// frame for watermark analysis.
abstract final class WatermarkInput {
  static Future<WatermarkFrame?> fromImage(
    ui.Image source, {
    int targetWidth = 480,
    bool upscale = false,
  }) async {
    final width = upscale ? targetWidth : min(targetWidth, source.width);
    final height = max(1, (source.height * width / source.width).round());
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawImageRect(
      source,
      ui.Rect.fromLTWH(
        0,
        0,
        source.width.toDouble(),
        source.height.toDouble(),
      ),
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      ui.Paint()..filterQuality = ui.FilterQuality.low,
    );
    final picture = recorder.endRecording();
    final scaled = await picture.toImage(width, height);
    picture.dispose();
    final bytes = await scaled.toByteData(format: ui.ImageByteFormat.rawRgba);
    scaled.dispose();
    if (bytes == null) return null;

    final rgba = bytes.buffer.asUint8List(
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
    final luma = Uint8List(width * height);
    for (var pixel = 0, offset = 0; pixel < luma.length; pixel++, offset += 4) {
      luma[pixel] =
          (rgba[offset] * 77 + rgba[offset + 1] * 150 + rgba[offset + 2] * 29) >>
          8;
    }
    return WatermarkFrame(width: width, height: height, luma: luma);
  }
}
