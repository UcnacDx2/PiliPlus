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
      builder: (context, isFocused) {
        return Transform.scale(
          scale: isFocused ? 1.05 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isFocused
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: VideoCardV(
              videoItem: videoItem,
              onRemove: onRemove,
            ),
          ),
        );
      },
    );
  }
}
