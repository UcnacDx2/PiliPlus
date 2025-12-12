import 'package:flutter/material.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

import 'package:PiliPlus/utils/tv/region_manager.dart';

DpadNavigator dpadConfig(Widget child) {
  return DpadNavigator(
    enabled: true,
    focusMemory: const FocusMemoryOptions(enabled: true, maxHistory: 20),
    regionNavigation: RegionNavigationOptions(
      enabled: true,
      rules: TVRegionManager.defaultRules,
    ),
    onBackPressed: () => _handleTVBack(),
    child: child,
  );
}

KeyEventResult _handleTVBack() {
  if (SmartDialog.checkExist()) {
    SmartDialog.dismiss();
    return KeyEventResult.handled;
  }

  if (Get.isDialogOpen ?? Get.isBottomSheetOpen ?? false) {
    Get.back();
    return KeyEventResult.handled;
  }

  final plCtr = PlPlayerController.instance;
  if (plCtr != null) {
    if (plCtr.isFullScreen.value) {
      plCtr
        ..triggerFullScreen(status: false)
        ..controlsLock.value = false
        ..showControls.value = false;
      return KeyEventResult.handled;
    }

    if (plCtr.isDesktopPip) {
      plCtr
        ..exitDesktopPip().whenComplete(
          () => plCtr.initialFocalPoint = Offset.zero,
        )
        ..controlsLock.value = false
        ..showControls.value = false;
      return KeyEventResult.handled;
    }
  }

  Get.back();
  return KeyEventResult.handled;
}
