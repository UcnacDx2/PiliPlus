import 'dart:async';

import 'package:PiliPlus/models/common/video/video_quality.dart';
import 'package:PiliPlus/models_new/video/video_detail/episode.dart' as ugc;
import 'package:PiliPlus/models_new/video/video_detail/ugc_season.dart';
import 'package:PiliPlus/pages/common/common_intro_controller.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/pages/video/introduction/pgc/controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_status.dart';
import 'package:PiliPlus/plugin/pl_player/models/video_fit_type.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class TVKeyHandler {
  static TVKeyHandler? instance;
  void Function(String key, String action, bool isRepeat)? callback;
  void handleNativeKey(String key, String action, bool isRepeat) {
    callback?.call(key, action, isRepeat);
  }
}

class TVPlayerControls extends StatefulWidget {
  const TVPlayerControls({
    super.key,
    required this.plPlayerController,
    this.videoDetailController,
    this.introController,
    this.showEpisodes,
    required this.child,
  });

  final PlPlayerController plPlayerController;
  final VideoDetailController? videoDetailController;
  final CommonIntroController? introController;
  final void Function([
    int?,
    UgcSeason?,
    List<ugc.BaseEpisodeItem>?,
    String?,
    int?,
    int?,
  ])?
  showEpisodes;
  final Widget child;

  @override
  State<TVPlayerControls> createState() => _TVPlayerKeyHandlerState();
}

class _TVPlayerKeyHandlerState extends State<TVPlayerControls> {
  static _TVPlayerKeyHandlerState? _sidePanelOwner;
  PlPlayerController get ctr => widget.plPlayerController;
  final _isSubMenuOpen = ValueNotifier<bool>(false);
  bool _isLongPressing = false;
  bool _selectPressed = false;
  int? _pressedButtonIndex;
  // True after we consumed a BACK KeyDown that closed a panel — used to also consume the matching KeyUp
  // so Android's default onKeyUp(BACK) → onBackPressed doesn't fire and exit the video page.
  bool _backConsumed = false;
  double _originalSpeed = 1.0;
  final _showSpeedIndicator = ValueNotifier<double?>(null);

  // TV 控制面板状态: -1=隐藏, 0=进度条, 1=按钮行
  final _panelRow = ValueNotifier<int>(-1);
  final _btnIndex = ValueNotifier<int>(0);

  List<_TVBtnItem> get _buttons {
    final items = <_TVBtnItem>[
      if (widget.introController != null) ...[
        _TVBtnItem(Icons.skip_previous, '上一集', _playPrevious),
        _TVBtnItem(Icons.skip_next, '下一集', _playNext),
        if (widget.showEpisodes != null)
          _TVBtnItem(Icons.video_library_outlined, '选集', _showEpisodePicker),
      ],
      _TVBtnItem(Icons.speed, '${ctr.playbackSpeed}x', _showSpeedPicker),
      if (widget.videoDetailController != null)
        _TVBtnItem(
          Icons.high_quality_outlined,
          widget.videoDetailController!.currentVideoQa.value?.shortDesc ?? '画质',
          _showQualityPicker,
        ),
      _TVBtnItem(
        ctr.enableShowDanmaku.value ? Icons.subtitles : Icons.subtitles_off,
        '弹幕设置',
        _showDanmakuSettings,
      ),
      if (widget.videoDetailController != null)
        _TVBtnItem(
          Icons.closed_caption_outlined,
          '字幕',
          _showSubtitlePicker,
        ),
      _TVBtnItem(Icons.aspect_ratio, '画面比例', _showFitPicker),
    ];
    return items;
  }

