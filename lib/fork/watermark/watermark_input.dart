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
    ui.Rect? sourceRect,
  }) async {
    final src = sourceRect ??
        ui.Rect.fromLTWH(
          0,
          0,
          source.width.toDouble(),
          source.height.toDouble(),
        );
    final width = upscale ? targetWidth : min(targetWidth, src.width.round());
    final height = max(1, (src.height * width / src.width).round());
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawImageRect(
      source,
      src,
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
    // The video frame is letterboxed when the aspect differs from the sprite
    // frame, so the transparent border must not bleed into the luma.
    final luma = Uint8List(width * height);
    final whiteness = Uint8List(width * height);
    for (var pixel = 0, offset = 0; pixel < luma.length; pixel++, offset += 4) {
      if (rgba[offset + 3] < 16) continue;
      final r = rgba[offset];
      final g = rgba[offset + 1];
      final b = rgba[offset + 2];
      luma[pixel] = (r * 77 + g * 150 + b * 29) >> 8;
      // min(r, g, b) is high only for desaturated bright pixels: the white
      // watermark keeps it high on colored backgrounds, where a luma edge
      // alone cannot tell the mark from the scene.
      whiteness[pixel] = r < g ? (r < b ? r : b) : (g < b ? g : b);
    }
    return WatermarkFrame(
      width: width,
      height: height,
      luma: luma,
      whiteness: whiteness,
    );
  }
}
