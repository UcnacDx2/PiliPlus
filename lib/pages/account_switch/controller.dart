import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/models/common/account_type.dart';
import 'package:PiliPlus/models/user/info.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:get/get.dart';

import 'package:PiliPlus/utils/accounts/account.dart';
import 'account_details.dart';

class AccountSwitchController extends GetxController {
  final accountDetails = <AccountDetails>[].obs;
  final isLoading = true.obs;

  static final Map<int, UserInfoData> _userInfoCache = {};

  @override
  void onInit() {
    super.onInit();
    fetchAccountDetails();
  }

  Future<void> fetchAccountDetails() async {
    final originalMainAccount = Accounts.main;
    try {
      isLoading.value = true;
      final accounts = Accounts.account.values.toList();
      final details = <AccountDetails>[];

      for (var account in accounts) {
        final mid = (account as LoginAccount).mid;
        if (_userInfoCache.containsKey(mid)) {
          details.add(
              AccountDetails(account: account, userInfo: _userInfoCache[mid]));
          continue;
        }

        await Accounts.set(AccountType.main, account);
        final res = await UserHttp.userInfo();
        if (res.isSuccess) {
          _userInfoCache[mid] = res.data;
          details.add(AccountDetails(account: account, userInfo: res.data));
        } else {
          details.add(AccountDetails(account: account));
        }
      }
      accountDetails.value = details;
    } finally {
      await Accounts.set(AccountType.main, originalMainAccount);
      isLoading.value = false;
    }
  }

  Future<void> switchAccount(Account account) async {
    await Accounts.set(AccountType.main, account);
    Get.back();
  }

  void addAccount() {
    Get.toNamed('/loginPage');
  }
}
