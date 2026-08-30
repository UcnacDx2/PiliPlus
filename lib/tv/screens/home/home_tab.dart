import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:PiliPlus/tv/adapters/tv_video_item.dart';
import 'package:keframe/keframe.dart';
import 'package:PiliPlus/tv/adapters/tv_account_facade.dart';
import 'package:PiliPlus/tv/adapters/tv_home_adapter.dart';
import 'package:PiliPlus/tv/adapters/tv_settings_facade.dart';
import '../../widgets/tv_video_card.dart';
import '../../widgets/time_display.dart';
import '../player/player_screen.dart';

class HomeTab extends StatefulWidget {
  final FocusNode? sidebarFocusNode;
  final VoidCallback? onFirstLoadComplete;
  final List<TvVideoItem>? preloadedVideos; // 接收预加载数据

  const HomeTab({
    super.key,
    this.sidebarFocusNode,
    this.onFirstLoadComplete,
    this.preloadedVideos,
  });

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  int _selectedCategoryIndex = 0;
  final ScrollController _scrollController = ScrollController();
  late List<HomeCategory> _categories;
  late List<FocusNode> _categoryFocusNodes;

  // 数据缓存
  final Map<int, List<TvVideoItem>> _categoryVideos = {};
  final Map<int, bool> _categoryLoading = {};
  final Map<int, bool> _categoryHasMore = {};
  final Map<int, int> _categoryPage = {};
  final Map<int, int> _categoryRefreshIdx = {};
  final Map<int, int> _categoryRequestGeneration = {};
  bool _firstLoadDone = false;
  bool _usedPreloadedData = false; // 标记是否使用了预加载数据
  bool _isRefreshing = false; // 标记是否正在刷新中（用于控制分帧渲染）
  // 每个视频卡片的 FocusNode
  final Map<int, FocusNode> _videoFocusNodes = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadCategoryOrder();
    _categoryFocusNodes = List.generate(_categories.length, (_) => FocusNode());

