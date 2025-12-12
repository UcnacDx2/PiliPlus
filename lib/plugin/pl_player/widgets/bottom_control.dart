import 'package:PiliPlus/common/widgets/progress_bar/audio_video_progress_bar.dart';
import 'package:PiliPlus/common/widgets/progress_bar/segment_progress_bar.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/utils/focus_manager.dart';
import 'package:PiliPlus/plugin/pl_player/view.dart';
import 'package:PiliPlus/utils/extension.dart';
import 'package:PiliPlus/utils/feed_back.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ControlRows {
  const ControlRows({required this.top, required this.bottom});
  final Widget top;
  final Widget bottom;
}

class BottomControl extends StatefulWidget {
  const BottomControl({
    super.key,
    required this.maxWidth,
    required this.isFullScreen,
    required this.controller,
    required this.buildBottomControl,
    required this.videoDetailController,
  });

  final double maxWidth;
  final bool isFullScreen;
  final PlPlayerController controller;
  final ControlRows Function(BottomControlsFocusManager focusManager)
  buildBottomControl;
  final VideoDetailController videoDetailController;

  @override
  State<BottomControl> createState() => _BottomControlState();
}

class _BottomControlState extends State<BottomControl> {
  late final BottomControlsFocusManager focusManager =
      BottomControlsFocusManager();
  bool _progressFocused = false;
  int _lastPrimaryIndex = 0;
  int _lastSecondaryIndex = 0;

  PlPlayerController get controller => widget.controller;

