import 'dart:async';

import 'package:PiliPlus/http/sponsor_block.dart';
import 'package:PiliPlus/models/common/sponsor_block/skip_type.dart';
import 'package:PiliPlus/models_new/sponsor_block/segment_item.dart';
import 'package:PiliPlus/utils/storage_pref.dart';

/// A UI-free SponsorBlock controller for the TV player.
///
/// It deliberately exposes only segment state and a seek callback. It does
/// not know about Flutter, focus, dialogs, GetX, or any player controller.
class TvSponsorSegment {
  TvSponsorSegment({
    required this.uuid,
    required this.category,
    required this.start,
    required this.end,
    required this.skipType,
  });

  final String uuid;
  final String category;
  final Duration start;
  final Duration end;
  final SkipType skipType;
  bool hasSkipped = false;
}

class TvSponsorBlockController {
  TvSponsorBlockController(this._seek);

  final Future<void> Function(Duration) _seek;
  StreamSubscription<Duration>? _positionSubscription;
  final Set<String> _seekInFlight = {};
  final Set<String> _armed = {};
  final Set<String> _tracked = {};
  List<TvSponsorSegment> segments = const [];
  int _generation = 0;
  bool _disposed = false;

  bool get isEnabled => Pref.enableSponsorBlock;

  Future<void> load({required String bvid, required int cid}) async {
    final generation = ++_generation;
    segments = const [];
    _seekInFlight.clear();
    _armed.clear();
    _tracked.clear();
    if (_disposed || !isEnabled) return;

    final state = await SponsorBlock.getSkipSegments(bvid: bvid, cid: cid);
    if (_disposed || generation != _generation) return;
    final items = state.dataOrNull;
    if (items == null) return;
    segments = items
        .map(_toSegment)
        .where((segment) => segment != null)
        .cast<TvSponsorSegment>()
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  void bindPosition(Stream<Duration> position) {
    _positionSubscription?.cancel();
    if (_disposed) return;
    _positionSubscription = position.listen(_onPosition);
  }

  Future<void> reset() async {
    ++_generation;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    segments = const [];
    _seekInFlight.clear();
    _armed.clear();
    _tracked.clear();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await reset();
  }

  TvSponsorSegment? _toSegment(SegmentItemModel item) {
    if (item.segment.length < 2 || item.segment[1] <= item.segment[0]) {
      return null;
    }
    var type = _skipType(item.category);
    final minimumLength = (Pref.blockLimit * 1000).round();
    if (minimumLength > 0 && item.segment[1] - item.segment[0] < minimumLength) {
      type = SkipType.showOnly;
    }
    if (type == SkipType.disable) return null;
    return TvSponsorSegment(
      uuid: item.uuid,
      category: item.category,
      start: Duration(milliseconds: item.segment[0]),
      end: Duration(milliseconds: item.segment[1]),
      skipType: type,
    );
  }

  SkipType _skipType(String category) {
    for (final entry in Pref.blockSettings) {
      if (entry.first.name == category) return entry.second;
    }
    return SkipType.showOnly;
  }

  void _onPosition(Duration position) {
    if (_disposed) return;
    for (final segment in segments) {
      final key = segment.uuid.isEmpty
          ? '${segment.start.inMilliseconds}:${segment.end.inMilliseconds}'
          : segment.uuid;
      if (position < segment.start || position >= segment.end) {
        _armed.remove(key);
        continue;
      }
      if (segment.start <= position && position < segment.end &&
          (segment.skipType == SkipType.alwaysSkip ||
              (segment.skipType == SkipType.skipOnce && !segment.hasSkipped)) &&
          _armed.add(key) && _seekInFlight.add(key)) {
        unawaited(_skip(segment, key));
      }
    }
  }

  Future<void> _skip(TvSponsorSegment segment, String key) async {
    try {
      await _seek(segment.end);
      if (segment.skipType == SkipType.skipOnce) segment.hasSkipped = true;
      if (Pref.blockTrack && segment.uuid.isNotEmpty && _tracked.add(segment.uuid)) {
        await SponsorBlock.viewedVideoSponsorTime(segment.uuid);
      }
    } catch (_) {
      // Keep the segment retryable if the player rejects the seek.
      _armed.remove(key);
    } finally {
      _seekInFlight.remove(key);
    }
  }
}
