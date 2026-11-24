import 'dart:async';
import 'dart:ui' as ui;

import 'package:PiliPlus/fork/covers/video_shot_preview_service.dart';
import 'package:PiliPlus/fork/fork_prefs.dart';
import 'package:PiliPlus/fork/watermark/first_frame_watermark_service.dart';
import 'package:PiliPlus/fork/watermark/watermark_detector.dart';
import 'package:PiliPlus/fork/watermark/watermark_input.dart';
import 'package:PiliPlus/fork/watermark/watermark_filter.dart';
import 'package:PiliPlus/fork/watermark/watermark_mode.dart';
import 'package:PiliPlus/fork/watermark/watermark_position.dart';
import 'package:PiliPlus/fork/watermark/watermark_region.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:media_kit/media_kit.dart';

/// Owns watermark removal for the currently opened media.
///
/// All player-facing state lives here instead of `PlPlayerController`, so the
/// upstream player only needs three hook calls (`beforeOpen`, `started`,
/// `afterShaderChanged`).
final class ForkWatermarkRuntime {
  ForkWatermarkRuntime()
    : position = ForkPref.watermarkPosition.obs;

  final Rx<WatermarkPosition> position;

  Box get _setting => GStorage.setting;

  Player? _player;
  String? _bvid;
  int? _cid;
  bool _isLive = false;
  bool _audioOnly = false;
  int? _width;
  int? _height;

  int _generation = 0;
  List<WatermarkRegion> _activeRegions = const [];

  // Screen-capture sampling. Bilibili's creator watermark is engraved into the
  // stream itself while the videoshot sprites usually come from the clean
  // source, so the only reliable evidence that a watermark is on screen is
  // what the player is actually showing.
  static const _sampleInterval = Duration(milliseconds: 1100);
  static const _refreshInterval = Duration(seconds: 45);
  static const _startupSamples = 6;
  static const _refreshSamples = 4;
  static const _maxRecentFrames = 8;

  Timer? _sampler;
  Timer? _refresh;
  final List<WatermarkFrame> _recent = [];
  int _wanted = 0;
  bool _capturing = false;
  int _lastPosition = -1;
  bool _appliedOnce = false;

  /// Clears the shader applied to the previous media before a new source is
  /// opened on the same mpv instance.
  Future<void> beforeOpen() async {
    _generation++;
    _activeRegions = const [];
    _stopSampling();
    _appliedOnce = false;
    if (_player case final player?) {
      await WatermarkFilter.clear(player);
    }
  }

  /// Binds the freshly opened media and starts detection.
  void started({
    required Player player,
    required String? bvid,
    required int? cid,
    required bool isLive,
    required bool onlyPlayAudio,
    int? width,
    int? height,
  }) {
    _player = player;
    _bvid = bvid;
    _cid = cid;
    _isLive = isLive;
    _audioOnly = onlyPlayAudio;
    _width = width;
    _height = height;
    _start();
    _startSampling(_generation);
  }

  /// Anime4K shader changes reset the shader list, so the watermark filter has
  /// to be appended again.
  Future<void> afterShaderChanged(Player player) async {
    if (_activeRegions.isEmpty || !identical(player, _player)) return;
    try {
      await WatermarkFilter.apply(player, _activeRegions);
    } catch (error, stackTrace) {
      if (kDebugMode) debugPrint('reapply watermark failed: $error');
      Utils.reportError('reapply watermark failed: $error', stackTrace);
    }
  }

  Future<void> setPosition(WatermarkPosition value) async {
    position.value = value;
    await _setting.put(ForkPref.watermarkPositionKey, value.index);
    if (ForkPref.watermarkMode != WatermarkMode.bilibili ||
        _isLive ||
        _audioOnly) {
      return;
    }
    await _applyFixed(++_generation);
  }

  void dispose() {
    _generation++;
    _stopSampling();
    _player = null;
    _activeRegions = const [];
  }

  void _start() {
    final mode = ForkPref.watermarkMode;
    if (mode == WatermarkMode.disabled || _isLive || _audioOnly) return;
    final generation = ++_generation;
    switch (mode) {
      case WatermarkMode.disabled:
        break;
      case WatermarkMode.bilibili:
        unawaited(_applyFixed(generation));
      case WatermarkMode.bilibiliAuto:
        unawaited(_detectBilibili(generation));
      case WatermarkMode.advanced:
        unawaited(_detectAdvanced(generation));
    }
  }

  void _startSampling(int generation) {
    final mode = ForkPref.watermarkMode;
    if (mode != WatermarkMode.bilibiliAuto &&
        mode != WatermarkMode.advanced) {
      return;
    }
    if (_isLive || _audioOnly || _player == null) return;
    _sampler?.cancel();
    _refresh?.cancel();
    _recent.clear();
    _lastPosition = -1;
    _wanted = _startupSamples;
    _sampler = Timer.periodic(_sampleInterval, (_) {
      unawaited(_captureScreen(generation));
    });
    _refresh = Timer.periodic(_refreshInterval, (_) {
      final player = _player;
      if (player == null || !_isCurrent(generation, player)) {
        _refresh?.cancel();
        return;
      }
      if (_wanted <= 0) _wanted = _refreshSamples;
    });
  }

