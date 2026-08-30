import 'package:PiliPlus/services/account_service.dart';
import 'package:get/get.dart';

abstract final class TvAccountFacade {
  static bool get isLoggedIn => Get.isRegistered<AccountService>() &&
      Get.find<AccountService>().isLogin.value;
  static String? get face => Get.isRegistered<AccountService>()
      ? Get.find<AccountService>().face.value
      : null;
  static String? get uname => null;
  static int? get mid => null;
  static bool get isVip => false;
  static Future<void> logout() async {}
  static Future<void> saveLoginCredentials({required String accessToken, required String refreshToken, required int mid, Map<String, dynamic>? cookieInfo}) async {}
}
