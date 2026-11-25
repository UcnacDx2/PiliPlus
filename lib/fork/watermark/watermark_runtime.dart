import 'dart:async';

import 'package:PiliPlus/fork/fork_prefs.dart';
import 'package:PiliPlus/fork/watermark/first_frame_watermark_service.dart';
import 'package:PiliPlus/fork/watermark/watermark_detector.dart';
import 'package:PiliPlus/fork/watermark/watermark_stroke_mask.dart';
import 'package:PiliPlus/fork/watermark/watermark_filter.dart';
import 'package:PiliPlus/fork/watermark/watermark_mode.dart';
import 'package:PiliPlus/fork/watermark/watermark_region.dart';
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

  /// Clears the shader applied to the previous media before a new source is
  /// opened on the same mpv instance.
  Future<void> beforeOpen() async {
    _generation++;
    _activeRegions = const [];
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
      await WatermarkFilter.apply(player, _activeRegions);
    } catch (error, stackTrace) {
      if (kDebugMode) debugPrint('reapply watermark failed: $error');
      Utils.reportError('reapply watermark failed: $error', stackTrace);
    }
  }

  void dispose() {
    _generation++;
    _player = null;
    _activeRegions = const [];
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
    final refinement = ForkPref.watermarkMode == WatermarkMode.stroke
        ? await _buildRefinement(detail.frames, region)
        : null;
    if (await _applyDetected(generation, player, [region],
        refinement: refinement)) {
      SmartDialog.showToast('已处理 bilibili 水印');
    }
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
      await WatermarkFilter.apply(player, regions, refinement: refinement);
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