  void _stopSampling() {
    _sampler?.cancel();
    _refresh?.cancel();
    _sampler = null;
    _refresh = null;
    _recent.clear();
    _wanted = 0;
    _capturing = false;
    _lastPosition = -1;
  }

  /// Grabs the frame currently on screen. Sampling only while frames advance
  /// keeps a paused player from collecting the same frame repeatedly.
  Future<void> _captureScreen(int generation) async {
    final player = _player;
    if (player == null ||
        !_isCurrent(generation, player) ||
        _wanted <= 0 ||
        _capturing ||
        !player.state.playing) {
      return;
    }
    final position = player.state.position.inMilliseconds;
    if (position == _lastPosition) return;
    _lastPosition = position;
    _capturing = true;
    try {
      final image = await player.screenshot();
      if (image == null) return;
      try {
        final frame = await WatermarkInput.fromImage(image);
        if (frame == null || !_isCurrent(generation, player)) return;
        _recent.add(frame);
        if (_recent.length > _maxRecentFrames) _recent.removeAt(0);
        _wanted--;
        if (_wanted <= 0) {
          unawaited(_detectFromScreen(generation, player));
        }
      } finally {
        image.dispose();
      }
    } catch (error) {
      if (kDebugMode) debugPrint('watermark screenshot failed: $error');
    } finally {
      _capturing = false;
    }
  }

  Future<void> _detectFromScreen(int generation, Player player) async {
    final frames = List<WatermarkFrame>.of(_recent);
    if (frames.length < 2 || !_isCurrent(generation, player)) return;
    final mode = ForkPref.watermarkMode;
    final regions = <WatermarkRegion>[];
    if (mode == WatermarkMode.advanced && frames.length >= 6) {
      try {
        regions.addAll(
          await WatermarkDetector.detect(WatermarkMode.advanced, frames),
        );
      } catch (error, stackTrace) {
        Utils.reportError('watermark screen detection failed: $error', stackTrace);
      }
    }
    try {
      final anchor = await WatermarkDetector.detectBilibiliAnchorInFrames(
        frames,
      );
      if (anchor != null) {
        regions.add(anchor.region);
        if (kDebugMode) {
          debugPrint(
            'watermark screen anchor: ${anchor.corner.name} '
            'score=${anchor.score.toStringAsFixed(3)} '
            'support=${anchor.support}/${anchor.frameCount}',
          );
        }
      }
    } catch (error, stackTrace) {
      Utils.reportError('watermark screen anchor failed: $error', stackTrace);
    }
    if (regions.isEmpty || !_isCurrent(generation, player)) return;
    final merged = WatermarkDetector.mergeRegions([
      ..._activeRegions,
      ...regions,
    ]);
    if (merged.length == _activeRegions.length &&
        _sameRegions(merged, _activeRegions)) {
      return;
    }
    final applied = await _applyDetected(generation, player, merged);
    if (applied && !_appliedOnce) {
      _appliedOnce = true;
      SmartDialog.showToast('已处理 ${_activeRegions.length} 处水印');
    }
  }

