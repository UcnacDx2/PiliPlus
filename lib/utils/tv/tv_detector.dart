import 'dart:io';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:device_info_plus/device_info_plus.dart';

class TVDetector {
  static bool _isTV = false;

  static bool get isTV => _isTV || Pref.enableTVMode;

  static Future<void> init() async {
    if (Platform.isAndroid) {
      _isTV = await _isAndroidTV();
    }
  }

  static Future<bool> _isAndroidTV() async {
    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      // A common way to check for Android TV is to look for the leanback feature.
      return deviceInfo.systemFeatures.contains('android.software.leanback');
    } catch (e) {
      return false;
    }
  }
}
