import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/pages/video/widgets/header_control.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/utils/extension.dart';
import 'package:flutter/material.dart';

class SetSubtitlePanel extends StatefulWidget {
  const SetSubtitlePanel({
    super.key,
    required this.videoDetailCtr,
    required this.plPlayerController,
  });

  final VideoDetailController videoDetailCtr;
  final PlPlayerController plPlayerController;

  @override
  State<SetSubtitlePanel> createState() => _SetSubtitlePanelState();
}

class _SetSubtitlePanelState extends State<SetSubtitlePanel> with HeaderMixin {
  @override
  PlPlayerController get plPlayerController => widget.plPlayerController;

  @override
  bool get isFullScreen => plPlayerController.isFullScreen.value;

  @override
  Widget build(BuildContext context) {
    double subtitleFontScale = plPlayerController.subtitleFontScale;
    double subtitleFontScaleFS = plPlayerController.subtitleFontScaleFS;
    int subtitlePaddingH = plPlayerController.subtitlePaddingH;
    int subtitlePaddingB = plPlayerController.subtitlePaddingB;
    double subtitleBgOpaticy = plPlayerController.subtitleBgOpaticy;
    double subtitleStrokeWidth = plPlayerController.subtitleStrokeWidth;
    int subtitleFontWeight = plPlayerController.subtitleFontWeight;

    final theme = Theme.of(context);
    const titleStyle = TextStyle(fontSize: 14);

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
              child: Center(child: Text('字幕设置', style: titleStyle)),
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
                  () => updateState(() => plPlayerController.subtitleFontScale = subtitleFontScale = 1.0),
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
                  onChanged: (val) => updateState(() => plPlayerController.subtitleFontScale = subtitleFontScale = val),
                  onChangeEnd: (_) =>
                      plPlayerController.putSubtitleSettings(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
