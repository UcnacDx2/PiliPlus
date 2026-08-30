import 'dart:typed_data';

/// 视频快照(雪碧图)数据模型
class VideoshotData {
  final List<String> images;
  final int imgXLen; // 对应 JS 中的 i
  final int imgYLen; // 对应 JS 中的 n
  final int imgXSize; // 对应 JS 中的 a (perImgW)
  final int imgYSize; // 对应 JS 中的 s (perImgH)
  final String? pvdataUrl;
  List<int>? _frameTimestamps;

  /// The mobile API usually returns this directly; pvdata is the fallback.
  List<int> get frameIndexes => _frameTimestamps ?? const [];

  int get framesPerImage => imgXLen * imgYLen; // 对应 JS 中的 l

  VideoshotData({
    required this.images,
    required this.imgXLen,
    required this.imgYLen,
    required this.imgXSize,
    required this.imgYSize,
    this.pvdataUrl,
  });

  factory VideoshotData.fromJson(Map<String, dynamic> json) {
    return VideoshotData(
        images:
            (json['image'] as List?)
                ?.map((e) => _fixUrl(e.toString()))
                .toList() ??
            [],
        imgXLen: json['img_x_len'] as int? ?? 10,
        imgYLen: json['img_y_len'] as int? ?? 10,
        imgXSize: json['img_x_size'] as int? ?? 160,
        imgYSize: json['img_y_size'] as int? ?? 90,
        pvdataUrl: json['pvdata'] != null ? _fixUrl(json['pvdata']) : null,
      )
      .._frameTimestamps = (json['index'] as List?)
          ?.map((value) => (value as num).toInt())
          .toList();
  }

  static String _fixUrl(String url) {
    if (url.startsWith('//')) return 'https:$url';
    return url;
  }

  void setTimestamps(List<int> timestamps) {
    _frameTimestamps = timestamps;
  }

  /// 1. 还原 getIndex 算法
  /// 对应 JS: getIndex = function(t) { ... i = o - 1; ... return i >= 0 && i || 0; }
  int getIndex(Duration position) {
    if (_frameTimestamps == null || _frameTimestamps!.isEmpty) return 0;

    final double seconds = position.inMilliseconds / 1000.0;
    final timestamps = _frameTimestamps!;

    // 默认值：JS 中 i = t.length - 2
    int resultIdx = timestamps.length - 2;

    // 对应 JS 循环: for (var o = 0; o < t.length - 1; o++)
    for (int o = 0; o < timestamps.length - 1; o++) {
      if (seconds >= timestamps[o] && seconds < timestamps[o + 1]) {
        resultIdx = o - 1; // 关键：B站逻辑是索引再减1
        break;
      }
    }

    // 对应 JS: return i >= 0 && i || 0;
    return resultIdx >= 0 ? resultIdx : 0;
  }

  /// 2. 还原坐标计算逻辑
  /// 对应 JS: d = r % l % i * a; (X坐标)
  /// 对应 JS: u = Math.floor(r % l / n) * s; (Y坐标)
  FrameInfo? getFrameAt(Duration position) {
    if (images.isEmpty) return null;

    // 获取帧索引 r
    final int r = getIndex(position);

    // 每张大图的总帧数 l
    final int l = framesPerImage;

    // 计算在大图列表中的图片索引 (第几张大图)
    // 对应 JS: c = t[Math.floor(r / l)]
    int imageIndex = (r / l).floor();
    if (imageIndex >= images.length) imageIndex = images.length - 1;

    // 计算在单张大图内部的偏移
    // 对应 JS X坐标: d = r % l % i * a
    // i 是 imgXLen (列数), a 是 imgXSize (宽)
    final int x = (r % l % imgXLen) * imgXSize;

    // Y坐标: 标准行主序布局，除以列数 (xLen)
    // Python: y = math.floor((r % l) / self.x_len) * self.per_img_h
    final int y = ((r % l) ~/ imgXLen) * imgYSize;

    return FrameInfo(
      imageUrl: images[imageIndex],
      x: x,
      y: y,
      width: imgXSize,
      height: imgYSize,
    );
  }

  /// 获取最接近给定位置的帧时间戳
  /// 用于时间吸附功能，确保预览位置对齐到实际帧
  Duration getClosestTimestamp(Duration position) {
    if (_frameTimestamps == null || _frameTimestamps!.isEmpty) {
      return position;
    }

    final double seconds = position.inMilliseconds / 1000.0;
    final timestamps = _frameTimestamps!;

    // 找到最接近的时间戳
    int closestIdx = 0;
    double minDiff = (timestamps[0] - seconds).abs();

    for (int i = 1; i < timestamps.length; i++) {
      final diff = (timestamps[i] - seconds).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestIdx = i;
      }
    }

    return Duration(seconds: timestamps[closestIdx]);
  }

  /// 3. 解析 pvdata.bin
  /// 严格按照 JS 的 Uint8 移位解析（Big-Endian）
  static List<int> parsePvdata(Uint8List bytes) {
    if (bytes.isEmpty || bytes.length.isOdd) return const [];
    final timestamps = <int>[];
    for (var i = 0; i < bytes.length; i += 2) {
      // 对应 JS: var r = i.getUint8(s) << 8 | i.getUint8(s + 1);
      final value = (bytes[i] << 8) | bytes[i + 1];
      timestamps.add(value);
    }
    for (var i = 1; i < timestamps.length; i++) {
      if (timestamps[i] < timestamps[i - 1]) return const [];
    }
    return timestamps;
  }
}

class FrameInfo {
  final String imageUrl;
  final int x;
  final int y;
  final int width;
  final int height;

  FrameInfo({
    required this.imageUrl,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}
