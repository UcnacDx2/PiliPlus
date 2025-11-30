import 'dart:io';

import 'package:PiliPlus/common/widgets/custom_icon.dart';
import 'package:PiliPlus/models/common/video/video_quality.dart';
import 'package:PiliPlus/models/model_video.dart';
import 'package:PiliPlus/models/video/play/url.dart';
import 'package:PiliPlus/pages/setting/widgets/select_dialog.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/pages/video/widgets/settings_panels/danmaku_settings_panel.dart';
import 'package:PiliPlus/pages/video/widgets/settings_panels/subtitle_settings_panel.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_repeat.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/common/account_type.dart';
import 'package:PiliPlus/models/home/rcmd/result.dart';
import 'package:PiliPlus/models_new/space/space_archive/item.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:PiliPlus/pages/search/widgets/search_text.dart';
import 'package:PiliPlus/pages/video/ai_conclusion/view.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/controller.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hive/hive.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:convert';
import 'package:PiliPlus/models_new/video/video_play_info/subtitle.dart';

class TVPopupMenu {
  static void show(
    BuildContext context, {
    BaseSimpleVideoItemModel? videoItem,
    PlPlayerController? plPlayerController,
    VideoDetailController? videoDetailController,
    Function? onRemove,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TVPopupMenuDialog(
          videoItem: videoItem,
          plPlayerController: plPlayerController,
          videoDetailController: videoDetailController,
          onRemove: onRemove,
        );
      },
    );
  }
}

class TVPopupMenuDialog extends StatefulWidget {
  final BaseSimpleVideoItemModel? videoItem;
  final PlPlayerController? plPlayerController;
  final VideoDetailController? videoDetailController;
  final Function? onRemove;

  const TVPopupMenuDialog({
    super.key,
    this.videoItem,
    this.plPlayerController,
    this.videoDetailController,
    this.onRemove,
  });

  @override
  State<TVPopupMenuDialog> createState() => _TVPopupMenuDialogState();
}

