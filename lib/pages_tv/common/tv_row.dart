import 'package:material_ui/material_ui.dart';

class TVRow extends StatelessWidget {
  const TVRow({
    super.key,
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
    this.height = 220,
    this.itemWidth = 200,
    this.titleStyle,
    this.onMorePressed,
  });

  final String title;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double height;
  final double itemWidth;
  final TextStyle? titleStyle;
  final VoidCallback? onMorePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 10),
          child: Row(
            children: [
              Text(
                title,
                style: titleStyle ??
                    theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF5F5F5),
                    ),
              ),
              if (onMorePressed != null) ...[
                const Spacer(),
                TextButton(
                  onPressed: onMorePressed,
                  child: const Text('查看更多 >'),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: itemCount,
            separatorBuilder: (_, __) => const SizedBox(width: 20),
            itemBuilder: itemBuilder,
          ),
        ),
      ],
    );
  }
}
