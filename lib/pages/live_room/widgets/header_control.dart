import 'dart:io';
import 'dart:math' as math;

import 'package:PiliPlus/common/widgets/custom_icon.dart';
import 'package:PiliPlus/common/widgets/marquee.dart';
import 'package:PiliPlus/pages/live_room/controller.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/widgets/menu_row.dart';
import 'package:PiliPlus/pages/video/widgets/header_control.dart'
    show HeaderMixin, HeaderControlState, TimeBatteryMixin;
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/video_fit_type.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/common_btn.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:floating/floating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class LiveHeaderControl extends StatefulWidget {
  const LiveHeaderControl({
    super.key,
    required this.title,
    required this.upName,
    required this.plPlayerController,
    required this.onSendDanmaku,
    required this.onPlayAudio,
    required this.isPortrait,
    required this.liveController,
  });

  final String? title;
  final String? upName;
  final PlPlayerController plPlayerController;
  final VoidCallback onSendDanmaku;
  final VoidCallback onPlayAudio;
  final bool isPortrait;
  final LiveRoomController liveController;

  @override
  State<LiveHeaderControl> createState() => _LiveHeaderControlState();
}

class _LiveHeaderControlState extends State<LiveHeaderControl>
    with TimeBatteryMixin, HeaderMixin {
  @override
  late final plPlayerController = widget.plPlayerController;

  @override
  bool get horizontalScreen => true;

  @override
  bool get isFullScreen => plPlayerController.isFullScreen.value;

  @override
  bool get isPortrait => widget.isPortrait;

  static const TextStyle subTitleStyle = TextStyle(fontSize: 12);
  static const TextStyle titleStyle = TextStyle(fontSize: 14);

  /// 设置面板
  void showSettingSheet() {
    final liveController = widget.liveController;
    showBottomSheet(
      (context, setState) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
            clipBehavior: Clip.hardEdge,
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 14),
              children: [
                ListTile(
                  dense: true,
                  onTap: () {
                    Get.back();
                    widget.onSendDanmaku();
                  },
                  leading: const Icon(Icons.comment_outlined, size: 20),
                  title: const Text('发弹幕', style: titleStyle),
                ),
                Obx(
                  () {
                    final onlyPlayAudio = plPlayerController.onlyPlayAudio.value;
                    return ListTile(
                      dense: true,
                      onTap: () {
                        plPlayerController.onlyPlayAudio.value = !onlyPlayAudio;
                        widget.onPlayAudio();
                        setState(() {});
                      },
                      leading: onlyPlayAudio
                          ? const Icon(MdiIcons.musicCircle, size: 20)
                          : const Icon(MdiIcons.musicCircleOutline, size: 20),
                      title: const Text('仅播放音频', style: titleStyle),
                      trailing: onlyPlayAudio
                          ? Icon(
                              Icons.done,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                    );
                  },
                ),
                if (Platform.isAndroid || (Utils.isDesktop && !isFullScreen))
                  ListTile(
                    dense: true,
                    onTap: () async {
                      Get.back();
                      if (Utils.isDesktop) {
                        plPlayerController.toggleDesktopPip();
                        return;
                      }
                      if (await Floating().isPipAvailable) {
                        plPlayerController
                          ..showControls.value = false
                          ..enterPip();
                      }
                    },
                    leading: const Icon(Icons.picture_in_picture_outlined, size: 20),
                    title: const Text('画中画', style: titleStyle),
                  ),
                ListTile(
                  dense: true,
                  onTap: () {
                    Get.back();
                    PageUtils.scheduleExit(context, isFullScreen, true);
                  },
                  leading: const Icon(Icons.schedule, size: 20),
                  title: const Text('定时关闭', style: titleStyle),
                ),
                ListTile(
                  dense: true,
                  onTap: () {
                    Get.back();
                    HeaderControlState.showPlayerInfo(
                      context,
                      plPlayerController: plPlayerController,
                    );
                  },
                  leading: const Icon(Icons.info_outline, size: 20),
                  title: const Text('播放信息', style: titleStyle),
                ),
                ListTile(
                  dense: true,
                  onTap: () {
                    Get.back();
                    liveController.queryLiveUrl();
                  },
                  leading: const Icon(Icons.refresh, size: 20),
                  title: const Text('刷新', style: titleStyle),
                ),
                ListTile(
                  dense: true,
                  onTap: () {
                    Get.back();
                    if (liveController.isLogin) {
                      Get.toNamed(
                        '/liveDmBlockPage',
                        parameters: {
                          'roomId': liveController.roomId.toString(),
                        },
                      );
                    } else {
                      SmartDialog.showToast('账号未登录');
                    }
                  },
                  leading: const Icon(Icons.block, size: 20),
                  title: const Text('屏蔽', style: titleStyle),
                ),
                SwitchListTile(
                  value: plPlayerController.enableShowDanmaku.value,
                  onChanged: (value) {
                    setState(() {
                      plPlayerController.enableShowDanmaku.value = value;
                      if (!plPlayerController.tempPlayerConf) {
                        GStorage.setting.put(
                          SettingBoxKey.enableShowLiveDanmaku,
                          value,
                        );
                      }
                    });
                  },
                  secondary: const Icon(Icons.comment_outlined, size: 20),
                  title: const Text('弹幕', style: titleStyle),
                ),
                ListTile(
                  dense: true,
                  onTap: () {
                    Get.back();
                    showSetDanmaku(isLive: true);
                  },
                  leading: const Icon(CustomIcons.dm_settings, size: 20),
                  title: const Text('弹幕设置', style: titleStyle),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.aspect_ratio_outlined, size: 20),
                  title: Row(
                    children: [
                      const Text(
                        '画面比例',
                        strutStyle: StrutStyle(leading: 0, height: 1),
                        style: TextStyle(
                          height: 1,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Obx(
                        () => PopupMenuButton<VideoFitType>(
                          initialValue: plPlayerController.videoFit.value,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  plPlayerController.videoFit.value.desc,
                                  strutStyle: const StrutStyle(
                                    leading: 0,
                                    height: 1,
                                  ),
                                  style: TextStyle(
                                    height: 1,
                                    fontSize: 14,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                                Icon(
                                  MdiIcons.unfoldMoreHorizontal,
                                  size: MediaQuery.textScalerOf(
                                    context,
                                  ).scale(14),
                                  color: theme.colorScheme.secondary,
                                ),
                              ],
                            ),
                          ),
                          onSelected: (value) {
                            plPlayerController.toggleVideoFit(value);
                            if (context.mounted) {
                              (context as Element).markNeedsBuild();
                            }
                          },
                          itemBuilder: (context) => VideoFitType.values
                              .map(
                                (item) => PopupMenuItem(
                                  value: item,
                                  child: Text(item.desc),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.play_circle_outline, size: 20),
                  title: Row(
                    children: [
                      const Text(
                        '画质',
                        strutStyle: StrutStyle(leading: 0, height: 1),
                        style: TextStyle(
                          height: 1,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Obx(
                        () => PopupMenuButton<int>(
                          initialValue: liveController.currentQn,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  liveController.currentQnDesc.value,
                                  strutStyle: const StrutStyle(
                                    leading: 0,
                                    height: 1,
                                  ),
                                  style: TextStyle(
                                    height: 1,
                                    fontSize: 14,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                                Icon(
                                  MdiIcons.unfoldMoreHorizontal,
                                  size: MediaQuery.textScalerOf(
                                    context,
                                  ).scale(14),
                                  color: theme.colorScheme.secondary,
                                ),
                              ],
                            ),
                          ),
                          onSelected: (value) {
                            liveController.changeQn(value);
                            if (context.mounted) {
                              (context as Element).markNeedsBuild();
                            }
                          },
                          itemBuilder: (context) => liveController.acceptQnList
                              .map(
                                (item) => PopupMenuItem(
                                  value: item.code,
                                  child: Text(item.desc),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    spacing: 10,
                    children: [
                      Obx(
                        () {
                          final flipX = plPlayerController.flipX.value;
                          return ActionRowLineItem(
                            iconData: Icons.flip,
                            onTap: () =>
                                plPlayerController.flipX.value = !flipX,
                            text: " 左右翻转 ",
                            selectStatus: flipX,
                          );
                        },
                      ),
                      Obx(
                        () {
                          final flipY = plPlayerController.flipY.value;
                          return ActionRowLineItem(
                            icon: Transform.rotate(
                              angle: math.pi / 2,
                              child: Icon(
                                Icons.flip,
                                size: 13,
                                color: flipY
                                    ? theme.colorScheme.onSecondaryContainer
                                    : theme.colorScheme.outline,
                              ),
                            ),
                            onTap: () {
                              plPlayerController.flipY.value = !flipY;
                            },
                            text: " 上下翻转 ",
                            selectStatus: flipY,
                          );
                        },
                      ),
                      Obx(
                        () => ActionRowLineItem(
                          iconData: Icons.play_circle_outline,
                          onTap: plPlayerController.setContinuePlayInBackground,
                          text: " 后台播放 ",
                          selectStatus:
                              plPlayerController.continuePlayInBackground.value,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  dense: true,
                  onTap: () {
                    Get.back();
                  },
                  leading: const Icon(Icons.arrow_back, size: 20),
                  title: const Text('返回', style: titleStyle),
                ),
                ListTile(
                  dense: true,
                  onTap: () {
                    Get.until((route) => route.isFirst);
                  },
                  leading: const Icon(Icons.home, size: 20),
                  title: const Text('返回主页', style: titleStyle),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFullScreen = this.isFullScreen;
    showCurrTimeIfNeeded(isFullScreen);
    final liveController = widget.liveController;
    Widget child;
    child = Obx(
      () => MarqueeText(
        key: titleKey,
        liveController.title.value,
        spacing: 30,
        velocity: 30,
        style: const TextStyle(
          fontSize: 15,
          height: 1,
          color: Colors.white,
        ),
      ),
    );
    if (isFullScreen) {
      child = Column(
        spacing: 5,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          Row(
            spacing: 10,
            children: [
              if (widget.upName case final upName?)
                Text(
                  upName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              liveController.watchedWidget,
              liveController.onlineWidget,
              liveController.timeWidget,
            ],
          ),
        ],
      );
    }
    child = Expanded(child: child);
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      primary: false,
      automaticallyImplyLeading: false,
      titleSpacing: 14,
      title: Row(
        children: [
          if (isFullScreen || plPlayerController.isDesktopPip)
            ComBtn(
              height: 30,
              tooltip: '返回',
              icon: const Icon(FontAwesomeIcons.arrowLeft, size: 15),
              onTap: () {
                if (plPlayerController.isDesktopPip) {
                  plPlayerController.exitDesktopPip();
                } else {
                  plPlayerController.triggerFullScreen(status: false);
                }
              },
            ),
          child,
          ...?timeBatteryWidgets,
          const SizedBox(width: 10),
          ComBtn(
            height: 30,
            tooltip: '发弹幕',
            icon: const Icon(
              size: 18,
              Icons.comment_outlined,
              color: Colors.white,
            ),
            onTap: widget.onSendDanmaku,
          ),
          Obx(
            () {
              final onlyPlayAudio = plPlayerController.onlyPlayAudio.value;
              return ComBtn(
                height: 30,
                tooltip: '仅播放音频',
                onTap: () {
                  plPlayerController.onlyPlayAudio.value = !onlyPlayAudio;
                  widget.onPlayAudio();
                },
                icon: onlyPlayAudio
                    ? const Icon(
                        size: 18,
                        MdiIcons.musicCircle,
                        color: Colors.white,
                      )
                    : const Icon(
                        size: 18,
                        MdiIcons.musicCircleOutline,
                        color: Colors.white,
                      ),
              );
            },
          ),
          if (Platform.isAndroid || (Utils.isDesktop && !isFullScreen))
            ComBtn(
              height: 30,
              tooltip: '画中画',
              onTap: () async {
                if (Utils.isDesktop) {
                  plPlayerController.toggleDesktopPip();
                  return;
                }
                if (await Floating().isPipAvailable) {
                  plPlayerController
                    ..showControls.value = false
                    ..enterPip();
                }
              },
              icon: const Icon(
                size: 18,
                Icons.picture_in_picture_outlined,
                color: Colors.white,
              ),
            ),
          ComBtn(
            height: 30,
            tooltip: '定时关闭',
            onTap: () => PageUtils.scheduleExit(context, isFullScreen, true),
            icon: const Icon(
              size: 18,
              Icons.schedule,
              color: Colors.white,
            ),
          ),
          ComBtn(
            height: 30,
            tooltip: '播放信息',
            onTap: () => HeaderControlState.showPlayerInfo(
              context,
              plPlayerController: plPlayerController,
            ),
            icon: const Icon(
              size: 18,
              Icons.info_outline,
              color: Colors.white,
            ),
          ),
          ComBtn(
            height: 30,
            tooltip: "更多设置",
            icon: const Icon(
              Icons.more_vert_outlined,
              size: 19,
              color: Colors.white,
            ),
            onTap: showSettingSheet,
          ),
        ],
      ),
    );
  }
}

// Export the private state class for access via GlobalKey
typedef LiveHeaderControlState = _LiveHeaderControlState;
