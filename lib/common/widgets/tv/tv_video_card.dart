import 'package:PiliPlus/common/widgets/video_card/video_card_v.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/utils/tv/focus_effects.dart';
import 'package:flutter/material.dart';
import 'package:dpad/dpad.dart';

class TVVideoCard extends StatelessWidget {
  final BaseRecVideoItemModel videoItem;
  final VoidCallback? onRemove;
  final bool autofocus;
  final bool isEntryPoint;

  const TVVideoCard({
    super.key,
    required this.videoItem,
    this.onRemove,
    this.autofocus = false,
    this.isEntryPoint = false,
  });

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      autofocus: autofocus,
      isEntryPoint: isEntryPoint,
      effects: [TVFocusEffects.primary(context)],
      child: VideoCardV(
        videoItem: videoItem,
        onRemove: onRemove,
      ),
    );
  }
}
