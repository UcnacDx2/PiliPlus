import 'dart:developer';
import 'package:PiliPlus/utils/storage_pref.dart';

class ReplaceCover {
  static const String _replaceHost = 'i0.hdslb.com';

  static String? getReplacedCover(String? originalCover) {
    if (originalCover == null) return null;
    if (!Pref.replaceCover) return originalCover;
    try {
      final uri = Uri.parse(originalCover);
      if (uri.host != _replaceHost) {
        return uri.replace(host: _replaceHost).toString();
      }
    } catch (e) {
      log(e.toString());
    }
    return originalCover;
  }
}
