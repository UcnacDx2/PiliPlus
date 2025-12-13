import 'package:PiliPlus/models/common/dynamic/dynamic_badge_mode.dart';
import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/utils/tv/focus_effects.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TVBottomNavBar extends StatelessWidget {
  final MainController mainController;
  final void Function(int) onDestinationSelected;

  const TVBottomNavBar({
    super.key,
    required this.mainController,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }

  Widget _buildIcon({
    required NavigationBarType type,
    bool selected = false,
  }) {
    final icon = selected ? type.selectIcon : type.icon;
    return type == NavigationBarType.dynamics
        ? Obx(
            () {
              final dynCount = mainController.dynCount.value;
              return Badge(
                isLabelVisible: dynCount > 0,
                label:
                    mainController.dynamicBadgeMode == DynamicBadgeMode.number
                        ? Text(dynCount.toString())
                        : null,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: icon,
              );
            },
          )
        : icon;
  }

  Widget _buildNavItem(
      BuildContext context, int index, NavigationBarType item, bool isSelected) {
    return Expanded(
      child: DpadFocusable(
        autofocus: index == 0,
        isEntryPoint: index == 0,
        region: 'bottom_nav',
        onTap: () => onDestinationSelected(index),
        builder: (context, hasFocus, child) {
          final color = isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface;
          return TVFocusEffects.primary(
            context,
            hasFocus,
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIcon(type: item, selected: isSelected),
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