  @override
  void dispose() {
    focusManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final primary = colorScheme.isLight
        ? colorScheme.inversePrimary
        : colorScheme.primary;
    final thumbGlowColor = primary.withAlpha(80);
    final bufferedBarColor = primary.withValues(alpha: 0.4);
    final Color focusColor = colorScheme.primary.withAlpha(90);

    void onDragStart(ThumbDragDetails duration) {
      feedBack();
      controller.onChangedSliderStart(duration.timeStamp);
    }

    void onDragUpdate(ThumbDragDetails duration, int max) {
      if (!controller.isFileSource && controller.showSeekPreview) {
        controller.updatePreviewIndex(duration.timeStamp.inSeconds);
      }
      controller.onUpdatedSliderProgress(duration.timeStamp);
    }

    void onSeek(Duration duration, int max) {
      if (controller.showSeekPreview) {
        controller.showPreview.value = false;
      }
      controller
        ..onChangedSliderEnd()
        ..onChangedSlider(duration.inSeconds.toDouble())
        ..seekTo(Duration(seconds: duration.inSeconds), isSeek: false);
    }

    KeyEventResult handleProgressKey(KeyEvent event) {
      if (event is! KeyDownEvent) return KeyEventResult.ignored;
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.arrowLeft) {
        controller.onBackward(controller.fastForBackwardDuration);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowRight) {
        controller.onForward(controller.fastForBackwardDuration);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    Widget progressBar() {
      final Widget bar = Obx(() {
        final int value = controller.sliderPositionSeconds.value;
        final int max = controller.durationSeconds.value.inSeconds;
        if (value > max || max <= 0) {
          return const SizedBox.shrink();
        }
        return ProgressBar(
          progress: Duration(seconds: value),
          buffered: Duration(seconds: controller.bufferedSeconds.value),
          total: Duration(seconds: max),
          progressBarColor: primary,
          baseBarColor: const Color(0x33FFFFFF),
          bufferedBarColor: bufferedBarColor,
          thumbColor: primary,
          thumbGlowColor: thumbGlowColor,
          barHeight: 3.5,
          thumbRadius: 7,
          thumbGlowRadius: 25,
          onDragStart: onDragStart,
          onDragUpdate: (e) => onDragUpdate(e, max),
          onSeek: (e) => onSeek(e, max),
        );
      });

      final Widget child = Focus(
        focusNode: focusManager.progressNode,
        onFocusChange: (focused) {
          if (_progressFocused != focused) {
            setState(() => _progressFocused = focused);
          }
        },
        onKeyEvent: (node, event) => handleProgressKey(event),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: _progressFocused
                ? Border.all(color: focusColor, width: 1.1)
                : null,
          ),
          child: bar,
        ),
      );

      if (Utils.isDesktop) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: child,
        );
      }
      return child;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      child: BottomControlsFocusMarker(
        child: Focus(
          // Custom navigation to keep vertical movement aligned by index and
          // prevent focus loss on left at row start.
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            final logicalKey = event.logicalKey;
            final primaryNodes = focusManager.primaryNodesList;
            final secondaryNodes = focusManager.secondaryNodesList;
            final current = FocusManager.instance.primaryFocus;
            final int primaryIndex = primaryNodes.indexWhere((n) => n.hasFocus);
            final int secondaryIndex = secondaryNodes.indexWhere(
              (n) => n.hasFocus,
            );
            // Remember last visited indices for mapping through progress bar.
            if (primaryIndex >= 0) {
              _lastPrimaryIndex = primaryIndex;
            }
            if (secondaryIndex >= 0) {
              _lastSecondaryIndex = secondaryIndex;
            }

            if (logicalKey == LogicalKeyboardKey.arrowDown) {
              if (current == focusManager.progressNode) {
                if (secondaryNodes.isNotEmpty) {
                  FocusScope.of(context).requestFocus(secondaryNodes.first);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              }
              return KeyEventResult.ignored;
            }

            if (logicalKey == LogicalKeyboardKey.arrowUp) {
              if (current == focusManager.progressNode) {
                if (primaryNodes.isNotEmpty) {
                  FocusScope.of(context).requestFocus(primaryNodes.first);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              }
              return KeyEventResult.ignored;
            }

            if (logicalKey == LogicalKeyboardKey.arrowLeft &&
                secondaryNodes.isNotEmpty &&
                secondaryIndex >= 0) {
              if (secondaryIndex <= 0) {
                FocusScope.of(context).requestFocus(secondaryNodes.first);
                return KeyEventResult.handled;
              }
              FocusScope.of(
                context,
              ).requestFocus(secondaryNodes[secondaryIndex - 1]);
              return KeyEventResult.handled;
            }

            return KeyEventResult.ignored;
          },
          child: FocusTraversalGroup(
            policy: WidgetOrderTraversalPolicy(),
            child: FocusScope(
              node: focusManager.scopeNode,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Builder(
                    builder: (context) {
                      final rows = widget.buildBottomControl(focusManager);
                      return Column(
                        children: [
                          rows.top,
                          const SizedBox(height: 6),
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.bottomCenter,
                            children: [
                              progressBar(),
                              if (controller.enableBlock &&
                                  widget
                                      .videoDetailController
                                      .segmentProgressList
                                      .isNotEmpty)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 5.25,
                                  child: IgnorePointer(
                                    child: RepaintBoundary(
                                      child: CustomPaint(
                                        key: const Key('segmentList'),
                                        size: const Size(double.infinity, 3.5),
                                        painter: SegmentProgressBar(
                                          segmentColors: widget
                                              .videoDetailController
                                              .segmentProgressList,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (controller.showViewPoints &&
                                  widget
                                      .videoDetailController
                                      .viewPointList
                                      .isNotEmpty &&
                                  widget
                                      .videoDetailController
                                      .showVP
                                      .value) ...[
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 5.25,
                                  child: IgnorePointer(
                                    child: RepaintBoundary(
                                      child: CustomPaint(
                                        key: const Key('viewPointList'),
                                        size: const Size(double.infinity, 3.5),
                                        painter: SegmentProgressBar(
                                          segmentColors: widget
                                              .videoDetailController
                                              .viewPointList,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (!Utils.isMobile)
                                  buildViewPointWidget(
                                    widget.videoDetailController,
                                    controller,
                                    8.75,
                                    widget.maxWidth - 40,
                                  ),
                              ],
                              if (widget
                                  .videoDetailController
                                  .showDmTrendChart
                                  .value)
                                if (widget
                                        .videoDetailController
                                        .dmTrend
                                        .value
                                        ?.dataOrNull
                                    case final list?)
                                  buildDmChart(
                                    primary,
                                    list,
                                    widget.videoDetailController,
                                    4.5,
                                  ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          rows.bottom,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