class _TVPopupMenuDialogState extends State<TVPopupMenuDialog> {
  @override
  Widget build(BuildContext context) {
    final List<_VideoCustomAction> actions = [];

    if (widget.videoItem != null) {
      actions.addAll(_buildVideoCardActions());
    }

    if (widget.plPlayerController != null &&
        widget.videoDetailController != null) {
      actions.addAll(_buildPlayerActions());
    }

    return AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: actions
              .map(
                (e) => ListTile(
                  leading: e.icon,
                  title: Text(e.title),
                  onTap: () {
                    Get.back();
                    e.onTap();
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  List<_VideoCustomAction> _buildVideoCardActions() {
    final List<_VideoCustomAction> actions = [];
    if (widget.videoItem!.bvid?.isNotEmpty == true) {
      actions.addAll([
        _VideoCustomAction(
          widget.videoItem!.bvid!,
          const Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(MdiIcons.identifier, size: 16),
              Icon(MdiIcons.circleOutline, size: 16),
            ],
          ),
          () => Utils.copyText(widget.videoItem!.bvid!),
        ),
        _VideoCustomAction(
          '稍后再看',
          const Icon(MdiIcons.clockTimeEightOutline, size: 16),
          () async {
            var res = await UserHttp.toViewLater(
              bvid: widget.videoItem!.bvid,
            );
            SmartDialog.showToast(res['msg']);
          },
        ),
        if (widget.videoItem!.cid != null && Pref.enableAi)
          _VideoCustomAction(
            'AI总结',
            const Stack(
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
            () async {
              final res = await UgcIntroController.getAiConclusion(
                widget.videoItem!.bvid!,
                widget.videoItem!.cid!,
                widget.videoItem!.owner.mid,
              );
              if (res != null) {
                showDialog(
                  context: Get.context!,
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
      ]);
    }
    if (widget.videoItem is! SpaceArchiveItem) {
      actions.addAll([
        _VideoCustomAction(
          '访问：${widget.videoItem!.owner.name}',
          const Icon(MdiIcons.accountCircleOutline, size: 16),
          () => Get.toNamed('/member?mid=${widget.videoItem!.owner.mid}'),
        ),
        _VideoCustomAction(
          '不感兴趣',
          const Icon(MdiIcons.thumbDownOutline, size: 16),
          () {
            String? accessKey = Accounts.get(
              AccountType.recommend,
            ).accessKey;
            if (accessKey == null || accessKey == "") {
              SmartDialog.showToast("请退出账号后重新登录");
              return;
            }
            if (widget.videoItem case RecVideoItemAppModel item) {
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
                      widget.onRemove?.call();
                    }
                  },
                );
              }

              showDialog(
                context: Get.context!,
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
                context: Get.context!,
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
                                    bvid: widget.videoItem!.bvid!,
                                    type: true,
                                  );
                                  SmartDialog.dismiss();
                                  SmartDialog.showToast(
                                    res['status'] ? "点踩成功" : res['msg'],
                                  );
                                  if (res['status']) {
                                    widget.onRemove?.call();
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
                                    bvid: widget.videoItem!.bvid!,
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
        _VideoCustomAction(
          '拉黑：${widget.videoItem!.owner.name}',
          const Icon(MdiIcons.cancel, size: 16),
          () => showDialog(
            context: Get.context!,
            builder: (context) {
              return AlertDialog(
                title: const Text('提示'),
                content: Text(
                  '确定拉黑:${widget.videoItem!.owner.name}(${widget.videoItem!.owner.mid})?'
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
                        mid: widget.videoItem!.owner.mid!,
                        act: 5,
                        reSrc: 11,
                      );
                      if (res['status']) {
                        widget.onRemove?.call();
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
      ]);
    }

    actions.add(
      _VideoCustomAction(
        "${MineController.anonymity.value ? '退出' : '进入'}无痕模式",
        MineController.anonymity.value
            ? const Icon(MdiIcons.incognitoOff, size: 16)
            : const Icon(MdiIcons.incognito, size: 16),
        MineController.onChangeAnonymity,
      ),
    );

    return actions;
  }

  List<_VideoCustomAction> _buildPlayerActions() {
    return [
      _VideoCustomAction(
        '选择画质',
        const Icon(Icons.play_circle_outline, size: 20),
        () => showSetVideoQa(),
      ),
      if (widget.videoDetailController!.currentAudioQa != null)
        _VideoCustomAction(
          '选择音质',
          const Icon(Icons.album_outlined, size: 20),
          () => showSetAudioQa(),
        ),
      _VideoCustomAction(
        '解码格式',
        const Icon(Icons.av_timer_outlined, size: 20),
        () => showSetDecodeFormats(),
      ),
      _VideoCustomAction(
        '播放顺序',
        const Icon(Icons.repeat, size: 20),
        () => showSetRepeat(),
      ),
      _VideoCustomAction(
        '弹幕设置',
        const Icon(CustomIcons.dm_settings, size: 20),
        () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                content: SizedBox(
                  width: 400,
                  height: 500,
                  child: DanmakuSettingsPanel(
                    plPlayerController: plPlayerController,
                  ),
                ),
              );
            },
          );
        },
      ),
      _VideoCustomAction(
        '字幕设置',
        const Icon(Icons.subtitles_outlined, size: 20),
        () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                content: SizedBox(
                  width: 400,
                  height: 500,
                  child: SubtitleSettingsPanel(
                    plPlayerController: plPlayerController,
                  ),
                ),
              );
            },
          );
        },
      ),
      _VideoCustomAction(
        '加载字幕',
        const Icon(Icons.file_open_outlined, size: 20),
        () async {
          try {
            final FilePickerResult? file =
                await FilePicker.platform.pickFiles();
            if (file != null) {
              final first = file.files.first;
              final path = first.path;
              if (path != null) {
                final file = File(path);
                final stream = file.openRead().transform(
                      utf8.decoder,
                    );
                final buffer = StringBuffer();
                await for (final chunk in stream) {
                  buffer.write(chunk);
                }
                String sub = buffer.toString();
                final name = first.name;
                if (name.endsWith('.json')) {
                  sub = await compute<List, String>(
                    VideoHttp.processList,
                    jsonDecode(sub)['body'],
                  );
                }
                final length = widget.videoDetailController!.subtitles.length;
                widget.videoDetailController!
                  ..subtitles.add(
                    Subtitle(
                      lan: '',
                      lanDoc: name.split('.').firstOrNull ?? name,
                    ),
                  )
                  ..vttSubtitles[length] = sub;
                await widget.videoDetailController!.setSubtitle(length + 1);
              }
            }
          } catch (e) {
            SmartDialog.showToast('加载失败: $e');
          }
        },
      ),
    ];
  }

  PlPlayerController get plPlayerController => widget.plPlayerController!;

  VideoDetailController get videoDetailController =>
      widget.videoDetailController!;

  PlayUrlModel get videoInfo => videoDetailController.data;
  Box get setting => GStorage.setting;

  /// 选择画质
  void showSetVideoQa() {
    if (videoInfo.dash == null) {
      SmartDialog.showToast('当前视频不支持选择画质');
      return;
    }
    final VideoQuality? currentVideoQa = videoDetailController.currentVideoQa.value;
    if (currentVideoQa == null) return;

    final List<FormatItem> videoFormat = videoInfo.supportFormats!;
    showDialog(
        context: context,
        builder: (context) {
          return SelectDialog(
            title: '选择画质',
            options: videoFormat,
            optionTitleBuilder: (item) => (item as FormatItem).newDesc!,
            isSelected: (item) =>
                currentVideoQa.code == (item as FormatItem).quality,
            onSelect: (item) async {
              Get.back();
              final int quality = (item as FormatItem).quality!;
              final newQa = VideoQuality.fromCode(quality);
              videoDetailController
                ..plPlayerController.cacheVideoQa = newQa.code
                ..currentVideoQa.value = newQa
                ..updatePlayer();

              SmartDialog.showToast("画质已变为：${newQa.desc}");

              if (!plPlayerController.tempPlayerConf) {
                setting.put(
                  await Utils.isWiFi
                      ? SettingBoxKey.defaultVideoQa
                      : SettingBoxKey.defaultVideoQaCellular,
                  quality,
                );
              }
            },
          );
        });
  }

  void showSetAudioQa() {
    final currentAudioQa = videoDetailController.currentAudioQa!;
    final List<AudioItem> audio = videoInfo.dash!.audio!;

    showDialog(
      context: context,
      builder: (context) {
        return SelectDialog(
          title: '选择音质',
          options: audio,
          optionTitleBuilder: (item) => (item as AudioItem).quality,
          isSelected: (item) =>
              currentAudioQa.code == (item as AudioItem).id,
          onSelect: (item) async {
            Get.back();
            final int quality = (item as AudioItem).id!;
            final newQa = AudioQuality.fromCode(quality);
            videoDetailController
              ..plPlayerController.cacheAudioQa = newQa.code
              ..currentAudioQa = newQa
              ..updatePlayer();

            SmartDialog.showToast("音质已变为：${newQa.desc}");

            if (!plPlayerController.tempPlayerConf) {
              setting.put(
                await Utils.isWiFi
                    ? SettingBoxKey.defaultAudioQa
                    : SettingBoxKey.defaultAudioQaCellular,
                quality,
              );
            }
          },
        );
      },
    );
  }

  void showSetDecodeFormats() {
    final firstVideo = videoDetailController.firstVideo;
    final List<FormatItem> videoFormat = videoInfo.supportFormats!;
    final List<String>? list = videoFormat
        .firstWhere((e) => e.quality == firstVideo.quality.code)
        .codecs;
    if (list == null) {
      SmartDialog.showToast('当前视频不支持选择解码格式');
      return;
    }

    final currentDecodeFormats = videoDetailController.currentDecodeFormats;
    showDialog(
      context: context,
      builder: (context) {
        return SelectDialog(
          title: '选择解码格式',
          options: list,
          optionTitleBuilder: (item) =>
              VideoDecodeFormatType.fromString(item as String).description,
          isSelected: (item) => currentDecodeFormats.codes.any(
            (item as String).startsWith,
          ),
          onSelect: (item) {
            Get.back();
            final format =
                VideoDecodeFormatType.fromString(item as String);
            videoDetailController
              ..currentDecodeFormats = format
              ..updatePlayer();
          },
        );
      },
    );
  }

  void showSetRepeat() {
    showDialog(
      context: context,
      builder: (context) {
        return SelectDialog(
          title: '选择播放顺序',
          options: PlayRepeat.values,
          optionTitleBuilder: (item) => (item as PlayRepeat).desc,
          isSelected: (item) => plPlayerController.playRepeat == item,
          onSelect: (item) {
            Get.back();
            plPlayerController.setPlayRepeat(item as PlayRepeat);
          },
        );
      },
    );
  }
}

class _VideoCustomAction {
  final String title;
  final Widget icon;
  final VoidCallback onTap;
  const _VideoCustomAction(this.title, this.icon, this.onTap);
}
