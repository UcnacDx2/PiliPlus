import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages_tv/common/tv_card.dart';
import 'package:PiliPlus/pages_tv/common/tv_focus_wrapper.dart';
import 'package:PiliPlus/pages_tv/common/tv_page.dart';
import 'package:PiliPlus/pages_tv/common/tv_row.dart';
import 'package:PiliPlus/pages_tv/home/controller.dart';
import 'package:PiliPlus/utils/id_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/utils/num_utils.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';

class TVHomePage extends StatefulWidget {
  const TVHomePage({super.key});

  @override
  State<TVHomePage> createState() => _TVHomePageState();
}

class _TVHomePageState extends State<TVHomePage> {
  final _controller = Get.put(TVHomeController());

  String? _viewText(dynamic item) {
    final view = item.stat?.view;
    return view is num && view > 0 ? NumUtils.numFormat(view) : null;
  }

  String? _durationText(dynamic item) {
    final duration = item.duration;
    return duration is num && duration > 0
        ? DurationUtils.formatDuration(duration)
        : null;
  }

  String? _publishText(dynamic item) {
    final stamp = item.pubdate;
    if (stamp is! num || stamp <= 0) return null;
    final date = DateTime.fromMillisecondsSinceEpoch(stamp.toInt() * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return TVPage(
      isRoot: true,
      child: Row(
        children: [
          _buildSidebar(context),
          Expanded(child: _buildContent(context)),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Obx(() {
      final expanded = _controller.sidebarExpanded.value;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: expanded ? 180 : 60,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
        ),
        child: Focus(
          onFocusChange: (hasFocus) {
            _controller.sidebarExpanded.value = hasFocus;
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 32, 8, 8),
            itemCount: TVHomeCategory.values.length,
            itemBuilder: (context, index) {
              final cat = TVHomeCategory.values[index];
              return Obx(() {
                final selected = _controller.selectedCategory.value == index;
                return TVFocusWrapper(
                  scaleFactor: 1.0,
                  borderRadius: 8,
                  borderWidth: 2,
                  onSelect: () => _onCategoryTap(index),
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFFB7299).withValues(alpha: 0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          cat.icon,
                          size: 24,
                          color: selected
                              ? const Color(0xFFFB7299)
                              : Colors.white60,
                        ),
                        if (expanded) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              cat.label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.white70,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              });
            },
          ),
        ),
      );
    });
  }

  void _onCategoryTap(int index) {
    _controller.selectedCategory.value = index;
    final cat = TVHomeCategory.values[index];
    switch (cat) {
      case TVHomeCategory.recommend:
      case TVHomeCategory.hot:
        break;
      case TVHomeCategory.live:
        Get.toNamed('/tvLive');
      case TVHomeCategory.pgc:
        Get.toNamed('/tvPgc');
      case TVHomeCategory.rank:
        Get.toNamed('/tvRank');
      case TVHomeCategory.dynamics:
        Get.toNamed('/tvDynamics');
      case TVHomeCategory.history:
        Get.toNamed('/tvHistory');
      case TVHomeCategory.later:
        Get.toNamed('/tvLater');
      case TVHomeCategory.favorite:
        Get.toNamed('/tvFavorite');
      case TVHomeCategory.search:
        Get.toNamed('/tvSearch');
      case TVHomeCategory.setting:
        Get.toNamed('/tvSetting');
    }
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildRcmdRow(),
          const SizedBox(height: 16),
          _buildHotRow(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRcmdRow() {
    return Obx(() {
      final state = _controller.rcmdState.value;
      return switch (state) {
        Loading() => const _LoadingRow(title: '推荐'),
        Success(:final response) => response != null && response.isNotEmpty
            ? TVRow(
                title: '推荐',
                itemCount: response.length,
                itemBuilder: (ctx, i) {
                  final item = response[i];
                  return TVCard(
                    title: item.title ?? '',
                    subtitle: item.owner?.name ?? '',
                    coverUrl: item.cover,
                    firstFrameUrl: item.firstFrame,
                    bvid: item.bvid,
                    cid: item.cid,
                    viewText: _viewText(item),
                    durationText: _durationText(item),
                    ownerText: item.owner?.name,
                    publishText: _publishText(item),
                    autoFocus: i == 0,
                    onSelect: () => _navigateToVideo(item),
                  );
                },
              )
            : const _EmptyRow(title: '推荐'),
        Error(:final errMsg) => _ErrorRow(title: '推荐', message: errMsg),
      };
    });
  }

  Widget _buildHotRow() {
    return Obx(() {
      final state = _controller.hotState.value;
      return switch (state) {
        Loading() => const _LoadingRow(title: '热门'),
        Success(:final response) => response != null && response.isNotEmpty
            ? TVRow(
                title: '热门',
                itemCount: response.length,
                itemBuilder: (ctx, i) {
                  final item = response[i];
                  return TVCard(
                    title: item.title ?? '',
                    subtitle: item.owner?.name ?? '',
                    coverUrl: item.cover,
                    firstFrameUrl: item.firstFrame,
                    bvid: item.bvid,
                    cid: item.cid,
                    viewText: _viewText(item),
                    durationText: _durationText(item),
                    ownerText: item.owner?.name,
                    publishText: _publishText(item),
                    onSelect: () => _navigateToVideo(item),
                  );
                },
              )
            : const _EmptyRow(title: '热门'),
        Error(:final errMsg) => _ErrorRow(title: '热门', message: errMsg),
      };
    });
  }

  void _navigateToVideo(dynamic item) {
    final int? aid = item.aid;
    final String? bvid = item.bvid;
    final int? cid = item.cid;
    if (cid != null) {
      PageUtils.toVideoPage(
        aid: aid ?? (bvid != null ? IdUtils.bv2av(bvid) : null),
        bvid: bvid ?? (aid != null ? IdUtils.av2bv(aid) : null),
        cid: cid,
        cover: item.cover,
        title: item.title,
      );
    }
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return TVRow(
      title: title,
      itemCount: 6,
      itemBuilder: (ctx, i) => SizedBox(
        width: 200,
        height: 170,
        child: Card(
          child: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return TVRow(
      title: title,
      itemCount: 1,
      itemBuilder: (ctx, i) => const SizedBox(
        width: 200,
        height: 170,
        child: Card(child: Center(child: Text('暂无数据'))),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.title, this.message});
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return TVRow(
      title: title,
      itemCount: 1,
      itemBuilder: (ctx, i) => SizedBox(
        width: 200,
        height: 170,
        child: Card(child: Center(child: Text(message ?? '加载失败'))),
      ),
    );
  }
}
