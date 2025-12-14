import 'package:PiliPlus/pages/common/common_intro_controller.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/plugin/pl_player/tv_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
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
    final VideoDetailController videoDetailController = Get.find();
    final CommonIntroController introController =
        videoDetailController.introController;
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
            const SizedBox(width: 12),
            Expanded(
              child: Obx(
                () => Text(
                  introController.videoDetail.value.title ?? '视频标题',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            ComBtn(
              tooltip: '上一集',
              icon: const Icon(
                Icons.skip_previous,
                size: 28,
                color: Colors.white,
              ),
              onTap: () {
                if (!introController.prevPlay()) {
                  SmartDialog.showToast('已经是第一集了');
                }
              },
            ),
            const SizedBox(width: 8),
            PlayOrPauseButton(plPlayerController: controller),
            const SizedBox(width: 8),
            ComBtn(
              tooltip: '下一集',
              icon: const Icon(
                Icons.skip_next,
                size: 28,
                color: Colors.white,
              ),
              onTap: () {
                if (!introController.nextPlay()) {
                  SmartDialog.showToast('已经是最后一集了');
                }
              },
            ),
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
