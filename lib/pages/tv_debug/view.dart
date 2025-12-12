import 'package:PiliPlus/pages/login/controller.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:PiliPlus/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class TVDebugPage extends StatefulWidget {
  const TVDebugPage({super.key});

  @override
  State<TVDebugPage> createState() => _TVDebugPageState();
}

class _TVDebugPageState extends State<TVDebugPage> {
  final List<FocusNode> _focusNodes = List.generate(11, (index) => FocusNode());
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _focusNodes[0].requestFocus();
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _focusedIndex = (_focusedIndex + 1) % _focusNodes.length;
          _focusNodes[_focusedIndex].requestFocus();
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _focusedIndex = (_focusedIndex - 1 + _focusNodes.length) % _focusNodes.length;
          _focusNodes[_focusedIndex].requestFocus();
        });
      } else if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
        // Handle selection
        _onItemTapped(_focusedIndex);
      }
    }
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Get.toNamed('/loginPage');
        break;
      case 1:
        Get.toNamed('/download');
        break;
      case 2:
        Get.toNamed('/history');
        break;
      case 3:
        Get.toNamed('/subscription');
        break;
      case 4:
        Get.toNamed('/later');
        break;
      case 5:
        Get.toNamed('/fav');
        break;
      case 6:
        MineController.onAnonymity();
        break;
      case 7:
        LoginPageController.switchAccountDialog(context);
        break;
      case 8:
        ThemeUtils.changeTheme();
        break;
      case 9:
        Get.toNamed('/setting');
        break;
      case 10:
        Get.toNamed('/search');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TV Debug Menu'),
      ),
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: _handleKeyEvent,
        child: ListView.builder(
          itemCount: 11,
          itemBuilder: (context, index) {
            return ListTile(
              focusNode: _focusNodes[index],
              onTap: () => _onItemTapped(index),
              leading: _getIcon(index),
              title: Text(_getText(index)),
              selected: _focusNodes[index].hasFocus,
            );
          },
        ),
      ),
    );
  }

  Icon _getIcon(int index) {
    switch (index) {
      case 0:
        return const Icon(Icons.add_circle_outline_outlined);
      case 1:
        return const Icon(Icons.download);
      case 2:
        return const Icon(Icons.history);
      case 3:
        return const Icon(Icons.subscriptions);
      case 4:
        return const Icon(Icons.watch_later);
      case 5:
        return const Icon(Icons.favorite);
      case 6:
        return const Icon(Icons.visibility_off);
      case 7:
        return const Icon(Icons.switch_account);
      case 8:
        return const Icon(Icons.brightness_4);
      case 9:
        return const Icon(Icons.settings);
      case 10:
        return const Icon(Icons.search);
      default:
        return const Icon(Icons.error);
    }
  }

  String _getText(int index) {
    switch (index) {
      case 0:
        return '添加账户';
      case 1:
        return '离线缓存';
      case 2:
        return '观看记录';
      case 3:
        return '我的订阅';
      case 4:
        return '稍后再看';
      case 5:
        return '我的收藏';
      case 6:
        return '进入无痕模式';
      case 7:
        return '设置账号模式';
      case 8:
        return '切换到浅色主题';
      case 9:
        return '设置';
      case 10:
        return '搜索';
      default:
        return '';
    }
  }
}
