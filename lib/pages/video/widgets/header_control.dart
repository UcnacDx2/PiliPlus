import 'dart:async';

import 'package:PiliPlus/common/widgets/marquee.dart';
import 'package:PiliPlus/pages/common/common_intro_controller.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/pages/video/introduction/local/controller.dart';
import 'package:PiliPlus/pages/video/introduction/pgc/controller.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/controller.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/widgets/action_item.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/utils/fullscreen.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart' hide showBottomSheet;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

mixin TimeBatteryMixin<T extends StatefulWidget> on State<T> {
  PlPlayerController get plPlayerController;
  late final titleKey = GlobalKey();
  ContextSingleTicker? provider;
  ContextSingleTicker get effectiveProvider => provider ??= ContextSingleTicker(
    context,
    autoStart: () =>
        plPlayerController.showControls.value &&
        !plPlayerController.controlsLock.value,
  );

  bool get isPortrait;
  bool get isFullScreen;
  bool get horizontalScreen;

  Timer? _clock;
  RxString now = ''.obs;

  static final _format = DateFormat('HH:mm');

  @override
  void dispose() {
    stopClock();
    super.dispose();
  }

  void startClock() {
    if (!_showCurrTime) return;
    if (_clock == null) {
      now.value = _format.format(DateTime.now());
      _clock ??= Timer.periodic(const Duration(seconds: 1), (Timer t) {
        if (!mounted) {
          stopClock();
          return;
        }
        now.value = _format.format(DateTime.now());
      });
    }
  }

  void stopClock() {
    _clock?.cancel();
    _clock = null;
  }

  bool _showCurrTime = false;
  void showCurrTimeIfNeeded(bool isFullScreen) {
    _showCurrTime = !isPortrait && (isFullScreen || !horizontalScreen);
    if (!_showCurrTime) {
      stopClock();
    }
  }

  late final _battery = Battery();
  late final RxnInt _batteryLevel = RxnInt();
  late final _showBatteryLevel = Pref.showBatteryLevel;
  void getBatteryLevelIfNeeded() {
    if (!_showCurrTime || !_showBatteryLevel) return;
    EasyThrottle.throttle(
      'getBatteryLevel$hashCode',
      const Duration(seconds: 30),
      () async {
        try {
          _batteryLevel.value = await _battery.batteryLevel;
        } catch (_) {}
      },
    );
  }

  List<Widget>? get timeBatteryWidgets {
    if (_showCurrTime) {
      return [
        if (_showBatteryLevel) ...[
          Obx(
            () {
              final batteryLevel = _batteryLevel.value;
              if (batteryLevel == null) {
                return const SizedBox.shrink();
              }
              return Text(
                '$batteryLevel%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
        Obx(
          () => Text(
            now.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ),
      ];
    }
    return null;
  }
}

mixin HeaderMixin<T extends StatefulWidget> on State<T> {
  PlPlayerController get plPlayerController;

  bool get isFullScreen => plPlayerController.isFullScreen.value;

  void showBottomSheet(StatefulWidgetBuilder builder, {double? padding}) {
    PageUtils.showVideoBottomSheet(
      context,
      isFullScreen: () => isFullScreen,
      padding: padding,
      child: StatefulBuilder(
        builder: (context, setState) => plPlayerController.darkVideoPage
            ? Theme(
                data: Theme.of(this.context),
                child: builder(this.context, setState),
              )
            : builder(context, setState),
      ),
    );
  }

  Widget resetBtn(
    ThemeData theme,
    Object def,
    VoidCallback onPressed, {
    bool isDanmaku = true,
  }) {
    return iconButton(
      tooltip: '默认值: $def',
      icon: const Icon(Icons.refresh),
      onPressed: () {
        onPressed();
        if (isDanmaku) {
          plPlayerController.putDanmakuSettings();
        } else {
          plPlayerController.putSubtitleSettings();
        }
      },
      iconColor: theme.colorScheme.outline,
      size: 24,
      iconSize: 24,
    );
  }

  /// 弹幕功能
  void showSetDanmaku({bool isLive = false}) {
    // 屏蔽类型
    const List<({int value, String label})> blockTypesList = [
      (value: 5, label: '顶部'),
      (value: 2, label: '滚动'),
      (value: 4, label: '底部'),
      (value: 6, label: '彩色'),
    ];
    final blockTypes = plPlayerController.blockTypes;
    // 智能云屏蔽
    int danmakuWeight = plPlayerController.danmakuWeight;
    // 显示区域
    double showArea = plPlayerController.showArea;
    // 不透明度
    double danmakuOpacity = plPlayerController.danmakuOpacity.value;
    // 字体大小
    double danmakuFontScale = plPlayerController.danmakuFontScale;
    // 全屏字体大小
    double danmakuFontScaleFS = plPlayerController.danmakuFontScaleFS;
    double danmakuLineHeight = plPlayerController.danmakuLineHeight;
    // 弹幕速度
    double danmakuDuration = plPlayerController.danmakuDuration;
    double danmakuStaticDuration = plPlayerController.danmakuStaticDuration;
    // 弹幕描边
    double danmakuStrokeWidth = plPlayerController.danmakuStrokeWidth;
    // 字体粗细
    int danmakuFontWeight = plPlayerController.danmakuFontWeight;
    bool massiveMode = plPlayerController.massiveMode;

    final DanmakuController<DanmakuExtra>? danmakuController =
        plPlayerController.danmakuController;

    final isFullScreen = this.isFullScreen;

    showBottomSheet(
      (context, setState) {
        final theme = Theme.of(context);

        final sliderTheme = SliderThemeData(
          trackHeight: 10,
          trackShape: const MSliderTrackShape(),
          thumbColor: theme.colorScheme.primary,
          activeTrackColor: theme.colorScheme.primary,
          inactiveTrackColor: theme.colorScheme.onInverseSurface,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
        );

        void updateLineHeight(double val) {
          plPlayerController.danmakuLineHeight = danmakuLineHeight = val
              .toPrecision(1);
          setState(() {});
          try {
            danmakuController?.updateOption(
              danmakuController.option.copyWith(
                lineHeight: danmakuLineHeight,
              ),
            );
          } catch (_) {}
        }

        void updateDuration(double val) {
          plPlayerController.danmakuDuration = danmakuDuration = val
              .toPrecision(1);
          setState(() {});
          try {
            danmakuController?.updateOption(
              danmakuController.option.copyWith(
                duration: danmakuDuration / plPlayerController.playbackSpeed,
              ),
            );
          } catch (_) {}
        }

        void updateStaticDuration(double val) {
          plPlayerController.danmakuStaticDuration = danmakuStaticDuration = val
              .toPrecision(1);
          setState(() {});
          try {
            danmakuController?.updateOption(
              danmakuController.option.copyWith(
                staticDuration:
                    danmakuStaticDuration / plPlayerController.playbackSpeed,
              ),
            );
          } catch (_) {}
        }

        void updateFontSizeFS(double val) {
          plPlayerController.danmakuFontScaleFS = danmakuFontScaleFS = val;
          setState(() {});
          if (isFullScreen) {
            try {
              danmakuController?.updateOption(
                danmakuController.option.copyWith(
                  fontSize: (15 * danmakuFontScaleFS).toDouble(),
                ),
              );
            } catch (_) {}
          }
        }

        void updateFontSize(double val) {
          plPlayerController.danmakuFontScale = danmakuFontScale = val;
          setState(() {});
          if (!isFullScreen) {
            try {
              danmakuController?.updateOption(
                danmakuController.option.copyWith(
                  fontSize: (15 * danmakuFontScale).toDouble(),
                ),
              );
            } catch (_) {}
          }
        }

        void updateStrokeWidth(double val) {
          plPlayerController.danmakuStrokeWidth = danmakuStrokeWidth = val;
          setState(() {});
          try {
            danmakuController?.updateOption(
              danmakuController.option.copyWith(
                strokeWidth: danmakuStrokeWidth,
              ),
            );
          } catch (_) {}
        }

        void updateFontWeight(double val) {
          plPlayerController.danmakuFontWeight = danmakuFontWeight = val
              .toInt();
          setState(() {});
          try {
            danmakuController?.updateOption(
              danmakuController.option.copyWith(fontWeight: danmakuFontWeight),
            );
          } catch (_) {}
        }

        void updateOpacity(double val) {
          plPlayerController.danmakuOpacity.value = danmakuOpacity = val;
          setState(() {});
        }

        void updateShowArea(double val) {
          plPlayerController.showArea = showArea = val.toPrecision(1);
          setState(() {});
          try {
            danmakuController?.updateOption(
              danmakuController.option.copyWith(area: showArea),
            );
          } catch (_) {}
        }

        void updateDanmakuWeight(double val) {
          plPlayerController.danmakuWeight = danmakuWeight = val.toInt();
          setState(() {});
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
            clipBehavior: Clip.hardEdge,
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(
                    height: 45,
                    child: Center(
                      child: Text('弹幕设置', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!isLive) ...[
                    Row(
                      children: [
                        Text('智能云屏蔽 $danmakuWeight 级'),
                        const Spacer(),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => Get
                            ..back()
                            ..toNamed(
                              '/danmakuBlock',
                              arguments: plPlayerController,
                            ),
                          child: Text(
                            "屏蔽管理(${plPlayerController.filters.count})",
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 0,
                        bottom: 6,
                        left: 10,
                        right: 10,
                      ),
                      child: SliderTheme(
                        data: sliderTheme,
                        child: Slider(
                          min: 0,
                          max: 10,
                          value: danmakuWeight.toDouble(),
                          divisions: 10,
                          label: '$danmakuWeight',
                          onChanged: updateDanmakuWeight,
                          onChangeEnd: (_) =>
                              plPlayerController.putDanmakuSettings(),
                        ),
                      ),
                    ),
                  ],
                  const Text('按类型屏蔽'),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        for (final (value: value, label: label)
                            in blockTypesList) ...[
                          ActionRowLineItem(
                            onTap: () {
                              if (blockTypes.contains(value)) {
                                blockTypes.remove(value);
                              } else {
                                blockTypes.add(value);
                              }
                              plPlayerController
                                ..blockTypes = blockTypes
                                ..blockColorful = blockTypes.contains(6)
                                ..putDanmakuSettings();
                              setState(() {});
                              try {
                                danmakuController?.updateOption(
                                  danmakuController.option.copyWith(
                                    hideTop: blockTypes.contains(5),
                                    hideBottom: blockTypes.contains(4),
                                    hideScroll: blockTypes.contains(2),
                                    // 添加或修改其他需要修改的选项属性
                                  ),
                                );
                              } catch (_) {}
                            },
                            text: label,
                            selectStatus: blockTypes.contains(value),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ],
                    ),
                  ),
                  SetSwitchItem(
                    title: '海量弹幕',
                    contentPadding: EdgeInsets.zero,
                    titleStyle: const TextStyle(fontSize: 14),
                    defaultVal: massiveMode,
                    setKey: SettingBoxKey.danmakuMassiveMode,
                    onChanged: (value) {
                      massiveMode = value;
                      plPlayerController.massiveMode = value;
                      setState(() {});
                      try {
                        danmakuController?.updateOption(
                          danmakuController.option.copyWith(massiveMode: value),
                        );
                      } catch (_) {}
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('显示区域 ${showArea * 100}%'),
                      resetBtn(
                        theme,
                        '50.0%',
                        () => updateShowArea(0.5),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        min: 0.1,
                        max: 1,
                        value: showArea,
                        divisions: 9,
                        label: '${showArea * 100}%',
                        onChanged: updateShowArea,
                        onChangeEnd: (_) =>
                            plPlayerController.putDanmakuSettings(),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('不透明度 ${danmakuOpacity * 100}%'),
                      resetBtn(
                        theme,
                        '100.0%',
                        () => updateOpacity(1.0),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        min: 0,
                        max: 1,
                        value: danmakuOpacity,
                        divisions: 10,
                        label: '${danmakuOpacity * 100}%',
                        onChanged: updateOpacity,
                        onChangeEnd: (_) =>
                            plPlayerController.putDanmakuSettings(),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('字体粗细 ${danmakuFontWeight + 1}（可能无法精确调节）'),
                      resetBtn(
                        theme,
                        6,
                        () => updateFontWeight(5),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        min: 0,
                        max: 8,
                        value: danmakuFontWeight.toDouble(),
                        divisions: 8,
                        label: '${danmakuFontWeight + 1}',
                        onChanged: updateFontWeight,
                        onChangeEnd: (_) =>
                            plPlayerController.putDanmakuSettings(),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('描边粗细 $danmakuStrokeWidth'),
                      resetBtn(
                        theme,
                        1.5,
                        () => updateStrokeWidth(1.5),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        min: 0,
                        max: 5,
                        value: danmakuStrokeWidth,
                        divisions: 10,
                        label: '$danmakuStrokeWidth',
                        onChanged: updateStrokeWidth,
                        onChangeEnd: (_) =>
                            plPlayerController.putDanmakuSettings(),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '字体大小 ${(danmakuFontScale * 100).toStringAsFixed(1)}%',
                      ),
                      resetBtn(
                        theme,
                        '100.0%',
                        () => updateFontSize(1.0),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        min: 0.5,
                        max: 2.5,
                        value: danmakuFontScale,
                        divisions: 20,
                        label:
                            '${(danmakuFontScale * 100).toStringAsFixed(1)}%',
                        onChanged: updateFontSize,
                        onChangeEnd: (_) =>
                            plPlayerController.putDanmakuSettings(),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '全屏字体大小 ${(danmakuFontScaleFS * 100).toStringAsFixed(1)}%',
                      ),
                      resetBtn(
                        theme,
                        '120.0%',
                        () => updateFontSizeFS(1.2),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        min: 0.5,
                        max: 2.5,
                        value: danmakuFontScaleFS,
                        divisions: 20,
                        label:
                            '${(danmakuFontScaleFS * 100).toStringAsFixed(1)}%',
                        onChanged: updateFontSizeFS,
                        onChangeEnd: (_) =>
                            plPlayerController.putDanmakuSettings(),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('滚动弹幕时长 $danmakuDuration 秒'),
                      resetBtn(
                        theme,
                        7.0,
                        () => updateDuration(7.0),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        min: 1,
                        max: 50,
                        value: danmakuDuration,
                        divisions: 49,
                        label: danmakuDuration.toString(),
                        onChanged: updateDuration,
                        onChangeEnd: (_) =>
                            plPlayerController.putDanmakuSettings(),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('静态弹幕时长 $danmakuStaticDuration 秒'),
                      resetBtn(
                        theme,
                        4.0,
                        () => updateStaticDuration(4.0),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        min: 1,
                        max: 50,
                        value: danmakuStaticDuration,
                        divisions: 49,
                        label: danmakuStaticDuration.toString(),
                        onChanged: updateStaticDuration,
                        onChangeEnd: (_) =>
                            plPlayerController.putDanmakuSettings(),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('弹幕行高 $danmakuLineHeight'),
                      resetBtn(
                        theme,
                        1.6,
                        () => updateLineHeight(1.6),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        min: 1.0,
                        max: 3.0,
                        value: danmakuLineHeight,
                        onChanged: updateLineHeight,
                        onChangeEnd: (_) =>
                            plPlayerController.putDanmakuSettings(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class HeaderControl extends StatefulWidget {
  const HeaderControl({
    required this.isPortrait,
    required this.controller,
    required this.videoDetailCtr,
    required this.heroTag,
    super.key,
  });

  final bool isPortrait;
  final PlPlayerController controller;
  final VideoDetailController videoDetailCtr;
  final String heroTag;

  @override
  State<HeaderControl> createState() => HeaderControlState();

  static Future<bool> likeDanmaku(VideoDanmaku extra, int cid) async {
    if (!Accounts.main.isLogin) {
      SmartDialog.showToast('请先登录');
      return false;
    }
    final isLike = !extra.isLike;
    final res = await DanmakuHttp.danmakuLike(
      isLike: isLike,
      cid: cid,
      id: extra.id,
    );
    if (res.isSuccess) {
      extra.isLike = isLike;
      if (isLike) {
        extra.like++;
      } else {
        extra.like--;
      }
      SmartDialog.showToast('${isLike ? '' : '取消'}点赞成功');
      return true;
    } else {
      res.toast();
      return false;
    }
  }

  static Future<bool> deleteDanmaku(int id, int cid) async {
    final res = await DanmakuHttp.danmakuRecall(
      cid: cid,
      id: id,
    );
    if (res.isSuccess) {
      SmartDialog.showToast('删除成功');
      return true;
    } else {
      res.toast();
      return false;
    }
  }

  static Future<void> reportDanmaku(
    BuildContext context, {
    required VideoDanmaku extra,
    required PlPlayerController ctr,
  }) {
    if (Accounts.main.isLogin) {
      return autoWrapReportDialog(
        context,
        ReportOptions.danmakuReport,
        (reasonType, reasonDesc, banUid) {
          if (banUid) {
            final filter = ctr.filters;
            if (filter.dmUid.add(extra.mid)) {
              filter.count++;
              GStorage.localCache.put(
                LocalCacheKey.danmakuFilterRules,
                filter,
              );
            }
            DanmakuFilterHttp.danmakuFilterAdd(
              filter: extra.mid,
              type: 2,
            );
          }
          return DanmakuHttp.danmakuReport(
            reason: reasonType == 0 ? 11 : reasonType,
            cid: ctr.cid!,
            id: extra.id,
            content: reasonType == 0 ? reasonDesc : null,
          );
        },
      );
    } else {
      return SmartDialog.showToast('请先登录');
    }
  }

  static Future<void> reportLiveDanmaku(
    BuildContext context, {
    required int roomId,
    required String msg,
    required LiveDanmaku extra,
    required PlPlayerController ctr,
  }) {
    if (Accounts.main.isLogin) {
      return autoWrapReportDialog(
        context,
        ReportOptions.liveDanmakuReport,
        (reasonType, reasonDesc, banUid) {
          // if (banUid) {
          //   final filter = ctr.filters;
          //   if (filter.dmUid.add(extra.mid)) {
          //     filter.count++;
          //     GStorage.localCache.put(
          //       LocalCacheKey.danmakuFilterRules,
          //       filter,
          //     );
          //   }
          //   DanmakuFilterHttp.danmakuFilterAdd(
          //     filter: extra.mid,
          //     type: 2,
          //   );
          // }
          return LiveHttp.liveDmReport(
            roomId: roomId,
            mid: extra.mid,
            msg: msg,
            reason: ReportOptions.liveDanmakuReport['']![reasonType]!,
            reasonId: reasonType,
            dmType: extra.dmType,
            idStr: extra.id,
            ts: extra.ts,
            sign: extra.ct,
          );
        },
      );
    } else {
      return SmartDialog.showToast('请先登录');
    }
  }
}

class HeaderControlState extends State<HeaderControl>
    with HeaderMixin, TimeBatteryMixin {
  @override
  late final PlPlayerController plPlayerController = widget.controller;
  late final VideoDetailController videoDetailCtr = widget.videoDetailCtr;
  late final PlayUrlModel videoInfo = videoDetailCtr.data;
  static const TextStyle subTitleStyle = TextStyle(fontSize: 12);
  static const TextStyle titleStyle = TextStyle(fontSize: 14);

  String get heroTag => widget.heroTag;
  late final UgcIntroController ugcIntroController;
  late final PgcIntroController pgcIntroController;
  late final LocalIntroController localIntroController;
  late CommonIntroController introController = isFileSource
      ? localIntroController
      : videoDetailCtr.isUgc
      ? ugcIntroController
      : pgcIntroController;

  @override
  bool get isPortrait => widget.isPortrait;
  @override
  late final horizontalScreen = videoDetailCtr.horizontalScreen;

  Box setting = GStorage.setting;

  @override
  void initState() {
    super.initState();
    if (isFileSource) {
      introController = Get.find<LocalIntroController>(tag: heroTag);
    } else if (videoDetailCtr.isUgc) {
      introController = Get.find<UgcIntroController>(tag: heroTag);
    } else {
      introController = Get.find<PgcIntroController>(tag: heroTag);
    }
  }

  late final isFileSource = videoDetailCtr.isFileSource;

  @override
  Widget build(BuildContext context) {
    final isFullScreen = this.isFullScreen;
    final isFSOrPip = isFullScreen || plPlayerController.isDesktopPip;
    final showFSActionItem =
        !isFileSource && plPlayerController.showFSActionItem && isFSOrPip;
    showCurrTimeIfNeeded(isFullScreen);
    Widget title;
    if (introController.videoDetail.value.title != null &&
        (isFullScreen ||
            ((!horizontalScreen || plPlayerController.isDesktopPip) &&
                !isPortrait))) {
      title = Padding(
        padding: isPortrait
            ? EdgeInsets.zero
            : const EdgeInsets.only(right: 10),
        child: Obx(
          () {
            final videoDetail = introController.videoDetail.value;
            final String title;
            if (isFileSource || videoDetail.videos == 1) {
              title = videoDetail.title!;
            } else {
              title =
                  videoDetail.pages
                      ?.firstWhereOrNull(
                        (e) => e.cid == videoDetailCtr.cid.value,
                      )
                      ?.part ??
                  videoDetail.title!;
            }
            return MarqueeText(
              key: titleKey,
              title,
              spacing: 30,
              velocity: 30,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              provider: effectiveProvider,
            );
          },
        ),
      );
      if (introController.isShowOnlineTotal) {
        title = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            Obx(
              () => Text(
                '${introController.total.value}人正在看',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        );
      }
      title = Expanded(child: title);
    } else {
      title = const Spacer();
    }
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      primary: false,
      automaticallyImplyLeading: false,
      toolbarHeight: showFSActionItem ? 112 : null,
      flexibleSpace: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 11),
          Row(
            children: [
              SizedBox(
                width: 42,
                height: 34,
                child: IconButton(
                  tooltip: '返回',
                  icon: const Icon(
                    FontAwesomeIcons.arrowLeft,
                    size: 15,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (plPlayerController.isDesktopPip) {
                      plPlayerController.exitDesktopPip();
                    } else if (isFullScreen) {
                      plPlayerController.triggerFullScreen(status: false);
                    } else if (Utils.isMobile &&
                        !horizontalScreen &&
                        !isPortrait) {
                      verticalScreenForTwoSeconds();
                    } else {
                      Get.back();
                    }
                  },
                ),
              ),
              if (!plPlayerController.isDesktopPip &&
                  (!isFullScreen || !isPortrait))
                SizedBox(
                  width: 42,
                  height: 34,
                  child: IconButton(
                    tooltip: '返回主页',
                    icon: const Icon(
                      FontAwesomeIcons.house,
                      size: 15,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      videoDetailCtr.plPlayerController
                        ..isCloseAll = true
                        ..dispose();
                      Get.until((route) => route.isFirst);
                    },
                  ),
                ),
              title,
              // show current datetime
              ...?timeBatteryWidgets,
              if (!isFileSource) ...[
                if (!isFSOrPip) ...[
                  if (videoDetailCtr.isUgc)
                    SizedBox(
                      width: 42,
                      height: 34,
                      child: IconButton(
                        tooltip: '听音频',
                        style: const ButtonStyle(
                          padding: WidgetStatePropertyAll(EdgeInsets.zero),
                        ),
                        onPressed: videoDetailCtr.toAudioPage,
                        icon: const Icon(
                          Icons.headphones_outlined,
                          size: 19,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 42,
                    height: 34,
                    child: IconButton(
                      tooltip: '投屏',
                      style: const ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.zero),
                      ),
                      onPressed: videoDetailCtr.onCast,
                      icon: const Icon(
                        Icons.cast,
                        size: 19,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                if (plPlayerController.enableSponsorBlock)
                  SizedBox(
                    width: 42,
                    height: 34,
                    child: IconButton(
                      tooltip: '提交片段',
                      style: const ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.zero),
                      ),
                      onPressed: () => videoDetailCtr.onBlock(context),
                      icon: const Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 19,
                            color: Colors.white,
                          ),
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                Obx(
                  () => videoDetailCtr.segmentProgressList.isNotEmpty
                      ? SizedBox(
                          width: 42,
                          height: 34,
                          child: IconButton(
                            tooltip: '片段信息',
                            style: const ButtonStyle(
                              padding: WidgetStatePropertyAll(EdgeInsets.zero),
                            ),
                            onPressed: () =>
                                videoDetailCtr.showSBDetail(context),
                            icon: const Icon(
                              MdiIcons.advertisements,
                              size: 19,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
          if (showFSActionItem)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 42,
                  height: 34,
                  child: Obx(
                    () => ActionItem(
                      expand: false,
                      icon: const Icon(
                        FontAwesomeIcons.thumbsUp,
                        color: Colors.white,
                      ),
                      selectIcon: const Icon(
                        FontAwesomeIcons.solidThumbsUp,
                      ),
                      selectStatus: introController.hasLike.value,
                      semanticsLabel: '点赞',
                      animation: introController.tripleAnimation,
                      onStartTriple: () {
                        plPlayerController.tripling = true;
                        introController.onStartTriple();
                      },
                      onCancelTriple: ([bool isTapUp = false]) {
                        plPlayerController
                          ..tripling = false
                          ..hideTaskControls();
                        introController.onCancelTriple(isTapUp);
                      },
                    ),
                  ),
                ),
                if (introController case UgcIntroController ugc)
                  SizedBox(
                    width: 42,
                    height: 34,
                    child: Obx(
                      () => ActionItem(
                        expand: false,
                        icon: const Icon(
                          FontAwesomeIcons.thumbsDown,
                          color: Colors.white,
                        ),
                        selectIcon: const Icon(
                          FontAwesomeIcons.solidThumbsDown,
                        ),
                        onTap: () => ugc.handleAction(ugc.actionDislikeVideo),
                        selectStatus: ugc.hasDislike.value,
                        semanticsLabel: '点踩',
                      ),
                    ),
                  ),
                SizedBox(
                  width: 42,
                  height: 34,
                  child: Obx(
                    () => ActionItem(
                      expand: false,
                      animation: introController.tripleAnimation,
                      icon: const Icon(
                        FontAwesomeIcons.b,
                        color: Colors.white,
                      ),
                      selectIcon: const Icon(FontAwesomeIcons.b),
                      onTap: introController.actionCoinVideo,
                      selectStatus: introController.hasCoin,
                      semanticsLabel: '投币',
                    ),
                  ),
                ),
                SizedBox(
                  width: 42,
                  height: 34,
                  child: Obx(
                    () => ActionItem(
                      expand: false,
                      animation: introController.tripleAnimation,
                      icon: const Icon(
                        FontAwesomeIcons.star,
                        color: Colors.white,
                      ),
                      selectIcon: const Icon(FontAwesomeIcons.solidStar),
                      onTap: () => introController.showFavBottomSheet(context),
                      onLongPress: () => introController.showFavBottomSheet(
                        context,
                        isLongPress: true,
                      ),
                      selectStatus: introController.hasFav.value,
                      semanticsLabel: '收藏',
                    ),
                  ),
                ),
                SizedBox(
                  width: 42,
                  height: 34,
                  child: ActionItem(
                    expand: false,
                    icon: const Icon(
                      FontAwesomeIcons.shareFromSquare,
                      color: Colors.white,
                    ),
                    onTap: () => introController.actionShareVideo(context),
                    semanticsLabel: '分享',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class MSliderTrackShape extends RoundedRectSliderTrackShape {
  const MSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    SliderThemeData? sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    const double trackHeight = 3;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2 + 4;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
