import 'dart:typed_data';

/// One luma frame used by watermark analysis.
///
/// Decoding and scaling live in `watermark_input.dart`; this type stays free of
/// `dart:ui` so the detection code can run on a plain Dart VM (`dart run
/// tool/watermark_eval.dart`) and in unit tests without an engine.
class WatermarkFrame {
  const WatermarkFrame({
    required this.width,
    required this.height,
    required this.luma,
  });

  final int width;
  final int height;
  final Uint8List luma;
}
