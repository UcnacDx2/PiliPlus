import 'package:PiliPlus/common/widgets/tv_menu/tv_popup_menu_item.dart';
import 'package:flutter/material.dart';

class TvPopupMenu extends StatelessWidget {
  final List<TvPopupMenuItem> items;

  const TvPopupMenu({
    required this.items,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool autofocusSet = false;

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12))),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final bool shouldAutofocus = !autofocusSet;
          if (shouldAutofocus) {
            autofocusSet = true;
          }
          return ListTile(
            autofocus: shouldAutofocus,
            dense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Icon(item.icon, size: 22),
            title: Text(item.title, style: const TextStyle(fontSize: 16)),
            onTap: item.onTap,
          );
        }).toList(),
      ),
    );
  }
}
