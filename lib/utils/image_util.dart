import 'package:PiliPlus/utils/storage_pref.dart';

class ImageUtil {
  static final _thumbRegex = RegExp(
    r'(@(\d+[a-z]_?)*)(\..*)?\$',
    caseSensitive: false,
  );

  static String thumbnailUrl(String? src, [int? quality]) {
    if (src != null && Pref.replaceCover) {
      final atIndex = src.lastIndexOf('@');
      if (atIndex != -1) {
        return src.substring(0, atIndex);
      }
    }
    return src ?? '';
  }
}
