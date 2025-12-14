import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/models/common/account_type.dart';
import 'package:PiliPlus/models/user/info.dart';
import 'package:PiliPlus/pages/profile/model.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/accounts/account.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  final RxList<Profile> profiles = RxList<Profile>();

  @override
  void onInit() {
    super.onInit();
    fetchProfiles();
  }

  Future<void> fetchProfiles() async {
    final accountValues = Accounts.account.values.toList();
    for (final account in accountValues) {
      final res = await UserHttp.userInfo(account: account);
      if (res.isSuccess) {
        profiles.add(Profile(account: account, userInfo: res.data));
      }
    }
  }

  void switchAccount(Account account) {
    Accounts.set(AccountType.main, account);
    Get.back();
  }
}
