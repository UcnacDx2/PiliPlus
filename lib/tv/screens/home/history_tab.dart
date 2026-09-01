import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/rendering.dart';
import 'package:PiliPlus/tv/adapters/tv_video_item.dart';
import 'package:PiliPlus/tv/adapters/tv_bilibili_facade.dart';
import 'package:keframe/keframe.dart';
import 'package:PiliPlus/tv/adapters/tv_account_facade.dart';
import '../../widgets/history_video_card.dart';
import '../../widgets/time_display.dart';
import '../player/player_screen.dart';

/// 观看历史 Tab
class HistoryTab extends StatefulWidget {
  final FocusNode? sidebarFocusNode;
  final bool isVisible;

  const HistoryTab({super.key, this.sidebarFocusNode, this.isVisible = false});

  @override
  State<HistoryTab> createState() => HistoryTabState();
}

class HistoryTabState extends State<HistoryTab> {
  List<TvVideoItem> _videos = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _viewAt = 0;
  int _max = 0;
  final ScrollController _scrollController = ScrollController();
  bool _hasLoaded = false;
  bool _isRefreshing = false; // 标记是否正在刷新中（用于控制分帧渲染）
  String? _loadError;
  // 每个视频卡片的 FocusNode
  final Map<int, FocusNode> _videoFocusNodes = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.isVisible) {
      _hasLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadHistory(reset: true);
      });
    }
  }

  @override
  void didUpdateWidget(HistoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible && !_hasLoaded) {
      _hasLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadHistory(reset: true);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    // 清理所有视频卡片的 FocusNode
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

  void _onScroll() {
    if (!_isLoading && !_isLoadingMore && _hasMore) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadHistory(reset: false);
      }
    }
  }

  /// 公开的刷新方法 - 供外部调用
  void refresh() {
    _hasLoaded = true; // 标记已加载，避免切换时重复加载
    _loadHistory(reset: true);
  }

  Future<void> _loadHistory({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _isRefreshing = true; // 开始刷新
        _videos = [];
        _viewAt = 0;
        _max = 0;
        _hasMore = true;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final result = await TvBilibiliFacade.getHistory(
        ps: 30,
        viewAt: reset ? 0 : _viewAt,
        max: reset ? 0 : _max,
      );

      if (!mounted) return;

      if (result['succeeded'] != true) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _isRefreshing = false;
          _loadError = result['error']?.toString() ?? '历史加载失败，请再次刷新';
        });
        return;
      }

      final newVideos = (result['list'] as List<TvVideoItem>?) ?? const [];
      final nextViewAt = result['viewAt'] as int? ?? 0;
      final nextMax = result['max'] as int? ?? 0;
      final hasMore = result['hasMore'] as bool? ?? false;

      setState(() {
        _loadError = null;
        if (reset) {
          _videos = newVideos;
          _isLoading = false;
          _isRefreshing = false; // 刷新完成
        } else {
          // 去重：过滤掉已存在的视频
          final existingBvids = _videos.map((v) => v.bvid).toSet();
          final uniqueNewVideos = newVideos
              .where((v) => !existingBvids.contains(v.bvid))
              .toList();
          _videos.addAll(uniqueNewVideos);
          _isLoadingMore = false;
        }

        _viewAt = nextViewAt;
        _max = nextMax;

        if (!hasMore || newVideos.isEmpty) {
          _hasMore = false;
        }
      });
    } catch (error) {
      debugPrint('TV history load failed: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _isRefreshing = false;
        _loadError = error.toString();
      });
    }
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
    // 未登录提示
    if (!TvAccountFacade.isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '请先登录',
              style: TextStyle(color: Colors.white70, fontSize: 20),
            ),
            const SizedBox(height: 10),
            const Text(
              '登录后可查看观看历史',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_isLoading && _videos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _videos.isEmpty) {
      return Center(
        child: Text(
          '历史加载失败\n请稍后重试',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 20),
        ),
      );
    }

    if (_videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/tv_icons/history.svg',
              width: 80,
              height: 80,
              colorFilter: ColorFilter.mode(
                Colors.white.withValues(alpha: 0.3),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '暂无观看历史',
              style: TextStyle(color: Colors.white70, fontSize: 20),
            ),
          ],
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 视频网格
        Positioned.fill(
          child: SizeCacheWidget(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(30, 80, 30, 80),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 320 / 280,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 30,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final video = _videos[index];

                      // 构建卡片内容
                      Widget buildCard(BuildContext ctx) {
                        return HistoryVideoCard(
                          video: video,
                          focusNode: _getFocusNode(index),
                          onTap: () => _onVideoTap(video, index),
                          // 最左列按左键跳到侧边栏
                          onMoveLeft: (index % 4 == 0)
                              ? () => widget.sidebarFocusNode?.requestFocus()
                              : () => _getFocusNode(index - 1).requestFocus(),
                          // 强制向右导航
                          onMoveRight: (index + 1 < _videos.length)
                              ? () => _getFocusNode(index + 1).requestFocus()
                              : null,
                          // 严格按列向上移动（4个一行）
                          onMoveUp: index >= 4
                              ? () => _getFocusNode(index - 4).requestFocus()
                              : () {}, // 最顶行为无效输入
                          // 严格按列向下移动
                          onMoveDown: (index + 4 < _videos.length)
                              ? () => _getFocusNode(index + 4).requestFocus()
                              : null,
                          onFocus: () {
                            if (!_scrollController.hasClients) return;

                            final RenderObject? object = ctx.findRenderObject();
                            if (object != null && object is RenderBox) {
                              final viewport = RenderAbstractViewport.of(
                                object,
                              );
                              final offsetToReveal = viewport
                                  .getOffsetToReveal(object, 0.0)
                                  .offset;
                              final targetOffset = (offsetToReveal - 120).clamp(
                                0.0,
                                _scrollController.position.maxScrollExtent,
                              );

                              if ((_scrollController.offset - targetOffset)
                                      .abs() >
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

                      // 只有在刷新时才使用分帧渲染，否则直接渲染
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
                          child: Builder(builder: buildCard),
                        );
                      }

                      // 非刷新状态（从播放器返回）直接渲染
                      return Builder(builder: buildCard);
                    }, childCount: _videos.length),
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
          ),
        ),
        // 固定标题
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: const Color(0xFF121212),
            padding: const EdgeInsets.fromLTRB(30, 20, 30, 15),
            child: const Text(
              '观看历史',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // 右上角时间
        const Positioned(top: 20, right: 30, child: TimeDisplay()),
      ],
    );
  }
}
