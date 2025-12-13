import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/utils/tv/focus_effects.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

class TVBottomNavBar extends StatelessWidget {
  final MainController mainController;
  final Widget Function({
    required NavigationBarType type,
    bool selected,
  }) buildIcon;

  const TVBottomNavBar({
    super.key,
    required this.mainController,
    required this.buildIcon,
  });

  Widget _buildFocusableIcon(
      BuildContext context, int index, NavigationBarType type,
      {bool selected = false}) {
    return DpadFocusable(
      autofocus: index == 0,
      isEntryPoint: index == 0,
      onTap: () => mainController.setIndex(index),
      builder: (context, hasFocus, child) =>
          TVFocusEffects.primary(context)(
        context,
        hasFocus,
        buildIcon(type: type, selected: selected),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DpadRegionScope(
      region: 'bottom_nav',
      child: BottomNavigationBar(
        currentIndex: mainController.selectedIndex.value,
        onTap: mainController.setIndex,
        iconSize: 16,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        items: mainController.navigationBars
            .asMap()
            .entries
            .map(
              (entry) => BottomNavigationBarItem(
                label: entry.value.label,
                icon: _buildFocusableIcon(context, entry.key, entry.value),
                activeIcon: _buildFocusableIcon(
                    context, entry.key, entry.value,
                    selected: true),
              ),
            )
            .toList(),
      ),
    );
  }
}
