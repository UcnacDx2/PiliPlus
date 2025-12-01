import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:piliplus/common/widgets/tv_menu/tv_menu_overlay.dart';
import 'package:piliplus/services/tv_menu/menu_provider.dart';
import 'package:piliplus/services/tv_menu/providers/default_menu_provider.dart';

class TVMenuService extends GetxService {
  static TVMenuService get to => Get.find();

  final RxBool isMenuVisible = false.obs;
  final List<MenuProvider> _providers = [];

  @override
  void onInit() {
    super.onInit();
    registerProvider(DefaultMenuProvider());
  }

  void registerProvider(MenuProvider provider) {
    _providers.add(provider);
  }

  void unregisterProvider(Type providerType) {
    _providers.removeWhere((p) => p.runtimeType == providerType);
  }

  MenuProvider? getProviderForContext(BuildContext context) {
    // Return the default provider if no other provider can handle the context
    return _providers.lastWhere(
      (provider) => provider.canHandle(context),
      orElse: () => DefaultMenuProvider(),
    );
  }

  void toggleMenu(BuildContext context) {
    isMenuVisible.value = !isMenuVisible.value;
    if (isMenuVisible.value) {
      final provider = getProviderForContext(context);
      final menuItems = provider?.getMenuItems(context) ?? [];
      if (menuItems.isNotEmpty) {
        SmartDialog.show(
          builder: (_) => const TVMenuOverlay(),
          alignment: Alignment.center,
          backgroundColor: Colors.transparent,
          clickMaskDismiss: true,
          onDismiss: () {
            isMenuVisible.value = false;
          },
        );
      } else {
        isMenuVisible.value = false;
      }
    } else {
      SmartDialog.dismiss();
    }
  }
}
