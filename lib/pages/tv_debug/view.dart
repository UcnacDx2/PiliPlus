import 'package:PiliPlus/models/common/theme/theme_type.dart';
import 'package:PiliPlus/pages/login/controller.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
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
          ListTile(
            onTap: () => Get.toNamed('/download'),
            leading: const Icon(Icons.download_outlined),
            title: const Text('离线缓存'),
          ),
          ListTile(
            onTap: () => Get.toNamed('/history'),
            leading: const Icon(Icons.history_outlined),
            title: const Text('观看记录'),
          ),
          ListTile(
            onTap: () => Get.toNamed('/subscription'),
            leading: const Icon(Icons.subscriptions_outlined),
            title: const Text('我的订阅'),
          ),
          ListTile(
            onTap: () => Get.toNamed('/later'),
            leading: const Icon(Icons.watch_later_outlined),
            title: const Text('稍后再看'),
          ),
          ListTile(
            onTap: () => Get.toNamed('/fav'),
            leading: const Icon(Icons.favorite_border_outlined),
            title: const Text('我的收藏'),
          ),
          ListTile(
            onTap: () => Get.toNamed('/setting'),
            leading: const Icon(Icons.settings_outlined),
            title: const Text('设置'),
          ),
          ListTile(
            onTap: () => Get.toNamed('/search'),
            leading: const Icon(Icons.search_outlined),
            title: const Text('搜索'),
          ),
          ListTile(
            onTap: () => MineController.onChangeAnonymity(),
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('进入无痕模式'),
          ),
          ListTile(
            onTap: () => LoginPageController.switchAccountDialog(context),
            leading: const Icon(Icons.switch_account_outlined),
            title: const Text('设置账号模式'),
          ),
          ListTile(
            onTap: () {
              ThemeType newThemeType =
                  Get.isDarkMode ? ThemeType.light : ThemeType.dark;
              Get.find<MineController>().themeType.value = newThemeType;
              GStorage.setting.put(SettingBoxKey.themeMode, newThemeType.index);
              Get.changeThemeMode(newThemeType.toThemeMode);
            },
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('切换主题'),
          ),
        ],
      ),
    );
  }
}
