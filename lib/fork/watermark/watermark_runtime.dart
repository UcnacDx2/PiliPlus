import 'dart:async';

import 'package:PiliPlus/fork/fork_prefs.dart';
import 'package:PiliPlus/fork/watermark/first_frame_watermark_service.dart';
import 'package:PiliPlus/fork/watermark/watermark_detector.dart';
import 'package:PiliPlus/fork/watermark/watermark_stroke_mask.dart';
import 'package:PiliPlus/fork/watermark/watermark_filter.dart';
import 'package:PiliPlus/fork/watermark/watermark_mode.dart';
import 'package:PiliPlus/fork/watermark/watermark_region.dart';
import 'package:PiliPlus/fork/watermark/video_shot_frame_service.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:media_kit/media_kit.dart';

/// Owns watermark removal for the currently opened media.
///
/// All player-facing state lives here instead of `PlPlayerController`, so the
/// upstream player only needs three hook calls (`beforeOpen`, `started`,
/// `afterShaderChanged`).
final class ForkWatermarkRuntime {

  Player? _player;
  String? _bvid;
  bool _isLive = false;
  bool _audioOnly = false;

  int _generation = 0;
  List<WatermarkRegion> _activeRegions = const [];
  WatermarkRefinement? _activeRefinement;

  /// Clears the shader applied to the previous media before a new source is
  /// opened on the same mpv instance.
  Future<void> beforeOpen() async {
    _generation++;
    _activeRegions = const [];
    _activeRefinement = null;
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
    _isLive = isLive;
    _audioOnly = onlyPlayAudio;
    _start();
  }

  /// Anime4K shader changes reset the shader list, so the watermark filter has
  /// to be appended again.
  Future<void> afterShaderChanged(Player player) async {
    if (_activeRegions.isEmpty || !identical(player, _player)) return;
    try {
      await WatermarkFilter.apply(
        player,
        _activeRegions,
        refinement: _activeRefinement,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) debugPrint('reapply watermark failed: $error');
      Utils.reportError('reapply watermark failed: $error', stackTrace);
    }
  }

  void dispose() {
    _generation++;
    _player = null;
    _activeRegions = const [];
    _activeRefinement = null;
  }

  /// Re-runs detection with the current mode, for the in-player watermark
  /// switch. Only meaningful while a media is bound and playing.
  void reload() {
    final player = _player;
    if (player == null) return;
    WatermarkFilter.clear(player);
    _start();
  }

  void _start() {
    final mode = ForkPref.watermarkMode;
    if (mode == WatermarkMode.disabled || _isLive || _audioOnly) return;
    final generation = ++_generation;
    // Both removal styles need the same detection pass; they differ only in
    // how the detected region is rendered.
    unawaited(_detectBilibili(generation));
  }

  Future<void> _detectBilibili(int generation) async {
    final bvid = _bvid;
    final player = _player;
    if (bvid == null || player == null) return;

    final detail = await FirstFrameWatermarkService.detectDetail(bvid);
    final region = detail.region;
    if (region == null || !_isCurrent(generation, player)) return;
    // 整块覆盖不需要笔画 mask，直接用整框填充（fork.3 的纯文本 shader 路径）。
    WatermarkRefinement? refinement;
    if (ForkPref.watermarkMode == WatermarkMode.stroke) {
      // 视频截图中再取几帧补充时域投票：单帧投票会让背景噪声
      // 直接进入笔画 mask（细微白点扩散）。
      final frames = await _analysisFrames(
        bvid,
        detail,
        player,
      );
      refinement = await _buildRefinement(frames, region);
    }
    if (await _applyDetected(generation, player, [region],
        refinement: refinement)) {
      SmartDialog.showToast('已处理 bilibili 水印');
    }
  }

  /// The first-frame thumbnail plus videoshot sprite cells, so the stroke
  /// mask is voted on across timestamps instead of a single image.
  Future<List<WatermarkFrame>> _analysisFrames(
    String bvid,
    FirstFrameDetail detail,
    Player player,
  ) async {
    final frames = [...detail.frames];
    if (frames.isEmpty) return frames;
    try {
      final shot = await VideoShotFrameService.frames(bvid: bvid, cid: null);
      if (shot.isNotEmpty) {
        // Only frames whose aspect matches the first-frame thumbnail can vote
        // on the same grid, which `buildSync` enforces again per frame.
        final reference = frames.first;
        frames.addAll(
          shot.where((frame) {
            final ratio =
                (frame.width / frame.height) /
                (reference.width / reference.height);
            return (ratio - 1).abs() < 0.03;
          }),
        );
      }
    } catch (error, stackTrace) {
      Utils.reportError('videoshot frames failed: $error', stackTrace);
    }
    return frames;
  }

  /// Builds the stroke mask for a detected region from the frames the
  /// detection ran on. A failure here only downgrades the shader to the
  /// whole-region blend, never blocks the filter.
  Future<WatermarkRefinement?> _buildRefinement(
    List<WatermarkFrame> frames,
    WatermarkRegion region,
  ) async {
    if (frames.isEmpty) return null;
    try {
      final anchor = await WatermarkDetector.detectBilibiliAnchorInFrames(
        frames,
      );
      if (anchor == null) return null;
      return await WatermarkStrokeMaskBuilder.build(frames, anchor);
    } catch (error, stackTrace) {
      Utils.reportError('stroke mask build failed: $error', stackTrace);
      return null;
    }
  }

  bool _isCurrent(int generation, Player player) =>
      generation == _generation && identical(player, _player);

  Future<bool> _applyDetected(
    int generation,
    Player player,
    List<WatermarkRegion> regions, {
    WatermarkRefinement? refinement,
  }) async {
    if (!_isCurrent(generation, player) || regions.isEmpty) return false;
    try {
      await WatermarkFilter.apply(
        player,
        regions,
        refinement: refinement,
      );
      if (!_isCurrent(generation, player)) return false;
      _activeRegions = regions;
      _activeRefinement = refinement;
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