    // 【优化核心 1】如果有预加载数据，立即填充，且标记 loading 为 false
    if (widget.preloadedVideos != null && widget.preloadedVideos!.isNotEmpty) {
      _categoryVideos[0] = widget.preloadedVideos!;
      _categoryRefreshIdx[0] = 1;
      _categoryLoading[0] = false; // 关键：明确标记不加载
      _usedPreloadedData = true; // 标记使用了预加载数据
      _firstLoadDone = true;

      // 通知父组件（用于 Sidebar 焦点处理等）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onFirstLoadComplete?.call();
      });
    } else {
      // 只有没数据时，才自己去请求
      _loadVideosForCategory(0);
    }
  }

  // ... (省略 _loadCategoryOrder, dispose 等未改动代码) ...

  void _loadCategoryOrder() {
    final order = TvSettingsFacade.categoryOrder;
    final enabled = TvSettingsFacade.enabledCategories;
    _categories = order
        .where((name) => enabled.contains(name))
        .map(
          (name) => HomeCategory.values.firstWhere(
            (c) => c.name == name,
            orElse: () => HomeCategory.recommend,
          ),
        )
        .toList();
    if (_categories.isEmpty) _categories = [HomeCategory.recommend];
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    for (var node in _categoryFocusNodes) {
      node.dispose();
    }
    // 清理视频卡片的 FocusNode
    for (final node in _videoFocusNodes.values) {
      node.dispose();
    }
    _videoFocusNodes.clear();
    super.dispose();
  }

  // 获取或创建视频卡片的 FocusNode
  FocusNode _getFocusNode(int index) {
    return _videoFocusNodes.putIfAbsent(index, () => FocusNode());
  }

  List<TvVideoItem> get _currentVideos =>
      _categoryVideos[_selectedCategoryIndex] ?? [];
  bool get _isLoading => _categoryLoading[_selectedCategoryIndex] ?? false;
  bool get _hasMore => _categoryHasMore[_selectedCategoryIndex] ?? true;

  Future<void> _loadVideosForCategory(
    int categoryIndex, {
    bool refresh = false,
  }) async {
    if (_categoryLoading[categoryIndex] == true) return;

    // A refresh or a category switch can make an older request return late.
    // Keep each category's response stream isolated so stale pages cannot
    // append into the current feed.
    final generation =
        (_categoryRequestGeneration[categoryIndex] ?? 0) + 1;
    _categoryRequestGeneration[categoryIndex] = generation;

    final existingVideos = _categoryVideos[categoryIndex] ?? const <TvVideoItem>[];
    final isLoadMore = !refresh && existingVideos.isNotEmpty;
    final requestedPage = refresh
        ? 1
        : isLoadMore
        ? (_categoryPage[categoryIndex] ?? 1) + 1
        : 1;
    final requestedRefreshIdx = refresh
        ? 0
        : (_categoryRefreshIdx[categoryIndex] ?? 0);

    if (refresh) {
      _categoryPage[categoryIndex] = 1;
      _categoryRefreshIdx[categoryIndex] = 0;
      _categoryHasMore[categoryIndex] = true;
      setState(() {
        _categoryLoading[categoryIndex] = true;
        _categoryVideos[categoryIndex] = [];
        _isRefreshing = true; // 开始刷新
      });
    } else {
      setState(() => _categoryLoading[categoryIndex] = true);
    }

    final category = _categories[categoryIndex];
    List<TvVideoItem> videos;

    try {
      // 网络请求逻辑...
      switch (category) {
        case HomeCategory.recommend:
          videos = await TvHomeAdapter.loadRecommend(
            refreshIndex: requestedRefreshIdx,
          );
          break;
        case HomeCategory.popular:
          videos = await TvHomeAdapter.loadPopular(page: requestedPage);
          break;
        default:
          videos = await TvHomeAdapter.loadPopular(
            page: requestedPage,
          );
          break;
      }
    } catch (e) {
      videos = [];
    }

    if (!mounted ||
        generation != _categoryRequestGeneration[categoryIndex]) {
      return;
    }
    setState(() {
      // 插件过滤
      final filteredVideos = _filterVideos(videos);
      final existingBvids = existingVideos.map((video) => video.bvid).toSet();
      final uniqueVideos = isLoadMore
          ? filteredVideos
                .where((video) => existingBvids.add(video.bvid))
                .toList()
          : filteredVideos;

      if (!isLoadMore) {
        _categoryVideos[categoryIndex] = uniqueVideos;
      } else {
        _categoryVideos[categoryIndex] = [...existingVideos, ...uniqueVideos];
      }
      _categoryPage[categoryIndex] = requestedPage;
      if (category == HomeCategory.recommend && videos.isNotEmpty) {
        _categoryRefreshIdx[categoryIndex] = requestedRefreshIdx + 1;
      }
      // PiliPlus recommendation deliberately has no terminal page. Other
      // feeds use the API page size to stop repeated empty requests.
      _categoryHasMore[categoryIndex] =
          category == HomeCategory.recommend || videos.length >= 20;
      _categoryLoading[categoryIndex] = false;
      _isRefreshing = false; // 刷新完成

      if (!_firstLoadDone) {
        _firstLoadDone = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onFirstLoadComplete?.call();
        });
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoading || !_hasMore) return;
    if (_scrollController.position.extentAfter < 500) {
      _loadMore();
    }
  }

  void _maybeLoadMore(int index) {
    if (_isLoading || !_hasMore || index < _currentVideos.length - 8) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadMore();
    });
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    await _loadVideosForCategory(_selectedCategoryIndex);
  }

  Future<void> _loadMoreAndFocus(int currentIndex) async {
    final targetIndex = currentIndex + 4;
    await _loadMore();
    if (!mounted || targetIndex >= _currentVideos.length) return;
    _getFocusNode(targetIndex).requestFocus();
  }

  void _switchCategory(int index) {
    if (_selectedCategoryIndex == index) return;
    // 切换分类后不再是初始预加载状态
    _usedPreloadedData = false;
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    setState(() => _selectedCategoryIndex = index);
    if ((_categoryVideos[index] ?? []).isEmpty) _loadVideosForCategory(index);
  }

  void refreshCurrentCategory() {
    // 刷新后不再是初始预加载状态
    _usedPreloadedData = false;
    _loadVideosForCategory(_selectedCategoryIndex, refresh: true);
  }

  void _onVideoTap(TvVideoItem video) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => PlayerScreen(video: video)));
  }

  @override
  Widget build(BuildContext context) {
    // ... (Auth check logic 保持不变) ...
    if (!TvAccountFacade.isLoggedIn) {
      return const Center(child: Text("请先登录")); // 简写，保持你原有的 UI
    }

    // 判断是否是"启动后的第一屏数据"
    // 使用稳定的标志变量，避免 List 引用比较在 loadMore 后失效
    final bool isInitialLoad =
        _selectedCategoryIndex == 0 && _usedPreloadedData;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: FocusTraversalGroup(
            child: _isLoading && _currentVideos.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : SizeCacheWidget(
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(30, 100, 30, 80),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  childAspectRatio: 320 / 280,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 30,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final video = _currentVideos[index];

                              // 【优化】只有刷新时才使用交错加载
                              // 初始加载和从播放器返回时，图片已在缓存中，直接显示
                              final int? staggerIdx = _isRefreshing
                                  ? (index % 8)
                                  : null;

                              // 构建卡片内容
                              Widget buildCard(BuildContext ctx) {
                                return TvVideoCard(
                                  video: video,
                                  focusNode: _getFocusNode(index),
                                  autofocus: isInitialLoad && index == 0,
                                  disableCache: false,
                                  staggerIndex: staggerIdx,
                                  onTap: () => _onVideoTap(video),
                                  onMoveLeft: (index % 4 == 0)
                                      ? () => widget.sidebarFocusNode
                                            ?.requestFocus()
                                      : () => _getFocusNode(
                                          index - 1,
                                        ).requestFocus(),
                                  // 强制向右导航，避免 ScaleTransition 导致的误判
                                  onMoveRight:
                                      (index + 1 < _currentVideos.length)
                                      ? () => _getFocusNode(
                                          index + 1,
                                        ).requestFocus()
                                      : null,
                                  // 严格按列向上移动（4个一行），最顶行跳到分类标签
                                  onMoveUp: index >= 4
                                      ? () => _getFocusNode(
                                          index - 4,
                                        ).requestFocus()
                                      : () =>
                                            _categoryFocusNodes[_selectedCategoryIndex]
                                                .requestFocus(),
                                  // 严格按列向下移动
                                  onMoveDown:
                                      (index + 4 < _currentVideos.length)
                                      ? () => _getFocusNode(
                                          index + 4,
                                        ).requestFocus()
                                      : (_hasMore
                                            ? () => _loadMoreAndFocus(index)
                                            : null),
                                  onFocus: () {
                                    _maybeLoadMore(index);
                                    if (!_scrollController.hasClients) {
                                      return;
                                    }

                                    final RenderObject? object = ctx
                                        .findRenderObject();
                                    if (object != null && object is RenderBox) {
                                      final viewport =
                                          RenderAbstractViewport.of(object);
                                      final offsetToReveal = viewport
                                          .getOffsetToReveal(object, 0.0)
                                          .offset;
                                      final targetOffset =
                                          (offsetToReveal - 120).clamp(
                                            0.0,
                                            _scrollController
                                                .position
                                                .maxScrollExtent,
                                          );

                                      if ((_scrollController.offset -
                                                  targetOffset)
                                              .abs() >
                                          50) {
                                        _scrollController.animateTo(
                                          targetOffset,
                                          duration: const Duration(
                                            milliseconds: 500,
                                          ),
                                          curve: Curves.easeOutCubic,
                                        );
                                      }
                                    }
                                  },
                                );
                              }

                              // 只有刷新时使用分帧渲染，其他情况直接渲染
                              if (_isRefreshing) {
                                return FrameSeparateWidget(
                                  index: index,
                                  placeHolder: const Center(
                                    child: SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  child: Builder(builder: buildCard),
                                );
                              }

                              return Builder(builder: buildCard);
                            }, childCount: _currentVideos.length),
                          ),
                        ),
                        if (_isLoading && _currentVideos.isNotEmpty)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ),

        // ... (Header / Category Tabs 保持不变) ...
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 80,
          child: Container(
            color: const Color(0xFF121212),
            padding: const EdgeInsets.only(left: 30, right: 30, top: 20),
            child: FocusTraversalGroup(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_categories.length, (index) {
                    return _CategoryTab(
                      label: _categories[index].label,
                      isSelected: _selectedCategoryIndex == index,
                      focusNode: _categoryFocusNodes[index],
                      onTap: () => _switchCategory(index),
                      onFocus: () => _switchCategory(index),
                      onConfirm: refreshCurrentCategory,
                      onMoveLeft: index == 0
                          ? () => widget.sidebarFocusNode?.requestFocus()
                          : null,
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
        const Positioned(top: 20, right: 30, child: TimeDisplay()),
      ],
    );
  }

  List<TvVideoItem> _filterVideos(List<TvVideoItem> videos) {
    return videos;
  }
}

