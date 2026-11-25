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
    this.whiteness,
  });

  final int width;
  final int height;
  final Uint8List luma;

  /// Per-pixel `min(r, g, b)`: high for the white creator watermark, low for
  /// colored scene content. The creator nickname is white text, so a bright
  /// green background (grass, foliage) has a strong luma edge but a low
  /// whiteness, which keeps it out of the stroke mask. Null when the frame was
  /// synthesised from luma only (tests, offline PGM dumps).
  final Uint8List? whiteness;

  /// Whiteness at [index], or 255 when the frame carries no color plane so a
  /// whiteness gate never rejects a luma-only frame.
  int whitenessAt(int index) => whiteness?[index] ?? 255;
}
