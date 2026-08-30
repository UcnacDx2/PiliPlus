import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:keframe/keframe.dart';
import 'package:PiliPlus/tv/adapters/tv_video_item.dart';
import 'package:PiliPlus/tv/adapters/tv_bilibili_facade.dart';
import '../../../widgets/tv_video_card.dart';
import '../../player/player_screen.dart';

class SearchResultsView extends StatefulWidget {
  final String query;
  final FocusNode? sidebarFocusNode;
  final VoidCallback onBackToKeyboard;

  const SearchResultsView({
    super.key,
    required this.query,
    this.sidebarFocusNode,
    required this.onBackToKeyboard,
  });

  @override
  State<SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends State<SearchResultsView> {
  List<TvVideoItem> _searchResults = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  // Pagination & Sorting State
  int _currentPage = 1;
  String _currentOrder = 'totalrank'; // totalrank, click, pubdate, dm
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isRefreshing = false; // 用于控制分帧渲染
  int _requestGeneration = 0;

  // Focus Management
  late final List<FocusNode> _sortFocusNodes;
  final Map<int, FocusNode> _videoFocusNodes = {};
  bool _shouldFocusFirstResult = false;

  final Map<String, String> _sortOptions = {
    'totalrank': '综合排序',
    'click': '最多播放',
    'pubdate': '最新发布',
    'dm': '最多弹幕',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _sortFocusNodes = List.generate(_sortOptions.length, (_) => FocusNode());
    // Initial search
    _searchVideos(reset: true, focusStart: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    for (final node in _sortFocusNodes) {
      node.dispose();
    }
    for (final node in _videoFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  // Exposed for Parent to check status or force refresh if needed
  // But generally self-contained.

  void _onScroll() {
    if (_scrollController.hasClients &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    }
  }

  FocusNode _getFocusNode(int index) {
    return _videoFocusNodes.putIfAbsent(index, () => FocusNode());
  }

  @override
  void didUpdateWidget(covariant SearchResultsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _searchVideos(reset: true, focusStart: true);
    }
  }

  void _maybeLoadMore(int index) {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    if (index < _searchResults.length - 8) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadMore();
    });
  }

  Future<void> _searchVideos({
    bool reset = true,
    bool focusStart = false,
  }) async {
    if (widget.query.isEmpty) return;

    final generation = reset ? ++_requestGeneration : _requestGeneration;
    final requestedPage = reset ? 1 : _currentPage + 1;
    final requestedOrder = _currentOrder;
    final requestedQuery = widget.query;

    if (reset) {
      if (focusStart) {
        _shouldFocusFirstResult = true;
      }
      setState(() {
        _isLoading = true;
        _isLoadingMore = false;
        _isRefreshing = true; // 开始刷新
        _currentPage = 1;
        _searchResults = [];
        _hasMore = true;
      });
    }

    List<TvVideoItem> results;
    try {
      results = await TvBilibiliFacade.searchVideos(
        requestedQuery,
        page: requestedPage,
        order: requestedOrder,
      );
    } catch (_) {
      if (mounted && generation == _requestGeneration) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _isRefreshing = false;
        });
      }
      return;
    }

    if (!mounted ||
        generation != _requestGeneration ||
        requestedOrder != _currentOrder ||
        requestedQuery != widget.query) {
      return;
    }
    setState(() {
      if (reset) {
        _searchResults = results;
      } else {
        final existingBvids = _searchResults.map((video) => video.bvid).toSet();
        _searchResults.addAll(
          results.where((video) => existingBvids.add(video.bvid)),
        );
      }

      _currentPage = requestedPage;
      _isLoading = false;
      _isLoadingMore = false;
      _isRefreshing = false; // 刷新完成

      if (results.length < 20) {
        _hasMore = false;
      }

      // Handle explicit focus request after build
      if (_shouldFocusFirstResult && _searchResults.isNotEmpty) {
        _shouldFocusFirstResult = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final firstNode = _getFocusNode(0);
          if (firstNode.canRequestFocus) {
            firstNode.requestFocus();
          }
        });
      }
    });
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    await _searchVideos(reset: false);
  }

  Future<void> _loadMoreAndFocus(int currentIndex) async {
    final targetIndex = currentIndex + 4;
    await _loadMore();
    if (!mounted || targetIndex >= _searchResults.length) return;
    _getFocusNode(targetIndex).requestFocus();
  }

  Future<void> _onVideoTap(TvVideoItem video, int index) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PlayerScreen(video: video)));
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _getFocusNode(index).requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    // 初始加载或完全重新加载时显示加载圈
    if (_isLoading && _currentPage == 1) {
      if (_currentOrder == 'totalrank' && _searchResults.isEmpty) {
        // 初始搜索加载
        content = const Center(child: CircularProgressIndicator());
      } else {
        // 切换排序或刷新 existing -> Loading overlaid but header visible
        content = const Center(child: CircularProgressIndicator());
      }
    } else if (_searchResults.isEmpty) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/tv_icons/search.svg',
              width: 80,
              height: 80,
              colorFilter: ColorFilter.mode(
                Colors.white.withValues(alpha: 0.2),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '未找到相关视频',
              style: TextStyle(color: Colors.white38, fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
              '按返回键重新搜索',
              style: TextStyle(color: Colors.white24, fontSize: 14),
            ),
          ],
        ),
      );
    } else {
      content = SizeCacheWidget(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(30, 140, 30, 40),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  // Keep enough vertical room for BaseTvCard's image,
                  // title and metadata rows. The previous ratio left the
                  // card a fraction of a pixel too short on TV constraints.
                  childAspectRatio: 320 / 280,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 30,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final video = _searchResults[index];

                  Widget buildCard(BuildContext cardContext) {
                    return TvVideoCard(
                      video: video,
                      // Use index 0 special focus node logic if needed, but handled globally
                      focusNode: _getFocusNode(index),
                      autofocus: index == 0,
                      disableCache: false,
                      onTap: () => _onVideoTap(video, index),
                      // 最左列按左键跳到侧边栏
                      onMoveLeft: (index % 4 == 0)
                          ? () => widget.sidebarFocusNode?.requestFocus()
                          : () => _getFocusNode(index - 1).requestFocus(),
                      // 强制向右导航
                      onMoveRight: (index + 1 < _searchResults.length)
                          ? () => _getFocusNode(index + 1).requestFocus()
                          : null,
                      // 严格按列向上移动（4个一行），最顶行跳到排序按钮
                      onMoveUp: index >= 4
                          ? () => _getFocusNode(index - 4).requestFocus()
                          : () {
                              final sortIdx = _sortOptions.keys
                                  .toList()
                                  .indexOf(_currentOrder);
                              if (sortIdx >= 0 &&
                                  sortIdx < _sortFocusNodes.length) {
                                _sortFocusNodes[sortIdx].requestFocus();
                              }
                            },
                      // 严格按列向下移动
                      onMoveDown: (index + 4 < _searchResults.length)
                          ? () => _getFocusNode(index + 4).requestFocus()
                          : _hasMore
                          ? () => _loadMoreAndFocus(index)
                          : null,
                      onBack: widget.onBackToKeyboard,
                      onFocus: () {
                        _maybeLoadMore(index);
                        if (!_scrollController.hasClients) return;

                        final RenderObject? object = cardContext
                            .findRenderObject();
                        if (object != null && object is RenderBox) {
                          final viewport = RenderAbstractViewport.of(object);
                          final offsetToReveal = viewport
                              .getOffsetToReveal(object, 0.0)
                              .offset;
                          final targetOffset = (offsetToReveal - 180).clamp(
                            0.0,
                            _scrollController.position.maxScrollExtent,
                          );

                          if ((_scrollController.offset - targetOffset).abs() >
                              50) {
                            _scrollController.animateTo(
                              targetOffset,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        }
                      },
                    );
                  }

                  // 只有刷新时使用分帧渲染
                  if (_isRefreshing) {
                    return FrameSeparateWidget(
                      index: index,
                      placeHolder: const Center(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      child: Builder(builder: (ctx) => buildCard(ctx)),
                    );
                  }

                  return Builder(builder: (ctx) => buildCard(ctx));
                }, childCount: _searchResults.length),
              ),
            ),
            if (_isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: content),
        // 固定标题栏 + 排序栏
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: const Color(0xFF121212),
            padding: const EdgeInsets.fromLTRB(30, 20, 30, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '搜索结果: ${widget.query}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: _sortOptions.entries.toList().asMap().entries.map((
                    mapEntry,
                  ) {
                    final idx = mapEntry.key;
                    final entry = mapEntry.value;
                    final isSelected = _currentOrder == entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: _SortButton(
                        label: entry.value,
                        isSelected: isSelected,
                        focusNode: _sortFocusNodes[idx],
                        onTap: () {
                          if (!isSelected) {
                            setState(() => _currentOrder = entry.key);
                            _searchVideos(reset: true);
                          }
                        },
                        onFocus: () {
                          // Focus movement should not start a network search.
                          // Confirm with select/enter, matching PiliPlus onTap.
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SortButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final VoidCallback onFocus;

  const _SortButton({
    required this.label,
    required this.isSelected,
    required this.focusNode,
    required this.onTap,
    required this.onFocus,
  });

  @override
  State<_SortButton> createState() => _SortButtonState();
}

class _SortButtonState extends State<_SortButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
        if (focused) widget.onFocus();
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? const Color(0xFFfb7299)
              : _isFocused
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: _isFocused
              ? Border.all(color: Colors.white, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: widget.isSelected || _isFocused
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
