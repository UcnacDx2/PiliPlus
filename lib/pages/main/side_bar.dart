import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models/common/dynamic/dynamic_badge_mode.dart';
import 'package:PiliPlus/models/common/image_type.dart';
import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/pages/home/view.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class MainSideBar extends StatefulWidget {
  final MainController mainController;
  final ThemeData theme;

  const MainSideBar({
    super.key,
    required this.mainController,
    required this.theme,
  });

  @override
  State<MainSideBar> createState() => _MainSideBarState();
}

class _MainSideBarState extends State<MainSideBar> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      onFocusChange: (value) {
        if (_isFocused != value) {
          setState(() {
            _isFocused = value;
          });
        }
      },
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            IconButton(
              tooltip: '搜索',
              icon: const Icon(
                Icons.search_outlined,
                semanticLabel: '搜索',
              ),
              onPressed: () => Get.toNamed('/search'),
            ),
            const SizedBox(height: 10),
            ...widget.mainController.navigationBars.map(
              _buildNavItem,
            ),
            const Spacer(),
            _buildAvatar(),
            const SizedBox(height: 10),
            IconButton(
              tooltip: '设置',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Get.toNamed('/setting'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(NavigationBarType type) {
    return Obx(() {
      final selected = widget.mainController.selectedIndex.value == type.index;
      final icon = selected ? type.selectIcon : type.icon;

      Widget child = type == NavigationBarType.dynamics
          ? _buildDynamicBadge(icon)
          : icon;

      return Focus(
        key: ValueKey(type.index),
        autofocus: selected,
        canRequestFocus: selected || _isFocused,
        onFocusChange: (hasFocus) {
          if (hasFocus &&
              type.index != widget.mainController.selectedIndex.value) {
            widget.mainController.setIndex(type.index);
          }
        },
        child: InkWell(
          onTap: () => widget.mainController.setIndex(type.index),
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 50,
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 5),
            decoration: selected
                ? BoxDecoration(
                    color: widget.theme.colorScheme.secondaryContainer,
                    shape: BoxShape.circle,
                  )
                : null,
            child: IconTheme(
              data: IconThemeData(
                color: selected
                    ? widget.theme.colorScheme.onSecondaryContainer
                    : widget.theme.colorScheme.onSurfaceVariant,
              ),
              child: Center(child: child),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDynamicBadge(Widget icon) {
    final dynCount = widget.mainController.dynCount.value;
    return Badge(
      isLabelVisible: dynCount > 0,
      label: widget.mainController.dynamicBadgeMode == DynamicBadgeMode.number
          ? Text(dynCount.toString())
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: icon,
    );
  }

  Widget _buildAvatar() {
    return Semantics(
      label: "我的",
      child: Obx(
        () => widget.mainController.accountService.isLogin.value
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  NetworkImgLayer(
                    type: ImageType.avatar,
                    width: 34,
                    height: 34,
                    src: widget.mainController.accountService.face.value,
                  ),
                  Positioned.fill(
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: widget.mainController.toMinePage,
                        splashColor: widget.theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.3),
                        customBorder: const CircleBorder(),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -6,
                    bottom: -6,
                    child: Obx(
                      () => MineController.anonymity.value
                          ? IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: widget
                                      .theme.colorScheme.secondaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  size: 16,
                                  MdiIcons.incognito,
                                  color: widget
                                      .theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              )
            : defaultUser(
                theme: widget.theme,
                onPressed: widget.mainController.toMinePage,
              ),
      ),
    );
  }
}
