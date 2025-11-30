import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/common/widgets/tv_popup_menu.dart';

class TvMenuManager {
  static final TvMenuManager _instance = TvMenuManager._internal();

  factory TvMenuManager() {
    return _instance;
  }

  TvMenuManager._internal();

  BuildContext? _currentContext;
  String? _contextType;
  dynamic _focusData;

  void register(BuildContext context, String contextType, dynamic focusData) {
    _currentContext = context;
    _contextType = contextType;
    _focusData = focusData;
  }

  void unregister() {
    _currentContext = null;
    _contextType = null;
    _focusData = null;
  }

  void showMenu() {
    if (_currentContext != null && _contextType != null && _focusData != null) {
      showDialog(
        context: _currentContext!,
        builder: (context) => TvPopupMenu(
          focusData: _focusData,
          contextType: _contextType!,
        ),
      );
    }
  }
}
