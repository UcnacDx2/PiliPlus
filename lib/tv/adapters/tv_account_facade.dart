import 'package:PiliPlus/services/account_service.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/accounts/account.dart';
import 'package:PiliPlus/models/common/account_type.dart';
import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/utils/login_utils.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:get/get.dart';

abstract final class TvAccountFacade {
  static bool get isLoggedIn => Accounts.main.isLogin;

  /// Older TV login imports persisted credentials without assigning a role.
  /// Restore the cached user (or the only available account) as main on TV
  /// startup, keeping the shared account/login implementation untouched.
  static Future<void> restorePersistedMainRole() async {
    if (Accounts.main.isLogin && Accounts.video.isLogin) return;
    final cachedMid = Pref.userInfoCache?.mid;
    final accounts = Accounts.account.values.toList(growable: false);
    LoginAccount? candidate;
    if (cachedMid == null) {
      candidate = accounts.length == 1 ? accounts.single : null;
    } else {
      for (final account in accounts) {
        if (account.mid == cachedMid) {
          candidate = account;
          break;
        }
      }
    }
    if (candidate != null) {
      if (!Accounts.main.isLogin) {
        await Accounts.set(AccountType.main, candidate);
      }
      if (!Accounts.video.isLogin) {
        await Accounts.set(AccountType.video, candidate);
      }
    }
  }

  static String? get face => Get.isRegistered<AccountService>()
      ? Get.find<AccountService>().face.value
      : null;
  static String? get uname => Pref.userInfoCache?.uname;
  static int? get mid => Pref.userInfoCache?.mid ?? (isLoggedIn ? Accounts.main.mid : null);
  static bool get isVip => (Pref.userInfoCache?.vipStatus ?? 0) == 1;
  static Future<void> logout() => Accounts.deleteAll({Accounts.main});
  static Future<void> saveLoginCredentials({required String accessToken, required String refreshToken, required int mid, Map<String, dynamic>? cookieInfo}) async {
    final cookies = cookieInfo?['cookies'];
    if (cookies is! List || cookies.isEmpty) return;
    final account = LoginAccount(BiliCookieJar.fromList(cookies), accessToken, refreshToken);
    await Future.wait([account.onChange(), AnonymousAccount().delete()]);
    for (final type in AccountType.values) {
      if (Accounts.accountMode[type.index].mid == account.mid) {
        Accounts.accountMode[type.index] = account;
      }
    }
    if (!Accounts.main.isLogin) Accounts.accountMode[AccountType.main.index] = account;
    Request.setCookie();
    await LoginUtils.onLoginMain();
  }
}
