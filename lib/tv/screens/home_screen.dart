import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:PiliPlus/tv/adapters/tv_video_item.dart';
import 'home/home_tab.dart';
import 'home/history_tab.dart';
import 'home/search_tab.dart';
import 'home/login_tab.dart';
import 'home/dynamic_tab.dart';
import 'home/live_tab.dart';
import '../widgets/tv_focusable_item.dart';
import 'package:PiliPlus/tv/adapters/tv_account_facade.dart';
import 'package:PiliPlus/tv/adapters/tv_settings_facade.dart';

/// 主页框架 - 完全按照 animeone_tv_app 的方式
class HomeScreen extends StatefulWidget {
  final List<TvVideoItem>? preloadedVideos;

  const HomeScreen({super.key, this.preloadedVideos});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 1; // 默认选中首页
  DateTime? _lastBackPressed;
  DateTime? _backFromSearchHandled; // 防止搜索键盘返回键重复处理

  // Tab 顺序: 搜索、首页、动态、历史、直播、登录
  final List<String> _tabIcons = [
    'assets/tv_icons/search.svg',
    'assets/tv_icons/home.svg',
    'assets/tv_icons/dynamic.svg',
    'assets/tv_icons/history.svg',
    'assets/tv_icons/live.svg', // 新增直播图标
    'assets/tv_icons/user.svg',
  ];

  late List<FocusNode> _sideBarFocusNodes;

  // 用于访问 SearchTab 状态
  final GlobalKey<SearchTabState> _searchTabKey = GlobalKey<SearchTabState>();
  // 用于访问 HomeTab 状态 (刷新功能)
  final GlobalKey<HomeTabState> _homeTabKey = GlobalKey<HomeTabState>();
  // 动态和历史记录 Tab - 每次切换时刷新
  final GlobalKey<DynamicTabState> _dynamicTabKey =
      GlobalKey<DynamicTabState>();
  final GlobalKey<HistoryTabState> _historyTabKey =
      GlobalKey<HistoryTabState>();
  final GlobalKey<LoginTabState> _loginTabKey = GlobalKey<LoginTabState>();
  // 直播 Tab
  final GlobalKey<LiveTabState> _liveTabKey = GlobalKey<LiveTabState>();

