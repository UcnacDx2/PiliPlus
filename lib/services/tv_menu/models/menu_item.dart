import 'package:flutter/material.dart';

/// Data model for a TV menu item
class TvMenuItem {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool enabled;
  final List<TvMenuItem>? children;

  const TvMenuItem({
    required this.label,
    this.icon,
    this.onTap,
    this.enabled = true,
    this.children,
  });

  bool get hasChildren => children != null && children!.isNotEmpty;
}
