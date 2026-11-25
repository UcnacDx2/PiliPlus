import 'package:PiliPlus/fork/player/stream_renewal.dart';
import 'package:PiliPlus/fork/watermark/watermark_runtime.dart';
import 'package:PiliPlus/models/video/play/url.dart' show Volume;
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/data_source.dart';
import 'package:media_kit/media_kit.dart';

/// The single object the upstream player controller talks to.
///
/// Everything the fork adds to the player lives behind this bridge, so the
/// upstream file only keeps a handful of marked hook calls.
final class PlPlayerFork {
  PlPlayerFork(this.controller) {
    renewal = ForkStreamRenewal(
      isPlaying: () =>
          !controller.isLive && controller.playerStatus.isPlaying,
      positionMs: () => controller.positionInMilliseconds,
    );
  }

  final PlPlayerController controller;
  final ForkWatermarkRuntime watermark = ForkWatermarkRuntime();
  late final ForkStreamRenewal renewal;

  /// Registers the page callback that refetches the playurl.
  void bindRenewer(Future<bool> Function()? renewer) {
    renewal.renew = renewer;
  }

  Future<void> beforeOpen() async {
    renewal.clearSource();
    await watermark.beforeOpen();
  }

  void afterOpen(String mediaUrl, {required bool isLive}) {
    renewal.markSource(mediaUrl, isLive: isLive);
  }

  /// Reloads the player's media source in-place without pausing, without
  /// clearing danmaku, and without flashing a loading spinner.
  ///
  /// Only used for VOD stream renewal: live streams reconnect on their own.
  Future<void> reloadMedia({
    required String videoUrl,
    String? audioUrl,
    required Duration seekTo,
    required bool play,
    Volume? volume,
  }) async {
    final native = controller.videoPlayerController;
    if (native == null) return;

    controller.dataSource = NetworkSource(
      videoSource: videoUrl,
      audioSource: audioUrl,
    );

    String media = videoUrl;
    if (audioUrl != null && audioUrl.isNotEmpty) {
      if (controller.onlyPlayAudio.value) {
        media = audioUrl;
      } else {
        media =
            'edl://!no_chapters;'
            '%${media.length}%$media;'
            '!new_stream;!no_chapters;'
            '%${audioUrl.length}%$audioUrl;';
      }
    }

    final Map<String, String> extras = {
      ...controller.buffer,
    };
    controller.audioFilterExtras(volume, map: extras);

    await native.open(
      Media(
        media,
        start: seekTo,
        extras: extras.isEmpty ? null : extras,
      ),
      play: play,
    );
    afterOpen(media, isLive: false);
    // mpv resets the shader list on media change; re-add the watermark filter.
    await afterReload();
  }

  void started({
    required bool isLive,
    required bool onlyPlayAudio,
    required int? cid,
    int? width,
    int? height,
  }) {
    final player = controller.videoPlayerController;
    if (player == null) return;
    watermark.started(
      player: player,
      bvid: _bvidOrNull(),
      cid: cid,
      isLive: isLive,
      onlyPlayAudio: onlyPlayAudio,
      width: width,
      height: height,
    );
  }

  /// Re-applies the watermark filter after an in-place media reload; the
  /// shader list is reset by mpv when the media changes.
  Future<void> afterReload() async {
    final player = controller.videoPlayerController;
    if (player != null) {
      await watermark.afterShaderChanged(player);
    }
  }

  Future<void> afterShaderChanged(Player player) =>
      watermark.afterShaderChanged(player);

  /// Returns true when the guard handled the error.
  bool onStreamError(String event) => renewal.onStreamError(event);

  void dispose() {
    renewal.dispose();
    watermark.dispose();
  }

  String? _bvidOrNull() {
    try {
      return controller.bvid;
    } catch (_) {
      return null;
    }
  }
}
