import 'package:flutter/material.dart';
import 'tv_menu_adapter.dart';

class TvPopupMenu extends StatelessWidget {
  final TvMenuAdapter adapter;

  const TvPopupMenu({
    required this.adapter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      clipBehavior: Clip.hardEdge,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: adapter.buildMenuItems(context),
      ),
    );
  }
}