  @override
  void initState() {
    super.initState();
    _sideBarFocusNodes = List.generate(
      _tabIcons.length,
      (index) => FocusNode(),
    );

    // 可以在这里做一些初始化，但不再强制请求 sidebar 焦点
    // 而是等待 HomeTab 加载完成后请求内容焦点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 确保 Highlight 策略正确
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
    });
  }

  // 激活焦点系统
  void _activateFocusSystem() {
    if (!mounted) return;

    // 强制设置高亮策略为传统模式 (TV 模式)
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;

    final currentFocusNode = _sideBarFocusNodes[_selectedTabIndex];
    if (!currentFocusNode.hasFocus) {
      currentFocusNode.requestFocus();
    }

    // 首页加载完成后，延迟后台预加载动态和历史记录
    _preloadOtherTabs();
  }

  // 后台预加载动态和历史记录
  void _preloadOtherTabs() {
    // 延迟 500ms 后开始预加载，避免影响首页渲染
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      // 预加载动态页面（如果用户已登录）
      if (TvAccountFacade.isLoggedIn) {
        _dynamicTabKey.currentState?.refresh();
      }
    });

    // 再延迟 1 秒后预加载历史记录
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      // 预加载历史记录（如果用户已登录）
      if (TvAccountFacade.isLoggedIn) {
        _historyTabKey.currentState?.refresh();
      }
    });

    // 预加载直播
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      _liveTabKey.currentState?.refresh();
    });
  }

  @override
  void dispose() {
    for (var node in _sideBarFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleSideBarTap(int index) {
    // 如果已经在当前标签，点击刷新
    if (index == _selectedTabIndex) {
      if (index == 1) {
        _homeTabKey.currentState?.refreshCurrentCategory();
      } else if (index == 2) {
        _dynamicTabKey.currentState?.refresh();
      } else if (index == 3) {
        _historyTabKey.currentState?.refresh();
      } else if (index == 4) {
        _liveTabKey.currentState?.refresh();
      }
      return;
    }

    setState(() => _selectedTabIndex = index);
    _sideBarFocusNodes[index].requestFocus();

    // 动态和历史记录、直播标签: 切换时也刷新
    if (index == 2) {
      _dynamicTabKey.currentState?.refresh();
    } else if (index == 3) {
      _historyTabKey.currentState?.refresh();
    } else if (index == 4) {
      _liveTabKey.currentState?.refresh();
    }
  }

  void _refreshCurrentTab() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 检查是否刚刚被搜索键盘的返回键处理过
        if (_backFromSearchHandled != null &&
            DateTime.now().difference(_backFromSearchHandled!) <
                const Duration(milliseconds: 200)) {
          return; // 已被处理，忽略
        }

        // 只有在主页标签 (index=1) 才显示退出提示
        // 搜索标签需要特殊处理：结果界面返回键盘，键盘返回主页
        if (_selectedTabIndex == 0) {
          // 搜索标签
          final handled = _searchTabKey.currentState?.handleBack() ?? false;
          if (!handled) {
            // 键盘界面 → 回主页
            setState(() => _selectedTabIndex = 1);
            _sideBarFocusNodes[1].requestFocus();
          }
          return;
        }

        if (_selectedTabIndex != 1) {
          // 其他标签（历史、直播、登录）按返回键都回到主页
          setState(() => _selectedTabIndex = 1);
          _sideBarFocusNodes[1].requestFocus();
          return;
        }

        // 主页标签：按两次退出
        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;

          Fluttertoast.showToast(
            msg: '再按一次返回键退出应用',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.black.withValues(alpha: 0.7),
            textColor: Colors.white,
            fontSize: 18.0,
          );
        } else {
          // 退出前清理缓存
          await TvSettingsFacade.clearImageCache();
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧边栏
            Expanded(
              flex: 8,
              child: Container(
                color: const Color(0xFF1E1E1E),
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List.generate(_tabIcons.length, (index) {
                    final isUserTab = index == 5; // User tab is now at index 5
                    final avatarUrl = isUserTab && TvAccountFacade.isLoggedIn
                        ? TvAccountFacade.face
                        : null;

                    return TvFocusableItem(
                      iconPath: _tabIcons[index],
                      avatarUrl: avatarUrl,
                      isSelected: _selectedTabIndex == index,
                      focusNode: _sideBarFocusNodes[index],
                      onFocus: () {
                        // 焦点移动时只切换标签页，不刷新任何内容
                        setState(() => _selectedTabIndex = index);
                      },
                      onTap: () => _handleSideBarTap(index), // 按确定键才刷新
                      // 用户标签按右键导航到设置分类标签
                      onMoveRight: index == 4
                          ? () {
                              _liveTabKey.currentState?.focusFirstItem();
                            }
                          : isUserTab && TvAccountFacade.isLoggedIn
                          ? () =>
                                _loginTabKey.currentState?.focusFirstCategory()
                          : null,
                    );
                  }),
                ),
              ),
            ),
            // 右侧内容区
            Expanded(flex: 92, child: _buildRightContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildRightContent() {
    // 使用 IndexedStack 保持所有 Tab 状态，避免切换时重新加载
    return IndexedStack(
      index: _selectedTabIndex,
      children: [
        // 0: 搜索
        SearchTab(
          key: _searchTabKey,
          sidebarFocusNode: _sideBarFocusNodes[0],
          onBackToHome: () {
            _backFromSearchHandled = DateTime.now(); // 记录处理时间
            setState(() => _selectedTabIndex = 1);
            _sideBarFocusNodes[1].requestFocus();
          },
        ),
        // 1: 首页
        HomeTab(
          key: _homeTabKey,
          sidebarFocusNode: _sideBarFocusNodes[1],
          onFirstLoadComplete: _activateFocusSystem,
          preloadedVideos: widget.preloadedVideos,
        ),
        // 2: 动态
        DynamicTab(
          key: _dynamicTabKey,
          sidebarFocusNode: _sideBarFocusNodes[2],
          isVisible: _selectedTabIndex == 2,
        ),
        // 3: 历史
        HistoryTab(
          key: _historyTabKey,
          sidebarFocusNode: _sideBarFocusNodes[3],
          isVisible: _selectedTabIndex == 3,
        ),
        // 4: 直播
        LiveTab(
          key: _liveTabKey,
          sidebarFocusNode: _sideBarFocusNodes[4],
          isVisible: _selectedTabIndex == 4,
        ),
        // 5: 登录/用户
        LoginTab(
          key: _loginTabKey,
          sidebarFocusNode: _sideBarFocusNodes[5],
          onLoginSuccess: _refreshCurrentTab,
        ),
      ],
    );
  }
}
