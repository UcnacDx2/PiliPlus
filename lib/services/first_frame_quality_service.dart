import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/utils/extension/string_ext.dart';
import 'package:dio/dio.dart';

/// Result of inspecting a low-resolution first frame.
enum FirstFrameQuality {
  usable,
  mostlyBlack,
  tinyVisibleSubject,
  lowInformationDark,
  lowInformationFlat,
  decodeFailed,
}

final class FirstFrameQualityMetrics {
  const FirstFrameQualityMetrics({
    required this.meanLuma,
    required this.darkRatio,
    required this.visibleRatio,
    required this.standardDeviation,
    required this.shadowRatio,
    required this.edgeRatio,
  });

  final double meanLuma;
  final double darkRatio;
  final double visibleRatio;
  final double standardDeviation;
  final double shadowRatio;
  final double edgeRatio;
}

final class FirstFrameQualityAnalyzer {
  const FirstFrameQualityAnalyzer._();

  static FirstFrameQualityMetrics metrics(
    Uint8List rgba, {
    int darkThreshold = 18,
    int visibleThreshold = 54,
  }) {
    if (rgba.isEmpty || rgba.length % 4 != 0) {
      return const FirstFrameQualityMetrics(
        meanLuma: 0,
        darkRatio: 1,
        visibleRatio: 0,
        standardDeviation: 0,
        shadowRatio: 1,
        edgeRatio: 0,
      );
    }

    final pixelCount = rgba.length ~/ 4;
    var darkPixels = 0;
    var visiblePixels = 0;
    var sum = 0.0;
    var squareSum = 0.0;
    var shadowPixels = 0;
    final lumas = Float64List(pixelCount);

    for (var i = 0; i < rgba.length; i += 4) {
      // Integer approximation of BT.709 luma; alpha is intentionally ignored.
      final luma =
          (rgba[i] * 54 + rgba[i + 1] * 183 + rgba[i + 2] * 19) / 256;
      lumas[i ~/ 4] = luma;
      sum += luma;
      squareSum += luma * luma;
      if (luma <= darkThreshold) darkPixels++;
      if (luma <= 40) shadowPixels++;
      if (luma >= visibleThreshold) visiblePixels++;
    }

    var edges = 0;
    var edgeComparisons = 0;
    const analysisWidth = 32;
    for (var index = 0; index < pixelCount; index++) {
      final x = index % analysisWidth;
      final y = index ~/ analysisWidth;
      if (x > 0) {
        if ((lumas[index] - lumas[index - 1]).abs() >= 16) edges++;
        edgeComparisons++;
      }
      if (y > 0) {
        if ((lumas[index] - lumas[index - analysisWidth]).abs() >= 16) {
          edges++;
        }
        edgeComparisons++;
      }
    }
    final mean = sum / pixelCount;
    final variance = (squareSum / pixelCount) - mean * mean;
    return FirstFrameQualityMetrics(
      meanLuma: mean / 255,
      darkRatio: darkPixels / pixelCount,
      visibleRatio: visiblePixels / pixelCount,
      standardDeviation: math.sqrt(math.max(0, variance)) / 255,
      shadowRatio: shadowPixels / pixelCount,
      edgeRatio: edgeComparisons == 0 ? 0 : edges / edgeComparisons,
    );
  }

