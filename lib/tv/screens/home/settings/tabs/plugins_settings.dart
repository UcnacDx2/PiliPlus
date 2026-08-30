import 'package:flutter/material.dart';
import 'package:PiliPlus/tv/core/focus/focus_navigation.dart';

/// PiliPlus 没有对应的 BiliTV 插件中心能力，因此不伪造插件业务。
class PluginsSettingsTab extends StatelessWidget {
  const PluginsSettingsTab({super.key, this.onMoveUp, this.sidebarFocusNode});
  final VoidCallback? onMoveUp;
  final FocusNode? sidebarFocusNode;

  @override
  Widget build(BuildContext context) => TvFocusScope(
    pattern: FocusPattern.vertical,
    autofocus: true,
    exitLeft: sidebarFocusNode,
    onExitUp: onMoveUp,
    child: const Center(
      child: Text('当前版本不提供插件中心', style: TextStyle(color: Colors.white70)),
    ),
  );
}
