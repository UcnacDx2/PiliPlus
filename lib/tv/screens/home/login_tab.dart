import 'package:flutter/material.dart';
import 'package:PiliPlus/tv/adapters/tv_account_facade.dart';
import 'login/login_view.dart';
import 'settings/settings_view.dart';

/// 登录 Tab / 用户设置 Tab
class LoginTab extends StatefulWidget {
  final FocusNode? sidebarFocusNode;
  final VoidCallback? onLoginSuccess;

  const LoginTab({super.key, this.sidebarFocusNode, this.onLoginSuccess});

  @override
  State<LoginTab> createState() => LoginTabState();
}

class LoginTabState extends State<LoginTab> {
  final GlobalKey<SettingsViewState> _settingsKey =
      GlobalKey<SettingsViewState>();

  /// 请求第一个分类标签的焦点（用于从侧边栏导航）
  void focusFirstCategory() {
    if (TvAccountFacade.isLoggedIn) {
      _settingsKey.currentState?.focusFirstCategory();
    }
  }

  void _handleLoginSuccess() {
    setState(() {}); // Refresh to show SettingsView
    widget.onLoginSuccess?.call();
  }

  Future<void> _handleLogout() async {
    await TvAccountFacade.logout();
    if (mounted) {
      setState(() {}); // Refresh to show LoginView
    }
  }

  @override
  Widget build(BuildContext context) {
    if (TvAccountFacade.isLoggedIn) {
      return SettingsView(
        key: _settingsKey,
        sidebarFocusNode: widget.sidebarFocusNode,
        onLogout: _handleLogout,
      );
    }

    return LoginView(
      sidebarFocusNode: widget.sidebarFocusNode,
      onLoginSuccess: _handleLoginSuccess,
    );
  }
}
