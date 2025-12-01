import 'package:get/get.dart';
import 'package:pilipala/models/focus_context.dart';

class GlobalMenuManager {
  static final GlobalMenuManager _instance = GlobalMenuManager._internal();
  factory GlobalMenuManager() => _instance;
  GlobalMenuManager._internal();

  final Rx<FocusContext?> currentFocus = Rx<FocusContext?>(null);
  final RxBool isMenuVisible = false.obs;

  void updateFocus(FocusContext context) {
    currentFocus.value = context;
  }

  void toggleMenu() {
    isMenuVisible.value = !isMenuVisible.value;
  }
}
