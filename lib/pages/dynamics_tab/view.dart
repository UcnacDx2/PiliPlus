import 'dart:async';

import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/dynamic/dynamics_type.dart';
import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/pages/common/common_page.dart';
import 'package:PiliPlus/pages/dynamics/controller.dart';
import 'package:PiliPlus/pages/dynamics/widgets/dynamic_panel.dart';
import 'package:PiliPlus/pages/dynamics_tab/controller.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/utils/global_data.dart';
import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_v.dart';
import 'package:PiliPlus/models/common/dynamic/dynamic_to_rec_video_adapter.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/utils/waterfall.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:waterfall_flow/waterfall_flow.dart'
    hide SliverWaterfallFlowDelegateWithMaxCrossAxisExtent;

class DynamicsTabPage extends StatefulWidget {
  const DynamicsTabPage({super.key, required this.dynamicsType});

  final DynamicsTabType dynamicsType;

  @override
  State<DynamicsTabPage> createState() => _DynamicsTabPageState();
}

class _DynamicsTabPageState
    extends CommonPageState<DynamicsTabPage, DynamicsTabController>
    with AutomaticKeepAliveClientMixin, DynMixin {
  StreamSubscription? _listener;
  late final MainController _mainController = Get.find<MainController>();

  DynamicsController dynamicsController = Get.put(DynamicsController());
  @override
  late DynamicsTabController controller = Get.put(
    DynamicsTabController(dynamicsType: widget.dynamicsType)
      ..mid = dynamicsController.mid.value,
    tag: widget.dynamicsType.name,
  );

  @override
  bool get wantKeepAlive => true;

  bool get checkPage =>
      _mainController.navigationBars[0] != NavigationBarType.dynamics &&
      _mainController.selectedIndex.value == 0;

  @override
  bool onNotification(UserScrollNotification notification) {
    if (checkPage) {
      return false;
    }
    return super.onNotification(notification);
  }

  @override
  void listener() {
    if (checkPage) {
      return;
    }
    super.listener();
  }

  @override
  void initState() {
    super.initState();
    if (widget.dynamicsType == DynamicsTabType.up) {
      _listener = dynamicsController.mid.listen((mid) {
        if (mid != -1) {
          controller
            ..mid = mid
            ..onReload();
        }
      });
    }
  }

  @override
  void dispose() {
    _listener?.cancel();
    dynamicsController.mid.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final body = refreshIndicator(
      onRefresh: () {
        dynamicsController.queryFollowUp();
        return controller.onRefresh();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: controller.scrollController,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              top: widget.dynamicsType == DynamicsTabType.videoNew
                  ? StyleString.cardSpace
                  : 0,
              bottom: 100,
            ),
            sliver: buildPage(
              Obx(() => _buildBody(controller.loadingState.value)),
            ),
          ),
        ],
      ),
    );

    return onBuild(
      widget.dynamicsType == DynamicsTabType.videoNew
          ? Container(
              clipBehavior: Clip.hardEdge,
              margin:
                  const EdgeInsets.symmetric(horizontal: StyleString.safeSpace),
              decoration:
                  const BoxDecoration(borderRadius: StyleString.mdRadius),
              child: body,
            )
          : body,
    );
  }

  late final gridDelegate = SliverGridDelegateWithExtentAndRatio(
    mainAxisSpacing: StyleString.cardSpace,
    crossAxisSpacing: StyleString.cardSpace,
    maxCrossAxisExtent: Grid.smallCardWidth,
    childAspectRatio: StyleString.aspectRatio,
    mainAxisExtent: MediaQuery.textScalerOf(context).scale(90),
  );

  Widget _buildBody(LoadingState<List<DynamicItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => dynSkeleton,
      Success(:var response) =>
<<<<<<< HEAD
        response != null && response.isNotEmpty
            ? GlobalData().dynamicsWaterfallFlow
                  ? SliverWaterfallFlow(
                      gridDelegate: dynGridDelegate,
                      delegate: SliverChildBuilderDelegate(
                        (_, index) {
                          if (index == response.length - 1) {
                            controller.onLoadMore();
                          }
                          final item = response[index];
                          return DynamicPanel(
                            item: item,
                            onRemove: (idStr) =>
                                controller.onRemove(index, idStr),
                            onBlock: () => controller.onBlock(index),
                            maxWidth: maxWidth,
                            onUnfold: () => controller.onUnfold(item, index),
                          );
                        },
                        childCount: response.length,
                      ),
                    )
                  : SliverList.builder(
                      itemBuilder: (context, index) {
                        if (index == response.length - 1) {
                          controller.onLoadMore();
                        }
                        final item = response[index];
                        return DynamicPanel(
                          item: item,
                          onRemove: (idStr) =>
                              controller.onRemove(index, idStr),
                          onBlock: () => controller.onBlock(index),
                          maxWidth: maxWidth,
                          onUnfold: () => controller.onUnfold(item, index),
                        );
                      },
                      itemCount: response.length,
                    )
            : HttpError(onReload: controller.onReload),
=======
        _buildSuccess(context, response),
>>>>>>> b85ec6680 (feat: Isolate dynamics submission tab style)
      Error(:var errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }

  Widget _buildSuccess(
      BuildContext context, List<DynamicItemModel>? response) {
    if (response?.isNotEmpty != true) {
      return HttpError(onReload: controller.onReload);
    }
    if (widget.dynamicsType == DynamicsTabType.videoNew) {
      return SliverGrid.builder(
        gridDelegate: gridDelegate,
        itemBuilder: (context, index) {
          if (response != null && index == response.length - 1) {
            controller.onLoadMore();
          }
          return VideoCardV(
            videoItem: DynamicToRecVideoAdapter(response![index]),
            onRemove: () =>
                controller.onRemove(index, response[index].idStr),
          );
        },
        itemCount: response?.length ?? 0,
      );
    } else {
      return GlobalData().dynamicsWaterfallFlow
          ? SliverWaterfallFlow(
              gridDelegate: dynGridDelegate,
              delegate: SliverChildBuilderDelegate(
                (_, index) {
                  if (response != null && index == response.length - 1) {
                    controller.onLoadMore();
                  }
                  final item = response![index];
                  return DynamicPanel(
                    item: item,
                    onRemove: (idStr) => controller.onRemove(index, idStr),
                    onBlock: () => controller.onBlock(index),
                    maxWidth: maxWidth,
                    onUnfold: () => controller.onUnfold(item, index),
                  );
                },
                childCount: response?.length ?? 0,
              ),
            )
          : SliverList.builder(
              itemBuilder: (context, index) {
                if (response != null && index == response.length - 1) {
                  controller.onLoadMore();
                }
                final item = response![index];
                return DynamicPanel(
                  item: item,
                  onRemove: (idStr) => controller.onRemove(index, idStr),
                  onBlock: () => controller.onBlock(index),
                  maxWidth: maxWidth,
                  onUnfold: () => controller.onUnfold(item, index),
                );
              },
              itemCount: response?.length ?? 0,
            );
    }
  }
}
