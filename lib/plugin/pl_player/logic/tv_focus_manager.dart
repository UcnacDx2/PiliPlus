import 'package:flutter/widgets.dart';

class TVFocusManager {
  // 1. 上方锚点：播放/暂停按钮
  final FocusNode playButtonNode = FocusNode(debugLabel: 'Main-PlayBtn');

  // 2. 中间锚点：进度条
  final FocusNode seekBarNode = FocusNode(debugLabel: 'Center-SeekBar');

  // 3. 下方锚点：画质按钮
  final FocusNode qualityButtonNode = FocusNode(debugLabel: 'Sub-QualityBtn');

  void dispose() {
    playButtonNode.dispose();
    seekBarNode.dispose();
    qualityButtonNode.dispose();
  }
}
