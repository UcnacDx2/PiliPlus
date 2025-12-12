import 'dart:io';

import 'package:PiliPlus/utils/storage_pref.dart';

class TVDetector {
  static bool get isTV {
    return Pref.enableTVMode || _isAndroidTV();
  }

  static bool _isAndroidTV() {
    // TODO: Implement device detection logic
    return false;
  }
}
