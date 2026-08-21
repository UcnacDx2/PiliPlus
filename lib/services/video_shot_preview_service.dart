import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models_new/video/video_shot/data.dart';
import 'package:PiliPlus/services/first_frame_quality_service.dart';
import 'package:dio/dio.dart';

/// A small, display-ready frame cropped from a Bilibili videoshot sprite.
final class VideoShotPreview {
  const VideoShotPreview({
    required this.bytes,
    required this.timestamp,
    required this.frameIndex,
  });

  final Uint8List bytes;
  final int timestamp;
  final int frameIndex;
}

final class VideoShotFrameLocation {
  const VideoShotFrameLocation({
    required this.spriteUrl,
    required this.frameIndex,
    required this.timestamp,
    required this.column,
    required this.row,
  });

  final String spriteUrl;
  final int frameIndex;
  final int timestamp;
  final int column;
  final int row;
}

final class _PreviewCacheEntry {
  const _PreviewCacheEntry(this.preview, this.expiresAt);

  final VideoShotPreview? preview;
  final DateTime expiresAt;
}

final class _AsyncGate {
  _AsyncGate(this.limit);

  final int limit;
  int _active = 0;
  final Queue<Completer<void>> _waiting = Queue();

  Future<T> run<T>(Future<T> Function() action) async {
    if (_active >= limit) {
      final waiter = Completer<void>();
      _waiting.add(waiter);
      await waiter.future;
    }
    _active++;
    try {
      return await action();
    } finally {
      _active--;
      if (_waiting.isNotEmpty) _waiting.removeFirst().complete();
    }
  }
}

/// Resolves a representative videoshot frame after a first-frame rejection.
///
/// The service deliberately processes only one sprite at a time. Full sprite
/// sheets can be large after decoding, so neither source bytes, [ui.Image]s nor
/// codecs are retained. Only small PNG results are kept in a bounded LRU cache.
abstract final class VideoShotPreviewService {
  static const _targetWidth = 320;
  static const _targetHeight = 180;
  static const _analysisWidth = 32;
  static const _analysisHeight = 18;
  static const _maxEntries = 96;
  static const _successTtl = Duration(hours: 12);
  static const _failureTtl = Duration(minutes: 10);

  static final LinkedHashMap<String, _PreviewCacheEntry> _cache =
      LinkedHashMap();
  static final Map<String, Future<VideoShotPreview?>> _inFlight = {};
  static final _metadataGate = _AsyncGate(3);
  static final _spriteGate = _AsyncGate(1);

  /// Returns a usable middle frame, or null so callers can keep the cover.
  ///
  /// The 50% candidate is tried first. 35% and 65% are fallbacks, and sprite
  /// sheets shared by candidates are downloaded and decoded only once.
  static Future<VideoShotPreview?> resolve({
    required String bvid,
    required int cid,
  }) {
    if (bvid.isEmpty || cid <= 0) return Future.value();
    final key = '$bvid:$cid';
    final now = DateTime.now();
    final cached = _cache.remove(key);
    if (cached != null && cached.expiresAt.isAfter(now)) {
      _cache[key] = cached;
      return Future.value(cached.preview);
    }

    return _inFlight.putIfAbsent(key, () async {
      VideoShotPreview? preview;
      try {
        preview = await _metadataGate.run(() async {
          final state = await VideoHttp.videoshot(bvid: bvid, cid: cid);
          final data = state.dataOrNull;
          if (data == null || !_isValid(data)) return null;
          return _spriteGate.run(() => _resolveFromMetadata(data));
        });
      } catch (_) {
        preview = null;
      } finally {
        _inFlight.remove(key);
      }

      _cache[key] = _PreviewCacheEntry(
        preview,
        DateTime.now().add(preview == null ? _failureTtl : _successTtl),
      );
      while (_cache.length > _maxEntries) {
        _cache.remove(_cache.keys.first);
      }
      return preview;
    });
  }

  static bool _isValid(VideoShotData data) =>
      data.image.isNotEmpty &&
      data.index.isNotEmpty &&
      data.imgXLen > 0 &&
      data.imgYLen > 0 &&
      data.imgXSize > 0 &&
      data.imgYSize > 0;