  Timer? _hideTimer;

  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 8), () {
      _panelRow.value = -1;
    });
  }

  void _showPanel() {
    _panelRow.value = 0; // 默认在进度条
    _btnIndex.value = 0; // 默认选中倍速（索引0）
    _resetHideTimer();
  }

  void _onKey(String direction) {
    if (_panelRow.value == -1) {
      _showPanel();
      return;
    }
    _resetHideTimer();
    final row = _panelRow.value;
    if (direction == 'up') {
      if (row == 1) _panelRow.value = 0;
    } else if (direction == 'down') {
      if (row == 0) _panelRow.value = 1;
    } else if (direction == 'left') {
      if (row == 0 && !ctr.isLive) {
        ctr.seekTo(Duration(seconds: ctr.position.value - 10));
      } else if (row == 1) {
        final max = _buttons.length - 1;
        _btnIndex.value = (_btnIndex.value - 1).clamp(0, max);
      }
    } else if (direction == 'right') {
      if (row == 0 && !ctr.isLive) {
        ctr.seekTo(Duration(seconds: ctr.position.value + 10));
      } else if (row == 1) {
        final max = _buttons.length - 1;
        _btnIndex.value = (_btnIndex.value + 1).clamp(0, max);
      }
    } else if (direction == 'ok') {
      if (row == 0) {
        ctr.playerStatus.isPlaying ? ctr.pause() : ctr.play();
      } else if (row == 1) {
        _buttons[_btnIndex.value].onTap();
      }
    } else if (direction == 'back') {
      _panelRow.value = -1;
    }
  }

  bool _handleKeyEvent(KeyEvent event) {
    final key = event.logicalKey;
    final isSelect =
        key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter;
    final isBack =
        key == LogicalKeyboardKey.goBack || key == LogicalKeyboardKey.escape;

    if (!_isSubMenuOpen.value && ModalRoute.of(context)?.isCurrent != true) {
      return false;
    }

    // === BACK key (handle BEFORE the KeyUp early-return, otherwise Android's
    // default onKeyUp(BACK) → onBackPressed will fire and exit the video page) ===
    if (isBack) {
      if (_isSubMenuOpen.value) {
        // Sub-menu visible: let subKeyHandler handle it (it consumes all BACK events)
        return false;
      }
      if (event is KeyDownEvent) {
        if (_panelRow.value != -1) {
          // Main panel visible: close it and remember to consume the matching KeyUp
          _panelRow.value = -1;
          _backConsumed = true;
          return true;
        }
        // Nothing visible: let PopScope/system handle (exit video page)
        _backConsumed = false;
        return false;
      }
      if (event is KeyUpEvent || event is KeyRepeatEvent) {
        // If we consumed the KeyDown, consume the rest of this BACK press too
        if (_backConsumed) {
          if (event is KeyUpEvent) _backConsumed = false;
          return true;
        }
        return false;
      }
      return false;
    }

    // Sub-menu open: let the sub-menu's own HardwareKeyboard handler take priority
    if (_isSubMenuOpen.value) {
      return false;
    }

    // Only a KeyUp paired with a KeyDown may activate a control. Some TV
    // remotes emit an additional select/enter KeyUp for one physical press.
    if (isSelect && event is KeyDownEvent) {
      _selectPressed = true;
      _pressedButtonIndex = _panelRow.value == 1 ? _btnIndex.value : null;
      return true;
    }

    // Long-press OK = speed boost (works regardless of panel state)
    if (isSelect && event is KeyRepeatEvent) {
      if (!_isLongPressing) {
        _isLongPressing = true;
        _originalSpeed = ctr.playbackSpeed;
        ctr.setPlaybackSpeed(_originalSpeed + 1.0);
        _showSpeedIndicator.value = _originalSpeed + 1.0;
      }
      return true;
    }
    if (isSelect && event is KeyUpEvent && _isLongPressing) {
      ctr.setPlaybackSpeed(_originalSpeed);
      _isLongPressing = false;
      _selectPressed = false;
      _pressedButtonIndex = null;
      _showSpeedIndicator.value = null;
      return true;
    }

    // OK KeyUp: play/pause (only when not long-pressing)
    if (isSelect && event is KeyUpEvent) {
      if (_selectPressed && !_isLongPressing) {
        final pressedButtonIndex = _pressedButtonIndex;
        _selectPressed = false;
        _pressedButtonIndex = null;
        if (_panelRow.value == -1) {
          if (ctr.playerStatus.isPlaying) {
            ctr.pause();
            _showPanel();
          } else {
            ctr.play();
            _panelRow.value = -1;
          }
        } else if (_panelRow.value == 1 && pressedButtonIndex != null) {
          final buttons = _buttons;
          if (pressedButtonIndex < buttons.length) {
            buttons[pressedButtonIndex].onTap();
          }
        } else {
          _onKey('ok');
        }
      }
      return true;
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return false;
    }

    final isUpDown =
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.audioVolumeUp ||
        key == LogicalKeyboardKey.audioVolumeDown;

    // === Panel hidden ===
    if (_panelRow.value == -1) {
      if (isSelect) {
        return true; // consume KeyDown, KeyUp handles it above
      } else if (key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.arrowRight) {
        if (!ctr.isLive) {
          final s = key == LogicalKeyboardKey.arrowLeft ? -10 : 10;
          ctr.seekTo(Duration(seconds: ctr.position.value + s));
        }
        return true;
      } else if (isUpDown) {
        _showPanel();
        return true;
      } else if (key == LogicalKeyboardKey.contextMenu) {
        _showPanel();
        return true;
      }
      return false;
    }

    // === Panel shown ===
    final row = _panelRow.value;
    if (isSelect) {
      return true; // consume KeyDown, KeyUp handles it above
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      if (row == 0 && !ctr.isLive) {
        final s = key == LogicalKeyboardKey.arrowLeft ? -10 : 10;
        ctr.seekTo(Duration(seconds: ctr.position.value + s));
        _resetHideTimer();
      } else if (row == 1) {
        final max = _buttons.length - 1;
        if (key == LogicalKeyboardKey.arrowLeft) {
          _btnIndex.value = (_btnIndex.value - 1).clamp(0, max);
        } else {
          _btnIndex.value = (_btnIndex.value + 1).clamp(0, max);
        }
        _resetHideTimer();
      }
      return true;
    } else if (isUpDown) {
      if (key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.audioVolumeUp) {
        if (row == 1) {
          _panelRow.value = 0;
          _resetHideTimer();
        }
      } else {
        if (row == 0) {
          _panelRow.value = 1;
          _resetHideTimer();
        }
      }
      return true;
    } else if (key == LogicalKeyboardKey.contextMenu) {
      _panelRow.value = -1;
      return true;
    }
    return true;
  }

  void _handleNativeKey(String key, String action, bool isRepeat) {
    if (action != 'down') return;
    if (_isSubMenuOpen.value) {
      _subMenuNativeKeyCallback?.call(key);
      return;
    }
    if (ModalRoute.of(context)?.isCurrent != true) return;
    if (key == 'arrowUp' || key == 'arrowDown') {
      final isUp = key == 'arrowUp';
      if (_panelRow.value == -1) {
        _showPanel();
      } else if (_panelRow.value == 0 && !isUp) {
        _panelRow.value = 1;
        _resetHideTimer();
      } else if (_panelRow.value == 1 && isUp) {
        _panelRow.value = 0;
        _resetHideTimer();
      }
    }
  }

  // 子菜单的上下键回调
  void Function(String)? _subMenuNativeKeyCallback;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    TVKeyHandler.instance = TVKeyHandler()..callback = _handleNativeKey;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    TVKeyHandler.instance?.callback = null;
    if (identical(_sidePanelOwner, this)) _sidePanelOwner = null;
    _showSpeedIndicator.dispose();
    _panelRow.dispose();
    _btnIndex.dispose();
    _isSubMenuOpen.dispose();
    super.dispose();
  }

  /// 通用右侧边栏选择器
  Future<T?> _showSidePanel<T>({
    required String title,
    required List<_TVDialogOption<T>> options,
  }) async {
    if (_isSubMenuOpen.value || _sidePanelOwner != null) return null;
    _sidePanelOwner = this;
    _isSubMenuOpen.value = true;
    _hideTimer?.cancel();
    int selectedIndex = options.indexWhere((o) => o.isSelected);
    if (selectedIndex < 0) selectedIndex = 0;

    final completer = Completer<T?>();
    late StateSetter setSheetState;
    bool handled = false;
    bool selectPressed = false;

    _subMenuNativeKeyCallback = (key) {
      if (key == 'arrowUp') {
        setSheetState(() {
          selectedIndex = (selectedIndex - 1).clamp(0, options.length - 1);
        });
      } else if (key == 'arrowDown') {
        setSheetState(() {
          selectedIndex = (selectedIndex + 1).clamp(0, options.length - 1);
        });
      }
    };

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, _, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !handled) {
              handled = true;
              Navigator.of(ctx).pop();
              completer.complete(null);
            }
          },
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: const Color(0xF0181818),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: SizedBox(
                width: 280,
                child: StatefulBuilder(
                  builder: (ctx, setState) {
                    setSheetState = setState;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(color: Colors.white24, height: 1),
                        Expanded(
                          child: ListView.builder(
                            itemCount: options.length,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemBuilder: (ctx, i) {
                              final opt = options[i];
                              final isSel = i == selectedIndex;
                              return GestureDetector(
                                onTap: () {
                                  if (!handled) {
                                    handled = true;
                                    Navigator.of(ctx).pop();
                                    completer.complete(opt.value);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                  color: isSel ? Colors.white12 : null,
                                  child: Row(
                                    children: [
                                      if (isSel)
                                        const Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Icon(
                                            Icons.chevron_right,
                                            color: Colors.lightBlueAccent,
                                            size: 20,
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          opt.label,
                                          style: TextStyle(
                                            color: isSel
                                                ? Colors.lightBlueAccent
                                                : (opt.isSelected
                                                      ? Colors.lightBlueAccent
                                                      : Colors.white),
                                            fontSize: 16,
                                            fontWeight: isSel || opt.isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (opt.isSelected)
                                        const Icon(
                                          Icons.check,
                                          color: Colors.lightBlueAccent,
                                          size: 18,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    ).then((_) {
      if (!handled && !completer.isCompleted) completer.complete(null);
    });

    // OK 和返回键处理
    bool subKeyHandler(KeyEvent event) {
      if (!_isSubMenuOpen.value) return false;
      final k = event.logicalKey;

      // BACK：消费所有事件类型（KeyDown 关闭子菜单，KeyUp 也要消费防止 onBackPressed
      // 误关主菜单。设 _backConsumed=true，使 _isSubMenuOpen 变 false 后 _handleKeyEvent
      // 也能消费匹配的 KeyUp）
      if (k == LogicalKeyboardKey.goBack || k == LogicalKeyboardKey.escape) {
        if (event is KeyDownEvent && !handled) {
          handled = true;
          _backConsumed = true;
          Navigator.of(context).pop();
          completer.complete(null);
        }
        return true;
      }

      if (k == LogicalKeyboardKey.select || k == LogicalKeyboardKey.enter) {
        // Confirm on KeyUp. Closing/rebuilding the player controls on KeyDown
        // lets the matching KeyUp hit the newly exposed button underneath.
        if (event is KeyDownEvent) {
          selectPressed = true;
          return true;
        }
        if (event is KeyRepeatEvent) return true;
        if (event is KeyUpEvent && selectPressed && !handled) {
          selectPressed = false;
          handled = true;
          Navigator.of(context).pop();
          completer.complete(options[selectedIndex].value);
        }
        return true;
      }

      // Direction keys only act on KeyDown/KeyRepeat.
      if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;

      if (k == LogicalKeyboardKey.arrowUp) {
        setSheetState(() {
          selectedIndex = (selectedIndex - 1).clamp(0, options.length - 1);
        });
        return true;
      } else if (k == LogicalKeyboardKey.arrowDown) {
        setSheetState(() {
          selectedIndex = (selectedIndex + 1).clamp(0, options.length - 1);
        });
        return true;
      }
      return false;
    }

    HardwareKeyboard.instance.addHandler(subKeyHandler);
    final result = await completer.future;
    HardwareKeyboard.instance.removeHandler(subKeyHandler);
    _subMenuNativeKeyCallback = null;
    _isSubMenuOpen.value = false;
    if (identical(_sidePanelOwner, this)) _sidePanelOwner = null;
    _resetHideTimer();
    return result;
  }

  void _playPrevious() {
    if (widget.introController?.prevPlay() != true) {
      SmartDialog.showToast('已经是第一集了');
    }
  }

  void _playNext() {
    if (widget.introController?.nextPlay() != true) {
      SmartDialog.showToast('已经是最后一集了');
    }
  }

  void _showEpisodePicker() {
    final introController = widget.introController;
    final showEpisodes = widget.showEpisodes;
    if (introController == null || showEpisodes == null) return;

    final videoDetail = introController.videoDetail.value;
    final currentCid = ctr.cid;
    int sectionIndex = 0;
    List<ugc.BaseEpisodeItem>? episodes;
    UgcSeason? season;

    if (videoDetail.ugcSeason?.sections case final sections?) {
      season = videoDetail.ugcSeason;
      for (var i = 0; i < sections.length; i++) {
        final sectionEpisodes = sections[i].episodes;
        if (sectionEpisodes?.any((item) => item.cid == currentCid) == true) {
          sectionIndex = i;
          episodes = sectionEpisodes;
          break;
        }
      }
    } else if (videoDetail.pages?.isNotEmpty == true) {
      episodes = videoDetail.pages;
    } else if (introController is PgcIntroController) {
      episodes = introController.pgcItem.episodes;
    }

    showEpisodes(sectionIndex, season, season == null ? episodes : null);
    _panelRow.value = -1;
  }

  Future<void> _showSubtitlePicker() async {
    final videoController = widget.videoDetailController;
    if (videoController == null) return;
    final subtitles = videoController.subtitles;
    final options = <_TVDialogOption<int>>[
      _TVDialogOption(
        label: '关闭字幕',
        value: 0,
        isSelected: videoController.vttSubtitlesIndex.value <= 0,
      ),
      for (var i = 0; i < subtitles.length; i++)
        _TVDialogOption(
          label: subtitles[i].lanDoc ?? subtitles[i].lan,
          value: i + 1,
          isSelected: videoController.vttSubtitlesIndex.value == i + 1,
        ),
    ];
    final result = await _showSidePanel<int>(
      title: '字幕',
      options: options,
    );
    if (result != null) {
      await videoController.setSubtitle(result);
    }
  }

  Future<void> _showSpeedPicker() async {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0];
    final result = await _showSidePanel<double>(
      title: '播放速度',
      options: speeds
          .map(
            (s) => _TVDialogOption(
              label: '${s}x',
              value: s,
              isSelected: ctr.playbackSpeed == s,
            ),
          )
          .toList(),
    );
    if (result != null) ctr.setPlaybackSpeed(result);
  }

  Future<void> _showQualityPicker() async {
    final vdc = widget.videoDetailController;
    if (vdc == null) return;
    var aq = vdc.data.acceptQuality;
    var ad = vdc.data.acceptDesc;
    // fnval=1 时 acceptQuality 可能为空，用固定列表
    if (aq == null || aq.isEmpty) {
      aq = [80, 64, 32, 16];
      ad = ['1080P 高清', '720P 高清', '480P 清晰', '360P 流畅'];
    }
    ad ??= [];
    final qualities = aq;
    final descs = ad;
    final result = await _showSidePanel<int>(
      title: '画质',
      options: List.generate(
        qualities.length,
        (i) => _TVDialogOption(
          label: i < descs.length ? '${descs[i]}' : '未知',
          value: qualities[i],
          isSelected: vdc.currentVideoQa.value?.code == qualities[i],
        ),
      ),
    );
    if (result != null) {
      vdc.currentVideoQa.value = VideoQuality.fromCode(result);
      vdc.updatePlayer();
      _panelRow.value = -1;
    }
  }

  Future<void> _showFitPicker() async {
    final fits = [
      VideoFitType.contain,
      VideoFitType.cover,
      VideoFitType.fill,
      VideoFitType.fitWidth,
      VideoFitType.fitHeight,
    ];
    final result = await _showSidePanel<VideoFitType>(
      title: '画面比例',
      options: fits
          .map(
            (f) => _TVDialogOption(
              label: f.desc,
              value: f,
              isSelected: ctr.videoFit.value == f,
            ),
          )
          .toList(),
    );
    if (result != null) ctr.videoFit.value = result;
  }

  Future<void> _showDanmakuSettings() async {
    final on = ctr.enableShowDanmaku.value;
    final result = await _showSidePanel<String>(
      title: '弹幕设置',
      options: [
        _TVDialogOption(
          label: on ? '关闭弹幕' : '开启弹幕',
          value: 'toggle',
          isSelected: false,
        ),
        _TVDialogOption(
          label: '透明度 30%',
          value: 'op_30',
          isSelected: ctr.danmakuOpacity.value == 0.3,
        ),
        _TVDialogOption(
          label: '透明度 50%',
          value: 'op_50',
          isSelected: ctr.danmakuOpacity.value == 0.5,
        ),
        _TVDialogOption(
          label: '透明度 70%',
          value: 'op_70',
          isSelected: ctr.danmakuOpacity.value == 0.7,
        ),
        _TVDialogOption(
          label: '透明度 100%',
          value: 'op_100',
          isSelected: ctr.danmakuOpacity.value == 1.0,
        ),
      ],
    );
    if (result == null) return;
    switch (result) {
      case 'toggle':
        ctr.enableShowDanmaku.value = !ctr.enableShowDanmaku.value;
      case 'op_30':
        ctr.danmakuOpacity.value = 0.3;
      case 'op_50':
        ctr.danmakuOpacity.value = 0.5;
      case 'op_70':
        ctr.danmakuOpacity.value = 0.7;
      case 'op_100':
        ctr.danmakuOpacity.value = 1.0;
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_panelRow, _isSubMenuOpen]),
    builder: (context, _) => PopScope(
      canPop: _panelRow.value == -1 && !_isSubMenuOpen.value,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _panelRow.value != -1) {
          _panelRow.value = -1;
        }
        // When sub-menu is open, the dialog's own PopScope handles closing it.
        // We just need canPop=false (above) to prevent popping the video page.
      },
      child: Stack(
        children: [
          widget.child,
          // Speed indicator
          ValueListenableBuilder<double?>(
            valueListenable: _showSpeedIndicator,
            builder: (context, speed, _) {
              if (speed == null) return const SizedBox.shrink();
              return Positioned(
                right: 24,
                top: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${speed}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
          // TV control panel
          ListenableBuilder(
            listenable: Listenable.merge([
              _panelRow,
              _btnIndex,
              _isSubMenuOpen,
            ]),
            builder: (context, _) {
              if (_panelRow.value == -1) return const SizedBox.shrink();
              return Obx(_buildPanel);
            },
          ),
        ],
      ),
    ),
  );

  Widget _buildPanel() {
    final row = _panelRow.value;
    final selBtn = _btnIndex.value;
    final btns = _buttons;
    final duration = ctr.duration.value;
    final pos = ctr.position.value;

    return ColoredBox(
      color: Colors.black54,
      child: SafeArea(
        child: Column(
          children: [
            // 顶部信息
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text(
                    '${DurationUtils.formatDuration(pos)}'
                    ' / ${DurationUtils.formatDuration(duration)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const Spacer(),
                  Text(
                    '${ctr.playbackSpeed}x',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // 进度条（高亮显示当前行）
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: row == 0 ? Colors.lightBlueAccent : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
                color: row == 0
                    ? Colors.lightBlueAccent.withValues(alpha: 0.1)
                    : null,
              ),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: duration > 0 ? pos / duration : 0,
                    backgroundColor: Colors.white24,
                    minHeight: 4,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      row == 0 ? '← 后退  OK 暂停/播放  前进 →  ↓ 菜单' : '↓ 选择菜单',
                      style: TextStyle(
                        color: row == 0 ? Colors.white70 : Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 按钮行
            if (row == 1)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  '↑ 返回进度条',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(btns.length, (i) {
                final btn = btns[i];
                final selected = row == 1 && selBtn == i;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected
                          ? Colors.lightBlueAccent
                          : (row == 1 ? Colors.white38 : Colors.transparent),
                      width: selected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: selected
                        ? Colors.lightBlueAccent.withValues(alpha: 0.2)
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        btn.icon,
                        color: selected ? Colors.lightBlueAccent : Colors.white,
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        btn.label,
                        style: TextStyle(
                          color: selected
                              ? Colors.lightBlueAccent
                              : Colors.white70,
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _TVBtnItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _TVBtnItem(this.icon, this.label, this.onTap);
}

class _TVDialogOption<T> {
  final String label;
  final T value;
  final bool isSelected;
  const _TVDialogOption({
    required this.label,
    required this.value,
    this.isSelected = false,
  });
}
