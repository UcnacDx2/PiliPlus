import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

enum FocusLevel {
  lvl1, // Default bottom bar item
  lvl2, // Non-default bottom bar item
  lvl3, // Page content - default tab
  lvl4, // Page content - non-default tab
}

class FocusState {
  final FocusLevel level;
  final int index;
  final FocusNode? node;

  FocusState({required this.level, required this.index, this.node});
}

class FocusManagementService extends GetxService {
  final _focusStack = <FocusState>[].obs;
  Timer? _debounce;

  FocusState? get currentState => _focusStack.isNotEmpty ? _focusStack.last : null;

  void requestFocus(FocusState state, {bool debounce = false}) {
    if (debounce) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        _updateFocus(state);
      });
    } else {
      _updateFocus(state);
    }
  }

  void _updateFocus(FocusState state) {
    if (_focusStack.isNotEmpty && _focusStack.last.level == state.level) {
      _focusStack.removeLast();
    }
    _focusStack.add(state);
    state.node?.requestFocus();
  }

  bool handleBackButton() {
    if (_focusStack.isEmpty) return false;

    final currentState = _focusStack.last;
    switch (currentState.level) {
      case FocusLevel.lvl4:
        // Go back to default tab
        _focusStack.removeLast();
        final pageState = _focusStack.firstWhereOrNull((s) => s.level == FocusLevel.lvl3);
        if (pageState != null) {
          pageState.node?.requestFocus();
          return true;
        }
        break;
      case FocusLevel.lvl3:
        // Go back to bottom bar
        _focusStack.removeLast();
        final bottomBarState = _focusStack.firstWhereOrNull((s) => s.level == FocusLevel.lvl1 || s.level == FocusLevel.lvl2);
        if (bottomBarState != null) {
          bottomBarState.node?.requestFocus();
          return true;
        }
        break;
      case FocusLevel.lvl2:
        // Go back to default bottom bar item
        _focusStack.removeLast();
        final defaultBottomBarState = _focusStack.firstWhereOrNull((s) => s.level == FocusLevel.lvl1);
        if (defaultBottomBarState != null) {
          defaultBottomBarState.node?.requestFocus();
          return true;
        }
        break;
      case FocusLevel.lvl1:
        // Handle exit confirmation
        // This will be handled in the UI
        return false;
    }
    return false;
  }

  void clear() {
    _focusStack.clear();
  }
}
