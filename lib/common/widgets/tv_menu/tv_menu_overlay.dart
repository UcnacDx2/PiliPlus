import 'package:PiliPlus/services/tv_menu/models/menu_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TV Menu overlay widget that displays menu items in a focusable grid
class TvMenuOverlay extends StatefulWidget {
  final List<TvMenuItem> items;
  final VoidCallback onDismiss;

  const TvMenuOverlay({
    super.key,
    required this.items,
    required this.onDismiss,
  });

  @override
  State<TvMenuOverlay> createState() => _TvMenuOverlayState();
}

class _TvMenuOverlayState extends State<TvMenuOverlay> {
  int _focusedIndex = 0;
  List<TvMenuItem>? _subMenuItems;
  int _subFocusedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: 280,
          margin: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _subMenuItems != null
                ? _buildSubMenu(colorScheme)
                : _buildMainMenu(colorScheme),
          ),
        ),
      ),
    );
  }

  Widget _buildMainMenu(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '菜单',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final isFocused = index == _focusedIndex;
              return _buildMenuItem(item, isFocused, colorScheme, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubMenu(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.arrow_back, size: 20, color: colorScheme.onSurface),
              const SizedBox(width: 8),
              Text(
                widget.items[_focusedIndex].label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _subMenuItems!.length,
            itemBuilder: (context, index) {
              final item = _subMenuItems![index];
              final isFocused = index == _subFocusedIndex;
              return _buildMenuItem(item, isFocused, colorScheme, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    TvMenuItem item,
    bool isFocused,
    ColorScheme colorScheme,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isFocused
            ? colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        enabled: item.enabled,
        leading: item.icon != null
            ? Icon(
                item.icon,
                size: 22,
                color: isFocused
                    ? colorScheme.onPrimaryContainer
                    : item.enabled
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.38),
              )
            : null,
        title: Text(
          item.label,
          style: TextStyle(
            fontSize: 15,
            color: isFocused
                ? colorScheme.onPrimaryContainer
                : item.enabled
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withValues(alpha: 0.38),
          ),
        ),
        trailing: item.hasChildren
            ? Icon(
                Icons.chevron_right,
                color: isFocused
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface.withValues(alpha: 0.6),
              )
            : null,
        onTap: item.enabled ? () => _onItemTap(item) : null,
      ),
    );
  }

  void _onItemTap(TvMenuItem item) {
    if (item.hasChildren) {
      setState(() {
        _subMenuItems = item.children;
        _subFocusedIndex = 0;
      });
    } else if (item.onTap != null) {
      widget.onDismiss();
      item.onTap!();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final items = _subMenuItems ?? widget.items;
    final focusIndex = _subMenuItems != null ? _subFocusedIndex : _focusedIndex;
    final maxIndex = items.length - 1;

    // Navigation
    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_subMenuItems != null) {
          _subFocusedIndex = (_subFocusedIndex - 1).clamp(0, maxIndex);
        } else {
          _focusedIndex = (_focusedIndex - 1).clamp(0, maxIndex);
        }
      });
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (_subMenuItems != null) {
          _subFocusedIndex = (_subFocusedIndex + 1).clamp(0, maxIndex);
        } else {
          _focusedIndex = (_focusedIndex + 1).clamp(0, maxIndex);
        }
      });
      return KeyEventResult.handled;
    }

    // Enter submenu or select item
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.arrowRight) {
      final item = items[focusIndex];
      if (item.enabled) {
        _onItemTap(item);
      }
      return KeyEventResult.handled;
    }

    // Go back from submenu or close menu
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack) {
      if (_subMenuItems != null) {
        setState(() {
          _subMenuItems = null;
          _subFocusedIndex = 0;
        });
      } else {
        widget.onDismiss();
      }
      return KeyEventResult.handled;
    }

    // Close menu with menu key
    if (key == LogicalKeyboardKey.contextMenu) {
      widget.onDismiss();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}
