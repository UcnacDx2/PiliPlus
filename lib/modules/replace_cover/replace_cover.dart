import 'dart:developer';
import 'package:PiliPlus/utils/storage_pref.dart';

class ReplaceCover {
  static String? getReplacedCover(String? originalCover) {
    if (originalCover == null || originalCover.isEmpty) {
      return originalCover;
    }
    if (!Pref.replaceCover) {
      return originalCover;
    }

    try {
      // Bilibili封面URL可能在'@'符号后包含分辨率说明。
      // 删除它们可以获得原始的高分辨率图像。
      // 例如：http://i0.hdslb.com/bfs/archive/xxx.jpg@412w_232h_1c.jpg -> http://i0.hdslb.com/bfs/archive/xxx.jpg
      final atIndex = originalCover.lastIndexOf('@');
      if (atIndex != -1) {
        return originalCover.substring(0, atIndex);
      }
    } catch (e) {
      log('Failed to replace cover: $e');
    }

    return originalCover;
  }
}
