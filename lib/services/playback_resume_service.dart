import 'dart:collection';

import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/models_new/history/data.dart';
import 'package:PiliPlus/utils/accounts.dart';

Future<int?> resolvePlaybackResumeProgress({
  required bool sameAccount,
  required int? explicitProgress,
  required String? bvid,
  required int? cid,
  required int? epId,
  required Future<HistoryData?> Function(String keyword) loadHistory,
}) async {
  if (explicitProgress != null || sameAccount) return explicitProgress;
  if (epId == null && (bvid == null || bvid.isEmpty)) return null;

  final keyword = epId != null ? '$epId' : bvid!;
  final response = await loadHistory(keyword);
  final normalizedBvid = bvid?.toUpperCase();
  for (final item in response?.list ?? const []) {
    final history = item.history;
    final matched = epId != null
        ? history.epid == epId
        : history.bvid?.toUpperCase() == normalizedBvid &&
            (cid == null || history.cid == null || history.cid == cid);
    if (matched) return item.playbackProgress;
  }
  return null;
}

/// Resolves playback progress when history and video parsing use different
/// accounts.
///
/// A null result deliberately lets the player use the progress returned by the
/// video account's play-url response. A zero result explicitly starts over.
abstract final class PlaybackResumeService {
  static const _maxEntries = 320;
  static const _ttl = Duration(minutes: 5);

  static final LinkedHashMap<String,
          ({DateTime expiresAt, Future<int?> value})>
      _cache = LinkedHashMap();

  static Future<int?> resolve({
    String? bvid,
    int? cid,
    int? epId,
    int? explicitProgress,
  }) {
    final sameAccount = Accounts.history.mid == Accounts.video.mid;
    if (explicitProgress != null || sameAccount) {
      return Future<int?>.value(explicitProgress);
    }

    final identity = epId != null
        ? 'ep:$epId'
        : bvid == null || bvid.isEmpty
            ? null
            : 'bv:${bvid.toUpperCase()}:${cid ?? 0}';
    if (identity == null) return Future<int?>.value();

    final key = '${Accounts.history.mid}:$identity';
    final now = DateTime.now();
    final cached = _cache.remove(key);
    if (cached != null && cached.expiresAt.isAfter(now)) {
      _cache[key] = cached;
      return cached.value;
    }

    final request = _query(
      bvid: bvid,
      cid: cid,
      epId: epId,
      key: key,
    );
    _cache[key] = (expiresAt: now.add(_ttl), value: request);
    while (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    return request;
  }

  static Future<int?> _query({
    String? bvid,
    int? cid,
    int? epId,
    required String key,
  }) async {
    try {
      return resolvePlaybackResumeProgress(
        sameAccount: false,
        explicitProgress: null,
        bvid: bvid,
        cid: cid,
        epId: epId,
        loadHistory: (keyword) async {
          final res = await UserHttp.searchHistory(
            pn: 1,
            keyword: keyword,
            account: Accounts.history,
          );
          return switch (res) {
            Success(:final response) => response,
            _ => null,
          };
        },
      );
    } catch (_) {
      _cache.remove(key);
      return null;
    }
  }
}
