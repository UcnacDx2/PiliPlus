import 'dart:math' show max, min;

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

  WatermarkPixelRegion toPixelRegion(int width, int height) {
    var x = max(1, (left * width).floor());
    var y = max(1, (top * height).floor());
    var rightPx = min(width - 1, (right * width).ceil());
    var bottomPx = min(height - 1, (bottom * height).ceil());

    // delogo behaves more consistently with even dimensions.
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
