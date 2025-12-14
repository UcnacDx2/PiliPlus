import 'package:PiliPlus/plugin/pl_player/tv_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/common_btn.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/play_pause_btn.dart';

class TvTopControl extends StatelessWidget {
  const TvTopControl({
    super.key,
    required this.controller,
  });

  final TvPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: controller.focusNodeA,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            ComBtn(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onTap: () => Get.back(),
            ),
            const Spacer(),
            PlayOrPauseButton(plPlayerController: controller),
            ComBtn(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onTap: () {
                // TODO: Implement settings sheet
              },
            ),
          ],
        ),
      ),
    );
  }
}
