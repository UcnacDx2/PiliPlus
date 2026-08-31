import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/http/browser_ua.dart';
import 'package:PiliPlus/http/constants.dart';
import 'package:PiliPlus/models/common/video/video_type.dart';
import 'package:PiliPlus/utils/video_utils.dart';
import 'package:PiliPlus/services/first_frame_watermark_service.dart';
import 'package:PiliPlus/plugin/pl_player/utils/watermark_filter.dart';
import 'package:PiliPlus/models/common/watermark_mode.dart';
import 'package:PiliPlus/tv/adapters/tv_video_item.dart';
import 'package:PiliPlus/tv/adapters/tv_bilibili_facade.dart';
import 'package:PiliPlus/tv/adapters/tv_settings_facade.dart';
import 'package:PiliPlus/tv/adapters/tv_sponsor_block_controller.dart';
import 'package:PiliPlus/tv/screens/player/widgets/controls_overlay.dart';
import 'package:PiliPlus/tv/screens/player/widgets/mpv_video_player_compat.dart';
import 'package:PiliPlus/tv/screens/player/widgets/video_layer.dart';
import 'package:PiliPlus/tv/screens/player/widgets/action_buttons.dart';
import 'package:PiliPlus/tv/screens/player/widgets/episode_panel.dart';
import 'package:PiliPlus/tv/screens/player/widgets/quality_picker_sheet.dart';
import 'package:PiliPlus/tv/screens/player/widgets/settings_panel.dart';

/// BiliTV 的播放器界面和焦点语义；播放数据由 PiliPlus VideoHttp 提供。
/// 这里不依赖旧的 PiliPlus TV 播放器控制器。
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.video});
  final TvVideoItem video;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

enum _PlayerControlRegion { actions, progress }

class _PlayerScreenState extends State<PlayerScreen> {
  final FocusNode _rootFocusNode = FocusNode(debugLabel: 'tv-player-root');
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;
  bool _showControls = true;
  bool _danmaku = true;
  int _focusedIndex = 0;
  bool _progressFocused = false;
  _PlayerControlRegion _controlRegion = _PlayerControlRegion.actions;
  bool _showEpisodePanel = false;
  bool _showSettingsPanel = false;
  bool _showActionButtons = false;
  SettingsMenuType _settingsMenuType = SettingsMenuType.main;
  int _settingsFocusedIndex = 0;
  int _focusedEpisodeIndex = 0;
  int? _activeCid;
  List<dynamic> _episodes = const [];
  List<Map<String, dynamic>> _qualities = const [];
  int _currentQuality = 80;
  String _currentQualityDesc = '自动';
  Timer? _heartbeat;
  Timer? _hideTimer;
  TvSponsorBlockController? _sponsorBlock;
  int _playbackGeneration = 0;
  bool _seeking = false;
  bool _qualityPickerOpen = false;
  Duration? _seekOrigin;
  Duration? _seekPreview;

  List<TvPlayerControlItem> get _controls => [
        TvPlayerControlItem(icon: Icons.playlist_play, onTap: _openEpisodes),
        TvPlayerControlItem(icon: Icons.tune, onTap: _openSettings),
        TvPlayerControlItem(
          icon: Icons.thumb_up_outlined,
          onTap: _openActionButtons,
        ),
        TvPlayerControlItem(
          icon: _controller?.value.isPlaying == true
              ? Icons.pause
              : Icons.play_arrow,
          onTap: _togglePlayback,
        ),
        TvPlayerControlItem(
          icon: _danmaku ? Icons.subtitles : Icons.subtitles_off,
          onTap: () => setState(() => _danmaku = !_danmaku),
        ),
      ];

  @override
  void initState() {
    super.initState();
    RawKeyboard.instance.addListener(_handleRawKey);
    unawaited(_loadVideoDetails());
    _openVideo();
  }

