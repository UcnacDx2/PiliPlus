import 'package:flutter/material.dart';

class MenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final List<MenuItem>? children;

  MenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.children,
  });
}
