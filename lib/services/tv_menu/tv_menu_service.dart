import 'package:get/get.dart';
import 'package:PiliPlus/services/tv_menu/menu_provider.dart';
import 'package:flutter/material.dart';

class TVMenuService extends GetxService {
  static TVMenuService get instance => Get.find();

  final RxBool isMenuVisible = false.obs;
  final List<MenuProvider> _providers = [];
  MenuProvider? _activeProvider;

  void registerProvider(MenuProvider provider) {
    _providers.add(provider);
  }

  void unregisterProvider(MenuProvider provider) {
    _providers.remove(provider);
  }

  void toggleMenu(BuildContext context) {
    if (isMenuVisible.value) {
      hideMenu();
    } else {
      showMenu(context);
    }
  }

  void showMenu(BuildContext context) {
    _activeProvider = _findProvider(context);
    if (_activeProvider != null) {
      isMenuVisible.value = true;
    }
  }

  void hideMenu() {
    isMenuVisible.value = false;
    _activeProvider = null;
  }

  MenuProvider? _findProvider(BuildContext context) {
    for (var provider in _providers.reversed) {
      if (provider.canHandle(context)) {
        return provider;
      }
    }
    return null;
  }

  MenuProvider? get activeProvider => _activeProvider;
}
