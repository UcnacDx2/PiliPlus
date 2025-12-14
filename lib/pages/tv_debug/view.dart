import 'package:PiliPlus/router/app_pages.dart';
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
          const Divider(),
          ListTile(
            onTap: () => Get.toNamed('/download'),
            leading: const Icon(Icons.download_outlined),
            title: const Text('离线缓存'),
          ),
          const Divider(),
          ListTile(
            onTap: () => Get.toNamed('/history'),
            leading: const Icon(Icons.history_outlined),
            title: const Text('观看记录'),
          ),
          const Divider(),
          ListTile(
            onTap: () => Get.toNamed('/subscription'),
            leading: const Icon(Icons.subscriptions_outlined),
            title: const Text('我的订阅'),
          ),
          const Divider(),
          ListTile(
            onTap: () => Get.toNamed('/later'),
            leading: const Icon(Icons.watch_later_outlined),
            title: const Text('稍后再看'),
          ),
          const Divider(),
          ListTile(
            onTap: () => Get.toNamed('/fav'),
            leading: const Icon(Icons.favorite_border_outlined),
            title: const Text('我的收藏'),
          ),
          const Divider(),
          ListTile(
            onTap: () {},
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('进入无痕模式'),
          ),
          const Divider(),
          ListTile(
            onTap: () {},
            leading: const Icon(Icons.account_box_outlined),
            title: const Text('设置账号模式'),
          ),
          const Divider(),
          ListTile(
            onTap: () => Get.changeThemeMode(ThemeMode.light),
            leading: const Icon(Icons.light_mode_outlined),
            title: const Text('切换到浅色主题'),
          ),
          const Divider(),
          ListTile(
            onTap: () => Get.toNamed('/setting'),
            leading: const Icon(Icons.settings_outlined),
            title: const Text('设置'),
          ),
          const Divider(),
          ListTile(
            onTap: () => Get.toNamed('/search'),
            leading: const Icon(Icons.search_outlined),
            title: const Text('搜索'),
          ),
          const Divider(),
          ListTile(
            onTap: () => Get.toNamed('/dpadTest'),
            leading: const Icon(Icons.gamepad),
            title: const Text('D-pad Test Page'),
          ),
          const Divider(),
          ...Routes.getPages.asMap().entries.map(
                (entry) => ListTile(
                  onTap: () => Get.toNamed(entry.value.name),
                  leading: Text((entry.key + 1).toString()),
                  title: Text(entry.value.name),
                ),
              ),
        ],
      ),
    );
  }
}
