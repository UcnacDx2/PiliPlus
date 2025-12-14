import 'package:PiliPlus/models/common/account_type.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/accounts/account.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  final RxList<Account> accounts = RxList<Account>();

  @override
  void onInit() {
    super.onInit();
    accounts.addAll(Accounts.account.values);
  }

  void switchAccount(Account account) {
    Accounts.set(AccountType.main, account);
    Get.back();
  }
}