  void _handleRawKey(RawKeyEvent rawEvent) {
    if (!mounted) return;
    final event = switch (rawEvent) {
      RawKeyUpEvent() => KeyUpEvent(
          physicalKey: rawEvent.physicalKey,
          logicalKey: rawEvent.logicalKey,
        ),
      _ => KeyDownEvent(
          physicalKey: rawEvent.physicalKey,
          logicalKey: rawEvent.logicalKey,
        ),
    };
    final routeCurrent = ModalRoute.of(context)?.isCurrent == true;
    final key = event.logicalKey;
    final isPlayerKey = key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.escape;
    if (!isPlayerKey || _qualityPickerOpen) return;
    debugPrint(
      'TV PLAYER hardware key=${key.keyLabel} type=${event.runtimeType} '
      'controls=$_showControls routeCurrent=$routeCurrent '
      'primary=${FocusManager.instance.primaryFocus?.debugLabel}',
    );
    _handleKey(event);
    return;
  }

  Future<void> _loadVideoDetails() async {
    try {
      final info = await TvBilibiliFacade.getVideoInfo(widget.video.bvid);
      if (!mounted || info == null) return;
      final pages = info['pages'];
      if (pages is List) setState(() => _episodes = pages);
    } catch (error) {
      debugPrint('TV VOD detail unavailable: $error');
    }
  }

