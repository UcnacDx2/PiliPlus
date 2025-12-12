import 'package:flutter/widgets.dart';

/// Marker widget to detect whether the current focus is inside bottom controls.
class BottomControlsFocusMarker extends InheritedWidget {
  const BottomControlsFocusMarker({super.key, required super.child});

  static bool isInScope(BuildContext? context) {
    if (context == null) return false;
    return context
            .getElementForInheritedWidgetOfExactType<
              BottomControlsFocusMarker
            >() !=
        null;
  }

  @override
  bool updateShouldNotify(covariant BottomControlsFocusMarker oldWidget) =>
      false;
}

/// Manage focus nodes for the D-pad friendly bottom controls layout.
class BottomControlsFocusManager {
  BottomControlsFocusManager()
    : scopeNode = FocusScopeNode(debugLabel: 'BottomControlsFocusScope'),
      progressNode = FocusNode(debugLabel: 'BottomControlsProgress');

  final FocusScopeNode scopeNode;
  final FocusNode progressNode;
  final List<FocusNode> _primaryNodes = <FocusNode>[];
  final List<FocusNode> _secondaryNodes = <FocusNode>[];

  List<FocusNode> get primaryNodesList => _primaryNodes;
  List<FocusNode> get secondaryNodesList => _secondaryNodes;

  List<FocusNode> primaryNodes(int count) {
    _ensureNodes(_primaryNodes, count, prefix: 'Primary');
    return _primaryNodes.take(count).toList();
  }

  List<FocusNode> secondaryNodes(int count) {
    _ensureNodes(_secondaryNodes, count, prefix: 'Secondary');
    return _secondaryNodes.take(count).toList();
  }

  void _ensureNodes(
    List<FocusNode> bucket,
    int count, {
    required String prefix,
  }) {
    final int missing = count - bucket.length;
    if (missing <= 0) return;
    for (int i = 0; i < missing; i++) {
      bucket.add(
        FocusNode(debugLabel: 'BottomControls$prefix#$i'),
      );
    }
  }

  void dispose() {
    scopeNode.dispose();
    progressNode.dispose();
    for (final node in _primaryNodes) {
      node.dispose();
    }
    for (final node in _secondaryNodes) {
      node.dispose();
    }
  }
}
