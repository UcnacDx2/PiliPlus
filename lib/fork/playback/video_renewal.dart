import 'package:PiliPlus/fork/playback/account_playback.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/video/base_quality.dart';
import 'package:PiliPlus/models/video/play/url.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/utils/video_utils.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Refetches the playurl and reopens the current media in place.
///
/// This is what `PlPlayerFork.renewal` calls when a signed link expires or the
/// player stops advancing. Quality, codec and resume position are preserved,
/// so the viewer sees a short stall at most.
extension ForkVideoRenewal on VideoDetailController {
  /// Returns true when the media was reopened with a fresh playurl.
  Future<bool> forkRenewStream({bool showToast = false}) async {
    if (isClosed || isFileSource) return false;
    final player = plPlayerController;
    if (player.isLive) return false;

    final quality = currentVideoQa.value?.code;
    final position = player.positionInMilliseconds;
    final wasPlaying = player.playerStatus.isPlaying ||
        (!player.playerStatus.isCompleted && position > 0);

    final result = await ForkAccountPlayback.videoUrl(
      cid: cid.value,
      bvid: bvid,
      qn: quality ?? VideoQuality.hdrVivid.code,
      epid: epId,
      seasonId: seasonId,
      tryLook: player.tryLook,
      videoType: forkVideoType,
      language: currLang.value,
      voiceBalance: player.enableAudioNormalization,
    );
    if (isClosed) return false;
    if (result is! Success<PlayUrlModel>) {
      if (showToast) result.toast();
      return false;
    }

    final fresh = result.response.dash;
    final videos = fresh?.video;
    if (fresh == null || videos == null || videos.isEmpty) return false;

    // Signed URLs are per-response, so the stale items must be replaced, not
    // merged (merge keeps the old item for the same quality/codec pair).
    final old = data.dash;
    if (old != null) {
      old.video = videos;
      if (fresh.audio case final audios? when audios.isNotEmpty) {
        old.audio = audios;
      }
    } else {
      data = result.response;
    }

    final currentQa = currentVideoQa.value?.code;
    if (currentQa != null && videos.any((item) => item.id == currentQa)) {
      firstVideo = findVideoByQa(currentQa, setCodecs: true);
    } else {
      final (targetQuality, _, targetDecode, targetVideo) =
          VideoUtils.findTargetVideo(
            videos,
            currentQa ?? videos.first.id,
            result.response.acceptQuality,
            result.response.supportFormats ?? const [],
            preferCodecs,
          );
      currentVideoQa.value = VideoQuality.fromCode(targetQuality);
      currentDecodeFormats = targetDecode;
      firstVideo = targetVideo;
    }
    videoUrl = VideoUtils.getCdnUrl(firstVideo.playUrls);

    final audios = fresh.audio ?? data.dash?.audio;
    if (audios != null && audios.isNotEmpty) {
      final firstAudio = VideoUtils.findTargetAudio(
        audios,
        currentAudioQa?.code ?? audios.first.id,
      );
      currentAudioQa = AudioQuality.fromCode(firstAudio.id);
      audioUrl = VideoUtils.getCdnUrl(firstAudio.playUrls, isAudio: true);
    }

    if (kDebugMode) {
      debugPrint(
        'fork renew: qa=${firstVideo.id} codec=${firstVideo.codecid} '
        'position=${position}ms playing=$wasPlaying',
      );
    }

    // Reopen from the current position instead of the remembered progress.
    defaultST = Duration(milliseconds: position);
    await playerInit(autoplay: wasPlaying);
    return true;
  }
}
