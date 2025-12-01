import 'package:flutter/material.dart';
import 'dart:async';

import 'package:get/get.dart';
import 'package:pilipala/services/global_menu_manager.dart';
import 'package:pilipala/services/menu_content_generator.dart';
import 'package:pilipala/utils/storage_pref.dart';

class GlobalMenu extends StatefulWidget {
  const GlobalMenu({super.key});

  @override
  State<GlobalMenu> createState() => _GlobalMenuState();
}

class _GlobalMenuState extends State<GlobalMenu> {
  final GlobalMenuManager menuManager = Get.find<GlobalMenuManager>();
  late final StreamSubscription subscription;

  @override
  void initState() {
    super.initState();
    subscription = menuManager.isMenuVisible.listen((isVisible) {
      if (isVisible && Pref.enableRemoteMenu) {
        _showMenu();
      }
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  void _showMenu() {
    final focus = menuManager.currentFocus.value;
    if (focus == null) {
      menuManager.toggleMenu();
      return;
    }
    final strategy = _getMenuStrategy(focus.pageType);
    final items = strategy.generateItems(focus);
    if (items.isEmpty) {
      menuManager.toggleMenu();
      return;
    }

    final screenSize = MediaQuery.of(context).size;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(screenSize.width - 200, 100, 0, 0),
      items: items,
    ).then((_) {
      menuManager.isMenuVisible.value = false;
    });
  }

  MenuContentStrategy _getMenuStrategy(String? pageType) {
    switch (pageType) {
      case 'video':
        return VideoPageMenuStrategy();
      case 'live':
        return LiveRoomMenuStrategy();
      default:
        return DefaultMenuStrategy();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
