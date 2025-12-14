import 'package:flutter/widgets.dart';

class TVFocusManager {
  final FocusNode seekBarNode = FocusNode(debugLabel: 'SeekBar');
  final FocusNode playButtonNode = FocusNode(debugLabel: 'PlayButton');
  final FocusNode qualityButtonNode = FocusNode(debugLabel: 'QualityButton');

  void dispose() {
    seekBarNode.dispose();
    playButtonNode.dispose();
    qualityButtonNode.dispose();
  }
}
