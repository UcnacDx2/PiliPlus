import 'package:PiliPlus/common/widgets/tv_menu/tv_menu_overlay.dart';
import 'package:PiliPlus/services/tv_menu/menu_provider.dart';
import 'package:PiliPlus/services/tv_menu/models/menu_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

/// Singleton service for managing TV menu state and providers
class TvMenuService extends GetxService {
  static TvMenuService? _instance;

  /// Get the singleton instance
  static TvMenuService get instance {
    _instance ??= Get.find<TvMenuService>();
    return _instance!;
  }

  /// Check if an instance exists
  static bool get hasInstance => _instance != null;

  /// Menu visibility state
  final RxBool isMenuVisible = false.obs;

  /// Registered menu providers
  final List<MenuProvider> _providers = [];

  /// Register a menu provider
  void registerProvider(MenuProvider provider) {
    if (!_providers.contains(provider)) {
      _providers.add(provider);
      // Sort by priority (higher priority first)
      _providers.sort((a, b) => b.priority.compareTo(a.priority));
    }
  }

  /// Unregister a menu provider by type
  void unregisterProvider<T extends MenuProvider>() {
    _providers.removeWhere((p) => p is T);
  }

  /// Unregister a specific provider instance
  void unregisterProviderInstance(MenuProvider provider) {
    _providers.remove(provider);
  }

  /// Toggle menu visibility
  void toggleMenu(BuildContext context) {
    if (isMenuVisible.value) {
      hideMenu();
    } else {
      showMenu(context);
    }
  }

  /// Show the menu
  void showMenu(BuildContext context) {
    if (isMenuVisible.value) return;

    final items = _getMenuItems(context);
    if (items.isEmpty) return;

    isMenuVisible.value = true;

    SmartDialog.show(
      tag: 'tv_menu',
      maskColor: Colors.black54,
      clickMaskDismiss: true,
      onDismiss: () {
        isMenuVisible.value = false;
      },
      builder: (context) => TvMenuOverlay(
        items: items,
        onDismiss: hideMenu,
      ),
    );
  }

  /// Hide the menu
  void hideMenu() {
    if (!isMenuVisible.value) return;
    isMenuVisible.value = false;
    SmartDialog.dismiss(tag: 'tv_menu');
  }

  /// Get menu items from the appropriate provider
  List<TvMenuItem> _getMenuItems(BuildContext context) {
    for (final provider in _providers) {
      if (provider.canHandle(context)) {
        return provider.getMenuItems(context);
      }
    }
    return [];
  }

  /// Get the current active provider (for debugging)
  MenuProvider? getActiveProvider(BuildContext context) {
    for (final provider in _providers) {
      if (provider.canHandle(context)) {
        return provider;
      }
    }
    return null;
  }

  @override
  void onClose() {
    _providers.clear();
    _instance = null;
    super.onClose();
  }
}
