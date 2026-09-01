import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/http/browser_ua.dart';
import 'package:PiliPlus/http/constants.dart';
import 'package:PiliPlus/models/common/video/video_type.dart';
import 'package:PiliPlus/models/common/video/audio_quality.dart';
import 'package:PiliPlus/models/video/play/url.dart';
import 'package:PiliPlus/utils/video_utils.dart';
import 'package:PiliPlus/utils/extension/iterable_ext.dart';
import 'package:PiliPlus/services/first_frame_watermark_service.dart';
import 'package:PiliPlus/plugin/pl_player/utils/watermark_filter.dart';
import 'package:PiliPlus/models/common/watermark_mode.dart';
import 'package:PiliPlus/tv/adapters/tv_video_item.dart';
import 'package:PiliPlus/tv/adapters/tv_bilibili_facade.dart';
import 'package:PiliPlus/tv/adapters/tv_settings_facade.dart';
import 'package:PiliPlus/tv/adapters/tv_sponsor_block_controller.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/tv/screens/player/widgets/controls_overlay.dart';
import 'package:PiliPlus/tv/screens/player/widgets/mpv_video_player_compat.dart';
import 'package:PiliPlus/tv/screens/player/widgets/video_layer.dart';
import 'package:PiliPlus/tv/screens/player/widgets/action_buttons.dart';
import 'package:PiliPlus/tv/screens/player/widgets/episode_panel.dart';
import 'package:PiliPlus/tv/screens/player/widgets/quality_picker_sheet.dart';
import 'package:PiliPlus/tv/screens/player/widgets/settings_panel.dart';
import 'package:PiliPlus/tv/screens/player/widgets/up_panel.dart';
import 'package:PiliPlus/tv/screens/player/widgets/related_panel.dart';

