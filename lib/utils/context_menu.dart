import 'package:flutter/material.dart';

import 'package:PiliPlus/common/widgets/video_card/video_card_h.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_v.dart';

class ContextMenu {
  static Future<void> onKey(BuildContext context, KeyEvent event) async {
    final videoCard = _findVideoCard(FocusManager.instance.primaryFocus);
    if (videoCard == null) return;
    Actions.invoke(videoCard, const ShowContextMenuIntent(Offset.zero));
  }

  static BuildContext? _findVideoCard(FocusNode? focusNode) {
    if (focusNode?.context == null) return null;
    final context = focusNode!.context!;
    final isDescendantOfVideoCard =
        context.findAncestorWidgetOfExactType<VideoCardV>() != null ||
            context.findAncestorWidgetOfExactType<VideoCardH>() != null;

    return isDescendantOfVideoCard ? context : null;
  }
}
