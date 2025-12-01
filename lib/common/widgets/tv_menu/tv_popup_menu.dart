// lib/common/widgets/tv_menu/tv_popup_menu.dart
import 'package:flutter/material.dart';

class TvPopupMenu extends StatefulWidget {
  final dynamic focusData; // 焦点对象数据，例如视频项
  final String contextType; // 上下文类型: 'videoCard' 或 'videoPlayer'
  final VoidCallback? onMoreOptions; // “更多选项”的回调

  const TvPopupMenu({
    required this.focusData,
    required this.contextType,
    this.onMoreOptions,
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
        return [const Text('无可用选项')];
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
      if (widget.onMoreOptions != null)
        ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: const Icon(Icons.more_horiz_outlined, size: 22),
          title: const Text('更多选项', style: TextStyle(fontSize: 16)),
          onTap: () {
            Navigator.of(context).pop();
            widget.onMoreOptions!();
          },
        ),
    ];
  }

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
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _buildMenuItems(),
        ),
      ),
    );
  }
}
