import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:pili_plus/services/tv_menu/tv_menu_service.dart';
import 'package:pili_plus/common/widgets/tv_menu/menu_item_widget.dart';

void showTVMenu() {
  final service = TVMenuService.to;
  if (service.currentProvider.value == null) return;

  final items = service.currentProvider.value!.getMenuItems(Get.context!);

  SmartDialog.show(
    tag: 'tv_menu',
    onDismiss: () {
      final service = TVMenuService.to;
      if (service.isMenuVisible.value) {
        service.hideMenu();
      }
    },
    builder: (context) {
      return Material(
        color: Colors.black.withOpacity(0.5),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return MenuItemWidget(
                  item: items[index],
                  autoFocus: index == 0,
                );
              },
            ),
          ),
        ),
      );
    },
  );
}
