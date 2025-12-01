import 'package:flutter/material.dart';

class TvPopupMenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  TvPopupMenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}
