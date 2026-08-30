import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/common/video/video_type.dart';
import 'package:PiliPlus/utils/video_utils.dart';
import 'package:PiliPlus/tv/adapters/tv_video_item.dart';
import 'package:PiliPlus/tv/adapters/tv_settings_facade.dart';
import 'widgets/controls_overlay.dart';
import 'widgets/mpv_video_player_compat.dart';
import 'widgets/video_layer.dart';

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

  @override
  void initState() {
    super.initState();
    _openVideo();
  }

  Future<void> _openVideo() async {
    try {
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
      if (playInfo == null || playInfo.playUrls.isEmpty) {
        throw StateError('无法获取播放地址');
      }
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(VideoUtils.getCdnUrl(playInfo.playUrls)),
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
      await controller.play();
    } catch (error) {
      if (mounted) setState(() { _loading = false; _error = error.toString(); });
    }
  }

  Future<int?> _resolveCid() async {
    return widget.video.cid == 0 ? null : widget.video.cid;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
      if (_controller == null) return;
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
      setState(() => _showControls = true);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _controller?.seekTo(_controller!.value.position - const Duration(seconds: 10));
      setState(() { _showControls = true; _focusedIndex = 0; });
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _controller?.seekTo(_controller!.value.position + const Duration(seconds: 10));
      setState(() { _showControls = true; _focusedIndex = 0; });
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
                onPlayPause: () => controller.value.isPlaying ? controller.pause() : controller.play(),
                onSettings: () {},
                onEpisodes: () {},
                isDanmakuEnabled: _danmaku,
                onToggleDanmaku: () => setState(() => _danmaku = !_danmaku),
                currentQuality: '1080P',
                onQualityClick: () {},
                alwaysShowPlayerTime: TvSettingsFacade.alwaysShowPlayerTime,
                danmakuCount: widget.video.danmaku,
              ),
          ],
        ),
      ),
    );
  }
}
