import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TvDebugPage extends StatelessWidget {
  const TvDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TV Debug Menu'),
      ),
      body: ListView(
        children: [
          ListTile(
            onTap: () => Get.toNamed('/loginPage'),
            leading: const Icon(Icons.add_circle_outline_outlined),
            title: const Text('添加账户'),
          ),
        ],
      ),
    );
  }
}
