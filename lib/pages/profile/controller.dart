import 'package:PiliPlus/http/api.dart';
import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/models/common/account_type.dart';
import 'package:PiliPlus/models/user/info.dart';
import 'package:PiliPlus/pages/profile/model.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/accounts/account.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  final RxList<Profile> profiles = RxList<Profile>();
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfiles();
  }

  Future<void> fetchProfiles() async {
    try {
      isLoading.value = true;
      final accountValues = Accounts.account.values.toList();
      for (final account in accountValues) {
        final res = await Request().get(
          Api.userInfo,
          options: Options(extra: {'account': account}),
        );
        if (res.data['code'] == 0) {
          final userInfo = UserInfoData.fromJson(res.data['data']);
          profiles.add(Profile(account: account, userInfo: userInfo));
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  void switchAccount(Account account) {
    Accounts.set(AccountType.main, account);
    Get.back();
  }
}
