import 'package:PiliPlus/common/widgets/tv_menu/tv_menu_overlay.dart';
import 'package:PiliPlus/services/tv_menu/menu_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

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

  MenuProvider? getProviderForContext(BuildContext context) {
    for (final provider in _providers) {
      if (provider.canHandle(context)) {
        return provider;
      }
    }
    return null;
  }

  void toggleMenu(BuildContext context) {
    if (isMenuVisible.value) {
      hideMenu();
    } else {
      final provider = getProviderForContext(context);
      if (provider != null) {
        showMenu(provider);
      }
    }
  }

  void showMenu(MenuProvider provider) {
    isMenuVisible.value = true;
    SmartDialog.show(
      builder: (_) => TVMenuOverlay(provider: provider),
      onDismiss: () {
        isMenuVisible.value = false;
      },
    );
  }

  void hideMenu() {
    SmartDialog.dismiss();
    isMenuVisible.value = false;
  }
}
