import 'package:flutter/material.dart';
import '../../../../core/focus/focus_navigation.dart';

/// A TV-friendly editable setting row.  The value is edited in a dialog,
/// while vertical navigation stays consistent with the other settings rows.
class SettingTextRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final String value;
  final VoidCallback onSelect;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final FocusNode? sidebarFocusNode;
  final bool autofocus;
  final bool isFirst;
  final bool isLast;

  const SettingTextRow({
    super.key,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onSelect,
    this.onMoveUp,
    this.onMoveDown,
    this.sidebarFocusNode,
    this.autofocus = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocusScope(
      pattern: FocusPattern.vertical,
      autofocus: autofocus,
      exitLeft: sidebarFocusNode,
      onExitUp: isFirst ? onMoveUp : null,
      onExitDown: isLast ? onMoveDown : null,
      isFirst: isFirst,
      isLast: isLast,
      onSelect: onSelect,
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: isFocused
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isFocused
                  ? Border.all(color: const Color(0xFFfb7299), width: 2)
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: isFocused ? Colors.white : Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            subtitle!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isFocused
                        ? const Color(0xFFfb7299)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    value.isEmpty ? '未设置' : value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isFocused ? Colors.white : Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: isFocused ? Colors.white : Colors.white54,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