/// 分类标签组件
class _CategoryTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final VoidCallback onFocus;
  final VoidCallback onConfirm;
  final VoidCallback? onMoveLeft;

  const _CategoryTab({
    required this.label,
    required this.isSelected,
    required this.focusNode,
    required this.onTap,
    required this.onFocus,
    required this.onConfirm,
    this.onMoveLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Focus(
        focusNode: focusNode,
        onFocusChange: (f) => f ? onFocus() : null,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
                onMoveLeft != null) {
              onMoveLeft!();
              return KeyEventResult.handled;
            }
            // 确定键刷新当前分类
            if (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter) {
              onConfirm();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Builder(
          builder: (ctx) {
            final f = Focus.of(ctx).hasFocus;
            return GestureDetector(
              onTap: onTap,
              child: Container(
                // 紧凑的 padding 确保文字高度位置与普通标题接近
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                decoration: BoxDecoration(
                  color: f ? const Color(0xFFfb7299) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: f ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: f
                            ? Colors.white
                            : (isSelected
                                  ? const Color(0xFFfb7299)
                                  : Colors.grey),
                        fontSize: 20,
                        fontWeight: f || isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 3,
                      width: 20,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFfb7299)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 首页分类枚举
enum HomeCategory {
  recommend('推荐', 0),
  popular('热门', 0),
  anime('番剧', 13),
  movie('影视', 181),
  game('游戏', 4),
  knowledge('知识', 36),
  tech('科技', 188),
  music('音乐', 3),
  dance('舞蹈', 129),
  life('生活', 160),
  food('美食', 211),
  douga('动画', 1);

  const HomeCategory(this.label, this.tid);
  final String label;
  final int tid;
}
