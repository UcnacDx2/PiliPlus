import 'package:PiliPlus/pages/setting/widgets/switch_item.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/widgets/action_item.dart';
import 'package:PiliPlus/pages/video/widgets/header_control.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/utils/extension.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SetDanmakuPanel extends StatefulWidget {
  const SetDanmakuPanel({
    super.key,
    required this.videoDetailCtr,
    required this.plPlayerController,
  });

  final VideoDetailController videoDetailCtr;
  final PlPlayerController plPlayerController;

  @override
  State<SetDanmakuPanel> createState() => _SetDanmakuPanelState();
}

class _SetDanmakuPanelState extends State<SetDanmakuPanel> with HeaderMixin {
  @override
  PlPlayerController get plPlayerController => widget.plPlayerController;

  @override
  bool get isFullScreen => plPlayerController.isFullScreen.value;

  @override
  Widget build(BuildContext context) {
    // Re-implement the danmaku settings UI from HeaderMixin.showSetDanmaku
    const List<({int value, String label})> blockTypesList = [
      (value: 5, label: '顶部'),
      (value: 2, label: '滚动'),
      (value: 4, label: '底部'),
      (value: 6, label: '彩色'),
    ];
    final blockTypes = plPlayerController.blockTypes;
    int danmakuWeight = plPlayerController.danmakuWeight;
    double showArea = plPlayerController.showArea;
    double danmakuOpacity = plPlayerController.danmakuOpacity.value;
    double danmakuFontScale = plPlayerController.danmakuFontScale;
    double danmakuFontScaleFS = plPlayerController.danmakuFontScaleFS;
    double danmakuLineHeight = plPlayerController.danmakuLineHeight;
    double danmakuDuration = plPlayerController.danmakuDuration;
    double danmakuStaticDuration = plPlayerController.danmakuStaticDuration;
    double danmakuStrokeWidth = plPlayerController.danmakuStrokeWidth;
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

    void updateState(VoidCallback fn) {
      if (mounted) {
        setState(fn);
      }
    }

    return Material(
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
                  onChanged: (val) => updateState(() => plPlayerController.danmakuWeight = danmakuWeight = val.toInt()),
                  onChangeEnd: (_) =>
                      plPlayerController.putDanmakuSettings(),
                ),
              ),
            ),
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
                        updateState(() {});
                        try {
                          danmakuController?.updateOption(
                            danmakuController.option.copyWith(
                              hideTop: blockTypes.contains(5),
                              hideBottom: blockTypes.contains(4),
                              hideScroll: blockTypes.contains(2),
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
                updateState(() {});
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
                  () => updateState(() => plPlayerController.showArea = showArea = 0.5),
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
                  onChanged: (val) => updateState(() => plPlayerController.showArea = showArea = val.toPrecision(1)),
                  onChangeEnd: (_) =>
                      plPlayerController.putDanmakuSettings(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
