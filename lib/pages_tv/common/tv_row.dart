import 'package:material_ui/material_ui.dart';

class TVRow extends StatefulWidget {
  const TVRow({
    super.key,
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
    this.height = 220,
    this.itemWidth = 200,
    this.titleStyle,
    this.onMorePressed,
    this.onApproachingEnd,
    this.preloadItemCount = 4,
  });

  final String title;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double height;
  final double itemWidth;
  final TextStyle? titleStyle;
  final VoidCallback? onMorePressed;
  final VoidCallback? onApproachingEnd;
  final int preloadItemCount;

  @override
  State<TVRow> createState() => _TVRowState();
}

class _TVRowState extends State<TVRow> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients || widget.onApproachingEnd == null) {
      return;
    }
    final preloadExtent = (widget.itemWidth + 16) * widget.preloadItemCount;
    if (_scrollController.position.extentAfter <= preloadExtent) {
      widget.onApproachingEnd!();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                widget.title,
                style:
                    widget.titleStyle ??
                    theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (widget.onMorePressed != null) ...[
                const Spacer(),
                TextButton(
                  onPressed: widget.onMorePressed,
                  child: const Text('查看更多 >'),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: widget.height,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.itemCount,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: widget.itemBuilder,
          ),
        ),
      ],
    );
  }
}
