import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/pages/main/controller.dart';
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
                icon: DpadFocusable(
                  autofocus: entry.key == 0,
                  isEntryPoint: entry.key == 0,
                  onFocus: () => mainController.setIndex(entry.key),
                  builder: (context, hasFocus) => buildIcon(type: entry.value),
                ),
                activeIcon: DpadFocusable(
                  autofocus: entry.key == 0,
                  isEntryPoint: entry.key == 0,
                  onFocus: () => mainController.setIndex(entry.key),
                  builder: (context, hasFocus) =>
                      buildIcon(type: entry.value, selected: true),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
