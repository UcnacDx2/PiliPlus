import 'package:flutter/widgets.dart';

class TVFocusManager {
  // 1. Upper Anchor: Play/Pause Button
  final FocusNode playButtonNode = FocusNode(debugLabel: 'Main-PlayBtn');

  // 2. Center Anchor: Seek Bar
  final FocusNode seekBarNode = FocusNode(debugLabel: 'Center-SeekBar');

  // 3. Lower Anchor: Quality Button
  final FocusNode qualityButtonNode = FocusNode(debugLabel: 'Sub-QualityBtn');

  // Focus Nodes for Popup Buttons
  final FocusNode superResolutionButtonNode = FocusNode(debugLabel: 'Sub-SuperResolutionBtn');
  final FocusNode fitButtonNode = FocusNode(debugLabel: 'Sub-FitBtn');
  final FocusNode speedButtonNode = FocusNode(debugLabel: 'Sub-SpeedBtn');
  final FocusNode subtitleButtonNode = FocusNode(debugLabel: 'Sub-SubtitleBtn');
  final FocusNode aiTranslateButtonNode = FocusNode(debugLabel: 'Sub-AITranslateBtn');

  void dispose() {
    playButtonNode.dispose();
    seekBarNode.dispose();
    qualityButtonNode.dispose();
    superResolutionButtonNode.dispose();
    fitButtonNode.dispose();
    speedButtonNode.dispose();
    subtitleButtonNode.dispose();
    aiTranslateButtonNode.dispose();
  }
}
