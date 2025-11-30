import 'package:PiliPlus/common/widgets/button/icon_button.dart';
import 'package:PiliPlus/pages/video/widgets/settings_panels/slider_track_shape.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:flutter/material.dart';
import 'package:PiliPlus/utils/extension.dart';

class SubtitleSettingsPanel extends StatefulWidget {
  final PlPlayerController plPlayerController;

  const SubtitleSettingsPanel({super.key, required this.plPlayerController});

  @override
  State<SubtitleSettingsPanel> createState() => _SubtitleSettingsPanelState();
}

class _SubtitleSettingsPanelState extends State<SubtitleSettingsPanel> {
  late PlPlayerController plPlayerController;
  late double subtitleFontScale;
  late double subtitleFontScaleFS;
  late int subtitlePaddingH;
  late int subtitlePaddingB;
  late double subtitleBgOpaticy;
  late double subtitleStrokeWidth;
  late int subtitleFontWeight;

  @override
  void initState() {
    super.initState();
    plPlayerController = widget.plPlayerController;
    subtitleFontScale = plPlayerController.subtitleFontScale;
    subtitleFontScaleFS = plPlayerController.subtitleFontScaleFS;
    subtitlePaddingH = plPlayerController.subtitlePaddingH;
    subtitlePaddingB = plPlayerController.subtitlePaddingB;
    subtitleBgOpaticy = plPlayerController.subtitleBgOpaticy;
    subtitleStrokeWidth = plPlayerController.subtitleStrokeWidth;
    subtitleFontWeight = plPlayerController.subtitleFontWeight;
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
    final theme = Theme.of(context);

    final sliderTheme = SliderThemeData(
      trackHeight: 10,
      trackShape: const MSliderTrackShape(),
      thumbColor: theme.colorScheme.primary,
      activeTrackColor: theme.colorScheme.primary,
      inactiveTrackColor: theme.colorScheme.onInverseSurface,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
    );

    void updateStrokeWidth(double val) {
      subtitleStrokeWidth = val;
      plPlayerController
        ..subtitleStrokeWidth = subtitleStrokeWidth
        ..updateSubtitleStyle();
      setState(() {});
    }

    void updateOpacity(double val) {
      subtitleBgOpaticy = val.toPrecision(2);
      plPlayerController
        ..subtitleBgOpaticy = subtitleBgOpaticy
        ..updateSubtitleStyle();
      setState(() {});
    }

    void updateBottomPadding(double val) {
      subtitlePaddingB = val.round();
      plPlayerController
        ..subtitlePaddingB = subtitlePaddingB
        ..updateSubtitleStyle();
      setState(() {});
    }

    void updateHorizontalPadding(double val) {
      subtitlePaddingH = val.round();
      plPlayerController
        ..subtitlePaddingH = subtitlePaddingH
        ..updateSubtitleStyle();
      setState(() {});
    }

    void updateFontScaleFS(double val) {
      subtitleFontScaleFS = val;
      plPlayerController
        ..subtitleFontScaleFS = subtitleFontScaleFS
        ..updateSubtitleStyle();
      setState(() {});
    }

    void updateFontScale(double val) {
      subtitleFontScale = val;
      plPlayerController
        ..subtitleFontScale = subtitleFontScale
        ..updateSubtitleStyle();
      setState(() {});
    }

    void updateFontWeight(double val) {
      subtitleFontWeight = val.toInt();
      plPlayerController
        ..subtitleFontWeight = subtitleFontWeight
        ..updateSubtitleStyle();
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
                child: Center(child: Text('字幕设置')),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '字体大小 ${(subtitleFontScale * 100).toStringAsFixed(1)}%',
                  ),
                  resetBtn(
                    theme,
                    '100.0%',
                    () => updateFontScale(1.0),
                    isDanmaku: false,
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
                    value: subtitleFontScale,
                    divisions: 20,
                    label:
                        '${(subtitleFontScale * 100).toStringAsFixed(1)}%',
                    onChanged: updateFontScale,
                    onChangeEnd: (_) =>
                        plPlayerController.putSubtitleSettings(),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '全屏字体大小 ${(subtitleFontScaleFS * 100).toStringAsFixed(1)}%',
                  ),
                  resetBtn(
                    theme,
                    '150.0%',
                    () => updateFontScaleFS(1.5),
                    isDanmaku: false,
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
                    value: subtitleFontScaleFS,
                    divisions: 20,
                    label:
                        '${(subtitleFontScaleFS * 100).toStringAsFixed(1)}%',
                    onChanged: updateFontScaleFS,
                    onChangeEnd: (_) =>
                        plPlayerController.putSubtitleSettings,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('字体粗细 ${subtitleFontWeight + 1}（可能无法精确调节）'),
                  resetBtn(
                    theme,
                    6,
                    () => updateFontWeight(5),
                    isDanmaku: false,
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
                    value: subtitleFontWeight.toDouble(),
                    divisions: 8,
                    label: '${subtitleFontWeight + 1}',
                    onChanged: updateFontWeight,
                    onChangeEnd: (_) =>
                        plPlayerController.putSubtitleSettings(),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('描边粗细 $subtitleStrokeWidth'),
                  resetBtn(
                    theme,
                    2.0,
                    () => updateStrokeWidth(2.0),
                    isDanmaku: false,
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
                    value: subtitleStrokeWidth,
                    divisions: 10,
                    label: '$subtitleStrokeWidth',
                    onChanged: updateStrokeWidth,
                    onChangeEnd: (_) =>
                        plPlayerController.putSubtitleSettings(),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('左右边距 $subtitlePaddingH'),
                  resetBtn(
                    theme,
                    24,
                    () => updateHorizontalPadding(24),
                    isDanmaku: false,
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
                    max: 100,
                    value: subtitlePaddingH.toDouble(),
                    divisions: 100,
                    label: '$subtitlePaddingH',
                    onChanged: updateHorizontalPadding,
                    onChangeEnd: (_) =>
                        plPlayerController.putSubtitleSettings(),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('底部边距 $subtitlePaddingB'),
                  resetBtn(
                    theme,
                    24,
                    () => updateBottomPadding(24),
                    isDanmaku: false,
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
                    max: 200,
                    value: subtitlePaddingB.toDouble(),
                    divisions: 200,
                    label: '$subtitlePaddingB',
                    onChanged: updateBottomPadding,
                    onChangeEnd: (_) =>
                        plPlayerController.putSubtitleSettings(),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('背景不透明度 ${(subtitleBgOpaticy * 100).toInt()}%'),
                  resetBtn(
                    theme,
                    '67%',
                    () => updateOpacity(0.67),
                    isDanmaku: false,
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
                    value: subtitleBgOpaticy,
                    onChanged: updateOpacity,
                    onChangeEnd: (_) =>
                        plPlayerController.putSubtitleSettings(),
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
