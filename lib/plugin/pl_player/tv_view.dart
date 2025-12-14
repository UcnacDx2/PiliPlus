import 'package:PiliPlus/pages/common/common_intro_controller.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/plugin/pl_player/tv_controller.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/tv_bottom_control.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/tv_progress_control.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/tv_top_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// TV端播放器视图
/// 专为TV遥控器交互设计，移除触摸手势，使用焦点管理系统
class TvVideoPlayer extends StatefulWidget {
  const TvVideoPlayer({
    required this.maxWidth,
    required this.maxHeight,
    required this.tvPlayerController,
    this.videoDetailController,
    this.introController,
    this.danmuWidget,
    this.fill = Colors.black,
    this.alignment = Alignment.center,
    super.key,
  });

  final double maxWidth;
  final double maxHeight;
  final TvPlayerController tvPlayerController;
  final VideoDetailController? videoDetailController;
  final CommonIntroController? introController;
  final Widget? danmuWidget;
  final Color fill;
  final Alignment alignment;

  @override
  State<TvVideoPlayer> createState() => _TvVideoPlayerState();
}

class _TvVideoPlayerState extends State<TvVideoPlayer> {
  late TvPlayerController controller;
  late VideoController videoController;

  @override
  void initState() {
    super.initState();
    controller = widget.tvPlayerController;
    videoController = controller.videoController!;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.fill,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          // 遮罩隐藏时的按键处理（盲操）
          if (!controller.showControls.value) {
            return controller.handleKeyEventWhenHidden(event);
          }
          
          // 遮罩显示时，返回键特殊处理
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.escape ||
                  event.logicalKey == LogicalKeyboardKey.goBack)) {
            return controller.handleBackKey();
          }
          
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            // 视频播放层
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9, // TODO: 根据实际视频比例调整
                child: Video(
                  controller: videoController,
                  fill: widget.fill,
                  alignment: widget.alignment,
                ),
              ),
            ),

            // 弹幕层
            if (widget.danmuWidget != null)
              Positioned.fill(
                child: widget.danmuWidget!,
              ),

            // TV控制层
            Obx(() {
              if (!controller.showControls.value) {
                return const SizedBox.shrink();
              }

              return Stack(
                children: [
                  // 半透明背景
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),

                  // 三段式布局
                  Column(
                    children: [
                      // 顶部控制区 (Area A)
                      Obx(() {
                        if (controller.currentFocusArea.value == FocusArea.top) {
                          return TvTopControl(
                            controller: controller,
                            title: widget.introController?.videoDetail.value.title ?? '',
                            onBack: () {
                              // TODO: 实现返回逻辑
                              Get.back();
                            },
                            onNext: () {
                              // TODO: 实现下一集逻辑
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      }),

                      const Spacer(),

                      // 进度条区 (Area B)
                      Obx(() {
                        if (controller.currentFocusArea.value == FocusArea.progress) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: TvProgressControl(
                              controller: controller,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),

                      const SizedBox(height: 24),

                      // 底部功能区 (Area C)
                      Obx(() {
                        if (controller.currentFocusArea.value == FocusArea.bottom) {
                          return TvBottomControl(
                            controller: controller,
                            onQualityTap: () {
                              // TODO: 实现画质选择
                            },
                            onSpeedTap: () {
                              // TODO: 实现倍速选择
                            },
                            onSubtitleTap: () {
                              // TODO: 实现字幕选择
                            },
                            onSettingsTap: () {
                              // TODO: 实现设置面板
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      }),

                      const SizedBox(height: 24),
                    ],
                  ),

                  // 缓冲指示器
                  Obx(() {
                    if (controller.isBuffering.value) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
