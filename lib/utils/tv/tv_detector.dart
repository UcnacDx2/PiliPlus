import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:PiliPlus/utils/storage_pref.dart';

class TVDetector {
  static bool _isTV = false;
  static bool get isTV => _isTV;

  static Future<void> init() async {
    if (Pref.enableTVMode) {
      _isTV = true;
      return;
    }
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      // Use a combination of factors to determine if it's a TV.
      // Android TVs often lack touch support and have specific UI modes.
      final isAndroidTV = deviceInfo.systemFeatures.contains('android.software.leanback') ||
                          deviceInfo.systemFeatures.contains('android.hardware.type.television');
      _isTV = isAndroidTV;
    } else {
      _isTV = false;
    }
  }
}
