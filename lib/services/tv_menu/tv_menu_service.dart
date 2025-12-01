import 'package:get/get.dart';
import 'package:PiliPlus/services/tv_menu/menu_provider.dart';

class TVMenuService extends GetxService {
  static TVMenuService get instance => Get.find();

  final RxBool isMenuVisible = false.obs;
  final List<MenuProvider> _providers = [];

  void registerProvider(MenuProvider provider) {
    _providers.add(provider);
  }

  void unregisterProvider(MenuProvider provider) {
    _providers.remove(provider);
  }

  MenuProvider? getProviderForContext(context) {
    for (var provider in _providers.reversed) {
      if (provider.canHandle(context)) {
        return provider;
      }
    }
    return null;
  }

  void toggleMenu() {
    isMenuVisible.value = !isMenuVisible.value;
  }
}
