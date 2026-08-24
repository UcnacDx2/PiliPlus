import 'dart:math' show max, min;

import 'package:PiliPlus/models/common/watermark_position.dart';

class WatermarkRegion {
  const WatermarkRegion({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.confidence,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;
  final double confidence;

  /// A deliberately generous fixed area for a creator nickname (up to about
  /// 16 CJK characters) followed by the bilibili mark.
  factory WatermarkRegion.fixed(WatermarkPosition position) {
    const marginX = 0.012;
    const marginY = 0.012;
    const regionWidth = 0.44;
    const regionHeight = 0.11;

    final left = switch (position) {
      WatermarkPosition.topLeft || WatermarkPosition.bottomLeft => marginX,
      WatermarkPosition.topRight ||
      WatermarkPosition.bottomRight => 1 - marginX - regionWidth,
    };
    final top = switch (position) {
      WatermarkPosition.topLeft || WatermarkPosition.topRight => marginY,
      WatermarkPosition.bottomLeft ||
      WatermarkPosition.bottomRight => 1 - marginY - regionHeight,
    };

    return WatermarkRegion(
      left: left,
      top: top,
      right: left + regionWidth,
      bottom: top + regionHeight,
      confidence: 1,
    );
  }

  WatermarkPixelRegion toPixelRegion(int width, int height) {
    var x = max(1, (left * width).floor());
    var y = max(1, (top * height).floor());
    var rightPx = min(width - 1, (right * width).ceil());
    var bottomPx = min(height - 1, (bottom * height).ceil());

    // Keep legacy pixel mappings aligned for any non-shader caller.
    x -= x.isOdd ? 1 : 0;
    y -= y.isOdd ? 1 : 0;
    rightPx += (rightPx - x).isOdd ? 1 : 0;
    bottomPx += (bottomPx - y).isOdd ? 1 : 0;
    rightPx = min(width - 1, rightPx);
    bottomPx = min(height - 1, bottomPx);

    return WatermarkPixelRegion(
      x: x,
      y: y,
      width: max(2, rightPx - x),
      height: max(2, bottomPx - y),
    );
  }
}

class WatermarkPixelRegion {
  const WatermarkPixelRegion({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;
}
