import 'package:PiliPlus/models/common/theme/theme_type.dart';
import 'package:PiliPlus/pages/login/controller.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:PiliPlus/router/app_pages.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TvDebugPage extends StatelessWidget {
  const TvDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, Map<String, dynamic>> pageMap = {
      '/loginPage': {'title': '添加账户', 'icon': Icons.add_circle_outline_outlined},
      '/download': {'title': '离线缓存', 'icon': Icons.download_outlined},
      '/history': {'title': '观看记录', 'icon': Icons.history_outlined},
      '/subscription': {'title': '我的订阅', 'icon': Icons.subscriptions_outlined},
      '/later': {'title': '稍后再看', 'icon': Icons.watch_later_outlined},
      '/fav': {'title': '我的收藏', 'icon': Icons.favorite_border_outlined},
      '/setting': {'title': '设置', 'icon': Icons.settings_outlined},
      '/search': {'title': '搜索', 'icon': Icons.search_outlined},
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('TV Debug Menu'),
      ),
      body: ListView.builder(
        itemCount: Routes.debugPages.length + 3,
        itemBuilder: (context, index) {
          if (index < Routes.debugPages.length) {
            final page = Routes.debugPages[index];
            final pageInfo = pageMap[page.name];
            return ListTile(
              onTap: () => Get.toNamed(page.name),
              leading: Icon(pageInfo?['icon'] ?? Icons.pageview),
              title: Text(pageInfo?['title'] ?? page.name),
            );
          } else if (index == Routes.debugPages.length) {
            return ListTile(
              onTap: () => MineController.onChangeAnonymity(),
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('进入无痕模式'),
            );
          } else if (index == Routes.debugPages.length + 1) {
            return ListTile(
              onTap: () => LoginPageController.switchAccountDialog(context),
              leading: const Icon(Icons.switch_account_outlined),
              title: const Text('设置账号模式'),
            );
          } else {
            return ListTile(
              onTap: () {
                ThemeType newThemeType =
                    Get.isDarkMode ? ThemeType.light : ThemeType.dark;
                Get.find<MineController>().themeType.value = newThemeType;
                GStorage.setting
                    .put(SettingBoxKey.themeMode, newThemeType.index);
                Get.changeThemeMode(newThemeType.toThemeMode);
              },
              leading: const Icon(Icons.brightness_6_outlined),
              title: const Text('切换主题'),
            );
          }
        },
      ),
    );
  }
}