/// BiliTV 的播放器界面和焦点语义；播放数据由 PiliPlus VideoHttp 提供。
/// 这里不依赖旧的 PiliPlus TV 播放器控制器。
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.video});
  final TvVideoItem video;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final FocusNode _rootFocusNode = FocusNode(debugLabel: 'tv-player-root');
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;
  bool _showControls = true;
  bool _danmaku = true;
  double _playbackSpeed = 1;
  double _danmakuOpacity = 0.6;
  double _danmakuFontSize = 17;
  double _danmakuArea = 0.25;
  double _danmakuSpeed = 10;
  bool _hideTopDanmaku = false;
  bool _hideBottomDanmaku = false;
  static const _availableSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  int _focusedIndex = 0;
  bool _progressFocused = false;
  bool _showEpisodePanel = false;
  bool _showSettingsPanel = false;
  bool _showActionButtons = false;
  bool _showUpPanel = false;
  bool _showRelatedPanel = false;
  SettingsMenuType _settingsMenuType = SettingsMenuType.main;
  int _settingsFocusedIndex = 0;
  int _settingsParentFocusIndex = 0;
  int _focusedEpisodeIndex = 0;
  int? _activeCid;
  List<dynamic> _episodes = const [];
  List<Map<String, dynamic>> _qualities = const [];
  int _requestedQuality = Pref.defaultVideoQa;
  int _currentQuality = Pref.defaultVideoQa;
  String _currentQualityDesc = '自动';
  Timer? _heartbeat;
  Timer? _hideTimer;
  TvSponsorBlockController? _sponsorBlock;
  int _playbackGeneration = 0;
  bool _seeking = false;
  bool _qualityPickerOpen = false;
  Duration? _seekOrigin;
  Duration? _seekPreview;
  int _menuReturnFocusIndex = 0;
  bool _backKeyJustHandled = false;

  List<TvPlayerControlItem> get _controls => [
        TvPlayerControlItem(icon: Icons.playlist_play, onTap: _openEpisodes),
        TvPlayerControlItem(icon: Icons.person_outline, onTap: _openUpPanel),
        TvPlayerControlItem(icon: Icons.video_library_outlined, onTap: _openRelatedPanel),
        TvPlayerControlItem(icon: Icons.tune, onTap: _openSettings),
        TvPlayerControlItem(
          icon: Icons.thumb_up_outlined,
          onTap: _openActionButtons,
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
    // Focus is the normal input path. Keep RawKeyboard only as a fallback
    // while Android's native video surface owns focus during attachment. If
    // any descendant panel already owns focus, its event will bubble to the
    // root Focus; handling it here as well would execute Back/Enter twice.
    final primaryContext = FocusManager.instance.primaryFocus?.context;
    if (primaryContext != null &&
        primaryContext.findAncestorStateOfType<_PlayerScreenState>() == this) {
      return;
    }
    final event = switch (rawEvent) {
      RawKeyUpEvent() => KeyUpEvent(
          physicalKey: rawEvent.physicalKey,
          logicalKey: rawEvent.logicalKey,
          timeStamp: Duration.zero,
        ),
      _ => KeyDownEvent(
          physicalKey: rawEvent.physicalKey,
          logicalKey: rawEvent.logicalKey,
          timeStamp: Duration.zero,
        ),
    };
    final routeCurrent = ModalRoute.of(context)?.isCurrent == true;
    if (!routeCurrent) return;
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
        _requestedQuality = qn;
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
      final tryLook = !Accounts.video.isLogin && Pref.p1080;
      final state = await VideoHttp.videoUrl(
        bvid: widget.video.bvid,
        cid: resolvedCid,
        qn: _requestedQuality,
        // Match PiliPlus's shared player rule: only anonymous 1080P
        // playback uses the preview/try-look parameter.  A logged-in video
        // account must request its real entitlement (including 4K).
        tryLook: tryLook,
        videoType: VideoType.ugc,
      );
      final playInfo = state.dataOrNull;
      if (playInfo == null) {
        throw StateError('无法获取播放地址');
      }
      final requestedQn = _requestedQuality;
      final videoItems = playInfo.dash?.video ?? const <VideoItem>[];
      final availableQns = videoItems.map((item) => item.quality.code).toSet().toList();
      availableQns.sort();
      final effectiveQn = _selectVideoQuality(
        requestedQn: requestedQn,
        responseQn: playInfo.quality,
        availableQns: availableQns,
      );
      final matchingVideos = videoItems
          .where((item) => item.quality.code == effectiveQn)
          .toList();
      final selectedVideo = _selectVideoRendition(matchingVideos);
      final dashUrls = selectedVideo?.playUrls.toList();
      final durlUrls = playInfo.durl
          ?.expand((item) => item.playUrls)
          .toList();
      final urls = dashUrls?.isNotEmpty == true ? dashUrls! : (durlUrls ?? const []);
      if (urls.isEmpty) throw StateError('无法获取播放地址');
      final acceptedQuality = playInfo.acceptQuality ?? const <int>[];
      final acceptedDesc = playInfo.acceptDesc ?? const <dynamic>[];
      final qualityLabels = <int, String>{};
      final qualityOrder = <int>[];
      // support_formats is the shared PiliPlus source for human-readable
      // quality names.  Keep accept_quality as a compatibility fallback for
      // older responses that omit support_formats.
      for (final format in playInfo.supportFormats ?? const []) {
        final qn = format.quality;
        if (qn == null || qualityLabels.containsKey(qn)) continue;
        qualityOrder.add(qn);
        qualityLabels[qn] = format.newDesc ??
            format.displayDesc ??
            '${qn}P';
      }
      for (var index = 0; index < acceptedQuality.length; index++) {
        final qn = acceptedQuality[index];
        if (qualityLabels.containsKey(qn)) continue;
        qualityOrder.add(qn);
        qualityLabels[qn] = index < acceptedDesc.length
            ? '${acceptedDesc[index]}'
            : '${qn}P';
      }
      _qualities = [
        for (final qn in qualityOrder)
          {
            'qn': qn,
            'desc': qualityLabels[qn],
            // A declared tier is not necessarily present in dash.video.
            // Expose it, but make the sheet refuse an unavailable resource.
            'available': videoItems.any((item) => item.quality.code == qn) ||
                (videoItems.isEmpty && qn == effectiveQn),
          },
      ];
      final currentIndex = _qualities.indexWhere(
        (quality) => quality['qn'] == effectiveQn,
      );
      // Keep the user's requested cap separate from the rendition actually
      // returned by DASH.  A later episode/P part must continue probing the
      // requested quality instead of inheriting a previous fallback (e.g.
      // 1080P after a 4K request was unavailable on one part).
      _currentQuality = effectiveQn;
      if (currentIndex >= 0) {
        _currentQualityDesc = '${_qualities[currentIndex]['desc']}';
      } else {
        _currentQualityDesc = '${effectiveQn}P';
      }
      final selectedAudio = _selectAudioRendition(playInfo.dash?.audio);
      final audioUrls = dashUrls?.isNotEmpty == true
          ? selectedAudio?.playUrls.toList()
          : null;
      final audioUrl = audioUrls?.firstOrNull;
      debugPrint(
        'TV VOD source bvid=${widget.video.bvid} cid=$resolvedCid '
        'dashVideo=${dashUrls?.length ?? 0} dashAudio=${audioUrls?.length ?? 0} '
        'durl=${durlUrls?.length ?? 0} videoHost=${Uri.parse(VideoUtils.getCdnUrl(urls)).host} '
        'audioHost=${audioUrl == null || audioUrl.isEmpty ? '-' : Uri.parse(VideoUtils.getCdnUrl([audioUrl])).host} '
        'requestedQn=$requestedQn effectiveQn=$effectiveQn '
        'tryLook=$tryLook '
        'videoAccount=${Accounts.video.mid}/${Accounts.video.isLogin} '
        'rendition=${selectedVideo?.width}x${selectedVideo?.height}/${selectedVideo?.codecs} '
        'audioQn=${selectedAudio?.id}',
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
      // History progress is expressed in seconds, while PlayUrlModel's
      // lastPlayTime is milliseconds. Both are CID-specific; do not apply a
      // progress value from another page of a multi-part video.
      final historyMatchesCid =
          widget.video.cid == 0 || widget.video.cid == resolvedCid;
      final historyResume = historyMatchesCid && widget.video.progress > 0
          ? widget.video.progress
          : 0;
      final serverMatchesCid =
          playInfo.lastPlayCid == null || playInfo.lastPlayCid == resolvedCid;
      final serverResume = serverMatchesCid && playInfo.lastPlayTime > 0
          ? (playInfo.lastPlayTime / 1000).round()
          : 0;
      final resume = historyResume > 0 ? historyResume : serverResume;
      debugPrint(
        'TV VOD resume bvid=${widget.video.bvid} cid=$resolvedCid '
        'historyProgress=${widget.video.progress}s '
        'serverProgress=${playInfo.lastPlayTime}ms '
        'serverCid=${playInfo.lastPlayCid} selected=${resume}s',
      );
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
      if (resume > 0) {
        await _seekAndConfirmResume(Duration(seconds: resume), controller);
      }
      _reclaimPlayerFocus();
      _startHideTimer();
      unawaited(_applyWatermark(controller, generation));
    } catch (error) {
      if (mounted) setState(() { _loading = false; _error = error.toString(); });
    }
  }

  /// Pick the highest rendition that does not exceed the user's preferred
  /// quality cap. If the server reports an actual quality that exists in the
  /// DASH list, trust that value; otherwise fall back to the available list.
  /// This mirrors the shared PiliPlus player rule instead of assuming that
  /// the first DASH item is the requested quality.
  int _selectVideoQuality({
    required int requestedQn,
    required int? responseQn,
    required List<int> availableQns,
  }) {
    if (availableQns.isEmpty) return responseQn ?? requestedQn;
    if (requestedQn <= 0) return availableQns.last;
    final atMost = availableQns.where((qn) => qn <= requestedQn).toList();
    // If the API ignored the cap and only returned higher renditions, use the
    // lowest one rather than silently jumping to the highest stream.
    return atMost.isNotEmpty ? atMost.last : availableQns.first;
  }

  VideoItem? _selectVideoRendition(List<VideoItem> candidates) {
    if (candidates.isEmpty) return null;
    final codecNames = candidates
        .map((item) => item.codecs)
        .whereType<String>()
        .where((codec) => codec.isNotEmpty)
        .toList();
    if (codecNames.isNotEmpty) {
      try {
        final preferred = VideoUtils.selectCodec(codecNames, Pref.preferCodecs);
        final matching = candidates.where(
          (item) => preferred.codes.any(
            (code) => item.codecs?.startsWith(code) == true,
          ),
        );
        if (matching.isNotEmpty) return matching.first;
      } catch (_) {
        // Unknown codec strings are kept as a safe first-item fallback.
      }
    }
    return candidates.first;
  }

  AudioItem? _selectAudioRendition(List<AudioItem>? candidates) {
    if (candidates == null || candidates.isEmpty) return null;
    final ids = candidates.map((item) => item.id).whereType<int>().toList();
    if (ids.isEmpty) return candidates.first;
    var target = ids.findClosestTarget(
      (id) => id <= Pref.defaultAudioQa,
      (a, b) => a > b ? a : b,
    );
    // Keep the shared player's compatibility rule: when a requested lossless
    // tier is absent but a higher 192K stream exists, prefer 192K over Dolby.
    if (!ids.contains(Pref.defaultAudioQa) &&
        ids.any((id) => id > Pref.defaultAudioQa)) {
      target = AudioQuality.k192.code;
    }
    return candidates.firstWhere(
      (item) => item.id == target,
      orElse: () => candidates.first,
    );
  }

  Future<bool> _seekAndConfirmResume(
    Duration target,
    VideoPlayerController controller,
  ) async {
    // mpv's EDL timeline may accept a seek before stream parameters are
    // published and then discard it when playback starts. Wait for readiness,
    // then confirm the reported position after each of two attempts.
    for (var i = 0; i < 20; i++) {
      if (controller.value.duration > Duration.zero ||
          controller.value.isPlaying) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    for (var attempt = 0; attempt < 2; attempt++) {
      await controller.seekTo(target);
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        final actual = controller.value.position;
        if ((actual - target).abs() <= const Duration(seconds: 2)) {
          debugPrint(
            'TV VOD resume confirmed target=${target.inSeconds}s '
            'actual=${actual.inSeconds}s attempt=${attempt + 1}',
          );
          return true;
        }
      }
    }
    debugPrint(
      'TV VOD resume unconfirmed target=${target.inSeconds}s '
      'actual=${controller.value.position.inSeconds}s',
    );
    return false;
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
    _menuReturnFocusIndex = _focusedIndex;
    _hideTimer?.cancel();
    setState(() {
      final currentCid = _activeCid ?? widget.video.cid;
      final index = _episodes.indexWhere((episode) => episode['cid'] == currentCid);
      _focusedEpisodeIndex = index >= 0 ? index : 0;
      _showEpisodePanel = true;
      _showSettingsPanel = false;
      _showActionButtons = false;
      _showUpPanel = false;
      _showRelatedPanel = false;
    });
  }

  void _openSettings() {
    _hideTimer?.cancel();
    _menuReturnFocusIndex = _focusedIndex;
    setState(() {
      _showSettingsPanel = true;
      _showEpisodePanel = false;
      _showActionButtons = false;
      _showUpPanel = false;
      _showRelatedPanel = false;
      _settingsMenuType = SettingsMenuType.main;
      _settingsFocusedIndex = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _requestPlayerFocus();
    });
  }

  void _openActionButtons() {
    _hideTimer?.cancel();
    _menuReturnFocusIndex = _focusedIndex;
    setState(() {
      _showActionButtons = true;
      _showEpisodePanel = false;
      _showSettingsPanel = false;
      _showUpPanel = false;
      _showRelatedPanel = false;
    });
  }

  void _openUpPanel() {
    _hideTimer?.cancel();
    _menuReturnFocusIndex = _focusedIndex;
    setState(() {
      _showUpPanel = true;
      _showRelatedPanel = false;
      _showEpisodePanel = false;
      _showSettingsPanel = false;
      _showActionButtons = false;
    });
  }

  void _openRelatedPanel() {
    _hideTimer?.cancel();
    _menuReturnFocusIndex = _focusedIndex;
    setState(() {
      _showRelatedPanel = true;
      _showUpPanel = false;
      _showEpisodePanel = false;
      _showSettingsPanel = false;
      _showActionButtons = false;
    });
  }

  void _switchEpisode(int cid) {
    _closeMenus();
    unawaited(_openVideo(cid: cid));
  }

  void _openSelectedVideo(TvVideoItem video) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => PlayerScreen(video: video)),
    );
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
      if (selected != null && selected != _requestedQuality) {
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
      _showUpPanel = false;
      _showRelatedPanel = false;
      _showControls = true;
      _focusedIndex = _menuReturnFocusIndex.clamp(0, _controls.length - 1);
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
        _showActionButtons || _showUpPanel || _showRelatedPanel || _seeking) return;
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || !_showControls || _showSettingsPanel ||
          _showEpisodePanel || _showActionButtons || _showUpPanel ||
          _showRelatedPanel || _seeking ||
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
    // Android TV's system Back is delivered to PopScope. Do not also pop the
    // Navigator from the Focus handler, otherwise the underlying HomeScreen
    // can consume the same physical key and switch back to the home tab.
    if (key == LogicalKeyboardKey.goBack) return;
    // Confirm/select is an action, not a repeatable navigation key. This
    // prevents a long press from toggling playback and opening a panel again.
    if ((key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.select) &&
        event is! KeyDownEvent) {
      return;
    }
    if ((key == LogicalKeyboardKey.goBack ||
            key == LogicalKeyboardKey.escape) &&
        event is KeyDownEvent) {
      // PopScope may receive the same Android Back after the Focus handler;
      // mark every in-player Back branch so it is consumed exactly once.
      _markBackKeyHandled();
    }

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
            _settingsFocusedIndex = _settingsParentFocusIndex;
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
        } else if (_settingsMenuType == SettingsMenuType.danmaku) {
          _adjustDanmakuSetting(-1);
        } else {
          setState(() {
            _settingsMenuType = SettingsMenuType.main;
            _settingsFocusedIndex = _settingsParentFocusIndex;
          });
        }
        return;
      }
      if (key == LogicalKeyboardKey.arrowRight) {
        if (_settingsMenuType == SettingsMenuType.main) {
          if (_settingsFocusedIndex == 1) {
            setState(() {
              _settingsParentFocusIndex = _settingsFocusedIndex;
              _settingsMenuType = SettingsMenuType.danmaku;
              _settingsFocusedIndex = 0;
            });
          } else if (_settingsFocusedIndex == 2) {
            setState(() {
              _settingsParentFocusIndex = _settingsFocusedIndex;
              _settingsMenuType = SettingsMenuType.speed;
              _settingsFocusedIndex = 0;
            });
          }
        } else if (_settingsMenuType == SettingsMenuType.danmaku) {
          _adjustDanmakuSetting(1);
        }
        return;
      }
      if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.select) {
        if (_settingsMenuType == SettingsMenuType.danmaku) {
          _activateDanmakuSetting();
          return;
        }
        if (_settingsMenuType == SettingsMenuType.speed) {
          if (_settingsFocusedIndex < _availableSpeeds.length) {
            final speed = _availableSpeeds[_settingsFocusedIndex];
            setState(() => _playbackSpeed = speed);
            unawaited(_controller?.setPlaybackSpeed(speed));
          }
          return;
        }
        if (_settingsFocusedIndex == 0) {
          unawaited(_showQualityPicker());
        } else if (_settingsFocusedIndex == 1) {
          setState(() {
            _settingsParentFocusIndex = _settingsFocusedIndex;
            _settingsMenuType = SettingsMenuType.danmaku;
            _settingsFocusedIndex = 0;
          });
        } else if (_settingsFocusedIndex == 2) {
          setState(() {
            _settingsParentFocusIndex = _settingsFocusedIndex;
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
    if (_showUpPanel || _showRelatedPanel) {
      if (key == LogicalKeyboardKey.goBack ||
          key == LogicalKeyboardKey.escape ||
          key == LogicalKeyboardKey.arrowLeft) {
        _closeMenus();
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
        _showControls) {
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
      if (!_showControls) {
        // With hidden controls, confirm is the play/pause command. Do not
        // reveal the bar or dispatch to the last visible button focus.
        _togglePlayback();
      } else {
        if (_focusedIndex < _controls.length) _controls[_focusedIndex].onTap();
        _showControlsAndResetTimer();
      }
    } else if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.goBack) {
      _handleBack();
    }
  }

  void _markBackKeyHandled() {
    _backKeyJustHandled = true;
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _backKeyJustHandled = false;
    });
  }

  void _handleBack() {
    if (_qualityPickerOpen) return;
    if (_seeking) {
      _cancelSeek();
      return;
    }
    if (_showSettingsPanel) {
      if (_settingsMenuType != SettingsMenuType.main) {
        setState(() {
          _settingsMenuType = SettingsMenuType.main;
          _settingsFocusedIndex = _settingsParentFocusIndex;
        });
      } else {
        _closeMenus();
      }
      return;
    }
    if (_showEpisodePanel ||
        _showActionButtons ||
        _showUpPanel ||
        _showRelatedPanel) {
      _closeMenus();
      return;
    }
    if (_showControls) {
      _hideTimer?.cancel();
      setState(() => _showControls = false);
      return;
    }
    Navigator.of(context).pop();
  }

  void _onPopInvokedWithResult(bool didPop, Object? result) {
    if (didPop) return;
    if (_backKeyJustHandled) {
      _backKeyJustHandled = false;
      return;
    }
    _handleBack();
  }

  void _beginSeek() {
    final controller = _controller;
    if (_seeking || controller == null || !controller.value.isInitialized) return;
    final origin = controller.value.position;
    if (controller.value.duration <= Duration.zero) return;
    setState(() {
      _seeking = true;
      _progressFocused = true;
      _seekOrigin = origin;
      _seekPreview = origin;
    });
    _hideTimer?.cancel();
  }

  void _adjustDanmakuSetting(int direction) {
    final index = _settingsFocusedIndex;
    setState(() {
      switch (index) {
        case 1:
          _danmakuOpacity = (_danmakuOpacity + direction * 0.1).clamp(0.1, 1.0);
          break;
        case 2:
          _danmakuFontSize = (_danmakuFontSize + direction * 2).clamp(10, 40);
          break;
        case 3:
          _danmakuArea = (_danmakuArea + direction * 0.25).clamp(0.25, 1.0);
          break;
        case 4:
          _danmakuSpeed = (_danmakuSpeed + direction).clamp(1, 20);
          break;
      }
    });
  }

  void _activateDanmakuSetting() {
    if (_settingsFocusedIndex == 0) {
      setState(() => _danmaku = !_danmaku);
    } else if (_settingsFocusedIndex == 5) {
      setState(() => _hideTopDanmaku = !_hideTopDanmaku);
    } else if (_settingsFocusedIndex == 6) {
      setState(() => _hideBottomDanmaku = !_hideBottomDanmaku);
    }
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
      _progressFocused = false;
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
      _progressFocused = false;
      _seekOrigin = null;
      _seekPreview = null;
    });
    if (controller != null && origin != null) unawaited(controller.seekTo(origin));
  }

  KeyEventResult _handleFocusKey(FocusNode node, KeyEvent event) {
    if (_qualityPickerOpen) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.goBack) return KeyEventResult.ignored;
    final isPlayerKey = key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.escape;
    if (!isPlayerKey) return KeyEventResult.ignored;
    _handleKey(event);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: _onPopInvokedWithResult,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          focusNode: _rootFocusNode,
          canRequestFocus: true,
          autofocus: true,
          onKeyEvent: _handleFocusKey,
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
            if (controller != null && !_loading && (_showControls || _seeking))
              ControlsOverlay(
                video: widget.video,
                controller: controller,
                showControls: true,
                focusedIndex: _focusedIndex,
                isProgressBarFocused: _progressFocused,
                previewPosition: _seekPreview,
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
            if (_showUpPanel)
              UpPanel(
                upName: widget.video.ownerName,
                upFace: widget.video.ownerFace,
                upMid: widget.video.ownerMid,
                onVideoSelect: _openSelectedVideo,
                onClose: _closeMenus,
              ),
            if (_showRelatedPanel)
              RelatedPanel(
                bvid: widget.video.bvid,
                onVideoSelect: _openSelectedVideo,
                onClose: _closeMenus,
              ),
            if (_showSettingsPanel)
              SettingsPanel(
                menuType: _settingsMenuType,
                focusedIndex: _settingsFocusedIndex,
                qualityDesc: _currentQualityDesc,
                playbackSpeed: _playbackSpeed,
                availableSpeeds: _availableSpeeds,
                danmakuEnabled: _danmaku,
                danmakuOpacity: _danmakuOpacity,
                danmakuFontSize: _danmakuFontSize,
                danmakuArea: _danmakuArea,
                danmakuSpeed: _danmakuSpeed,
                hideTopDanmaku: _hideTopDanmaku,
                hideBottomDanmaku: _hideBottomDanmaku,
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
