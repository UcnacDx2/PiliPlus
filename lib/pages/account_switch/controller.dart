import 'package:PiliPlus/models/common/account_type.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:get/get.dart';

import 'package:PiliPlus/utils/accounts/account.dart';

class AccountSwitchController extends GetxController {
  final accounts = <Account>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAccounts();
  }

  void fetchAccounts() {
    accounts.value = Accounts.account.values.toList();
  }

  Future<void> switchAccount(Account account) async {
    // Simulate a network delay for better user feedback
    await Future.delayed(const Duration(milliseconds: 300));
    Accounts.set(AccountType.main, account);
    Get.back();
  }

  void addAccount() {
    Get.toNamed('/loginPage');
  }
}
