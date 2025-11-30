import 'package:PiliPlus/common/widgets/pili_popup_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:PiliPlus/common/widgets/video_card/video_card_h.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_v.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/common/account_type.dart';
import 'package:PiliPlus/models/home/rcmd/result.dart';
import 'package:PiliPlus/models/model_video.dart';
import 'package:PiliPlus/models_new/space/space_archive/item.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:PiliPlus/pages/search/widgets/search_text.dart';
import 'package:PiliPlus/pages/video/ai_conclusion/view.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/view.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ContextMenu {
  static Future<void> onKey(BuildContext context, KeyEvent event) async {
    final focusedContext = FocusManager.instance.primaryFocus?.context;
    if (focusedContext == null) return;

    // Check if the focused widget is inside the video player
    if (focusedContext.findAncestorWidgetOfExactType<PLVideoPlayer>() != null) {
      PlPlayerController.instance?.showSettings();
      return;
    }

    List<PiliPopupMenuItem> items = [];

    // Find if the focused widget is a video card
    final videoCard = _findVideoCard(FocusManager.instance.primaryFocus);
    if (videoCard is VideoCardV) {
      items = _getVideoCardMenuItems(
          focusedContext, videoCard.videoItem, videoCard.onRemove);
    } else if (videoCard is VideoCardH) {
      items = _getVideoCardMenuItems(
          focusedContext, videoCard.videoItem, videoCard.onRemove);
    }

    if (items.isEmpty) {
      items.add(
        PiliPopupMenuItem(
          title: 'Exit Program',
          icon: const Icon(Icons.exit_to_app, color: Colors.white, size: 16),
          onTap: () => SystemNavigator.pop(),
        ),
      );
    }

    showPiliPopupMenu(context: focusedContext, items: items);
  }

  static List<PiliPopupMenuItem> _getVideoCardMenuItems(BuildContext context,
      BaseVideoItemModel videoItem, VoidCallback? onRemove) {
    return [
      if (videoItem.bvid?.isNotEmpty == true) ...[
        PiliPopupMenuItem(
          title: videoItem.bvid!,
          icon: const Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(MdiIcons.identifier, size: 16),
              Icon(MdiIcons.circleOutline, size: 16),
            ],
          ),
          onTap: () => Utils.copyText(videoItem.bvid!),
        ),
        PiliPopupMenuItem(
          title: '稍后再看',
          icon: const Icon(MdiIcons.clockTimeEightOutline, size: 16),
          onTap: () async {
            var res = await UserHttp.toViewLater(
              bvid: videoItem.bvid,
            );
            SmartDialog.showToast(res['msg']);
          },
        ),
        if (videoItem.cid != null && Pref.enableAi)
          PiliPopupMenuItem(
            title: 'AI总结',
            icon: const Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.circle_outlined, size: 16),
                ExcludeSemantics(
                  child: Text(
                    'AI',
                    style: TextStyle(
                      fontSize: 10,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                    strutStyle: StrutStyle(
                      fontSize: 10,
                      height: 1,
                      leading: 0,
                      fontWeight: FontWeight.w700,
                    ),
                    textScaler: TextScaler.noScaling,
                  ),
                ),
              ],
            ),
            onTap: () async {
              final res = await UgcIntroController.getAiConclusion(
                videoItem.bvid!,
                videoItem.cid!,
                videoItem.owner.mid,
              );
              if (res != null) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return Dialog(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 280,
                          maxWidth: 420,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          child: AiConclusionPanel.buildContent(
                            context,
                            Theme.of(context),
                            res,
                            tap: false,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
      ],
      if (videoItem is! SpaceArchiveItem) ...[
        PiliPopupMenuItem(
          title: '访问：${videoItem.owner.name}',
          icon: const Icon(MdiIcons.accountCircleOutline, size: 16),
          onTap: () => Get.toNamed('/member?mid=${videoItem.owner.mid}'),
        ),
        PiliPopupMenuItem(
          title: '不感兴趣',
          icon: const Icon(MdiIcons.thumbDownOutline, size: 16),
          onTap: () {
            String? accessKey = Accounts.get(
              AccountType.recommend,
            ).accessKey;
            if (accessKey == null || accessKey == "") {
              SmartDialog.showToast("请退出账号后重新登录");
              return;
            }
            if (videoItem case RecVideoItemAppModel item) {
              ThreePoint? tp = item.threePoint;
              if (tp == null) {
                SmartDialog.showToast("未能获取threePoint");
                return;
              }
              if (tp.dislikeReasons == null && tp.feedbacks == null) {
                SmartDialog.showToast(
                  "未能获取dislikeReasons或feedbacks",
                );
                return;
              }
              Widget actionButton(Reason? r, Reason? f) {
                return SearchText(
                  text: r?.name ?? f?.name ?? '未知',
                  onTap: (_) async {
                    Get.back();
                    SmartDialog.showLoading(msg: '正在提交');
                    var res = await VideoHttp.feedDislike(
                      reasonId: r?.id,
                      feedbackId: f?.id,
                      id: item.param!,
                      goto: item.goto!,
                    );
                    SmartDialog.dismiss();
                    SmartDialog.showToast(
                      res['status'] ? (r?.toast ?? f?.toast) : res['msg'],
                    );
                    if (res['status']) {
                      onRemove?.call();
                    }
                  },
                );
              }

              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (tp.dislikeReasons != null) ...[
                            const Text('我不想看'),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: tp.dislikeReasons!.map((
                                item,
                              ) {
                                return actionButton(item, null);
                              }).toList(),
                            ),
                          ],
                          if (tp.feedbacks != null) ...[
                            const SizedBox(height: 5),
                            const Text('反馈'),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: tp.feedbacks!.map((item) {
                                return actionButton(null, item);
                              }).toList(),
                            ),
                          ],
                          const Divider(),
                          Center(
                            child: FilledButton.tonal(
                              onPressed: () async {
                                SmartDialog.showLoading(
                                  msg: '正在提交',
                                );
                                var res = await VideoHttp.feedDislikeCancel(
                                  id: item.param!,
                                  goto: item.goto!,
                                );
                                SmartDialog.dismiss();
                                SmartDialog.showToast(
                                  res['status'] ? "成功" : res['msg'],
                                );
                                Get.back();
                              },
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text("撤销"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            } else {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    content: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 5),
                          const Text("web端暂不支持精细选择"),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 5.0,
                            runSpacing: 2.0,
                            children: [
                              FilledButton.tonal(
                                onPressed: () async {
                                  Get.back();
                                  SmartDialog.showLoading(
                                    msg: '正在提交',
                                  );
                                  var res = await VideoHttp.dislikeVideo(
                                    bvid: videoItem.bvid!,
                                    type: true,
                                  );
                                  SmartDialog.dismiss();
                                  SmartDialog.showToast(
                                    res['status'] ? "点踩成功" : res['msg'],
                                  );
                                  if (res['status']) {
                                    onRemove?.call();
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text("点踩"),
                              ),
                              FilledButton.tonal(
                                onPressed: () async {
                                  Get.back();
                                  SmartDialog.showLoading(
                                    msg: '正在提交',
                                  );
                                  var res = await VideoHttp.dislikeVideo(
                                    bvid: videoItem.bvid!,
                                    type: false,
                                  );
                                  SmartDialog.dismiss();
                                  SmartDialog.showToast(
                                    res['status'] ? "取消踩" : res['msg'],
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text("撤销"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
        PiliPopupMenuItem(
          title: '拉黑：${videoItem.owner.name}',
          icon: const Icon(MdiIcons.cancel, size: 16),
          onTap: () => showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('提示'),
                content: Text(
                  '确定拉黑:${videoItem.owner.name}(${videoItem.owner.mid})?'
                  '\n\n注：被拉黑的Up可以在隐私设置-黑名单管理中解除',
                ),
                actions: [
                  TextButton(
                    onPressed: Get.back,
                    child: Text(
                      '点错了',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      Get.back();
                      var res = await VideoHttp.relationMod(
                        mid: videoItem.owner.mid!,
                        act: 5,
                        reSrc: 11,
                      );
                      if (res['status']) {
                        onRemove?.call();
                      }
                      SmartDialog.showToast(res['msg'] ?? '成功');
                    },
                    child: const Text('确认'),
                  ),
                ],
              );
            },
          ),
        ),
      ],
      PiliPopupMenuItem(
        title: "${MineController.anonymity.value ? '退出' : '进入'}无痕模式",
        icon: MineController.anonymity.value
            ? const Icon(MdiIcons.incognitoOff, size: 16)
            : const Icon(MdiIcons.incognito, size: 16),
        onTap: MineController.onChangeAnonymity,
      ),
    ];
  }

  static Widget? _findVideoCard(FocusNode? focusNode) {
    if (focusNode?.context == null) return null;
    final context = focusNode!.context!;
    return context.findAncestorWidgetOfExactType<VideoCardV>() ??
        context.findAncestorWidgetOfExactType<VideoCardH>();
  }
}
