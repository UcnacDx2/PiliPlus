import 'package:get/get.dart';
import 'package:pili_plus/services/tv_menu/menu_provider.dart';

class TVMenuService extends GetxService {
  static TVMenuService get to => Get.find();

  final RxBool isMenuVisible = false.obs;
  final Rx<MenuProvider?> currentProvider = Rx<MenuProvider?>(null);

  final List<MenuProvider> _providers = [];

  void registerProvider(MenuProvider provider) {
    _providers.add(provider);
  }

  void unregisterProvider(MenuProvider provider) {
    _providers.remove(provider);
  }

  void toggleMenu(dynamic context) {
    if (isMenuVisible.value) {
      hideMenu();
    } else {
      showMenu(context);
    }
  }

  void showMenu(dynamic context) {
    final provider = _findProvider(context);
    if (provider != null) {
      currentProvider.value = provider;
      isMenuVisible.value = true;
    }
  }

  void hideMenu() {
    isMenuVisible.value = false;
    currentProvider.value = null;
  }

  MenuProvider? _findProvider(dynamic context) {
    return _providers.reversed.firstWhereOrNull((p) => p.canHandle(context));
  }
}
