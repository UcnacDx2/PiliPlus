import 'package:get/get.dart';

import 'controller.dart';

class TvDebugBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TvDebugController>(
      () => TvDebugController(),
    );
  }
}
