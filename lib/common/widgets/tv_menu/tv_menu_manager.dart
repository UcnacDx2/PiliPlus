import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tv_menu_adapter.dart';
import 'tv_popup_menu.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:get/get.dart';

class TvMenuManager {
  static final TvMenuManager _instance = TvMenuManager._internal();
  factory TvMenuManager() => _instance;
  TvMenuManager._internal();

  TvMenuAdapter? _focusedAdapter;

  void setFocusedAdapter(TvMenuAdapter? adapter) {
    _focusedAdapter = adapter;
  }

  void _handleMenuKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.menu) {
      if (Get.isDialogOpen ?? false) return;
      show();
    }
  }

  void Function(RawKeyEvent)? _listener;

  void addGlobalListener() {
    if (!Utils.isTV) return;
    _listener = _handleMenuKey;
    RawKeyboard.instance.addListener(_listener!);
  }

  void dispose() {
    if (_listener != null) {
      RawKeyboard.instance.removeListener(_listener!);
    }
  }

  void show() {
    showDialog(
      context: Get.overlayContext!,
      builder: (context) => TvPopupMenu(
        adapter: _focusedAdapter ?? DefaultMenuAdapter(),
      ),
    );
  }
}
