// lib/common/widgets/tv_menu/tv_popup_menu.dart
import 'package:flutter/material.dart';

class TvPopupMenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const TvPopupMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

class TvPopupMenu extends StatelessWidget {
  final List<TvPopupMenuItem> items;

  const TvPopupMenu({
    required this.items,
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
        children: List.generate(items.length, (index) {
          final item = items[index];
          return ListTile(
            autofocus: index == 0,
            dense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Icon(item.icon, size: 22),
            title: Text(item.title, style: const TextStyle(fontSize: 16)),
            onTap: item.onTap,
          );
        }),
      ),
    );
  }
}