  Future<void> _openVideo({int? qn, int? cid}) async {
    final generation = ++_playbackGeneration;
    final previousController = _controller;
    _heartbeat?.cancel();
    _hideTimer?.cancel();
    if (qn != null) {
      setState(() {
        _currentQuality = qn;
        _loading = true;
      });
    }
    try {
      debugPrint(
        'TV VOD open bvid=${widget.video.bvid} suppliedCid=${widget.video.cid}',
      );
      final resolvedCid = cid ?? (widget.video.cid == 0
          ? await _resolveCid()
          : widget.video.cid);
      if (resolvedCid == null || resolvedCid == 0) {
        throw StateError('无法获取视频 CID');
      }
      _activeCid = resolvedCid;
      final state = await VideoHttp.videoUrl(
        bvid: widget.video.bvid,
        cid: resolvedCid,
        qn: _currentQuality,
        tryLook: true,
        videoType: VideoType.ugc,
      );
      final playInfo = state.dataOrNull;
      if (playInfo == null) {
        throw StateError('无法获取播放地址');
      }
      final dashUrls = playInfo.dash?.video
          ?.expand((item) => item.playUrls)
          .toList();
      final durlUrls = playInfo.durl
          ?.expand((item) => item.playUrls)
          .toList();
      final urls = dashUrls?.isNotEmpty == true ? dashUrls! : (durlUrls ?? const []);
      if (urls.isEmpty) throw StateError('无法获取播放地址');
      final acceptedQuality = playInfo.acceptQuality ?? const <int>[];
      final acceptedDesc = playInfo.acceptDesc ?? const <dynamic>[];
      if (acceptedQuality.isNotEmpty) {
        _qualities = [
          for (var index = 0; index < acceptedQuality.length; index++)
            {
              'qn': acceptedQuality[index],
              'desc': index < acceptedDesc.length
                  ? '${acceptedDesc[index]}'
                  : '${acceptedQuality[index]}P',
            },
        ];
        final currentIndex = acceptedQuality.indexOf(playInfo.quality ?? _currentQuality);
        if (currentIndex >= 0) {
          _currentQuality = acceptedQuality[currentIndex];
          _currentQualityDesc = '${_qualities[currentIndex]['desc']}';
        }
      }
      final audioUrls = dashUrls?.isNotEmpty == true
          ? playInfo.dash?.audio?.expand((item) => item.playUrls).toList()
          : null;
      final audioUrl = audioUrls?.firstOrNull;
      debugPrint(
        'TV VOD source bvid=${widget.video.bvid} cid=$resolvedCid '
        'dashVideo=${dashUrls?.length ?? 0} dashAudio=${audioUrls?.length ?? 0} '
        'durl=${durlUrls?.length ?? 0} videoHost=${Uri.parse(VideoUtils.getCdnUrl(urls)).host} '
        'audioHost=${audioUrl == null || audioUrl.isEmpty ? '-' : Uri.parse(VideoUtils.getCdnUrl([audioUrl])).host}',
      );
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(VideoUtils.getCdnUrl(urls)),
        httpHeaders: {
          'User-Agent': BrowserUa.pc,
          'Referer': HttpString.baseUrl,
        },
        audioUrl: audioUrl == null || audioUrl.isEmpty
            ? null
            : VideoUtils.getCdnUrl([audioUrl]),
      );
      await controller.initialize();
      debugPrint('TV VOD initialized bvid=${widget.video.bvid}');
      if (!mounted || generation != _playbackGeneration) {
        await controller.dispose();
        return;
      }
      controller.addListener(_onControllerChanged);
      setState(() {
        _controller = controller;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && generation == _playbackGeneration) {
          _requestPlayerFocus();
        }
      });
      if (previousController != null && previousController != controller) {
        await previousController.dispose();
      }
      final sponsorBlock = TvSponsorBlockController(controller.seekTo);
      _sponsorBlock = sponsorBlock;
      sponsorBlock.bindPosition(controller.positionStream);
      unawaited(sponsorBlock.load(bvid: widget.video.bvid, cid: resolvedCid));
      // History cards carry the progress for the selected CID. Prefer it for
      // the history entry, then fall back to PiliPlus's account-aware
      // lastPlayTime returned by videoUrl. A completed item uses -1 and must
      // start from the beginning.
      final historyResume = widget.video.progress > 0
          ? widget.video.progress
          : 0;
      final resume = historyResume > 0
          ? historyResume
          : (playInfo.lastPlayTime > 0 ? playInfo.lastPlayTime : 0);
      debugPrint(
        'TV VOD resume bvid=${widget.video.bvid} cid=$resolvedCid '
        'historyProgress=${widget.video.progress} '
        'serverProgress=${playInfo.lastPlayTime} selected=$resume',
      );
      if (resume > 0) {
        await controller.seekTo(Duration(seconds: resume));
      }
      _heartbeat = Timer.periodic(const Duration(seconds: 15), (_) {
        final position = controller.value.position.inSeconds;
        VideoHttp.heartBeat(
          bvid: widget.video.bvid,
          cid: resolvedCid,
          progress: position,
          videoType: VideoType.ugc,
        );
      });
      await controller.play();
      _reclaimPlayerFocus();
      _startHideTimer();
      unawaited(_applyWatermark(controller, generation));
    } catch (error) {
      if (mounted) setState(() { _loading = false; _error = error.toString(); });
    }
  }

  Future<void> _applyWatermark(
    VideoPlayerController controller,
    int generation,
  ) async {
    try {
      if (TvSettingsFacade.watermarkMode == WatermarkMode.disabled) return;
      final region = await FirstFrameWatermarkService.detect(widget.video.bvid);
      if (!mounted || generation != _playbackGeneration || _controller != controller) {
        return;
      }
      if (region != null) await WatermarkFilter.apply(controller.player, [region]);
    } catch (error) {
      // Watermark is best-effort and must never prevent or interrupt playback.
      debugPrint('TV watermark unavailable: $error');
    }
  }

  Future<int?> _resolveCid() async {
    if (widget.video.cid != 0) return widget.video.cid;
    final introCid = await TvBilibiliFacade.getVideoCid(
      widget.video.bvid,
      aid: widget.video.aid,
    );
    if (introCid != null && introCid != 0) return introCid;
    return (await VideoHttp.getVideoFirstFrameInfo(widget.video.bvid))?.cid;
  }

  void _openEpisodes() {
    if (_episodes.isEmpty) return;
    _hideTimer?.cancel();
    setState(() {
      final currentCid = _activeCid ?? widget.video.cid;
      final index = _episodes.indexWhere((episode) => episode['cid'] == currentCid);
      _focusedEpisodeIndex = index >= 0 ? index : 0;
      _showEpisodePanel = true;
      _showSettingsPanel = false;
      _showActionButtons = false;
    });
  }

  void _openSettings() {
    _hideTimer?.cancel();
    setState(() {
      _showSettingsPanel = true;
      _showEpisodePanel = false;
      _showActionButtons = false;
      _settingsMenuType = SettingsMenuType.main;
      _settingsFocusedIndex = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _requestPlayerFocus();
    });
  }

  void _openActionButtons() {
    _hideTimer?.cancel();
    setState(() {
      _showActionButtons = true;
      _showEpisodePanel = false;
      _showSettingsPanel = false;
    });
  }

  void _switchEpisode(int cid) {
    _closeMenus();
    unawaited(_openVideo(cid: cid));
  }

  Future<void> _showQualityPicker() async {
    if (_qualities.isEmpty) return;
    _qualityPickerOpen = true;
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      isScrollControlled: true,
      builder: (_) => QualityPickerSheet(
        qualities: _qualities,
        currentQuality: _currentQuality,
        onSelect: (quality) => Navigator.of(context).pop(quality),
      ),
    );
    try {
      if (selected != null && selected != _currentQuality) {
        await _openVideo(qn: selected);
      }
      if (mounted) {
        _requestPlayerFocus();
        if (_showSettingsPanel) _startHideTimer();
      }
    } finally {
      _qualityPickerOpen = false;
    }
  }

  void _closeMenus() {
    setState(() {
      _showEpisodePanel = false;
      _showSettingsPanel = false;
      _showActionButtons = false;
      _showControls = true;
    });
    _requestPlayerFocus();
    _startHideTimer();
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_handleRawKey);
    _heartbeat?.cancel();
    _hideTimer?.cancel();
    ++_playbackGeneration;
    unawaited(_sponsorBlock?.dispose() ?? Future<void>.value());
    final player = _controller?.player;
    if (player != null) {
      WatermarkFilter.clear(player);
    }
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    _rootFocusNode.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    final controller = _controller;
    if (!mounted || controller == null || !controller.value.isPlaying) return;
    if (!_showControls || _showSettingsPanel || _showEpisodePanel ||
        _showActionButtons || _seeking) return;
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || !_showControls || _showSettingsPanel ||
          _showEpisodePanel || _showActionButtons || _seeking ||
          _controller?.value.isPlaying != true) return;
      setState(() => _showControls = false);
    });
  }

  void _showControlsAndResetTimer() {
    if (!_showControls) setState(() => _showControls = true);
    _requestPlayerFocus();
    _startHideTimer();
  }

  void _requestPlayerFocus() {
    if (!mounted) return;
    final scope = FocusScope.of(context);
    scope.requestFocus(_rootFocusNode);
  }

  // The Android TV video surface can reclaim focus while the native player is
  // being attached. Re-assert the Flutter player focus after that hand-off so
  // D-pad events keep reaching the TV control state machine.
  void _reclaimPlayerFocus() {
    _requestPlayerFocus();
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _requestPlayerFocus();
    });
    Future<void>.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _requestPlayerFocus();
    });
  }

  void _handleKey(KeyEvent event) {
    if (event is KeyUpEvent && _seeking) {
      _commitSeek();
      return;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    final key = event.logicalKey;

    if (_seeking) {
      if (key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.arrowRight) {
        _adjustSeek(key == LogicalKeyboardKey.arrowRight ? 10 : -10);
        return;
      }
      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.select) {
        _commitSeek();
        return;
      }
      if (key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.goBack ||
          key == LogicalKeyboardKey.escape) {
        _cancelSeek();
        return;
      }
    }

    if (_showSettingsPanel) {
      if (key == LogicalKeyboardKey.goBack ||
          key == LogicalKeyboardKey.escape) {
        if (_settingsMenuType != SettingsMenuType.main) {
          setState(() {
            _settingsMenuType = SettingsMenuType.main;
            _settingsFocusedIndex = 0;
          });
        } else {
          _closeMenus();
        }
        return;
      }
      if (key == LogicalKeyboardKey.arrowUp) {
        final maxIndex = _settingsMenuType == SettingsMenuType.main
            ? 2
            : _settingsMenuType == SettingsMenuType.danmaku
                ? 6
                : 3;
        setState(() => _settingsFocusedIndex =
            (_settingsFocusedIndex - 1).clamp(0, maxIndex));
        _requestPlayerFocus();
        return;
      }
      if (key == LogicalKeyboardKey.arrowDown) {
        final maxIndex = _settingsMenuType == SettingsMenuType.main
            ? 2
            : _settingsMenuType == SettingsMenuType.danmaku
                ? 6
                : 3;
        setState(() => _settingsFocusedIndex =
            (_settingsFocusedIndex + 1).clamp(0, maxIndex));
        _requestPlayerFocus();
        return;
      }
      if (key == LogicalKeyboardKey.arrowLeft) {
        if (_settingsMenuType == SettingsMenuType.main) {
          _closeMenus();
        } else {
          setState(() => _settingsMenuType = SettingsMenuType.main);
        }
        return;
      }
      if ((key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.select) &&
          _settingsMenuType == SettingsMenuType.main) {
        if (_settingsFocusedIndex == 0) {
          unawaited(_showQualityPicker());
        } else if (_settingsFocusedIndex == 1) {
          setState(() {
            _settingsMenuType = SettingsMenuType.danmaku;
            _settingsFocusedIndex = 0;
          });
        } else if (_settingsFocusedIndex == 2) {
          setState(() {
            _settingsMenuType = SettingsMenuType.speed;
            _settingsFocusedIndex = 0;
          });
        }
        return;
      }
      return;
    }
    if (_showEpisodePanel) {
      if (key == LogicalKeyboardKey.goBack ||
          key == LogicalKeyboardKey.escape ||
          key == LogicalKeyboardKey.arrowLeft) {
        _closeMenus();
        return;
      }
      if (key == LogicalKeyboardKey.arrowUp) {
        setState(() => _focusedEpisodeIndex =
            (_focusedEpisodeIndex - 1).clamp(0, _episodes.length - 1));
        return;
      }
      if (key == LogicalKeyboardKey.arrowDown) {
        setState(() => _focusedEpisodeIndex =
            (_focusedEpisodeIndex + 1).clamp(0, _episodes.length - 1));
        return;
      }
      if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.select) {
        if (_episodes.isNotEmpty) {
          final episode = _episodes[_focusedEpisodeIndex];
          final episodeCid = episode['cid'];
          if (episodeCid is int && episodeCid > 0) _switchEpisode(episodeCid);
        }
        return;
      }
      return;
    }
    if (_showActionButtons) {
      if (key == LogicalKeyboardKey.goBack ||
          key == LogicalKeyboardKey.escape ||
          key == LogicalKeyboardKey.arrowUp) {
        _closeMenus();
        return;
      }
      return;
    }
    if ((key == LogicalKeyboardKey.arrowLeft ||
            key == LogicalKeyboardKey.arrowRight) &&
        _showControls &&
        _controlRegion == _PlayerControlRegion.actions) {
      final delta = key == LogicalKeyboardKey.arrowLeft ? -1 : 1;
      setState(() {
        _focusedIndex = (_focusedIndex + delta + _controls.length) %
            _controls.length;
        _progressFocused = false;
      });
      return;
    }
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      _beginSeek();
      _adjustSeek(key == LogicalKeyboardKey.arrowRight ? 10 : -10);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      if (!_showControls) {
        _showControlsAndResetTimer();
      } else {
        _hideTimer?.cancel();
        setState(() => _showControls = false);
      }
    } else if (key == LogicalKeyboardKey.arrowDown) {
      if (!_showControls) {
        _showControlsAndResetTimer();
      } else {
        _hideTimer?.cancel();
        setState(() => _showControls = false);
      }
    } else if (key == LogicalKeyboardKey.space) {
      if (_controller != null) {
        _togglePlayback();
        _showControlsAndResetTimer();
      }
    } else if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
      if (_controller == null) return;
      if (_focusedIndex < _controls.length) _controls[_focusedIndex].onTap();
      _showControlsAndResetTimer();
    } else if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.goBack) {
      Navigator.of(context).maybePop();
    }
  }

  void _beginSeek() {
    final controller = _controller;
    if (_seeking || controller == null || !controller.value.isInitialized) return;
    final origin = controller.value.position;
    if (controller.value.duration <= Duration.zero) return;
    setState(() {
      _seeking = true;
      _seekOrigin = origin;
      _seekPreview = origin;
    });
    _hideTimer?.cancel();
  }

  void _adjustSeek(int seconds) {
    if (!_seeking) return;
    final controller = _controller;
    final preview = _seekPreview;
    if (controller == null || preview == null) return;
    final duration = controller.value.duration;
    final target = preview + Duration(seconds: seconds);
    setState(() => _seekPreview = target < Duration.zero
        ? Duration.zero
        : target > duration
            ? duration
            : target);
  }

  void _commitSeek() {
    if (!_seeking) return;
    final target = _seekPreview;
    final controller = _controller;
    setState(() {
      _seeking = false;
      _seekOrigin = null;
      _seekPreview = null;
    });
    if (controller != null && target != null) unawaited(controller.seekTo(target));
  }

  void _cancelSeek() {
    if (!_seeking) return;
    final origin = _seekOrigin;
    final controller = _controller;
    setState(() {
      _seeking = false;
      _seekOrigin = null;
      _seekPreview = null;
    });
    if (controller != null && origin != null) unawaited(controller.seekTo(origin));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _rootFocusNode,
        canRequestFocus: true,
        descendantsAreFocusable: false,
        autofocus: true,
        onKeyEvent: null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeFocus(
              child: VideoLayer(
                controller: controller,
                isLoading: _loading,
                errorMessage: _error,
              ),
            ),
            if (controller != null && !_loading && _showControls)
              ControlsOverlay(
                video: widget.video,
                controller: controller,
                showControls: true,
                focusedIndex: _focusedIndex,
                isProgressBarFocused: _progressFocused,
                controls: _controls,
                currentQuality: _currentQualityDesc,
                alwaysShowPlayerTime: TvSettingsFacade.alwaysShowPlayerTime,
                danmakuCount: widget.video.danmaku,
              ),
            if (_showEpisodePanel)
              EpisodePanel(
                episodes: _episodes,
                currentCid: _activeCid ?? widget.video.cid,
                focusedIndex: _focusedEpisodeIndex,
                onEpisodeSave: _switchEpisode,
                onClose: _closeMenus,
              ),
            if (_showSettingsPanel)
              SettingsPanel(
                menuType: _settingsMenuType,
                focusedIndex: _settingsFocusedIndex,
                qualityDesc: _currentQualityDesc,
                playbackSpeed: 1,
                availableSpeeds: const [0.5, 1, 1.5, 2],
                danmakuEnabled: _danmaku,
                danmakuOpacity: 1,
                danmakuFontSize: 25,
                danmakuArea: 1,
                danmakuSpeed: 1,
                hideTopDanmaku: false,
                hideBottomDanmaku: false,
                onNavigate: (type, index) => setState(() {
                  _settingsMenuType = type;
                  _settingsFocusedIndex = index;
                }),
                onQualityPicker: () => unawaited(_showQualityPicker()),
              ),
            if (_showActionButtons)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: ActionButtons(
                    video: widget.video,
                    aid: 0,
                    isFocused: true,
                    onFocusExit: _closeMenus,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      controller.pause();
      _hideTimer?.cancel();
    } else {
      unawaited(() async {
        await controller.play();
        if (mounted) _startHideTimer();
      }());
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }
}
