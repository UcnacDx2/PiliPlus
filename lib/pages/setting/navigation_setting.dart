import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:flutter/material.dart';

class NavigationSetting extends StatefulWidget {
  const NavigationSetting({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<NavigationSetting> createState() => _NavigationSettingState();
}

class _NavigationSettingState extends State<NavigationSetting> {
  late List<bool> _navigationBarVisibility;

  @override
  void initState() {
    super.initState();
    _navigationBarVisibility =
        (GStorage.setting.get(SettingBoxKey.navigationBarVisibility) as List?)
                ?.map((e) => e as bool)
                .toList() ??
            List.generate(
                NavigationBarType.values.length, (index) => index < 4);
    if (_navigationBarVisibility.length < NavigationBarType.values.length) {
      _navigationBarVisibility.addAll(List.generate(
          NavigationBarType.values.length - _navigationBarVisibility.length,
          (index) => false));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(title: const Text('导航栏设置')) : null,
      body: ListView.builder(
        itemCount: NavigationBarType.values.length,
        itemBuilder: (context, index) {
          final item = NavigationBarType.values[index];
          return SwitchListTile(
            title: Text(item.label),
            value: _navigationBarVisibility[index],
            onChanged: (value) {
              setState(() {
                _navigationBarVisibility[index] = value;
              });
              GStorage.setting.put(
                SettingBoxKey.navigationBarVisibility,
                _navigationBarVisibility,
              );
            },
          );
        },
      ),
    );
  }
}
