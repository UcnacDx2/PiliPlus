import 'package:PiliPlus/common/widgets/tv_popup_menu.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/model_video.dart';
import 'package:PiliPlus/models/tv_menu_context.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/pages/video/widgets/header_control.dart';
import 'package:PiliPlus/plugin/pl_player/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class TvMenuManager {
  static final TvMenuManager _instance = TvMenuManager._internal();

  factory TvMenuManager() {
    return _instance;
  }

  TvMenuManager._internal();

  ValueNotifier<TvMenuContext?> currentContext = ValueNotifier(null);

  void showTvMenu(BuildContext context) {
    final contextValue = currentContext.value;
    final String contextType =
        contextValue?.type.toString().split('.').last ?? 'default';
    final dynamic focusData = contextValue?.data;

    showDialog(
      context: context,
      builder: (dialogContext) => TvPopupMenu(
        focusData: focusData,
        contextType: contextType,
      ),
    );
  }
}
