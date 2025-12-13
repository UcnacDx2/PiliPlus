import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

enum FocusLevel {
  bottomBar,
  page,
  tab,
}

class FocusState {
  final FocusLevel level;
  final int index; // To know which tab or bottom bar item is focused
  final FocusNode? node;

  FocusState({required this.level, required this.index, this.node});
}

class FocusManagementService extends GetxService {
  final _focusStack = <FocusState>[].obs;

  FocusState? get currentState => _focusStack.isNotEmpty ? _focusStack.last : null;

  void requestFocus(FocusState state) {
    _focusStack.add(state);
    state.node?.requestFocus();
  }

  bool handleBackButton() {
    if (_focusStack.length > 1) {
      _focusStack.removeLast();
      currentState?.node?.requestFocus();
      return true;
    }
    return false;
  }

  void clear() {
    _focusStack.clear();
  }
}
