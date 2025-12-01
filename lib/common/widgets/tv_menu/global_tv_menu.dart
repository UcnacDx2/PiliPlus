import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GlobalTvMenu extends StatelessWidget {
  const GlobalTvMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            autofocus: true,
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: const Icon(Icons.person_add_outlined, size: 22),
            title: const Text('添加账户', style: TextStyle(fontSize: 16)),
            onTap: () {
              // TODO: Implement add account
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: const Icon(Icons.exit_to_app_outlined, size: 22),
            title: const Text('退出程序', style: TextStyle(fontSize: 16)),
            onTap: () {
              SystemNavigator.pop();
            },
          ),
        ],
      ),
    );
  }
}
