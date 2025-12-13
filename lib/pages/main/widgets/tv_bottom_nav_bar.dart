import 'package:PiliPlus/utils/tv/focus_effects.dart';
import 'package:flutter/material.dart';
import 'package:dpad/dpad.dart';

class TVBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  const TVBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DpadRegionScope(
      region: 'bottom_nav',
      child: Container(
        height: 80,
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(destinations.length, (index) {
            final destination = destinations[index];
            final isSelected = selectedIndex == index;
            return DpadFocusable(
              autofocus: index == 0,
              isEntryPoint: index == 0,
              onClick: () => onDestinationSelected(index),
              builder: (context, hasFocus) {
                return TVFocusEffects.scaleAndGlow(
                  context,
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      isSelected || hasFocus
                          ? destination.selectedIcon
                          : destination.icon,
                      const SizedBox(height: 4),
                      Text(
                        destination.label,
                        style: TextStyle(
                          color: isSelected || hasFocus
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  hasFocus,
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
