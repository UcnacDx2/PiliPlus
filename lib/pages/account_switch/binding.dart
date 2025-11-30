import 'package:get/get.dart';
import 'controller.dart';

class AccountSwitchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AccountSwitchController>(
      () => AccountSwitchController(),
    );
  }
}