  static bool _sameRegions(
    List<WatermarkRegion> first,
    List<WatermarkRegion> second,
  ) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      final a = first[index];
      final b = second[index];
      if ((a.left - b.left).abs() > 0.004 ||
          (a.top - b.top).abs() > 0.004 ||
          (a.right - b.right).abs() > 0.004 ||
          (a.bottom - b.bottom).abs() > 0.004) {
        return false;
      }
    }
    return true;
  }

  Future<void> _detectBilibili(int generation) async {
    final bvid = _bvid;
    final player = _player;
    if (bvid == null || player == null) return;

    final region = await FirstFrameWatermarkService.detect(bvid);
    if (region == null || !_isCurrent(generation, player)) return;
    if (await _applyDetected(generation, player, [region])) {
      SmartDialog.showToast('已处理 bilibili 水印');
    }
  }

  Future<bool> _applyFixed(int generation) async {
    if (generation != _generation) return false;
    final player = _player;
    if (player == null) return false;

    try {
      final region = WatermarkRegion.fixed(position.value);
      await WatermarkFilter.apply(player, [region]);
      if (!_isCurrent(generation, player)) return false;
      _activeRegions = [region];
      return true;
    } catch (error, stackTrace) {
      Utils.reportError('fixed watermark filter failed: $error', stackTrace);
      if (kDebugMode) {
        debugPrint('fixed watermark filter failed: $error');
        debugPrint(stackTrace.toString());
      }
      return false;
    }
  }

  Future<void> _detectAdvanced(int generation) async {
    final bvid = _bvid;
    final videoCid = _cid;
    final player = _player;
    if (bvid == null || videoCid == null || player == null) return;

    // Each branch publishes as soon as it completes: a slow first-frame
    // request must never delay an already-finished videoshot result.
    WatermarkRegion? firstFrameRegion;
    var videoShotRegions = const <WatermarkRegion>[];
    var applyQueue = Future<void>.value();

    Future<void> publish() {
      final regions = WatermarkDetector.mergeRegions([
        if (firstFrameRegion != null) firstFrameRegion!,
        ...videoShotRegions,
      ]);
      if (regions.isEmpty) return Future.value();
      applyQueue = applyQueue.then((_) async {
        if (!_isCurrent(generation, player)) return;
        await _applyDetected(generation, player, regions);
      });
      return applyQueue;
    }

    final firstFrameTask = () async {
      firstFrameRegion = await FirstFrameWatermarkService.detect(bvid);
      if (!_isCurrent(generation, player) || firstFrameRegion == null) {
        return;
      }
      await publish();
    }();
    final videoShotTask = () async {
      videoShotRegions = await _detectVideoShotWatermarks(
        generation,
        bvid,
        videoCid,
        player,
      );
      if (!_isCurrent(generation, player) || videoShotRegions.isEmpty) {
        return;
      }
      await publish();
    }();

    await Future.wait([firstFrameTask, videoShotTask]);
    await applyQueue;
    if (_isCurrent(generation, player) && _activeRegions.isNotEmpty) {
      SmartDialog.showToast('已处理 ${_activeRegions.length} 处固定水印');
    }
  }

  Future<List<WatermarkRegion>> _detectVideoShotWatermarks(
    int generation,
    String bvid,
    int videoCid,
    Player player,
  ) async {
    try {
      final previews = await VideoShotPreviewService.resolveFrames(
        bvid: bvid,
        cid: videoCid,
      );
      if (!_isCurrent(generation, player)) return const [];

      final frames = <WatermarkFrame>[];
      for (final preview in previews) {
        ui.Codec? codec;
        ui.Image? image;
        try {
          codec = await ui.instantiateImageCodec(preview.bytes);
          image = (await codec.getNextFrame()).image;
          final frame = await WatermarkInput.fromImage(image);
          if (frame != null) frames.add(frame);
        } finally {
          image?.dispose();
          codec?.dispose();
        }
      }

      if (frames.length < 6) {
        Utils.reportError(
          'watermark: videoshot returned only ${frames.length} usable frames',
        );
        return const [];
      }

      final regions = await WatermarkDetector.detect(
        WatermarkMode.advanced,
        frames,
      );
      if (!_isCurrent(generation, player)) return const [];
      if (regions.isEmpty) {
        final diagnostics = await WatermarkDetector.diagnoseAdvanced(frames);
        if (!_isCurrent(generation, player)) return const [];
        final shots = previews
            .map((item) => '${item.frameIndex}@${item.timestamp}')
            .join(',');
        Utils.reportError(
          'watermark: no stable candidate (advanced videoshot, '
          '${frames.length} frames); shots=[$shots]; $diagnostics',
        );
        return const [];
      }

      final videoParams = player.state.videoParams;
      final rotation = (videoParams.rotate ?? 0) % 360;
      final pixelAspectRatio = videoParams.par ?? 1.0;
      if (rotation != 0 || (pixelAspectRatio - 1.0).abs() > 0.01) {
        Utils.reportError(
          'watermark: unsupported video geometry '
          '(rotate=$rotation, par=$pixelAspectRatio)',
        );
        return const [];
      }
      final videoWidth =
          videoParams.w ??
          (player.state.width == 0 ? (_width ?? 0) : player.state.width);
      final videoHeight =
          videoParams.h ??
          (player.state.height == 0 ? (_height ?? 0) : player.state.height);
      if (videoWidth <= 0 || videoHeight <= 0) return const [];
      final previewAspect = frames.first.width / frames.first.height;
      final videoAspect = videoWidth / videoHeight;
      if (((previewAspect - videoAspect).abs() / videoAspect) > 0.03) {
        Utils.reportError(
          'watermark: videoshot aspect ratio mismatch '
          '($previewAspect vs $videoAspect)',
        );
        return const [];
      }
      return regions;
    } catch (error, stackTrace) {
      Utils.reportError(
        'videoshot watermark detection failed: $error',
        stackTrace,
      );
      if (kDebugMode) {
        debugPrint('videoshot watermark detection failed: $error');
        debugPrint(stackTrace.toString());
      }
      return const [];
    }
  }

  bool _isCurrent(int generation, Player player) =>
      generation == _generation && identical(player, _player);

  Future<bool> _applyDetected(
    int generation,
    Player player,
    List<WatermarkRegion> regions,
  ) async {
    if (!_isCurrent(generation, player) || regions.isEmpty) return false;
    try {
      await WatermarkFilter.apply(player, regions);
      if (!_isCurrent(generation, player)) return false;
      _activeRegions = regions;
      return true;
    } catch (error, stackTrace) {
      Utils.reportError('advanced watermark filter failed: $error', stackTrace);
      if (kDebugMode) {
        debugPrint('advanced watermark filter failed: $error');
        debugPrint(stackTrace.toString());
      }
      return false;
    }
  }
}
