import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/services/tv_menu/tv_menu_service.dart';
import 'package:PiliPlus/common/widgets/tv_menu/menu_item_widget.dart';

void showTvMenu() {
  final service = TVMenuService.instance;
  final provider = service.getProviderForContext(Get.context!);
  if (provider == null) {
    return;
  }

  SmartDialog.show(
    builder: (context) {
      return Obx(() {
        final items = provider.getMenuItems(Get.context!);
        return Material(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Container(
              width: 250,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return MenuItemWidget(
                    item: items[index],
                    autofocus: index == 0,
                  );
                },
              ),
            ),
          ),
        );
      });
    },
    onDismiss: () {
      service.isMenuVisible.value = false;
    },
  );
}
