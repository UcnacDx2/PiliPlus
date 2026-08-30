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
import 'package:PiliPlus/tv/adapters/tv_settings_facade.dart';
import 'package:PiliPlus/tv/adapters/tv_sponsor_block_controller.dart';
import 'package:PiliPlus/tv/screens/player/widgets/controls_overlay.dart';
import 'package:PiliPlus/tv/screens/player/widgets/mpv_video_player_compat.dart';
import 'package:PiliPlus/tv/screens/player/widgets/video_layer.dart';

/// BiliTV 的播放器界面和焦点语义；播放数据由 PiliPlus VideoHttp 提供。
/// 这里不依赖旧的 PiliPlus TV 播放器控制器。
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.video});
  final TvVideoItem video;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;
  bool _showControls = true;
  bool _danmaku = true;
  int _focusedIndex = 0;
  bool _progressFocused = false;
  Timer? _heartbeat;
  TvSponsorBlockController? _sponsorBlock;
  int _playbackGeneration = 0;

  List<TvPlayerControlItem> get _controls => [
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
    _openVideo();
  }

  Future<void> _openVideo() async {
    final generation = ++_playbackGeneration;
    try {
      debugPrint(
        'TV VOD open bvid=${widget.video.bvid} suppliedCid=${widget.video.cid}',
      );
      final cid = widget.video.cid == 0
          ? await _resolveCid()
          : widget.video.cid;
      if (cid == null || cid == 0) throw StateError('无法获取视频 CID');
      final state = await VideoHttp.videoUrl(
        bvid: widget.video.bvid,
        cid: cid,
        qn: 80,
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
      final audioUrls = dashUrls?.isNotEmpty == true
          ? playInfo.dash?.audio?.expand((item) => item.playUrls).toList()
          : null;
      final audioUrl = audioUrls?.firstOrNull;
      debugPrint(
        'TV VOD source bvid=${widget.video.bvid} cid=$cid '
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
      final sponsorBlock = TvSponsorBlockController(controller.seekTo);
      _sponsorBlock = sponsorBlock;
      sponsorBlock.bindPosition(controller.positionStream);
      unawaited(sponsorBlock.load(bvid: widget.video.bvid, cid: cid));
      final resume = playInfo.lastPlayTime;
      if (resume > 0) {
        await controller.seekTo(Duration(seconds: resume));
      }
      _heartbeat = Timer.periodic(const Duration(seconds: 15), (_) {
        final position = controller.value.position.inSeconds;
        VideoHttp.heartBeat(
          bvid: widget.video.bvid,
          cid: cid,
          progress: position,
          videoType: VideoType.ugc,
        );
      });
      await controller.play();
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
    final introCid = (await VideoHttp.videoIntro(bvid: widget.video.bvid))
        .dataOrNull
        ?.cid;
    if (introCid != null && introCid != 0) return introCid;
    return (await VideoHttp.getVideoFirstFrameInfo(widget.video.bvid))?.cid;
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    ++_playbackGeneration;
    unawaited(_sponsorBlock?.dispose() ?? Future<void>.value());
    final player = _controller?.player;
    if (player != null) {
      WatermarkFilter.clear(player);
    }
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    super.dispose();
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      final controller = _controller;
      if (controller != null) {
        controller.seekTo(controller.value.position - const Duration(seconds: 10));
      }
      setState(() { _showControls = true; _focusedIndex = 0; });
    } else if (key == LogicalKeyboardKey.arrowRight) {
      final controller = _controller;
      if (controller != null) {
        controller.seekTo(controller.value.position + const Duration(seconds: 10));
      }
      setState(() { _showControls = true; _focusedIndex = 0; });
    } else if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _showControls = true;
        _progressFocused = false;
        _focusedIndex = (_focusedIndex - 1 + _controls.length) % _controls.length;
      });
    } else if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _showControls = true;
        _progressFocused = false;
        _focusedIndex = (_focusedIndex + 1) % _controls.length;
      });
    } else if (key == LogicalKeyboardKey.space) {
      if (_controller != null) {
        _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
        setState(() => _showControls = true);
      }
    } else if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
      if (_controller == null) return;
      if (_focusedIndex < _controls.length) _controls[_focusedIndex].onTap();
      setState(() => _showControls = true);
    } else if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.goBack) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) { _handleKey(event); return KeyEventResult.handled; },
        child: Stack(
          fit: StackFit.expand,
          children: [
            VideoLayer(controller: controller, isLoading: _loading, errorMessage: _error),
            if (controller != null && !_loading && _showControls)
              ControlsOverlay(
                video: widget.video,
                controller: controller,
                showControls: true,
                focusedIndex: _focusedIndex,
                isProgressBarFocused: _progressFocused,
                controls: _controls,
                currentQuality: '1080P',
                alwaysShowPlayerTime: TvSettingsFacade.alwaysShowPlayerTime,
                danmakuCount: widget.video.danmaku,
              ),
          ],
        ),
      ),
    );
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null) return;
    controller.value.isPlaying ? controller.pause() : controller.play();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }
}
