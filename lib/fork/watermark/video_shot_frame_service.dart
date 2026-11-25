import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:PiliPlus/fork/http/fork_video_api.dart';
import 'package:PiliPlus/fork/watermark/watermark_detector.dart';
import 'package:PiliPlus/fork/watermark/watermark_frame.dart';
import 'package:PiliPlus/fork/watermark/watermark_input.dart';
import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/models_new/video/video_shot/data.dart';
import 'package:dio/dio.dart';

/// Additional analysis frames taken from Bilibili's videoshot sprites.
///
/// The first-frame thumbnail supplies one image, and a one-frame stroke vote
/// passes background noise straight into the mask. Videoshot sprites are
/// cached CDN stills from different timestamps, so they add the missing
/// temporal votes for free — no runtime screen sampling, no player work.
abstract final class VideoShotFrameService {
  static const _maxFrames = 3;

  /// Returns up to [_maxFrames] luma frames from the video's sprite sheets.
  /// Only frames whose aspect matches the first-frame thumbnail can vote on
  /// the same grid, which the caller enforces; here cells whose own
  /// letterboxing mismatches [aspectWidth]/[aspectHeight] are skipped.
  static Future<List<WatermarkFrame>> frames({
    required String bvid,
    required int? cid,
    int aspectWidth = 0,
    int aspectHeight = 0,
  }) async {
    try {
      final resolvedCid = cid ?? await _resolveCid(bvid);
      if (resolvedCid == null) return const [];
      final data = await ForkVideoApi.webVideoShot(bvid: bvid, cid: resolvedCid) ??
          await ForkVideoApi.appVideoShot(bvid: bvid, cid: resolvedCid);
      if (data == null) return const [];
      return await _decode(data, aspectWidth, aspectHeight);
    } catch (_) {
      return const [];
    }
  }

  static Future<int?> _resolveCid(String bvid) async {
    final info = await ForkVideoApi.getFirstFrameInfo(bvid);
    return info?.cid;
  }

  static Future<List<WatermarkFrame>> _decode(
    VideoShotData data,
    int aspectWidth,
    int aspectHeight,
  ) async {
    final frames = <WatermarkFrame>[];
    final cellW = data.imgXSize.round();
    final cellH = data.imgYSize.round();
    if (cellW <= 0 || cellH <= 0 || data.image.isEmpty) return const [];
    // The playing aspect decides which sprite cells match the visible frame;
    // a sprite of a differently letterboxed upload cannot vote on the same
    // grid. When unknown, fall back to the sprite cell's own aspect.
    final wantPortrait = aspectWidth > 0 && aspectHeight > 0
        ? aspectHeight > aspectWidth
        : cellH > cellW;

    for (final url in data.image) {
      if (frames.length >= _maxFrames) break;
      final bytes = await _download(url);
      if (bytes == null) continue;
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 480,
      );
      try {
        final image = (await codec.getNextFrame()).image;
        final cell = await _cellAt(
          image,
          cellW: cellW,
          cellH: cellH,
          columns: data.imgXLen,
          rows: data.imgYLen,
          index: frames.length,
          wantPortrait: wantPortrait,
        );
        if (cell != null) frames.add(cell);
      } finally {
        codec.dispose();
      }
    }
    return frames;
  }

  static Future<Uint8List?> _download(String url) async {
    try {
      final response = await Request.dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return null;
      return Uint8List.fromList(bytes);
    } catch (_) {
      return null;
    }
  }

  /// Crops one cell out of a decoded sprite image, skipping cells whose
  /// letterbox bars show they do not match the playing aspect.
  static Future<WatermarkFrame?> _cellAt(
    ui.Image image, {
    required int cellW,
    required int cellH,
    required int columns,
    required int rows,
    required int index,
    required bool wantPortrait,
  }) async {
    final cellIndex = index % (columns * rows);
    final column = cellIndex % columns;
    final row = cellIndex ~/ columns;
    // The decoded image is scaled to 480 px wide, so scale the cell geometry.
    final scale = image.width / (columns * cellW);
    final rect = ui.Rect.fromLTWH(
      column * cellW * scale,
      row * cellH * scale,
      cellW * scale,
      cellH * scale,
    );
    if (rect.right > image.width || rect.bottom > image.height) return null;
    final cellIsPortrait = cellH > cellW;
    // A landscape sprite of a portrait video is letterboxed and the watermark
    // sits inside the (undrawn) bars; analysing it would poison the vote.
    // Sprites occasionally letterbox a cell as well, so accept either
    // orientation when the playing aspect is unknown.
    if (wantPortrait != cellIsPortrait) return null;
    return WatermarkInput.fromImage(
      image,
      targetWidth: 480,
      upscale: true,
      sourceRect: rect,
    );
  }
}
