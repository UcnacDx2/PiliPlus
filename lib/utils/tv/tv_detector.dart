import 'dart:io';

import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:device_info_plus/device_info_plus.dart';

class TVDetector {
  static bool? _isAndroidTVDevice;

  static Future<void> init() async {
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      _isAndroidTVDevice =
          androidInfo.systemFeatures.contains('android.software.leanback_only');
    }
  }

  static bool get isTV {
    if (Pref.enableTVMode) {
      return true;
    }
    return _isAndroidTVDevice ?? false;
  }
}
