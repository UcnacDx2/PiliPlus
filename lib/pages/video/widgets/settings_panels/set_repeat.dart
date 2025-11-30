import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_repeat.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SetRepeatPanel extends StatelessWidget {
  const SetRepeatPanel({
    super.key,
    required this.videoDetailCtr,
    required this.plPlayerController,
  });

  final VideoDetailController videoDetailCtr;
  final PlPlayerController plPlayerController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const titleStyle = TextStyle(fontSize: 14);

    return Material(
      clipBehavior: Clip.hardEdge,
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 45,
              child: Center(
                child: Text('选择播放顺序', style: titleStyle),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: PlayRepeat.values.length,
            itemBuilder: (context, index) {
              final i = PlayRepeat.values[index];
              return ListTile(
                dense: true,
                onTap: () {
                  Get.back();
                  plPlayerController.setPlayRepeat(i);
                },
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                title: Text(i.desc),
                trailing: plPlayerController.playRepeat == i
                    ? Icon(
                        Icons.done,
                        color: theme.colorScheme.primary,
                      )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
