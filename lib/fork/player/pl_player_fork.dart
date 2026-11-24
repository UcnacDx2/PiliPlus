import 'package:PiliPlus/fork/player/stream_renewal.dart';
import 'package:PiliPlus/fork/watermark/watermark_runtime.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
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
      toast: SmartDialog.showToast,
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
