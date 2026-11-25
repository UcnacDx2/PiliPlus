import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/common/video/base_quality.dart';
import 'package:PiliPlus/models/video/play/url.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/utils/video_utils.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Refetches the playurl and reopens the current media seamlessly in place.
///
/// This is what `PlPlayerFork.renewal` calls when a signed link expires or the
/// player stops advancing. Quality, codec, and resume position are preserved,
/// while playback continues without pausing, clearing danmaku, or displaying toasts.
extension ForkVideoRenewal on VideoDetailController {
  /// Returns true when the media was refreshed with a fresh playurl.
  Future<bool> forkRenewStream({bool showToast = false}) async {
    if (isClosed || isFileSource) return false;
    final player = plPlayerController;
    if (player.isLive) return false;

    final quality = currentVideoQa.value?.code;
    final position = player.positionInMilliseconds;
    final wasPlaying = player.playerStatus.isPlaying ||
        (!player.playerStatus.isCompleted && position > 0);

    // Refresh stream URLs directly using the stream account (Accounts.video).
    // We intentionally bypass ForkAccountPlayback here because the current playback
    // position is already known in-memory and history account progress is not needed.
    final result = await VideoHttp.videoUrl(
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

    final currentPosition = player.positionInMilliseconds;
    final resumePosition = currentPosition > 0 ? currentPosition : position;

    if (kDebugMode) {
      debugPrint(
        'fork renew: qa=${firstVideo.id} codec=${firstVideo.codecid} '
        'position=${resumePosition}ms playing=$wasPlaying',
      );
    }

    final native = player.videoPlayerController;
    if (native != null) {
      await player.fork.reloadMedia(
        videoUrl: videoUrl!,
        audioUrl: audioUrl,
        seekTo: Duration(milliseconds: resumePosition),
        play: wasPlaying,
        volume: volume,
      );
    } else {
      defaultST = Duration(milliseconds: resumePosition);
      await playerInit(autoplay: wasPlaying);
    }
    return true;
  }
}
