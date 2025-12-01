// lib/common/widgets/tv_menu/tv_popup_menu.dart
import 'package:flutter/material.dart';

class TvPopupMenu extends StatefulWidget {
  final dynamic focusData; // 焦点对象数据，例如视频项
  final String contextType; // 上下文类型: 'videoCard' 或 'videoPlayer'

  const TvPopupMenu({
    this.focusData,
    required this.contextType,
    super.key,
  });

  @override
  State<TvPopupMenu> createState() => _TvPopupMenuState();
}

class _TvPopupMenuState extends State<TvPopupMenu> {
  // 根据上下文类型构建不同的菜单项列表
  List<Widget> _buildMenuItems() {
    switch (widget.contextType) {
      case 'videoCard':
        return _buildVideoCardMenu();
      case 'videoPlayer':
        return _buildVideoPlayerMenu();
      default:
        return _buildDefaultMenu();
    }
  }

  // 构建视频卡片的菜单项
  List<Widget> _buildVideoCardMenu() {
    // final videoItem = widget.focusData; // 可根据 focusData 获取具体数据
    return [
      ListTile(
        autofocus: true, // 关键：默认聚焦第一项，便于 D-pad 导航
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const Icon(Icons.play_arrow_outlined, size: 22),
        title: const Text('立即播放', style: TextStyle(fontSize: 16)),
        onTap: () {
          // TODO: 实现播放逻辑
          Navigator.of(context).pop();
        },
      ),
      ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const Icon(Icons.watch_later_outlined, size: 22),
        title: const Text('稍后再看', style: TextStyle(fontSize: 16)),
        onTap: () {
          // TODO: 实现添加到“稍后再看”的逻辑
          Navigator.of(context).pop();
        },
      ),
      // 可根据需要添加更多选项...
    ];
  }

  // 构建视频播放器的菜单项
  List<Widget> _buildVideoPlayerMenu() {
    // final videoDetail = widget.focusData; // 可根据 focusData 获取具体数据
    return [
      ListTile(
        autofocus: true, // 关键：默认聚焦第一项
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const Icon(Icons.settings_outlined, size: 22),
        title: const Text('播放设置', style: TextStyle(fontSize: 16)),
        onTap: () {
          // TODO: 显示播放器设置
          Navigator.of(context).pop();
        },
      ),
      ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const Icon(Icons.subtitles_outlined, size: 22),
        title: const Text('字幕设置', style: TextStyle(fontSize: 16)),
        onTap: () {
          // TODO: 显示字幕设置
          Navigator.of(context).pop();
        },
      ),
      // 可根据需要添加更多选项...
    ];
  }

  // 构建默认菜单项
  List<Widget> _buildDefaultMenu() {
    return [
      ListTile(
        autofocus: true,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const Icon(Icons.exit_to_app, size: 22),
        title: const Text('退出程序', style: TextStyle(fontSize: 16)),
        onTap: () {
          // TODO: 实现退出程序逻辑
          Navigator.of(context).pop();
        },
      ),
      ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const Icon(Icons.account_circle_outlined, size: 22),
        title: const Text('添加账户', style: TextStyle(fontSize: 16)),
        onTap: () {
          // TODO: 实现添加账户逻辑
          Navigator.of(context).pop();
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      // 关键修正 1: 添加 clipBehavior，确保内容在圆角边界被正确裁剪
      clipBehavior: Clip.hardEdge,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      // 关键修正 2: 调整 contentPadding，提供合适的内边距
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      // 关键修正 3: 使用 Column + mainAxisSize.min 替换 ListView
      content: Column(
        mainAxisSize: MainAxisSize.min, // 核心：让对话框高度自适应内容
        children: _buildMenuItems(),
      ),
    );
  }
}
