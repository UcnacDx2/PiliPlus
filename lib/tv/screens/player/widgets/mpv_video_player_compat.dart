import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart' as mk;

/// Small compatibility surface for the existing TV controls. The player
/// page continues to speak in video_player-like operations while rendering
/// through libmpv's GPU texture.
enum VideoViewType { textureView, platformView }

class DurationRange {
  const DurationRange(this.start, this.end);
  final Duration start;
  final Duration end;
}

class VideoPlayerValue {
  const VideoPlayerValue({
    this.duration = Duration.zero,
    this.position = Duration.zero,
    this.isPlaying = false,
    this.isInitialized = false,
    this.isBuffering = false,
    this.aspectRatio = 16 / 9,
    this.hasError = false,
    this.errorDescription,
    this.buffered = const [],
  });

  final Duration duration;
  final Duration position;
  final bool isPlaying;
  final bool isInitialized;
  final bool isBuffering;
  final double aspectRatio;
  final bool hasError;
  final String? errorDescription;
  final List<DurationRange> buffered;

  VideoPlayerValue copyWith({
    Duration? duration,
    Duration? position,
    bool? isPlaying,
    bool? isInitialized,
    bool? isBuffering,
    double? aspectRatio,
    bool? hasError,
    String? errorDescription,
    List<DurationRange>? buffered,
  }) => VideoPlayerValue(
        duration: duration ?? this.duration,
        position: position ?? this.position,
        isPlaying: isPlaying ?? this.isPlaying,
        isInitialized: isInitialized ?? this.isInitialized,
        isBuffering: isBuffering ?? this.isBuffering,
        aspectRatio: aspectRatio ?? this.aspectRatio,
        hasError: hasError ?? this.hasError,
        errorDescription: errorDescription ?? this.errorDescription,
        buffered: buffered ?? this.buffered,
      );
}

class VideoPlayerController {
  VideoPlayerController.networkUrl(
    Uri url, {
    Map<String, String>? httpHeaders,
    String? audioUrl,
    VideoViewType viewType = VideoViewType.textureView,
  }) : _media = Media(_buildMediaUrl(url.toString(), audioUrl)),
       _httpHeaders = httpHeaders;

  static String _buildMediaUrl(String videoUrl, String? audioUrl) {
    if (audioUrl == null || audioUrl.isEmpty) return videoUrl;
    return 'edl://'
        '!no_clip;!no_chapters;%${videoUrl.length}%$videoUrl;'
        '!new_stream;!no_clip;!no_chapters;%${audioUrl.length}%$audioUrl';
  }

  final Media _media;
  final Map<String, String>? _httpHeaders;
  late final Player _player;
  late final mk.VideoController videoController;
  final _listeners = <VoidCallback>{};
  final _subscriptions = <StreamSubscription>[];
  VideoPlayerValue _value = const VideoPlayerValue();

  VideoPlayerValue get value => _value;
  Player get player => _player;
  Stream<Duration> get positionStream => _player.stream.position;

  Future<void> initialize() async {
    _player = await Player.create(
      configuration: const PlayerConfiguration(logLevel: MPVLogLevel.warn),
    );
    videoController = await mk.VideoController.create(
      _player,
      configuration: const mk.VideoControllerConfiguration(
        vo: 'gpu',
        hwdec: 'mediacodec,auto-safe',
        enableHardwareAcceleration: true,
      ),
    );
    _subscriptions.addAll([
      _player.stream.position.listen((position) => _update(position: position)),
      _player.stream.duration.listen((duration) => _update(duration: duration)),
      _player.stream.playing.listen((playing) => _update(isPlaying: playing)),
      _player.stream.buffering.listen((buffering) => _update(isBuffering: buffering)),
      _player.stream.videoParams.listen((params) {
        final width = params.w ?? 0;
        final height = params.h ?? 0;
        if (width > 0 && height > 0) _update(aspectRatio: width / height);
      }),
      _player.stream.error.listen((error) => _update(
            hasError: true,
            errorDescription: error,
          )),
    ]);
    if (_httpHeaders case final headers? when headers.isNotEmpty) {
      _player.setMediaHeader(
        userAgent: headers['User-Agent'],
        referer: headers['Referer'],
      );
    }
    await _player.open(_media, play: false);
    _update(isInitialized: true);
  }

  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> seekTo(Duration position) => _player.seek(position);
  Future<void> setPlaybackSpeed(double speed) => _player.setRate(speed);

  void _update({
    Duration? duration,
    Duration? position,
    bool? isPlaying,
    bool? isInitialized,
    bool? isBuffering,
    double? aspectRatio,
    bool? hasError,
    String? errorDescription,
  }) {
    _value = _value.copyWith(
      duration: duration,
      position: position,
      isPlaying: isPlaying,
      isInitialized: isInitialized,
      isBuffering: isBuffering,
      aspectRatio: aspectRatio,
      hasError: hasError,
      errorDescription: errorDescription,
    );
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _listeners.clear();
    await _player.dispose();
  }
}

class VideoPlayer extends StatelessWidget {
  const VideoPlayer(this.controller, {super.key});
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) => mk.Video(
        controller: controller.videoController,
        controls: mk.NoVideoControls,
        fill: Colors.transparent,
        pauseUponEnteringBackgroundMode: false,
        resumeUponEnteringForegroundMode: false,
      );
}