  static FirstFrameQuality classify(FirstFrameQualityMetrics value) {
    final mostlyBlack =
        value.darkRatio >= 0.985 &&
        value.meanLuma <= 0.025 &&
        value.standardDeviation <= 0.035;
    if (mostlyBlack) return FirstFrameQuality.mostlyBlack;

    final tinyVisibleSubject =
        value.meanLuma <= 0.04 &&
        value.darkRatio >= 0.89 &&
        value.visibleRatio <= 0.06 &&
        value.standardDeviation <= 0.10;
    if (tinyVisibleSubject) return FirstFrameQuality.tinyVisibleSubject;

    final lowInformationDark =
        value.meanLuma <= 0.16 &&
        value.shadowRatio >= 0.985 &&
        value.standardDeviation <= 0.065 &&
        value.edgeRatio <= 0.035;
    if (lowInformationDark) return FirstFrameQuality.lowInformationDark;

    // Reject near-solid title cards/backgrounds at any brightness. Requiring both
    // tiny global variance and almost no local edges avoids rejecting ordinary
    // bright or softly exposed video frames.
    final lowInformationFlat =
        value.standardDeviation <= 0.012 && value.edgeRatio <= 0.008;
    if (lowInformationFlat) return FirstFrameQuality.lowInformationFlat;
    return FirstFrameQuality.usable;
  }
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
final class _QualityCacheEntry {
  const _QualityCacheEntry(this.quality, this.expiresAt);

  final FirstFrameQuality quality;
  final DateTime expiresAt;
}

/// Inspects first-frame thumbnails while retaining only bounded scalar results.
///
/// No [ui.Image], codec, raw image bytes or response bodies are cached.
abstract final class FirstFrameQualityService {
  static const _analysisWidth = 32;
  static const _analysisHeight = 18;
  static const _maxEntries = 320;
  static const _successTtl = Duration(hours: 12);
  static const _failureTtl = Duration(minutes: 10);

  static final LinkedHashMap<String, _QualityCacheEntry> _cache =
      LinkedHashMap();
  static final Map<String, Future<FirstFrameQuality>> _inFlight = {};
  static final _downloadGate = _AsyncGate(3);

  static Future<bool> isUsable(String? url) async {
    if (url == null || url.isEmpty) return false;
    return await inspect(url) == FirstFrameQuality.usable;
  }

  static Future<FirstFrameQuality> inspect(String url) {
    final now = DateTime.now();
    final cached = _cache.remove(url);
    if (cached != null && cached.expiresAt.isAfter(now)) {
      _cache[url] = cached;
      return Future.value(cached.quality);
    }

    return _inFlight.putIfAbsent(url, () async {
      FirstFrameQuality quality;
      try {
        quality = await _downloadGate.run(() => _downloadAndInspect(url));
      } catch (_) {
        quality = FirstFrameQuality.decodeFailed;
      } finally {
        _inFlight.remove(url);
      }

      final ttl = quality == FirstFrameQuality.decodeFailed
          ? _failureTtl
          : _successTtl;
      _cache[url] = _QualityCacheEntry(quality, DateTime.now().add(ttl));
      while (_cache.length > _maxEntries) {
        _cache.remove(_cache.keys.first);
      }
      return quality;
    });
  }

  static Future<FirstFrameQuality> _downloadAndInspect(String url) async {
    final response = await Request.dio.get<List<int>>(
      _analysisUrl(url),
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 8),
      ),
    );
    final data = response.data;
    if (data == null || data.isEmpty) return FirstFrameQuality.decodeFailed;

    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await ui.instantiateImageCodec(
        Uint8List.fromList(data),
        targetWidth: _analysisWidth,
        targetHeight: _analysisHeight,
      );
      final frame = await codec.getNextFrame();
      image = frame.image;
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bytes == null) return FirstFrameQuality.decodeFailed;
      return FirstFrameQualityAnalyzer.classify(
        FirstFrameQualityAnalyzer.metrics(bytes.buffer.asUint8List()),
      );
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }

  static String _analysisUrl(String url) {
    final uri = Uri.tryParse(url.http2https);
    if (uri == null || uri.host.isEmpty) return url.http2https;
    final isBiliCdn = uri.host.endsWith('.hdslb.com') ||
        uri.host.endsWith('.bilivideo.com') ||
        uri.host.endsWith('.biliimg.com');
    if (!isBiliCdn) return uri.toString();

    final separator = uri.path.contains('@') ? '_' : '@';
    return uri.replace(
      path: '${uri.path}${separator}64w_36h_1c_70q.webp',
    ).toString();
  }
}