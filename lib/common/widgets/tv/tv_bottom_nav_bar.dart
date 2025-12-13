import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/utils/tv/focus_effects.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      child: Container(
        height: kBottomNavigationBarHeight,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
        ),
        child: Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: mainController.navigationBars
                .asMap()
                .entries
                .map(
                  (entry) => _buildNavItem(
                    context,
                    entry.key,
                    entry.value,
                    mainController.selectedIndex.value == entry.key,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, int index, NavigationBarType item, bool isSelected) {
    return Expanded(
      child: DpadFocusable(
        autofocus: index == 0,
        isEntryPoint: index == 0,
        onTap: () => mainController.setIndex(index),
        builder: (context, hasFocus, child) {
          final color = isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface;
          return TVFocusEffects.primary(context)(
            context,
            hasFocus,
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildIcon(type: item, selected: isSelected),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
