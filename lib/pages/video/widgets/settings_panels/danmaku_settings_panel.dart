import 'package:PiliPlus/common/widgets/button/icon_button.dart';
import 'package:PiliPlus/pages/setting/widgets/switch_item.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/widgets/menu_row.dart';
import 'package:PiliPlus/pages/video/widgets/settings_panels/slider_track_shape.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/utils/extension.dart';

class DanmakuSettingsPanel extends StatefulWidget {
  final PlPlayerController plPlayerController;

  const DanmakuSettingsPanel({super.key, required this.plPlayerController});

  @override
  State<DanmakuSettingsPanel> createState() => _DanmakuSettingsPanelState();
}

class _DanmakuSettingsPanelState extends State<DanmakuSettingsPanel> {
  late PlPlayerController plPlayerController;

  @override
  void initState() {
    super.initState();
    plPlayerController = widget.plPlayerController;
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

  @override
  Widget build(BuildContext context) {
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
      plPlayerController.danmakuLineHeight = danmakuLineHeight = val.toPrecision(1);
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
      plPlayerController.danmakuDuration = danmakuDuration = val.toPrecision(1);
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
      plPlayerController.danmakuStaticDuration =
          danmakuStaticDuration = val.toPrecision(1);
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
      if (plPlayerController.isFullScreen.value) {
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
      if (!plPlayerController.isFullScreen.value) {
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
      plPlayerController.danmakuFontWeight = danmakuFontWeight = val.toInt();
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
              if (!plPlayerController.isLive) ...[
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
  }
}