  static Future<VideoShotPreview?> _resolveFromMetadata(
    VideoShotData data,
  ) async {
    final locations = candidateLocations(data);
    final bySprite = <String, List<VideoShotFrameLocation>>{};
    for (final location in locations) {
      bySprite.putIfAbsent(location.spriteUrl, () => []).add(location);
    }

    for (final entry in bySprite.entries) {
      final response = await Request.dio.get<List<int>>(
        entry.key,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 12),
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) continue;

      final result = await _decodeSprite(
        Uint8List.fromList(bytes),
        data,
        entry.value,
      );
      if (result != null) return result;
    }
    return null;
  }

  /// Pure coordinate calculation exposed for unit tests and alternate UIs.
  static List<VideoShotFrameLocation> candidateLocations(VideoShotData data) {
    final candidates = <VideoShotFrameLocation>[];
    final seen = <int>{};
    for (final ratio in const [0.50, 0.35, 0.65]) {
      final frameIndex = ((data.index.length - 1) * ratio).round();
      if (!seen.add(frameIndex)) continue;
      final pageIndex = frameIndex ~/ data.totalPerImage;
      if (pageIndex < 0 || pageIndex >= data.image.length) continue;
      final indexInPage = frameIndex % data.totalPerImage;
      candidates.add(
        VideoShotFrameLocation(
          spriteUrl: data.image[pageIndex],
          frameIndex: frameIndex,
          timestamp: data.index[frameIndex],
          column: indexInPage % data.imgXLen,
          row: indexInPage ~/ data.imgXLen,
        ),
      );
    }
    return candidates;
  }

  static Future<VideoShotPreview?> _decodeSprite(
    Uint8List bytes,
    VideoShotData data,
    List<VideoShotFrameLocation> candidates,
  ) async {
    ui.Codec? codec;
    ui.Image? sprite;
    try {
      codec = await ui.instantiateImageCodec(bytes);
      sprite = (await codec.getNextFrame()).image;
      final scaleX = sprite.width / (data.imgXLen * data.imgXSize);
      final scaleY = sprite.height / (data.imgYLen * data.imgYSize);

      for (final candidate in candidates) {
        final source = ui.Rect.fromLTWH(
          candidate.column * data.imgXSize * scaleX,
          candidate.row * data.imgYSize * scaleY,
          data.imgXSize * scaleX,
          data.imgYSize * scaleY,
        );
        final cropped = await _crop(sprite, source);
        try {
          if (!await _isUsable(cropped)) continue;
          final png = await cropped.toByteData(format: ui.ImageByteFormat.png);
          if (png == null) continue;
          return VideoShotPreview(
            bytes: png.buffer.asUint8List(
              png.offsetInBytes,
              png.lengthInBytes,
            ),
            timestamp: candidate.timestamp,
            frameIndex: candidate.frameIndex,
          );
        } finally {
          cropped.dispose();
        }
      }
      return null;
    } finally {
      sprite?.dispose();
      codec?.dispose();
    }
  }

  static Future<ui.Image> _crop(ui.Image source, ui.Rect sourceRect) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      source,
      sourceRect,
      ui.Rect.fromLTWH(
        0,
        0,
        _targetWidth.toDouble(),
        _targetHeight.toDouble(),
      ),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    final picture = recorder.endRecording();
    try {
      return picture.toImage(_targetWidth, _targetHeight);
    } finally {
      picture.dispose();
    }
  }

  static Future<bool> _isUsable(ui.Image image) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      image,
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      ui.Rect.fromLTWH(
        0,
        0,
        _analysisWidth.toDouble(),
        _analysisHeight.toDouble(),
      ),
      ui.Paint()..filterQuality = ui.FilterQuality.low,
    );
    final picture = recorder.endRecording();
    ui.Image? analysis;
    try {
      analysis = await picture.toImage(_analysisWidth, _analysisHeight);
      final rgba = await analysis.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (rgba == null) return false;
      final bytes = rgba.buffer.asUint8List(
        rgba.offsetInBytes,
        rgba.lengthInBytes,
      );
      return FirstFrameQualityAnalyzer.classify(
            FirstFrameQualityAnalyzer.metrics(bytes),
          ) ==
          FirstFrameQuality.usable;
    } finally {
      analysis?.dispose();
      picture.dispose();
    }
  }
}
