import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/common/video/video_type.dart';
import 'package:PiliPlus/models/video/play/url.dart';
import 'package:PiliPlus/utils/accounts.dart';

/// Account-aware playback helpers for split-account setups.
///
/// The stream may be fetched with the "video" account while watch history is
/// recorded by another account. Resume position must then come from the
/// history account, otherwise every open starts from the beginning (or from a
/// stale position the stream account happens to remember).
abstract final class ForkAccountPlayback {
  /// Same contract as [VideoHttp.videoUrl], plus the history-account progress
  /// merge when both roles are bound to different accounts.
  static Future<LoadingState<PlayUrlModel>> videoUrl({
    int? avid,
    String? bvid,
    required int cid,
    required int qn,
    dynamic epid,
    dynamic seasonId,
    required bool tryLook,
    required VideoType videoType,
    String? language,
    bool voiceBalance = false,
  }) async {
    final result = await VideoHttp.videoUrl(
      avid: avid,
      bvid: bvid,
      cid: cid,
      qn: qn,
      epid: epid,
      seasonId: seasonId,
      tryLook: tryLook,
      videoType: videoType,
      language: language,
      voiceBalance: voiceBalance,
    );
    if (result is! Success<PlayUrlModel>) return result;
    final history = Accounts.history;
    if (history.mid == Accounts.video.mid) return result;

    final progress = await VideoHttp.videoUrl(
      avid: avid,
      bvid: bvid,
      cid: cid,
      qn: qn,
      epid: epid,
      seasonId: seasonId,
      tryLook: tryLook,
      videoType: videoType,
      language: language,
      voiceBalance: voiceBalance,
      account: history,
    );
    if (progress case Success(:final response)) {
      result.response
        ..lastPlayTime = response.lastPlayTime
        ..lastPlayCid = response.lastPlayCid;
    }
    return result;
  }

  /// Resolves the resume position of a PGC episode.
  ///
  /// The stream account's playurl omits `watch_progress` for episodes it is
  /// not entitled to, so the recorded position is looked up in the history
  /// account instead.
  static Future<int?> pgcProgress({
    required int? progress,
    required int? epId,
    String? title,
  }) async {
    if ((progress != null && progress > 0) || epId == null) return progress;
    final history = Accounts.history;
    if (history.mid == Accounts.video.mid) return progress;
    final keyword = title?.trim();
    if (keyword == null || keyword.isEmpty) return progress;

    final res = await UserHttp.searchHistory(
      pn: 1,
      keyword: keyword,
      account: history,
    );
    if (res case Success(:final response)) {
      for (final item in response.list ?? const []) {
        if (item.history.business == 'pgc' && item.history.epid == epId) {
          return item.playbackProgress ?? progress;
        }
      }
    }
    return progress;
  }
}
