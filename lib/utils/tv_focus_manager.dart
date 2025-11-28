import 'package:flutter/widgets.dart';

class TvFocusManager {
  final List<FocusNode> _focusableNodes = [];
  int _currentNodeIndex = 0;

  void addFocusableNode(FocusNode node) {
    _focusableNodes.add(node);
  }

  void removeFocusableNode(FocusNode node) {
    _focusableNodes.remove(node);
  }

  void requestFocus(FocusNode node) {
    node.requestFocus();
    _currentNodeIndex = _focusableNodes.indexOf(node);
  }

  void clearFocus() {
    for (var node in _focusableNodes) {
      node.unfocus();
    }
  }

  void moveFocus(AxisDirection direction) {
    if (_focusableNodes.isEmpty) {
      return;
    }

    if (direction == AxisDirection.down || direction == AxisDirection.right) {
      _currentNodeIndex = (_currentNodeIndex + 1) % _focusableNodes.length;
    } else if (direction == AxisDirection.up || direction == AxisDirection.left) {
      _currentNodeIndex = (_currentNodeIndex - 1 + _focusableNodes.length) % _focusableNodes.length;
    }

    _focusableNodes[_currentNodeIndex].requestFocus();
  }
}
